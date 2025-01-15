# the functions file

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

function agtGen(endow::Int64,riskAversion::Float64,p::Float64)
    global agtTicker
    agtTicker=agtTicker+1
    push!(agtList,Agent(agtTicker,endow,riskAversion,0,p))
    # now generate agent file
    global key
    df=DataFrame(currKey=[key],
              agt=[agtTicker],
              endow=[endow],
              risk=[riskAversion],
              prob=[p]
              )
              #println(typeof(key))
              CSV.write("../Data6/agents"*key*".csv", df,header = false,append=true)


end

function constraintGen()
    # this function generates the agents with the parametric constraints
    global fixRisk
    global fixEndow
    global fixProb
    global agtCnt
    if fixRisk
        if fixEndow
            # fix risk and endow
            fEndow=sample(50:50:1000,1)[1]
            fRisk=sample(0:.1:2)[1]
            for a in 1:agtCnt
                agtGen(fEndow,fRisk,sample(.05:.05:.2,1)[1])
            end
        else
            if fixProb
                # fix risk and prob
                fRisk=sample(0:.1:2)[1]
                fProb=sample(.05:.05:.2)[1]
                for a in 1:agtCnt
                    agtGen(sample(50:50:1000,1)[1],fRisk,fProb)
                end
            else
                # fix risk only
                fRisk=sample(0:.1:2)[1]
                for a in 1:agtCnt
                    agtGen(sample(50:50:1000,1)[1],fRisk,sample(.05:.05:.2,1)[1])
                end
            end
        end
    else
        if fixEndow
            fEndow=sample(50:50:1000,1)[1]
            if fixProb
                fProb=sample(.05:.05:.2)[1]
                # fix endow and prob
                fEndow=sample(50:50:1000,1)[1]
                fProb=sample(.05:.05:.2)[1]
                for a in 1:agtCnt
                    agtGen(fEndow,sample(0:.1:2)[1],fProb)
                end
            else
                # fix endow only
                fEndow=sample(50:50:1000,1)[1]
                for a in 1:agtCnt
                    agtGen(fEndow,sample(0:.1:2)[1],sample(.05:.05:.2,1)[1])
                end
            end
        else
            if fixProb
                # fix prob only
                fProb=sample(.05:.05:.2)[1]
                for a in 1:agtCnt
                    agtGen(sample(50:50:1000,1)[1],sample(0:.1:2)[1],fProb)
                end
            else
                # fix nothing
                for a in 1:agtCnt
                    agtGen(sample(50:50:1000,1)[1],sample(0:.1:2)[1],sample(.05:.05:.2,1)[1])
                end
            end
        end
    end
end
function agtSimRound(agt::Agent)
    # this simulates one round
    myBinom=Binomial(length(agtList),agt.p)
    withdrawals=rand(myBinom,1)[1]
    global agtList
    agtWithDraw=sample(agtList,withdrawals,replace=false)
    # is the current agent among those who withdrew?
    simVault=theBank.vault
    withdrew=false
    withdrew::Bool
    # we need to track how many deposits are withdrawn
    # so we can calculate the agent's shares of the return
    withDrawEndow=Int64[]
    # save the original vault for later calculations
    totVault=theBank.vault
    for currAgt in agtWithDraw
        simVault=simVault-ceil(Int64,(1+insur)*currAgt.deposit)
        push!(withDrawEndow,currAgt.endow)
        if currAgt==agt
            if simVault < 0
                #println("Bankruptcy!")
                agtReturn=currAgt.endow+ceil(Int64,(1+insur)*currAgt.deposit)+simVault
                agtReturn::Int64
                withdrew=true
            else
                #println("No Bankruptcy")
                #println("Debug")
                #println(currAgt.deposit)
                #println(ceil(Int64,(1+insur)*currAgt.deposit))
                agtReturn=currAgt.endow+ceil(Int64,(1+insur)*currAgt.deposit)
                agtReturn::Int64
                withdrew=true
            end
            #println("Withdrawal")
            #println(agtReturn)
        end
    end
    # now if the agent did not withdraw, it gets its share of the leftover
    if withdrew==false
        totReturn=ceil(Int64,(1+prod)*max(0,simVault))
        #println("No Withdrawal")
        #println("Total Return")
        #println(totReturn)
        if totVault - sum(withDrawEndow) > 0
            share=agt.deposit/(totVault-sum(withDrawEndow))
        else
            share=0
        end
        agtReturn=agt.endow+floor(Int64,share*totReturn)
        agtReturn::Int64
        #println("Agent Return")
        #println(agtReturn)
    end
    #println(agtReturn)
    return agtReturn
