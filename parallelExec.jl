using Distributed
@everywhere using Folds
@everywhere using Distributions
@everywhere using Random
@everywhere using CSV
@everywhere using DataFrames
@everywhere using Dates
@everywhere using JLD2
@everywhere using TreeParzen
@everywhere using StatsBase
@everywhere using Plots
using IterTools
@everywhere include("objects2.jl")
@everywhere include("functions2.jl")

# Step 1: generate the parameter space
#studyGen(insur::Float64,prod::Float64,riskAversion::Float64,exogP::Float64)

# we vary the exogenous parameters
    # insurance pay out (.05,1)
    # production premium (.05,1)
    # coefficient of relative risk aversion (1.0,2.0)
    # exogenous withdrawal probability (.05,.4)

payOut=.1:.1:1.0
prodPrem=.1:.1:1.0
riskAver=1.0:.1:2.0
exogProb=.05:.05:.3

combos=vec(collect(product(payOut,prodPrem,riskAver,exogProb)))

cores=8

coreDict=Dict()
resultDict=Dict()
for j in 2:min(cores)
    coreDict[j]=nothing
    resultDict[j]=nothing
end