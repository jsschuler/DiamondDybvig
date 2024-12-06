using Folds
using Distributions
using Random
#using Distributed
using CSV
using DataFrames
using Dates
using JLD2
using TreeParzen
using StatsBase
using Plots
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

# now, the agent has to have a probability that it will have to withdraw ex ante.
tstStudy=studyGen(.1,.4,1.0,.1)
#chk=RunStudy(tstStudy)
#println(chk)

studyStep(tstStudy,0.5)

#chk=studyStep(tstStudy,.05)
#print(chk)