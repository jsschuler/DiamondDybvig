# the functions file

function util(mod::Model,x::Int64)
    if x < 0
        x=0
    end

    y=Float64(1+x)
    if mod.riskAversion==1.0
        return(log(y))
    else
        return((y^(1-mod.riskAversion))/(1-mod.riskAversion))
    end
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

function withdrawalSamp(mod::Model)
    wdCount=length(mod.nonBankingList)
    stillBanking=length(mod.bankingList)
    # now generate 1000 uniform variates
    global depth
    uVariates=rand(Uniform(),1)
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
    return countVec[1]
end

function roundSimul(mod::Model,decision::Bool)
    # How many agents have withdrawn?
    wdCount=withdrawalSamp(mod::Model)
    withdrawals=sample(vcat(repeat(true,count),repeat([false],length(bankingList)-count) ),length(bankingList),replace=false)
    



end



# now the bargaining step
# we constrain the agents to all have the same deposit

#function bargain(mod::Model)
#end

# we need the withdrawal function

function withdraw(mod::Model)
    pop!(mod.bankingList)
    mod.theBank.vault=max(mod.theBank.vault-(1+mod.insur)*mod.deposit,0)
end

