################################################################################################################
#                               Functions File: Uniform Version                                                #
#                               Diamond Dybvig                                                                 #
#                               September 2024                                                                 #
#                               John S. Schuler                                                                #
################################################################################################################

# Important: CLEARLY DISTINGUISH functions operating on main model agents vs those operating on the cloned simulation agents



# a utility function that takes an agent object and an quantity
function util(agt::Agent,x::Int64)
    if x < 0
        x=0
    end

    y=Float64(1+x)
    if agt.riskAversion==1.0
        return(log(y))
    else
        return((y^(1-agt.riskAversion))/(1-agt.riskAversion))
    end
end

# this function generates an agent in a model

function agtGen(mod::Model)

    mod.agtTicker=mod.agtTicker+1
    push!(mod.agtList,Agent(mod.agtTicker,mod.endow,mod.riskAversion,0,mod.p))
    # now generate agent file
    # Recall, there are two parameters, the agent's subject withdrawal probability which is the same for all agents
    # and the actual exogenous type 1 probability. We are calibrating the model such that the empirical
    # withdrawal probability matches the single subjective probability for all agents 
    # and so the agents have ratEx!
    df=DataFrame(currKey=[mod.key],
              agt=[mod.agtTicker],
              endow=[mod.endow],
              risk=[mod.riskAversion],
              prob=[mod.p]
              )
              #println(typeof(key))
              CSV.write("../Data6/agents"*mod.key*".csv", df,header = false,append=true)


end

# the following function simulates one shot of the process. 
# that is, a single exogenous withdrawal
function agtSimRound(mod::Model,agt::Agent)
    # this simulates one round
    # now, what agents are participating?
    participatingAgts::Array{Agent}=Agent[]
    for agt in mod.agtList
        if agt.deposit > 0
            push!(participatingAgts,agt)
        end
    end

    myBinom=Binomial(length(participatingAgts),agt.p)
    withdrawals=rand(myBinom,1)[1]
    #println("Withdrawals")
    #println(withdrawals)
    #println(mod.theBank.vault)
    agtWithDraw=sample(participatingAgts,withdrawals,replace=false)
    # is the current agent among those who withdrew?
    # copy the vault so as not to change it
    simVault=mod.theBank.vault
    # initialize withdrew to false. We will change it if the current agent in fact withdrew
    withdrew::Bool=false
    # we need to track how many deposits are withdrawn
    # so we can calculate the agent's shares of the return
    withDrawEndow=Int64[]
    # save the original vault for later calculations of shares
    totVault=mod.theBank.vault
    for currAgt in agtWithDraw
        #remove its endowment from the simulated vault
        simVault=simVault-ceil(Int64,(1+mod.insur)*currAgt.deposit)
        push!(withDrawEndow,currAgt.endow)
        if currAgt==agt
            #println("Withdrawal")
            if simVault < 0
                #println("Bankruptcy!")
                # if the simVault is negative, we remove the negative from the agent's return
                agtReturn=max(0,currAgt.endow+ceil(Int64,(1+mod.insur)*currAgt.deposit)+simVault)
                # set withdrew to true if the agent did
                withdrew=true
            else
                #println("No Bankruptcy")
                #println("Debug")
                #println(currAgt.deposit)
                #println(ceil(Int64,(1+insur)*currAgt.deposit))
                # Otherwise, the agent gets the full return
                agtReturn=currAgt.endow+ceil(Int64,(1+mod.insur)*currAgt.deposit)
                # set withdrew to true if the agent did
                withdrew=true
            end
            #println("Withdrawal Return")
            #println(agtReturn)
        end
    end
    # now if the agent did not withdraw, it gets its share of the leftover
    if withdrew==false
        totReturn=ceil(Int64,(1+mod.insur+mod.prod)*max(0,simVault))
        #println("No Withdrawal")
        #println("Total Return")
        #println(totReturn)
        # agent gets a share of the return proportional to what it put in
        if totVault - sum(withDrawEndow) > 0
            share=agt.deposit/(totVault-sum(withDrawEndow))
        else
            share=0
        end
        agtReturn=agt.endow+floor(Int64,share*totReturn)
        #println("Non-Withdrawal Return")
        #println(agtReturn)
    end
    #println(agtReturn)
    return agtReturn
end

# now we have a function that runs the one-shot agent simulation function in parallel
function agtSim(mod::Model,agt::Agent)
    # this function applies the simulation in parallel
    modArray=repeat([mod],mod.depth)
    agtArray=repeat([agt],mod.depth)
    #println(agtArray)
    #println(typeof(agtArray))
    # now use folds later for the tuning verions
    #Folds.map(agtSimRound,modArray,agtArray)
    
    #println("Running Agent Simulation")
    agtSimRound.(modArray,agtArray)
end

# now, we need a function that calculates a vector of utilities from the simulation returns

