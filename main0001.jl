using Distributions
using Random
using DataFrames
using TreeParzen
using JLD2
using Distributed
@everywhere agtCnt=100
@everywhere depth=10000
# now how many runs per model type?
@everywhere runCnt=100
@everywhere include("objects.jl")
@everywhere include("functions.jl")


# detect availabile cores
cores=Sys.CPU_THREADS
# now we use one fewer than the available thread to reserve the current thread for this process. 
procs=cores-1

# now, generate the possible values of insurance and production

tuples=[]

for insur in 0.05:0.05:1.0
    for prod in in 0.05:0.05:1.0
        push!(tuples,(insur,prod))
    end
end

coreDict=Dict()
for coreNum in 2:cores
    coreDict[coreNum] = nothing
end

# now we run the process
while length(tuples) > 0
    currTup=popfirst!(tuples)
    for c in keys(coreDict)
        # if the core contains nothing, send it an optimization procedure
        if isnothing(coreDict[c])
            coreDict[c]=@spawnat c optimize(currTup[1],currTup[2],1.0)
        elseif isReady(coreDict[c])
            result=fetch(coreDict[c])
            coreDict[c]=nothing
        end
    end
end
