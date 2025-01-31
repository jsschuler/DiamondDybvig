using Distributions
using Random

agtCnt=100
depth=100000
include("objects.jl")
include("function2.jl")




tstMod=modelGen(1000,.05,.1,.3,.1,1.0)
mUtil=modUtilGen(tstMod)


tstMod.deposit=tstMod.endow
tstMod.endow=0


for k in 1:length(tstMod.bankingList)
    tstMod.theBank.vault=tstMod.theBank.vault+tstMod.deposit
end
println("Initial Vault")
println(tstMod.theBank.vault)

for k in 1:15
    push!(tstMod.nonBankingList,pop!(tstMod.bankingList))
    tstMod.theBank.vault=tstMod.theBank.vault-(1+tstMod.insur)*tstMod.deposit
end

println("Post Vault")
println(tstMod.theBank.vault)



println(length(tstMod.bankingList))
println(length(tstMod.nonBankingList))
noWD=roundSimul(tstMod,false)
WD=roundSimul(tstMod,true)
println("Agent Stays Banking")
println(noWD > WD)