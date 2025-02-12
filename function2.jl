# the functions file

function util(mod::ModBase,x::Float64)
    if x < 0
        x=0
    end

    y=1+x
    if mod.riskAversion==1.0
        return(log(y))
    else
        return((y^(1-mod.riskAversion))/(1-mod.riskAversion))
    end
end

function modUtilGen(mod::ModBase)
    function tmpFunc(x::Float64)
        return util(mod,x)
    end
    return tmpFunc
end


function agtGen(mod::Model)
    push!(mod.bankingList,Agent())
end

# now a function to generate a model
function modelGen(endow::Int64,
                 subjP::Float64,
                 objP::Float64,
                 insur::Float64,
                 prod::Float64,
                 riskAver::Float64)
    global agtCnt
    mod=Model(Agent[],Agent[],endow,0,objP,subjP,insur,prod,riskAver,Bank(0))
    for t in 1:agtCnt
        agtGen(mod)
    end
    return mod
end



# Now, we need a function to simulate one round for agents to compare decisions
# Note that when the agent runs this function, it knows it does not have to withdraw
# we have a function below where the agent does not know this.
function roundSimul(mod::Model,decision::Bool)
    # How many agents have withdrawn?
    wdCount=length(mod.nonBankingList)
    stillBanking=length(mod.bankingList)
    #println("Withdrawn")
    #println(wdCount)
    #println("Still Banking")
    #println(stillBanking)
    # now, if the agent has decided to withdraw, we adjust these by one
    if decision
        wdCount=wdCount+1
        stillBanking=stillBanking-1
    end

    # now generate 1000 uniform variates
    global depth
    uVariates=rand(Uniform(),depth)
    # now, calculate the probability distribution of withdrawals conditional on there being
    # at least the number of observed withdrawals
    global agtCnt
    agtProb=Binomial(agtCnt,mod.subjP)
    cdfCond=Dict{Int64,Float64}()
    #println("Prob")
    #println(ccdf(agtProb,wdCount))
    for t in wdCount:(wdCount+stillBanking)
        cdfCond[t]=(cdf(agtProb,t)-cdf(agtProb,wdCount))/ccdf(agtProb,wdCount)
    end
    #println("CDF")
    #println(sort(collect(keys(cdfCond))))
    countVec=Int64[]
    for uVar in uVariates
        maxCount=0
        for t in wdCount:(wdCount+stillBanking)
            if uVar >= cdfCond[t]
                maxCount=t
            end
        end
        push!(countVec,maxCount)
    end
    #println(countVec)
    #println(maximum(countVec))
    #println(minimum(countVec))
    #println(mean(countVec))
    # now get how many agents have yet to withdraw 
    futureCount=countVec.-wdCount
    #println("future")
    #println(length(futureCount))
    # now, let's calculate the agent's return on the basis of a decision
    payVec=[]
    if decision
        
        # if the agent decides to withdraw, the agent decides to BE one of the withdrawing agents
        # we guaranteed above that the agent always has a spot
        # add the withdrawing agent to the withdrawal count
        futureCount=futureCount.+1
        # now, get the agent's place in line among those withdrawing
        # and in turn, the number of agents 
        for future in futureCount
            simMod=clone(mod)
            #println(length(simMod.bankingList))
            # now the agent has the same probability of being anywhere in line. 
            # Thus, we record the pay out for every withdrawal
            while future > 0
                future=future-1
                paid=withdraw(simMod)
                if isnan(paid)
                    #println("Flag")
                    #println(simMod.bankingList)
                    #println(simMod.theBank.vault)
                    #println(future)
                end
                push!(payVec,paid)
            end
            #println(length(simMod.bankingList))
            
        end
    else
        for future in futureCount
            #println("Hello")
            #println(length(mod.bankingList))
            simMod=clone(mod)
            #println(length(simMod.bankingList))
            while future > 0
                future=future-1
                # Withdraw other agents
                withdraw(simMod)
            end
            #println(length(simMod.bankingList))
            paid=payOut(simMod)
            #if isnan(paid)
            #    println("Flag")
            #    println(simMod.bankingList)
            #    println(simMod.theBank.vault)
            #    println(future)
            #end
            push!(payVec,paid)
        end
    end
    #println("Pays")
    #println(payVec)
    #println(length(payVec))
    #println(payMat[1,:])
    #println(payMat[10,:])
    # now calculate the expected utility
    uFunc=modUtilGen(mod)
    #println("Debug")
    #println(payVec)
    
    # now calculate total consumption
    totConsump=mod.endow .+ payVec

    return sum(uFunc.(totConsump))*(1/length(totConsump))

end

function subSimul(mod::Model)
    global agtCnt
    simMod=clone(mod)
    subBinom=Binomial(agtCnt,simMod.subjP)
    wdCount=rand(subBinom,1)[1]
    wOrder=sample(vcat(repeat([true],wdCount),repeat([false],agtCnt-wdCount)),agtCnt,replace=false)
    # we record each withdrawal amount
    # and repeat the final disbursal among the still banking agents
    # since each agent has an equal probability of being in any order
    payOuts=[]
    for j in 1:length(wOrder)
        if wOrder[j]
            push!(payOuts,withdraw(simMod))
        end
    end
    paidOut=payOut(simMod)
    for i in 1:(agtCnt-wdCount)
        push!(payOuts,paidOut)
    end
    uFunc=modUtilGen(mod)
    # now calculate total consumption
    totConsump=simMod.endow .+ payOuts
    return sum(uFunc.(totConsump))

end

