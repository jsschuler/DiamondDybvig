using Pkg
Pkg.activate("..")
Pkg.instantiate()
using Distributed, Distributions, Random, DataFrames, CSV

agtCnt  = 500
depth   = 100
totResr = 1000

include("objects.jl")
include("functions.jl")

Random.seed!(99999)
mod = modelGen(agtCnt, 0.1, 0.5, 0.5, 1.0)

t0 = time()
result = runMod(mod)
elapsed = time() - t0

println("K=500, one runMod call: ", round(elapsed, digits=2), " seconds")
println("failProb = ", result)
