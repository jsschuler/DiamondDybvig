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
    agent[],
    1000,
    .1,
    .1,
    1000,
    .2,
    1000,
    1.0,
    1000,
    .2,
    1000,
    12,
    Bank(0),
    "k"
)

modelRun(mod)