end

function agtSim(agt)
    # this function applies the simulation in parallel
    global depth
    agtArray=repeat(Agent[agt],depth)
    Folds.map(agtSimRound,agtArray,ex=ThreadedEx())
end

function simUtil(agt)
    # this function runs the simulation and returns the utility
    aFunc   = function(x)
        return(util(agt,x))
    end
    returns=agtSim(agt)
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

# now we need a function that runs the bargaining
function agtDecision(agt::Agent)
    # the agent decides how much to invest given all
    # other agents have invested
    # reset this agent's endowment and deposit
    origEndow=agt.endow+agt.deposit
    origEndow::Int64
    origDeposit=agt.deposit::Int64
    #println("original endowment")
    #println(origEndow)
    global bargRes
    #println(bargRes)
    #println(agt.endow)
    options=collect(0:bargRes:origEndow)
    options::Array{Int64}
    #println("options")
    #println(options)
    Util=Float64[]
    for opt in options
        agt.deposit=opt
        agt.endow=origEndow-opt
        #println("Deposit and Endow")
        #println(agt.deposit)
        #println(agt.endow)
        global depth
        totUtil=sum(simUtil(agt))/depth
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
    bestDeposit=options[findmax(Util)[2]]
    #println("Best Deposit")
    #println(bestDeposit)
    agt.deposit=bestDeposit
    agt.endow=origEndow-agt.deposit
    # now reset vault
    global theBank
    theBank.vault=theBank.vault-origDeposit+agt.deposit

end


function bargain()
    # now, we keep track of each agent's preferred deposit for
    # the past two rounds. If no agent changes in two rounds, we break
    ultiRound=similar(agtList,Int64)
    t=0
    while true
        penultiRound=deepcopy(ultiRound)
        t=t+1
        for i  in 1:length(agtList)
            agtDecision(agtList[i])
            ultiRound[i]=agtList[i].deposit
        end
        #println(t)
        #println("Arrays")
        #println(penultiRound)
        #println(ultiRound)
        if all(penultiRound.==ultiRound)
            break
        end
    end
end



function withdraw(agt::Agent,exog::Bool)
    # this function makes the agent withdraw
    global insur
    payout=min(theBank.vault,round(Int64,(1+insur)*agt.deposit))
    theBank.vault=theBank.vault-payout
    agt.endow=agt.endow+payout
    deleteat!(agtList, findall(x->x==agt,agtList))
    push!(withDList,agt)
    retVal=false
    retVal::Bool
    if theBank.vault==0
        retVal=true
    end
    global key
    df=DataFrame(currKey=[key],
              agt=[agt.idx],
              deposit=[agt.deposit],
              exogW=[exog],
              Failure=[retVal]
              )
              CSV.write("../Data6/withdrawals"*key*".csv", df,header = false,append=true)

    return(retVal)
end

function conditionalWithdraw(agt::Agent,withdraws::Array{Agent})
    # first, we need a copy of the array of agents
    global agtList
    allAgts=agtList
    allAgts::Array{agent}

end


function withdrawDecision(agt::Agent)
    # once the deposits are in, the agents decide whether to withdraw
    # if activation is true, the agent decides between certainty of
    # either the full deposit with insurance or the entire bank vault
    # which ever is larger
    # and the simulated payout including being later forced to withdraw
    global theBank
    global insur
    global depth
    # load the utility function
    aFunc   = function(x)
        return(util(agt,x))
    end


    wPayout=aFunc(min(theBank.vault,round(Int64,(1+insur)*agt.deposit)))
    wPayout::Float64
    totUtil=sum(simUtil(agt))/depth
    totUtil::Float64
    retVal=false
    retVal::Bool
    bankrupt=false
    bankrupt::Bool
    withdrawDesire=(wPayout > totUtil)::Bool
    if  withdrawDesire
        bankrupt=withdraw(agt,false)
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


function model()
    # this is the main model function.
    # first, we find out which agents are type 1
    univBinom=Binomial(length(agtList),exogP)
    withdrawals=rand(univBinom,1)[1]
    #println("withdrawals exogenous")
    #println(withdrawals)
    global agtList
    agtWithdraw=sample(agtList,withdrawals,replace=false)
    global activation
    # if the activation parameter is true, then agents announce a withdrawal and
    # withdraw. If false, all agents announce before withdrawing.
    bankrupt=false
    bankrupt::Bool

    for agt in agtWithdraw
        bankrupt=withdraw(agt,true)
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