function roundSimul(mod::Model)
    global depth
    global agtCnt
    utilFunc=[]
    for t in 1:depth
        push!(utilFunc,subSimul(mod))
    end
    # now we calculate expected utility
    # the denominator is the agtCnt times the depth 
    # since each subsimulation gives the return for every agent
    # and we run it as many times as the depth function 
    return (1/(agtCnt*depth))*sum(utilFunc)
end

# we need a function to clone a model. 

function clone(mod::Model)
    return SimModel(deepcopy(mod.nonBankingList),
                    deepcopy(mod.bankingList),
                    mod.endow,
                    mod.deposit,
                    mod.objP,
                    mod.subjP,
                    mod.insur,
                    mod.prod,
                    mod.riskAversion,
                    deepcopy(mod.theBank))
end

# we need a function that gives the vector of payments where there have been k withdrawals



# now the bargaining step
# we constrain the agents to all have the same deposit



function bargain(mod::Model)
    totAvail=mod.endow + mod.deposit
    utilResults=[]
    for dep in 0:10:totAvail
        mod.deposit=dep
        mod.endow=totAvail-mod.deposit
        # initialize the vault to empty
        mod.theBank.vault=0
        # now fill the vault
        for k in 1:agtCnt
            mod.theBank.vault=mod.theBank.vault+mod.deposit
        end
        push!(utilResults,roundSimul(mod))
    end
    #println(collect(0:10:totAvail)[argmax(utilResults)])
    mod.deposit=collect(0:10:totAvail)[argmax(utilResults)]
    mod.endow=totAvail-mod.deposit
    # now set the vault with the final decision
    mod.theBank.vault=0
    for k in 1:agtCnt
        mod.theBank.vault=mod.theBank.vault+mod.deposit
    end
end

# we need the withdrawal function

function withdraw(mod::ModBase)
    if length(mod.bankingList) > 0
        #println("Withdrawing")
        #println(length(mod.bankingList))
        pop!(mod.bankingList)
        #println(length(mod.bankingList))
        withdrawn=min((1+mod.insur)*mod.deposit,mod.theBank.vault)
        mod.theBank.vault=max(mod.theBank.vault-withdrawn,0)
    else
        withdrawn=0
    end
    #println(withdrawn)
    return withdrawn

end

function payOut(mod::ModBase)
    #println("Banking")
    #println(length(mod.bankingList))
    if length(mod.bankingList) > 0
        retVal=(1/length(mod.bankingList)*(1+mod.insur+mod.prod)*mod.theBank.vault)
    else 
        retVal=0.0
    end
    return retVal 
end

# now we need the main model function

function runMain(mod::Model)
    # exogenous withdrawals
    global agtCnt
    X=Binomial(agtCnt,mod.objP)
    exogWD=rand(X,1)[1]
    wOrder=sample(vcat(repeat([true],exogWD),repeat([false],agtCnt-exogWD)),agtCnt,replace=false)
    #println(wOrder)
    # now each agent decides whether or not to withdraw
    for j in 1:length(wOrder)
        println(j) 
        # is the agent withdrawing 
        if wOrder[j]
            withdraw(mod)
            #println("Exogenous Withdrawal")
        else
            wUtil=roundSimul(mod,true)
            sUtil=roundSimul(mod,false)
            #println(wUtil)
            #println(sUtil)
            if wUtil > sUtil
                withdraw(mod)
                #println("Endogenous Withdrawal")
            end
        end
        #println("Still Banking")
        #println(length(mod.bankingList))
        if mod.theBank.vault <= 0
            break
        end
    end
    # pull in global agent count
    global agtCnt
    withdrawalCnt=length(mod.bankingList)
    # now report the number of withdrawals and the run condition
    # if there has been a run, we consider all agents to have withdrawn 
    runCond::Bool=false
    if mod.theBank.vault <= 0
        runCond=true
        withdrawalCnt=agtCnt
    end
    # now what is the return?
    paid=payOut(mod)
    return (runCond,withdrawalCnt,paid)
end

# now we need the optimization functions

function runFuncGen(params,insur::Float64,prod::Float64,riskAversion::Float64)
    function runInstance(x)
        mod=modelGen(1000,params[:subjP],params[:objP],insur,prod,riskAversion)
        bargain(mod)
        result=runMain(mod)
    end
    return runInstance
end


function runInstance(params)
    repFunc=runFuncGen(params)
    # run the model with these parameters a certain number of times
    global runCnt
    resultVec=repFunc.(1:runCnt)
    runVec=Bool[]
    noRunCounts=Int64[]
    for res in resultVec
            push!(runVec,res[1])
            if ! res[1]
                push!(noRunCounts,res[2])
            end
        # now calculate run probability
        runProb=mean(runVec)
        # and calculate rates of each number of withdrawals
        countDict=Dict()
        for el in noRunCounts
            if !(el in keys(countDict))
                countDict[el]=1
            else
                countDict[el]=countDict[el] +1
            end
        end
        # now calculate a probability dictionary
        denom=runCnt-sum(runVec)
        probDict=Dict()
        for ky in keys(countDict)
            probDict[ky]=countDict[ky]/denom
        end
    end
end


# now we need a function that generates the probability distribution of outcomes based on 
# agent expectations alone. 
# we need a function that packages the non-tuned parameters
function probFuncGen(params,insur::Float64,prod::Float64,riskAversion::Float64)
    function runInstance(withdrawCount::Int64)
        mod=modelGen(1000,params[:subjP],params[:objP],insur,prod,riskAversion)

    end
    return runInstance
end


function baseProb()

end

function optimize(params)


end

space = Dict(
    :objP => HP.QuantUniform(:objP,0.0,.001, 1.0),
    :subjP => HP.QuantUniform(:subjP,0.0,.001, 1.0),
)