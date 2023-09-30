# now we generate plots
# first load agent data

using CSV
using DataFrames
using Plots

files=readdir()
activationFiles=[]
agentFiles=[]
withdrawalFiles=[]
modelFiles=[]

for fi in files
    if length(fi) > 11
        if fi[1:11]=="activations"
            push!(activationFiles,fi)
        elseif fi[1:6]=="agents"
            push!(agentFiles,fi)
        elseif fi[1:8]=="modelSet"
            push!(modelFiles,fi)
        elseif fi[1:11]=="withdrawals"
            push!(withdrawalFiles,fi)
        end
    end
end
activationData=DataFrame(CSV.File(activationFiles[1],header=["Key", "Agent", "Deposit","Failure"]))
for fi in activationFiles[2:length(activationFiles)]
    append!(activationData,DataFrame(CSV.File(fi,header=["Key", "Agent", "Deposit","Failure"])))
end

agentData=DataFrame(CSV.File(agentFiles[1],header=["Key","Agent","Deposit","Risk","Prob"]))
for fi in agentFiles[2:length(agentFiles)]
    append!(agentData,DataFrame(CSV.File(fi,header=["Key","Agent","Deposit","Risk","Prob"])))
end

withdrawalData=DataFrame(CSV.File(withdrawalFiles[1],header=["Key","Agent","Deposit","Exog","Failure"]))
for fi in withdrawalFiles[2:length(withdrawalFiles)]
    append!(withdrawalData,DataFrame(CSV.File(fi,header=["Key","Agent","Deposit","Exog","Failure"])))
end

modelData=DataFrame(CSV.File(modelFiles[1]))
for fi in modelFiles[2:length(modelFiles)]
    append!(modelData,DataFrame(CSV.File(fi)))
end

currKey="2022-07-12T14:20:05.745:9786"
currAgents=subset(agentData,:Key =>  a-> a.==currKey)
#plotlyjs()
sort!(currAgents,[:Risk])
#bColors=repeat([:blue],nrow(currAgents))
#plt1=bar(currAgents[:,:Deposit],color=bColors,fillalpha=currAgents[:,:Prob]/maximum(currAgents[:,:Prob]),legend = false,size=(600,400),xlab="Risk Preference")


# get model parameters
currMod=subset(modelData,:key =>  a-> a.==currKey)
payOut=currMod[1,:payout]
premium=currMod[1,:premium]
# now get total deposits, first will change, not second
allDeposits=sum(currAgents[:,:Deposit])
totDeposits=sum(currAgents[:,:Deposit])
totLiability=(1+payOut+premium)*allDeposits
#plt2=bar([allDeposits,(1+payOut+premium)*allDeposits],legend = false,orientation=:horizontal,xlims=(-(1+payOut+premium)*allDeposits,(1+payOut+premium)*allDeposits),size=(600,100),width=[.02,.2])
#plot(plt1,plt2,layout=(2,1))

currWD=subset(withdrawalData,:Key => a-> a.==currKey)


plt1=bar(currAgents[:,:Deposit],color=bColors,fillalpha=currAgents[:,:Prob]/maximum(currAgents[:,:Prob]),legend = false,size=(600,400),xlab="Risk Preference")
scatter(currAgents[:,:Prob], currAgents[:,:Risk]; zcolor=currAgents[:,:Deposit],markersize=sqrt.(currAgents[:,:Deposit]) ,color=:oslo)
# now for each withdrawal, produce a plot
# generate an array of colors
bColors=repeat([:blue],nrow(currAgents))
println(nrow(currWD))
for i in 1:nrow(currWD)
    println(i)
    #println(currWD[i,:])
    agt=currWD[i,:Agent][1]
    wTyp=currWD[i,:Exog][1]
    deposit=currWD[i,:Deposit][1]
    # now
    currAgtRow=(1:nrow(currAgents))[currAgents[:,:Agent].==agt][1]
    # now the bar turns green upon exogenous withdrawal and orange
    # upon endogenous withdrawal
    # previous withdrawals are red
    if wTyp
        bColors[currAgtRow]=:green
    else
        bColors[currAgtRow]=:orange
    end
    plt1=bar(currAgents[:,:Deposit],color=bColors,fillalpha=currAgents[:,:Prob]/maximum(currAgents[:,:Prob]),legend = false,size=(600,400),xlab="Risk Preference")
    # calculate new balance
    global allDeposits
    allDeposits=allDeposits-(1+payOut)*deposit
    if allDeposits > 0
        bankColor=:blue
    else
        bankColor=:red
    end
    plt2=bar([allDeposits],legend = false,orientation=:horizontal,xlims=(-totDeposits,totDeposits),size=(600,100),width=[.02,.2],colors=[bankColor])
    bColors[currAgtRow]=:red
    stackplot=plot(plt1,plt2,layout=(2,1))
    savefig(stackplot,"plots/diamond"*lpad(i,6,"0")*".png")
end
