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
using Folds
using LightGBM
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
include("objects.jl")
include("functions.jl")

# Step 1: set parameters

# AGENT COUNT
# uniform 10 to 1000
parameterGen(:AgtCnt,Uniform(10,100))
# RISK AVERSION
exogP=Array(.05:.05:.25)
# INSURANCE PAY OUT
parameterGen(:Pay,Uniform(.05,.5))
# INVESTMENT TECH PREMIUM OVER INSURANCE PAYOUT
parameterGen(:Prem,Uniform(.05,.25))
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
insur=0.0
prod=0.0
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
key=""
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

paramTable.result=repeat(Union{Float64,Nothing}[nothing],size(paramTable)[1])
#convert.(Union{Nothing,Bool},paramTable.result)
# round agent counts 
paramTable[!,:AgtCnt].=round.(Int64,paramTable[!,:AgtCnt])
println(paramTable)

fixRisk=false
fixEndow=false
fixProb=false


#for tdx in 1:100
for tdx in 1:5
    resList=[]
    #for jdx in 1:parameterRuns
    for jdx in 1:5
        global key
        key=sample(1:1000,1)
        #Random.seed!(argVec[2])
        argVec=paramTable[tdx,:]
        global insur
        insur=argVec[2]
        global prod
        prod=argVec[2] + argVec[3]
        global exogP
        exogP=argVec[4]
        # what agent parameters are constrained to be the same?
        #fixRisk=argVec[9]
        #fixEndow=argVec[10]
        #fixProb=argVec[11]
        global agtCnt
        agtCnt=argVec[1]
        # create agents
        global agtList
        agtList=Agent[]
        global withDList
        withDList=Agent[]

        constraintGen()
        global deposits
        deposits=Int64[]
        for agt in agtList
            agt.deposit=agt.endow-10
            push!(deposits,agt.deposit)
            agt.endow=10
        end
        #agtList[1].endow=5000
        #agtList[1].deposit=0
        global theBank
        theBank=Bank(sum(deposits))
        println("vault")
        println(theBank.vault)

        # now, let's test some functions
        #println("Before")
        #println(length(agtList))
        bargain()
        println("vault")
        println(theBank.vault)
        # now, any unwilling deposits are removed from the model
        agtList=filter!(x-> x.deposit !=0,agtList)

        run=model()
        push!(resList,run)
    end
    paramTable[tdx,:result]=mean(resList)
    println(paramTable)
end

# now, fit the first lightGBM model 
# temporarily generate random y variable
params = Dict(
    "objective" => "binary",
    "metric" => "binary_logloss",
    "num_iterations" => 100,
    "learning_rate" => 0.1
)

fakeY=sample([0,1],size(paramTable)[1],replace=true)
# hold out 15% for validation
trainDex=floor(Int64,.85*size(paramTable)[1])
testDex=size(paramTable)[1]-trainDex
trainSet=sample(vcat(repeat([true],trainDex),repeat([false],testDex)),size(paramTable)[1],replace=false)


LGBMClassification(;[
    objective = "multiclass",
    num_iterations = 10,
    learning_rate = .1,
    num_leaves = 127,
    max_depth = -1,
    tree_learner = "serial",
    num_threads = Sys.CPU_THREADS,
    histogram_pool_size = -1.,
    min_data_in_leaf = 20,
    min_sum_hessian_in_leaf = 10.,
    lambda_l1 = 0.,
    lambda_l2 = 0.,
    min_gain_to_split = 0.,
    feature_fraction = 1.,
    feature_fraction_seed = 2,
    bagging_fraction = 1.,
    bagging_freq = 0,
    bagging_seed = 3,
    early_stopping_round = 0,
    max_bin = 255,
    data_random_seed = 1,
    init_score = "",
    is_sparse = true,
    save_binary = false,
    categorical_feature = Int[],
    is_unbalance = false,
    metric = ["multi_logloss"],
    metric_freq = 1,
    is_training_metric = false,
    ndcg_at = Int[],
    num_machines = 1,
    local_listen_port = 12400,
    time_out = 120,
    machine_list_file = "",
    num_class = 1,
    device_type="cpu",
])


#for tdx in 0:((size(paramTable)[1]/boostingInterval)-1)
#    println((tdx*100+1))
#    println((tdx*100+100))
#    lo=Int64((tdx*100+1))
#    hi=Int64((tdx*100+100))
#    paramTable[lo:hi,:]
#end