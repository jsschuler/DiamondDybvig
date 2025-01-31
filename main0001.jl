using Distributions
using Random

agtCnt=100
depth=1000
include("objects.jl")
include("function2.jl")

tstMod=modelGen(1000,.05,.1,.2,.2,1.0)

for k in 1:1
    push!(tstMod.nonBankingList,pop!(tstMod.bankingList))
end
println(length(tstMod.bankingList))
println(length(tstMod.nonBankingList))
roundSimul(tstMod,true)