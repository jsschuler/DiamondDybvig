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
# Now, we need a function to simulate one round


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
    println("future")
    println(length(futureCount))
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
            while future > 0
                future=future-1
                push!(payVec,withdraw(simMod))
            end
            
        end
    else
        for future in futureCount
            #println("Hello")
            simMod=clone(mod)
            while future > 0
                future=future-1
                # Withdraw other agents
                withdraw(simMod)
            end
            push!(payVec,payOut(simMod))
        end
        
        
    end
    println("Pays")
    println(payVec)
    #println(payMat[1,:])
    #println(payMat[10,:])
    #return expReturn

end

# we need a function to clone a model. 

function clone(mod::Model)
    return SimModel(mod.nonBankingList,
                    mod.bankingList,
                    mod.endow,
                    mod.deposit,
                    mod.objP,
                    mod.subjP,
                    mod.insur,
                    mod.prod,
                    mod.riskAversion,
                    mod.theBank)
end

# we need a function that gives the vector of payments where there have been k withdrawals



# now the bargaining step
# we constrain the agents to all have the same deposit



function bargain(mod::Model)
    for dep in 0:10:mod.endow
        tmpMod=clone(mod)
        tmpMod.deposit=dep
        tmpMod.endow=mod.endow-dep
    end
end

# we need the withdrawal function

function withdraw(mod::ModBase)
    if length(mod.bankingList) > 0
        pop!(mod.bankingList)
        withdrawn=min((1+mod.insur)*mod.deposit,mod.theBank.vault)
        mod.theBank.vault=max(mod.theBank.vault-withdrawn,0)
    else
        withdrawn=0
    end
    return withdrawn

end

function payOut(mod::ModBase)
    #println("Banking")
    #println(length(mod.bankingList))
    return (1/length(mod.bankingList)*(1+mod.insur+mod.prod)*mod.theBank.vault)
end
