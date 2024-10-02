using Folds
using Distributions
using Random
using Distributed
using CSV
using DataFrames
using Dates
using JLD2


include("objects2.jl")
include("functions2.jl")

# In this version, all agents are identical so
# global parameters
    # probablity of being type 1
    # insurance payout
    # production addition factor
    # bargaining resolution
    # sample size
# agent level parameters
    # subject probability of being type 1
    # endowment
    # coefficient of relative risk aversion
    
# generate test model

mod=Model(
    0, 
    Agent[],
    10000,
    .15,
    .25,
    100,
    .25,
    1000,
    1.0,
    .25,
    1000,
    sample(1:100000,1)[1],
    Bank(0),
    "k"
)
for j in 1:100
    agtGen(mod::Model)
end
deposits=Int64[]
for agt in mod.agtList
    agt.deposit=agt.endow-100
    push!(deposits,agt.deposit)
    agt.endow=100
end
mod.theBank=Bank(sum(deposits))
# now, let's simulate the first agent's first round
simUtil(mod,mod.agtList[1])
agtDecision(mod,mod.agtList[1])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[1].deposit)
#
#simUtil(mod,mod.agtList[2])
#agtDecision(mod,mod.agtList[2])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[2].deposit)
#
#simUtil(mod,mod.agtList[3])
#agtDecision(mod,mod.agtList[3])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[3].deposit)
#
#simUtil(mod,mod.agtList[4])
#agtDecision(mod,mod.agtList[4])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[4].deposit)
#
#simUtil(mod,mod.agtList[5])
#agtDecision(mod,mod.agtList[5])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[5].deposit)
#
#simUtil(mod,mod.agtList[6])
#agtDecision(mod,mod.agtList[6])
#println("Vault")
#println(mod.theBank.vault)
#println("Deposit")
#println(mod.agtList[6].deposit)


bargain(mod)
println("Vault")
println(mod.theBank.vault)
#println("Deposits")
endows=[]
deposits=[]
for agt in mod.agtList
    #println(agt.deposit)
    #println(agt.endow)
    push!(endows,agt.endow)
    push!(deposits,agt.deposit)
end
println(endows)
println(deposits)
#println(sum(endows.===0))
#println(sum(deposits.===1000))
#result=modelRun(mod)
#println(mod.theBank.vault)
#println(result)


function tstModelGen(arg)

    mod=Model(
        0, 
        Agent[],
        1000,
        .1,
        .1,
        1000,
        .25,
        1000,
        0.0,
        1000,
        .5,
        1000,
        sample(1:100000,1)[1],
        Bank(0),
        "k"
    )
    for j in 1:10
        agtGen(mod::Model)
    end
    deposits=Int64[]
    for agt in mod.agtList
        agt.deposit=agt.endow-10
        push!(deposits,agt.deposit)
        agt.endow=10
    end
    mod.theBank=Bank(sum(deposits))
    bargain(mod)
    #println("Deposits")
    #for agt in mod.agtList
    #    println(agt.deposit)
    #end

    
    #println()
    result=modelRun(mod)
    return result[1]
end

#println(mean(tstModelGen.(1:1000)))