function simUtil(mod::Model,agt::Agent)
    # this function runs the simulation and returns the utility
    aFunc   = function(x)
        return(util(agt,x))
    end
    # now, get the simulated returns as each agent runs its own simulation
    returns=agtSim(mod,agt)
    #println(typeof(returns))
    #println(returns)
    #println(aFunc(1000))
    utilVec::Array{Float64,1}=map(aFunc,returns)
    #utilVec=Folds.map(aFunc,returns)
    
    #println("Returns")
    #println(returns)
    retMean=mean(returns)
    retMin=minimum(returns)
    retMax=maximum(returns)
    #println("Average Return")
    #println(retMean)
    #println("Min Return")
    #println(retMin)
    #println("Max Return")
    #println(retMax)
    return utilVec
end

# now we need a function that runs the bargaining for each agent
function agtDecision(mod::Model,agt::Agent)
    # the agent decides how much to invest given all
    # other agents have invested
    # reset this agent's endowment and deposit
    origEndow::Int64=agt.endow+agt.deposit
    origDeposit::Int64=agt.deposit
    #println("original endowment")
    #println(origEndow)
    #println(bargRes)
    #println(agt.endow)
    options::Array{Int64}=collect(0:mod.bargRes:origEndow)
    #println("options")
    #println(options)
    Util=Float64[]
    for opt in options
        agt.deposit=opt
        agt.endow=origEndow-opt
        #println("Deposit and Endow")
        #println(agt.deposit)
        #println(agt.endow)

        # the model parameter "depth" refers to the number of times each agent runs a simulation
        # thus, it is the appropriate denominator for the expected utility

        totUtil=sum(simUtil(mod,agt))/mod.depth
        totUtil::Float64
        push!(Util,totUtil)
        #println("Utility")
        #println(opt)
        #println(totUtil)
    end
    # now find the highest utility option
    #println("utilities")
    #println(Util)
    #for i in 1:length(options)
        #println(options[i]," ",Util[i])
    #end

    # the agent finds the deposit with the highest expected utility

    bestDeposit=options[findmax(Util)[2]]
    #println("Best Deposit")
    #println(bestDeposit)
    #println("Best Utility")
    #println(Util[findmax(Util)[2]])
    #println("All Utils")
    #println(Util)
    #println("Vault")
    #println(mod.theBank.vault)
    agt.deposit=bestDeposit
    agt.endow=origEndow-agt.deposit
    # now reset vault
    mod.theBank.vault=mod.theBank.vault-origDeposit+agt.deposit
    return agt.deposit
end


function bargain(mod::Model)
    # now, we keep track of each agent's preferred deposit for
    # the past two rounds. If no agent changes in two rounds, we break
    penultiRound=similar(mod.agtList,Int64)
    ultiRound=similar(mod.agtList,Int64)
    penultiRound=ultiRound
    while true
        for i  in 1:length(mod.agtList)
            #println("Decisions!")
            #println(mod.agtList[i].deposit)
            agtDecision(mod,mod.agtList[i])
            #println(mod.agtList[i].deposit)
            ultiRound[i]=mod.agtList[i].deposit
        end
        #println("Arrays")
        #println(penultiRound)
        #println(ultiRound)
        if all(penultiRound.==ultiRound)
            break
        end
    end
end



function withdraw(mod::Model,agt::Agent,exog::Bool)
    # this function makes the agent withdraw
    payout=min(mod.theBank.vault,round(Int64,(1+mod.insur)*agt.deposit))
    mod.theBank.vault=mod.theBank.vault-payout
    agt.endow=agt.endow+payout
    deleteat!(mod.agtList, findall(x->x==agt,mod.agtList))
    #push!(withDList,agt)
    retVal=false
    retVal::Bool
    if mod.theBank.vault==0
        retVal=true
    end
    df=DataFrame(currKey=[mod.key],
              agt=[agt.idx],
              deposit=[agt.deposit],
              exogW=[exog],
              Failure=[retVal]
              )
              CSV.write("../Data6/withdrawals"*mod.key*".csv", df,header = false,append=true)

    return(retVal)
end

function withdrawDecision(mod::Model,agt::Agent)
    # once the deposits are in, the agents decide whether to withdraw
    # if activation is true, the agent decides between certainty of
    # either the full deposit with insurance or the entire bank vault
    # which ever is larger
    # and the simulated payout including being later forced to withdraw
    # load the utility function
    aFunc   = function(x)
        return(util(agt,x))
    end


    wPayout::Float64=aFunc(min(mod.theBank.vault,round(Int64,(1+mod.insur)*agt.deposit)))
    totUtil::Float64=sum(simUtil(mod,agt))/mod.depth
    retVal::Bool=false
    bankrupt::Bool=false

    withdrawDesire=(wPayout > totUtil)::Bool
    if  withdrawDesire
        bankrupt=withdraw(mod,agt,false)
        retVal=true
    end

    global key
    df=DataFrame(currKey=[mod.key],
              agt=[agt.idx],
              deposit=[agt.deposit],
              withdraw=[withdrawDesire],
              Failure=[bankrupt],
              wdUtil=[wPayout],
              stUtil=[totUtil]
              )
              CSV.write("../Data6/activations"*mod.key*".csv", df,header = false,append=true)

    return(Bool[bankrupt,retVal])
