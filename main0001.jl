using Distributed
@everywhere using Distributions
@everywhere using Random
@everywhere using DataFrames
@everywhere using TreeParzen
@everywhere using JLD2

using CSV
@everywhere agtCnt=100
@everywhere depth=10000
# now how many runs per model type?
@everywhere runCnt=100
@everywhere include("objects.jl")
@everywhere include("functions.jl")


# detect availabile cores
cores=Sys.CPU_THREADS


# now, generate the possible values of insurance and production

tuples=[]

for insur in 0.5:0.1:0.6
    for prod in in 0.5:0.1:0.6
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
            df=DataFrame(insur=currTup[1],
                        prod=currTup[2],
                        subjP=result[:subjP],
                        objP=result[:objP]
                        )
            
            CSV.write("../optimization.csv", df,header = false,append=true)
        end
    end
end
