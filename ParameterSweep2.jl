################################################################################
#              Diamond-Dybvig ABM with Smart Sweep                             #
#                                                                              #
#               December 2022                                                  #
#               John S. Schuler                                                #
#               Parameter Sweep Generation Code                                #
################################################################################
using StatsBase
using DataFrames
using JLD2
using Dates
using CSV
using Distributions
using Primes
using Plots
using StatsBase
using Random

### SWEEP PARAMETERS ######
# how many parameterizations do we generate?
totalSweep::Int64=500
# how many times to run each parameterization?
parameterRuns::Int64=10
# How many rounds before the boosting is rerun?
boostingInterval=100


##### GLOBAL MODEL PARAMETERS ######
# AGENT COUNT
# RISK AVERSION
# INSURANCE PAY OUT
# INVESTMENT TECH PREMIUM OVER INSURANCE PAYOUT
### All Global parameters have a Probability Distributions


# now, include the parameter sweep functions
include("paramSweepFunctions.jl")

# Step 1: set parameters

# AGENT COUNT
# uniform 10 to 1000
parameterGen(:AgtCnt,Uniform(10,1000))
# RISK AVERSION
exogP=Array(.05:.05:.25)
# INSURANCE PAY OUT
parameterGen(:Pay,Uniform(.05,.5))
# INVESTMENT TECH PREMIUM OVER INSURANCE PAYOUT
parameterGen(:Prem,Uniform(.05,.5))
# Exogenous withdrawal probability
parameterGen(:Exog,Uniform(.01,.25))

# now generate all parameterizations

paramTable=parameterGenerate(totalSweep)
println(paramTable)

# now randomize the order
paramTable=paramTable[shuffle(1:size(paramTable)[1]),:]
println(paramTable)

# set global variables
agtTicker=0
agtTicker::Int64
depth=100000
insur=argVec[6]
prod=argVec[6] + argVec[7]
insur::Float64
prod::Float64
bargRes=100
bargRes::Int64
# we need an exogenous probability of withdrawal
exogP=.1
exogP::Float64
activation=true
activation::Bool
# we need a model KeyCol
sampSize=1000::Int64
seed=sample(1:(100*sampSize),sampSize,replace=false)[1]::Int64
currTime=now()
key=argVec[4]
#Random.seed!(argVec[2])

# what agent parameters are constrained to be the same?
#fixRisk=argVec[9]
#fixEndow=argVec[10]
#fixProb=argVec[11]
agtCnt=100
# create agents
agtList=Agent[]
withDList=Agent[]
#constraintGen()
deposits=Int64[]
for agt in agtList
    agt.deposit=agt.endow-10
    push!(deposits,agt.deposit)
    agt.endow=10
end
#agtList[1].endow=5000
#agtList[1].deposit=0
theBank=Bank(sum(deposits))
#println("vault")
#println(theBank.vault)

# now, let's test some functions
#println("Before")
#println(length(agtList))
#bargain()
# now, any unwilling deposits are removed from the model
#agtList=filter!(x-> x.deposit !=0,agtList)

#Random.seed!(argVec[3])
# now log the deposits
#for agt in agtList
#    df=DataFrame(currKey=[key],
#              agt=[agt.idx],
#              endow=[agt.endow],
#              deposit=[agt.deposit],
#              risk=[agt.riskAversion],
#              prob=[agt.p]
#              )
#              #println(typeof(key))
#              CSV.write("Data6/deposits"*key*".csv", df,header = false,append=true)
#end

paramTable[!,:result].= nothing
# round agent counts 
paramTable[!,:AgtCnt].=round.(Int64,paramTable[!,:AgtCnt])
println(paramTable)

for tdx in 1:100
    key=sample(1:1000,1)
    #Random.seed!(argVec[2])
    argVec=paramTable[tdx,:]
    # what agent parameters are constrained to be the same?
    #fixRisk=argVec[9]
    #fixEndow=argVec[10]
    #fixProb=argVec[11]
    agtCnt=100
    # create agents
    agtList=Agent[]
    withDList=Agent[]
    #constraintGen()
    deposits=Int64[]
    for agt in agtList
        agt.deposit=agt.endow-10
        push!(deposits,agt.deposit)
        agt.endow=10
    end
    #agtList[1].endow=5000
    #agtList[1].deposit=0
    theBank=Bank(sum(deposits))
    #println("vault")
    #println(theBank.vault)
    
    # now, let's test some functions
    #println("Before")
    #println(length(agtList))
    bargain()
    # now, any unwilling deposits are removed from the model
    agtList=filter!(x-> x.deposit !=0,agtList)
    
    run=model()


end


#for tdx in 0:((size(paramTable)[1]/boostingInterval)-1)
#    println((tdx*100+1))
#    println((tdx*100+100))
#    lo=Int64((tdx*100+1))
#    hi=Int64((tdx*100+100))
#    paramTable[lo:hi,:]
#end