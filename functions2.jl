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
    push!(agtList,Agent(mod.agtTicker,mod.endow,mod.riskAversion,0,mod.p))
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
              CSV.write("../Data6/agents"*key*".csv", df,header = false,append=true)


end

# the following function simulates one shot of the process. 
# that is, a single exogenous withdrawal
function agtSimRound(mod::Model,agt::Agent)
    # this simulates one round
    myBinom=Binomial(length(mod.agtList),agt.p)
    withdrawals=rand(myBinom,1)[1]
    agtWithDraw=sample(mod.agtList,withdrawals,replace=false)
    # is the current agent among those who withdrew?
    # copy the vault so as not to change it
    simVault=theBank.vault
    # initialize withdrew to false. We will change it if the current agent in fact withdrew
    withdrew::Bool=false
    # we need to track how many deposits are withdrawn
    # so we can calculate the agent's shares of the return
    withDrawEndow=Int64[]
    # save the original vault for later calculations of shares
    totVault=theBank.vault
    for currAgt in agtWithDraw
        #remove its endowment from the simulated vault
        simVault=simVault-ceil(Int64,(1+mod.insur)*currAgt.deposit)
        push!(withDrawEndow,currAgt.endow)
        if currAgt==agt
            if simVault < 0
                #println("Bankruptcy!")
                # if the simVault is negative, we remove the negative from the agent's return
                agtReturn=currAgt.endow+ceil(Int64,(1+mod.insur)*currAgt.deposit)+simVault
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
            #println("Withdrawal")
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
        #println("Agent Return")
        #println(agtReturn)
    end
    #println(agtReturn)
    return agtReturn
end

# now we have a function that runs the one-shot agent simulation function in parallel
function agtSim(mod::Model,agt::Agent)
    # this function applies the simulation in parallel
    agtArray=repeat([mod,agt],mod.depth)
    Folds.map(agtSimRound,agtArray)
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
    #utilVec=map(aFunc,returns)
    utilVec=Folds.map(aFunc,returns)
    utilVec::Array{Float64,1}
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

        totUtil=sum(simUtil(agt))/mod.depth
        totUtil::Float64
        push!(Util,totUtil)
        #println("Utility")
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
    agt.deposit=bestDeposit
    agt.endow=origEndow-agt.deposit
    # now reset vault
    mod.theBank.vault=mod.theBank.vault-origDeposit+agt.deposit

end


function bargain(mod::Model)
    # now, we keep track of each agent's preferred deposit for
    # the past two rounds. If no agent changes in two rounds, we break
    penultiRound=similar(mod.agtList,Int64)
    ultiRound=similar(mod.agtList,Int64)
    penultiRound=ultiRound
    while true
        for i  in 1:length(mod.agtList)
            agtDecision(mod.agtList[i])
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
    push!(withDList,agt)
    retVal=false
    retVal::Bool
    if theBank.vault==0
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
    totUtil::Float64=sum(simUtil(agt))/mod.depth
    retVal::Bool=false
    bankrupt::Bool=false

    withdrawDesire=(wPayout > totUtil)::Bool
    if  withdrawDesire
        bankrupt=withdraw(mod,agt,false)
        retVal=true
    end

    global key
    df=DataFrame(currKey=[key],
              agt=[agt.idx],
              deposit=[agt.deposit],
              withdraw=[withdrawDesire],
              Failure=[bankrupt],
              wdUtil=[wPayout],
              stUtil=[totUtil]
              )
              CSV.write("../Data6/activations"*key*".csv", df,header = false,append=true)

    return(Bool[bankrupt,retVal])
end


function modelRun(mod::Model)
    # this is the main model function.
    # first, we find out which agents are type 1
    univBinom=Binomial(length(mod.agtList),mod.exogP)
    withdrawals=rand(univBinom,1)[1]
    #println("withdrawals exogenous")
    #println(withdrawals)
    agtWithdraw=sample(mod.agtList,withdrawals,replace=false)
    bankrupt=false
    bankrupt::Bool

    for agt in agtWithdraw
        bankrupt=withdraw(mod,agt,true)
        if bankrupt
            #println("Bank FAILS!")
            return(bankrupt)
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
            agtList=sample(agtList,length(agtList),replace=false)
            for agt in agtList
                # this is where we track activation
                decision=withdrawDecision(agt)
                push!(withdrawing,decision[2])
                if decision[1]
                    #println("Bank Fails!")
                    return(decision[1])
                end
            end
            cond=any(withdrawing)
        end
    end
return(bankrupt)
end

