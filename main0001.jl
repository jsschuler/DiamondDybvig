using Distributions
using Random

agtCnt=100
depth=10000
# now how many runs per model type?
runCnt=100
include("objects.jl")
include("function2.jl")




tstMod=modelGen(1000,.25,.05,.1,.1,1.0)
mUtil=modUtilGen(tstMod)


tstMod.deposit=tstMod.endow
tstMod.endow=0



println("Initial Vault")
println(tstMod.theBank.vault)
println(length(tstMod.bankingList))
#for k in 1:5
#    push!(tstMod.nonBankingList,pop!(tstMod.bankingList))
#    tstMod.theBank.vault=tstMod.theBank.vault-(1+tstMod.insur)*tstMod.deposit
#end
#
#println("Post Vault")
#println(tstMod.theBank.vault)
#
#
#
#println(length(tstMod.bankingList))
#println(length(tstMod.nonBankingList))
#noWD=roundSimul(tstMod,false)
#WD=roundSimul(tstMod,true)
#println("Agent Stays Banking")
#println(noWD > WD)


#roundSimul(tstMod,false)
#roundSimul(tstMod,true)
bargain(tstMod)
#println(runMain(tstMod))
println(tstMod.deposit)