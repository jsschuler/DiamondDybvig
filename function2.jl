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

# but first we need the function to generate a withdrawal count


function lineSpot(long::Int64)
    return sample(1:long,1)[1]
end

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
    #println(futureCount)
    # now, let's calculate the agent's return on the basis of a decision
    currVault=mod.theBank.vault
    if decision
        # if the agent decides to withdraw, the agent decides to BE one of the withdrawing agents
        # we guaranteed above that the agent always has a spot
        # add the withdrawing agent to the withdrawal count
        countVec=countVec.+1
        # now, get the agent's place in line among those withdrawing
        # and in turn, the number of agents 
        
        vaultDistrib= max.(currVault .- (1+mod.insur).*futureCount.*mod.deposit,0)
        agtReturn=max.(min.(vaultDistrib,(1+mod.insur)*mod.deposit),0)
        #println("Withdrawing Returns")
        #println("Vaults")
        #println(maximum(vaultDistrib))
        #println(minimum(vaultDistrib))
        #println(mean(vaultDistrib))
        #println("Utils")
        #println(maximum(mUtil.(agtReturn)))
        #println(minimum(mUtil.(agtReturn)))
        #println(mean(mUtil.(agtReturn)))
        expReturn=mean(mUtil.(agtReturn))
    else
        priorWithdrawals=lineSpot.(countVec).-1
        vaultDistrib= max.(currVault .- (1+mod.insur).*priorWithdrawals.*mod.deposit,0)
        #println(vaultDistrib)
        agtReturn=((stillBanking.-futureCount).^(-1)) .* (vaultDistrib.*(1+mod.insur+ mod.prod))
        #println(vaultDistrib.*(1+mod.prod))
        #println("Staying Returns")
        #println("Vaults")
        #println(maximum(vaultDistrib))
        #println(minimum(vaultDistrib))
        #println(mean(vaultDistrib))
        #println("Utils")
        #println(maximum(mUtil.(agtReturn)))
        #println(minimum(mUtil.(agtReturn)))
        #println(mean(mUtil.(agtReturn)))
        expReturn=mean(mUtil.(agtReturn))
    end
    return expReturn

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

function modRun(mod::SimModel)
    global agtCnt
    # now many type two agents are there
    agtProb=Binomial(agtCnt,mod.subjP)
    retMatVec=[]
    for t in 0:agtCnt
        retVec=Float64[]
        ### THE index here vs above is inconsistent because we need a case where no agent withdraws earler. 
        for j in 1:agtCnt
            if j <= t
                push!(retVec,max(0,min((1+mod.insur)*mod.deposit,mod.theBank.vault)))
                mod.theBank.vault=mod.theBank.vault-(1+mod.insur)*mod.deposit
            else
                stillBanking=agtCnt-t
                push!(retVec,max((1/stillBanking)*(1+mod.insur+mod.prod)*mod.theBank.vault,0))
            end
        end
        push!(retMatVec,retVec)
        # now perform the utility calculations
    end
    retVec=hcat(retMatVec...)
    # each row of this matrix corresponts to a number of agents withdrawing.
    println(size(retVec))
    #println(retVec)
    println(retVec[:,1])
    println(retVec[:,2])
    println(retVec[:,25])
    uFunc=modUtilGen(mod)
    uMat=uFunc.(retVec)
    println(uMat[:,1])
    println(uMat[:,2])
    println(uMat[:,25])
    # now as each row is a number of agents withdrawing
    # we can take a weighted average weighted by a column of probabilities
    # this will give us the represenative agent's von Neumann-Morgenstern Expected utility
    

    vnUtil=uMat * pdf.(agtProb,0:100)
    println("Utilities")
    println(vnUtil)

end

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
    pop!(mod.bankingList)
    mod.theBank.vault=max(mod.theBank.vault-(1+mod.insur)*mod.deposit,0)
end

