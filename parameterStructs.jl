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
    depGraph::DiGraph
end

function parameterizationGen()
    return parameterization(parameter[],constraint[],Dict{Union{parameter,constant},Int64}(),DiGraph())
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
    end
    # now, generate a constant for every constraint with a value
    for constr in pSpace.constraints
        if :value in fieldnames(typeof(constr))
            t=t+1
            pSpace.nodeDict[constant(constr)]=t
        end
    end
end

function graphGen!(pSpace::parameterization)
    # keep track of 
    for constr in keys(pSpace.nodeDict)
        if typeof(constr)==constant
            add_edge!(pSpace.depGraph,pSpace.nodeDict[constr],pSpace.nodeDict[constr.parameter]) 
        end
    end
end


function parameterizationSetup!(pSetup::parameterization)

end

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
println(paramSpace)