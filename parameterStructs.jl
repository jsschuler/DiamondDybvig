using Distributions
using Graphs

# We need some structs to manage the parameter sweep and restrictions

abstract type parameter end
abstract type cardinal <: parameter end
abstract type ordinal <: parameter end
abstract type categorical <: parameter end

struct discreteParam <: cardinal 
    dist::DiscreteUnivariateDistribution
end
struct continuousParam <: cardinal 
    dist::ContinuousUnivariateDistribution
end

struct equiOrdinal <: ordinal 
    values::AbstractArray
end

struct nonEquiOrdinal <: ordinal 
    values::AbstractArray
    probs::Array{Float64}
end

struct equiCategorical <: categorical
    values::AbstractArray
end

struct nonEquiCategorical <: categorical
    values::AbstractArray
    probs::Array{Float64}
end

# now, some types and structs to keep track of constraints

abstract type constraint end
abstract type equalityConstraint <: constraint end
abstract type inequalityConstraint <: constraint end

# now, there are two types of equality constraints
# constraints that set a parameter equal to a value
# and constraints that set all parameter instances of this type
# as equal but let that value vary

struct valueEqualityConstraint <: equalityConstraint
    param::Array{parameter}
    value
end

struct rangeEqualityConstraint <: equalityConstraint
    param::Array{parameter}
end

struct valueCardinalInequalityConstraint <: inequalityConstraint
    param::Array{cardinal}
    value::Real
    lessThan::Bool
end

struct valueOrdinalInequalityConstraint <: inequalityConstraint
    param::Array{ordinal}
    value
    lessThan::Bool
end

# now, we need structs to keep track of models
# we need a struct for a constant
struct constant
    constr::Union{valueEqualityConstraint,valueCardinalInequalityConstraint,valueOrdinalInequalityConstraint}
end


# a parameterization keeps track of parameters and constraints


struct parameterization
    paramArray::Array{parameter}
    constraints::Array{constraint}
    nodeDict::Dict{Union{parameter,constant},Int64}
    intDict::Dict{Int64,Union{parameter,constant}}
    depGraph::DiGraph
end

function parameterizationGen()
    return parameterization(parameter[],constraint[],Dict{Union{parameter,constant},Int64}(),Dict{Int64,Union{parameter,constant}}(),DiGraph())
end

function parameterAdd!(pSpace::parameterization,param::parameter)
    push!(pSpace.paramArray,param)
end

function constraintAdd!(pSpace::parameterization,constr::constraint)
    push!(pSpace.constraints,constr)
end

# now, we can build functions that handle sampling
# Step 1 is to calculate the dimension of the parameter space
# We can build a dependency graph between constants and parameters
# we need functions to build these objects.

function nodeGen!(pSpace::parameterization)
    # generate a nodeDict entry for every parameter
    t::Int64=0
    for param in pSpace.paramArray
        t=t+1
        pSpace.nodeDict[param]=t
        pSpace.intDict[t]=param
        println("Adding")
        add_vertex!(pSpace.depGraph)
    end
    # now, generate a constant for every constraint with a value
    for constr in pSpace.constraints
        if :value in fieldnames(typeof(constr))
            t=t+1
            cnst=constant(constr)
            pSpace.nodeDict[cnst]=t
            pSpace.intDict[t]=cnst
            println("Adding")
            add_vertex!(pSpace.depGraph)
        end
    end
end

function graphGen!(pSpace::parameterization)
    # keep track of parameters related to constants
    constParams=parameter[]
    for constr in keys(pSpace.nodeDict)
        if typeof(constr)==constant
            for pVal in constr.constr.param
                add_edge!(pSpace.depGraph,pSpace.nodeDict[constr],pSpace.nodeDict[pVal]) 
                push!(constParams,pVal)
            end
        end
    end
    # now loop over constraints again and connect parameters that have non-constant constraints
    for constr in keys(pSpace.nodeDict)
        if !(:value in fieldnames(typeof(constr))) & !(constr isa parameter) & !(constr isa constant)
            paramOrder=parameter[]
            for param in constr.param
                if param in constParams
                    push!(paramOrder,param)
                end
            end
            for param in constr.param
                if !(param in constParams)
                    push!(paramOrder,param)
                end
            end
            # now, add an edge for all adjacent pairs
            for i in 1:(len(paramOrder)-1)
                source=paramOrder[i]
                dest=paramOrder[i+1]
                add_edge!(pSpace.depGraph,pSpace.nodeDict[source],pSpace.nodeDict[dest])
            end
        end
    end
    

end


#function parameterizationSetup!(pSetup::parameterization)

#end

# test some stuff
paramSpace=parameterizationGen()
# add two real parameters
parameterAdd!(paramSpace,nonEquiOrdinal([1,2],[.6,.4]))
parameterAdd!(paramSpace,nonEquiOrdinal([4,5],[.2,.8]))
# now add a constraint
constr1=valueEqualityConstraint(parameter[paramSpace.paramArray[1]],2)
constraintAdd!(paramSpace,constr1)
println(paramSpace)
println(fieldnames(typeof(constr1)))
println(:value in fieldnames(typeof(constr1)))
nodeGen!(paramSpace)
println(paramSpace.paramArray)
println(paramSpace.nodeDict)
graphGen!(paramSpace)
println(collect(vertices(paramSpace.depGraph)))
println(collect(edges(paramSpace.depGraph)))
for edg in edges(paramSpace.depGraph)
    println(paramSpace.intDict[src(edg)])
    println(paramSpace.intDict[dst(edg)])
end

# now, we need functions that sample
# First, we sample through edges
# then, we sample singleton nodes
# Thus, we need an ordering function that orders edges

function orderGraph(grph::SimpleDiGraph)
    # Step 1: find a root node
    # for all edges, find the edges whose sources have no in-neighbors
    rootVec=[]
    for edg in edges(grph)
        if len(inneighbors(grph,src(edge)))==0
            push!(rootVec,edge)
        end
    end
end