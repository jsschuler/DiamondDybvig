################################################################################
#             Main Diamond-Dybvig Code                                         #
#             Julia Version                                                    #
#             February 2022                                                    #
#             John S. Schuler                                                  #
#                                                                              #
#                                                                              #
################################################################################
using Folds
using Distributions
using Random
using Distributed
using CSV
using DataFrames
using Dates
using JLD2


include("objects.jl")
include("functions.jl")

ctrlFile=ARGS[1]
#println(ctrlFile)
ctrlFrame=load_object(ctrlFile)
#println(ctrlFrame[1:10,:])
# load only incomplete models
ctrlWorking=ctrlFrame[ctrlFrame[:,"complete"].==false,:]

# find the first row of the control df that is not complete
argVec=ctrlWorking[1,:]

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
exogP=argVec[8]
exogP::Float64
activation=true
activation::Bool
# we need a model KeyCol
sampSize=1000::Int64
seed=sample(1:(100*sampSize),sampSize,replace=false)[1]::Int64
currTime=now()
key=argVec[4]
Random.seed!(argVec[2])

# what agent parameters are constrained to be the same?
fixRisk=argVec[9]
fixEndow=argVec[10]
fixProb=argVec[11]
agtCnt=argVec[5]
# create agents
agtList=Agent[]
withDList=Agent[]
constraintGen()
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

Random.seed!(argVec[3])
# now log the deposits
for agt in agtList
    df=DataFrame(currKey=[key],
              agt=[agt.idx],
              endow=[agt.endow],
              deposit=[agt.deposit],
              risk=[agt.riskAversion],
              prob=[agt.p]
              )
              #println(typeof(key))
              CSV.write("Data6/deposits"*key*".csv", df,header = false,append=true)
end

run=model()
#println("After")
#println(length(agtList))
#println(run)
#println(theBank.vault)
currIndex=nrow(ctrlFrame)-nrow(ctrlFrame[ctrlFrame[:,"complete"].==false,:])+1
#println("File")
#println(ctrlFrame[currIndex,:complete])
ctrlFrame[currIndex,:complete]=true
#println(ctrlFrame[currIndex,:complete])
save_object(ctrlFile,ctrlFrame)
