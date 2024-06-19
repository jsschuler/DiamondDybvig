################################################################################
#              Diamond-Dybvig ABM                                              #
#               (networked)                                                    #
#               June 2022                                                      #
#               John S. Schuler                                                #
#               Parameter Sweep Generation Code                                #
#               Constrained to have identical agents                           #
################################################################################
using StatsBase
using DataFrames
using JLD2
using Dates
using CSV
##### PARAMETERS ######
# SEED
# AGENT COUNT
# RISK AVERSION
# INSURANCE PAY OUT
# INVESTMENT TECH PREMIUM OVER INSURANCE PAYOUT

# we want to have multiple runs from the same initialization
initSize=100
# and to run this a certain number of times
initRun=10
sampSize=initSize*initRun
agtCnts=10:10:100

# We have a unit 3-cube that we must fill with 

payOut=Array(.05:.05:.5)
premium=Array(.05:.05:.5)
exogP=Array(.05:.05:.25)
initSeed=[]
col1=[]
col2=[]
col3=[]
col4=[]
# flag to fix risk aversion
# flag to fix endowment
# flag to fix subjective probability
# we only ever fix at most two at a time,
# with probability of .3, we fix at least one
# conditional on this, we fix two with a probability of .5
col5=[]
col6=[]
col7=[]
for t in 1:initSize
    push!(col1,sample(agtCnts,1)[1])
    push!(col2,sample(payOut,1)[1])
    push!(col3,sample(premium,1)[1])
    push!(col4,sample(exogP,1)[1])
    #if rand()[1] <= .3
    #    if rand()[1] <= .5
    #        order=sample([true,true,false],3)
    #    else
    #        order=sample([true,false,false],3)
    #    end
    #else
    #    order=[false,false,false]
    #end
    push!(col5,true)
    push!(col6,true)
    push!(col7,true)

    push!(initSeed,sample(1:(100*sampSize),1,replace=false)[1])

end
col1=repeat(col1,initRun)
col2=repeat(col2,initRun)
col3=repeat(col3,initRun)
col4=repeat(col4,initRun)
col5=repeat(col5,initRun)
col6=repeat(col6,initRun)
col7=repeat(col7,initRun)

seedCol=repeat(initSeed,initRun)
currTime=now()

ctrlFrame=DataFrame()
ctrlFrame[!,"dateTime"]=repeat([currTime],sampSize)
ctrlFrame[!,"seed1"]=seedCol
ctrlFrame[!,"seed2"]=sample(1:(100*sampSize),sampSize,replace=false)
ctrlFrame[!,"key"]=string.(ctrlFrame[!,"dateTime"],":",ctrlFrame[!,"seed1"],":",ctrlFrame[!,"seed2"])
ctrlFrame[!,"agtCnt"]=col1
ctrlFrame[!,"payout"]=col2
ctrlFrame[!,"premium"]=col3
ctrlFrame[!,"exogP"]=col4
ctrlFrame[!,"fixRisk"]=col5
ctrlFrame[!,"fixEndow"]=col6
ctrlFrame[!,"fixProb"]=col7
ctrlFrame[!,"complete"]=repeat([false],sampSize)
println(ctrlFrame[1:10,:])



save_object("runCtrl_"*Dates.format(now(),"yyyymmddHHMMSS")*".jld2",ctrlFrame)
CSV.write("../Data6/modRun"*ctrlFrame[1,:key]*".csv",ctrlFrame)