end

# we want a function that generates the model 
function modelGen(insur::Float64,prod::Float64,exogP::Float64,endow::Int64,riskAversion::Float64,p::Float64)
    seed::Int64=sample(1:100000000,1)[1]
    mod=Model(0,Array{Agent}[],1000,insur,prod,100,exogP,endow,riskAversion,p,1000,seed,Bank(0),"run-"*string(now())*"-"*string(seed))
    #println("Generating Agents")
    for i in 1:50
        agtGen(mod)
    end
    #println(length(mod.agtList))
    for agt in mod.agtList
        agt.deposit=agt.endow-100
        agt.endow=100
    end
    deposits=Int64[]
    for agt in mod.agtList
        push!(deposits,agt.deposit)
    end
    mod.theBank=Bank(sum(deposits))
    #println("Pre-Bargain")
    #println(mod.theBank.vault)
    bargain(mod)
    #for agt in mod.agtList
    #    println(agt.deposit)
    #end
    mod.agtList=filter!(x-> x.deposit !=0,mod.agtList)
    #println("TST")
    #println(length(mod.agtList))
    deposits=Int64[]
    for agt in mod.agtList
        push!(deposits,agt.deposit)
    end
    mod.theBank=Bank(sum(deposits))

    return mod
end
# now we need a function that generates a "study", that is generates a series of models with certain fixed parameters


function modelRun(mod::Model)
    # this is the main model function.
    # first, we find out which agents are type 1
    #println("P")
    #println(mod.exogP)
    #println(length(mod.agtList))
    univBinom=Binomial(length(mod.agtList),mod.exogP)
    withdrawals=rand(univBinom,1)[1]
    #println("withdrawals exogenous")
    #println(withdrawals)
    #println(length(withdrawals))
    agtWithdraw=sample(mod.agtList,withdrawals,replace=false)
    bankrupt=false
    bankrupt::Bool
    withdrawalsCount::Int64=withdrawals
    for agt in agtWithdraw
        bankrupt=withdraw(mod,agt,true)
        if bankrupt
            #println("Bank FAILS!")
        end
    end
    if ! bankrupt
        # now that the type 1 agents have bailed, other agents reconsider their decision
        # shuffle the agent list
        cond=true
        cond::Bool
        while cond
            withdrawing=Bool[]
            # sort agents in random order
            mod.agtList=sample(mod.agtList,length(mod.agtList),replace=false)
            for agt in mod.agtList
                # this is where we track activation
                decision=withdrawDecision(mod,agt)
                push!(withdrawing,decision[2])
                if decision[2]
                    withdrawalsCount=withdrawalsCount+1
                end
                if decision[1]
                    #println("Bank Fails!")
                    bankrupt=true
                end
            end
            cond=any(withdrawing)
        end
    end
    #println((bankrupt,withdrawalsCount+1))
    return (bankrupt,withdrawalsCount)
end

function modelRunProc(arg)
    #println(arg)
    if arg[1]
        outP=1.0
    else
        outP=arg[2]/50
    end
    return outP 
end

# now, we need a function to define a study
function studyGen(insur::Float64,prod::Float64,riskAversion::Float64,exogP::Float64)
    return Study(insur,prod,riskAversion,exogP)
end

# now a function for a single run

function studyStep(study::Study,withDrawProb::Float64)
    modResults=[]
    for t in 1:100
        # generate model
        mod=modelGen(study.insur,study.prod,study.exogP,1000,study.riskAversion,withDrawProb)
        push!(modResults,modelRun(mod))
    end
    results=modelRunProc.(modResults)
    #results=Folds.map(modelRunProc,modResults,mode=Folds.Distributed())
    #Array{Float64,1}
    # now, calculate the expected withdrawals
    expWD=repeat([floor(Int64,50*withDrawProb)],100)
    divergence=(expWD./50).*(expWD./results)
    println("Divergence")
    println(divergence)
    println(expWD./results)
    println(sum(divergence))
    return sum(divergence)
end


# now, the optimization function takes a study and finds the ratEx configuration for the study
function RunStudy(study::Study)
    # define the space
    space = Dict(
    :subjP => HP.QuantUniform(:subjP,0.1, .9,.1)
    )

    function optimGen(study::Study)
        function outFunc(params)
            println("parameter")
            println(params[:subjP])
            return studyStep(study,params[:subjP])
            #return -params[:subjP]^2
            
        end
        return outFunc
    end
    optim=optimGen(study)
    println("Check")
    println(collect(methods(optim)))
    println(params)
    best = fmin(
    optim, # The function to be optimised.
    space,         # The space over which the optimisation should take place.
    20          # The number of iterations to take.
    )
    return best
end