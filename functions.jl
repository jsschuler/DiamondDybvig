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

# we also need a function to copy a model

function copy(mod::Model)
    return Model(deepcopy(mod.nonBankingList),
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
       # println(j) 
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




# we need a function to turn NaN into infinity
function process(x::Float64)
    if isnan(x)
        return Inf
    else
        return x
    end
end


function optimFuncGen(insur::Float64,prod::Float64,riskAversion::Float64)
    # set up the model
    function runInstances(params)
        mod=modelGen(1000,params[:subjP],params[:objP],insur,prod,riskAversion)
        bargain(mod)
        #if isfile("modSave.jld2")
        #    mod=JLD2.load("modSave.jld2")["model"]
        #else
        #    bargain(mod)
        #    @save "modSave.jld2" model=mod
        #end
        global runCnt
        modVec=Model[]
        for t in 1:runCnt
            push!(modVec,copy(mod))
        end
        resultVec=runMain.(modVec)
        #if isfile("runSave.jld2")
        #    resultVec=JLD2.load("runSave.jld2")["runVec"]
        #else
        #    resultVec=runMain.(modVec)
        #    @save "runSave.jld2" runVec=resultVec
        #end
        #println(resultVec)
        cnt=length(resultVec)

        
        # now, we need to calcuate the probability distribution of outcomes
        # under the representive agent's subjective assumption
        simMod=clone(mod)
        X=Binomial(agtCnt,params[:subjP])
        # now, for each possible number of withdrawing agents, determine whether
        # the bank has failed or not. 
        failVec=Float64[]
        nonFailVec=Float64[]
        for t in 0:agtCnt
            push!(failVec,(simMod.theBank.vault-t*(1+simMod.insur)*simMod.deposit <= 0)*pdf(X,t))
            push!(nonFailVec,(simMod.theBank.vault-t*(1+simMod.insur)*simMod.deposit > 0)*pdf(X,t))
        end
        # now get the probability of the bank failure UNDER the agent's hypothesis
        failProb=sum(failVec)
        nonFailProb=1-failProb
        #println(failProb)
        # now get the probability of each number of withdrawals condiional on failure
        condFailProb=failVec./failProb
        confNonFailProb=nonFailVec./nonFailProb
        # now we put these together
        failLabel=vcat(repeat([true],1),repeat([false],agtCnt+1))
        eventProbs=vcat([1.0],confNonFailProb)
        withdrawCount=vcat(agtCnt,collect(0:agtCnt))
        # add a column of 0's to change into pHat
        outFrame=DataFrame(fail=failLabel,withdrawals=withdrawCount,Prob=eventProbs,realCounts=repeat([0],(agtCnt+2)))
        # now for each run of the model, increment the relevant count by 1
        # also get failure counts when we run the actual model
        failCount=0
        for res in resultVec
            runVal=res[1]
            if runVal
                failCount=failCount+1
            end
            wCount=res[2]
            #println("tst")
            #println(outFrame.fail.==runVal)
            #println(outFrame.withdrawals.==wCount)
            #println(outFrame.fail.==runVal .&& outFrame.withdrawals.==wCount)
            outFrame[outFrame.fail.==runVal .&& outFrame.withdrawals.==wCount,:realCounts]=outFrame[outFrame.fail.==runVal .&& outFrame.withdrawals.==wCount,:realCounts].+1
        end

        modFailProb=failCount/length(resultVec)
        #println("True Fail Prob")
        #println(modFailProb)
        # now build a vector with P(FAIL)
        outFrame.modProbFail=vcat([modFailProb],repeat([1-modFailProb],agtCnt+1))
        outFrame.realProb.=outFrame.realCounts ./ length(resultVec)
        outFrame.jointProbSub=outFrame.Prob .* vcat([failProb],repeat([nonFailProb],agtCnt+1))
        outFrame.jointProbObj=outFrame.modProbFail .*  outFrame.realProb
        # now, we cannot allow zero probabilities for the purpose of calculating divergence. 
        # find the smallest probability in both and add in to every probability
        # renormalize probabilities over their sum, this also accounts for float errors
        # for this reason, we also remove impossible events
        filter!(row -> row.Prob !=0.0, outFrame)

        #println("Mins")

        #println(outFrame)
        #println(minimum(outFrame.jointProbSub))
        #println(minimum(outFrame.jointProbObj))
        
        outFrame.jointProbSub=outFrame.jointProbSub .+max(minimum(outFrame.jointProbSub),minimum(outFrame.jointProbObj))
        outFrame.jointProbObj=outFrame.jointProbObj .+max(minimum(outFrame.jointProbSub),minimum(outFrame.jointProbObj))
        outFrame.jointProbSub=outFrame.jointProbSub ./sum(outFrame.jointProbSub)
        outFrame.jointProbObj=outFrame.jointProbObj ./sum(outFrame.jointProbObj)


        # now form mixture distribution for Jensen-Shannon Divergence
        outFrame.M=(outFrame.jointProbSub+outFrame.jointProbObj)/2
        #println(outFrame.jointProbSub)
        #println(outFrame.jointProbObj)
        #println(sum(outFrame.M))


        
        # now calculate each row's addition to Jensen-Shannon divergence
        outFrame.JSDiv=outFrame.jointProbSub .* log2.(outFrame.jointProbSub./outFrame.M) .+ 
                       outFrame.jointProbObj .* log2.(outFrame.jointProbObj./outFrame.M)

        return sum(outFrame.JSDiv)
    end
    return runInstances
end

# now we need a function that runs the optimization for certain values
# this function will be sent to other cores

function optimize(insur::Float64,prod::Float64,riskAversion::Float64)
    optFunc=optimFuncGen(insur,prod,riskAversion)
    space = Dict(
    :subjP => HP.QuantUniform(:subjP,0.0,.01, 1.0),
    :objP => HP.QuantUniform(:objjP,0.0,.01, 1.0)
    )

    best = fmin(
        optFunc, # The function to be optimised.
        space,         # The space over which the optimisation should take place.
        10,          # The number of iterations to take.
)
    return best
end

# now we need some functions to handle the multi-threading
function isReady(arg::Future)
    return isready(arg)
end

function isReady(arg::Nothing)
    return false
end