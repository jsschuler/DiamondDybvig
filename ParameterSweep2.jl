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

# for reasons of book keeping, each of these parameters gets a struct
struct parameter
    name::Symbol
    distrib::UnivariateDistribution
end
# global parameter list
paramList=parameter[]
function parameterGen(name::Symbol,distribution::UnivariateDistribution)
    global paramList
    push!(paramList,parameter(name,distribution))
end

# Step 1: set parameters

# AGENT COUNT
# uniform 10 to 1000
parameterGen(:AgtCnt,Uniform(10,10000))
# RISK AVERSION



exogP=Array(.05:.05:.25)
# INSURANCE PAY OUT
parameterGen(:Pay,Uniform(.05,.5))
# INVESTMENT TECH PREMIUM OVER INSURANCE PAYOUT
parameterGen(:Prem,Uniform(.05,.5))
# Exogenous withdrawal probability
parameterGen(:Exog,Uniform(.01,.25))