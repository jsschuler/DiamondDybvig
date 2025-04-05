using Distributed
@everywhere using Distributions
@everywhere using Random
@everywhere using DataFrames
@everywhere using TreeParzen
@everywhere using JLD2

using CSV
@everywhere agtCnt=100
@everywhere depth=1000
@everywhere totResr::Int64=1000
# now how many runs per model type?
@everywhere runCnt=100
@everywhere include("objects.jl")
@everywhere include("functions.jl")


# detect availabile cores
cores=Sys.CPU_THREADS


# now, generate the possible values of insurance and production

tuples=[]

for insur in 0.5:0.1:0.6
    for prod in 0.5:0.1:0.6
        for objP in 0.0:0.2:1.0
            push!(tuples,(insur,prod,objP))
        end
    end
end

# count completed processes
procCnt=length(tuples)
doneCnt=0
coreDict=Dict()
for coreNum in 2:cores
    coreDict[coreNum] = nothing
end

# testing 


# now we run the process
while doneCnt < procCnt
    for c in keys(coreDict)
        # if the core contains nothing, send it an optimization procedure
        if isnothing(coreDict[c]) && length(tuples) > 0
            currTup=popfirst!(tuples)
            println("Sending tuple "*string(currTup)*" to core "*string(c))
            println(length(tuples))
            coreDict[c]=@spawnat c runFamily(currTup[1],currTup[2],currTup[3])
        elseif isReady(coreDict[c])
            result=fetch(coreDict[c])
            global doneCnt
            doneCnt=doneCnt+1
            coreDict[c]=nothing
            df=DataFrame(
                        insur=result[2],
                        prod=result[3],
                        objP=result[4]
                        failProb=result[1])
            println("Writing File")
            CSV.write("../data/results.csv", df,header = false,append=true)
        end
    end
end