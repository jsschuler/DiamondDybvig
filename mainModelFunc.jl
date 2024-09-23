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
    .1,
    .1,
    100,
    .25,
    1000,
    0.0,
    .5,
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
    agt.deposit=agt.endow-10
    push!(deposits,agt.deposit)
    agt.endow=10
end
mod.theBank=Bank(sum(deposits))
bargain(mod)
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
println(sum(endows.===0))
println(sum(deposits.===1000))

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