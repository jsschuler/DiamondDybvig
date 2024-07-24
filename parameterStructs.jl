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
# we need a struct for a constant
struct constant <: parameter
    value
end

# now, some types and structs to keep track of constraints

abstract type constraint end
abstract type equalityConstraint end

struct valueEqualityConstraint <: equalityConstraint 
    param1::constant
    param2::parameter
end

struct paramEqualityConstraint <: equalityConstraint 
    param1::parameter
    param2::parameter
end



abstract type inequalityConstraint <: constraint end

struct categoricalInequalityConstraint
    param1::categorical
    param2::categorical
end

struct cardinalInequalityConstraint
    param1::cardinal
    param2::cardinal
    lessThan::Bool
end

struct ordinalInequalityConstraint
    param1::ordinal
    param2::ordinal
    lessThan::Bool
end

# now, there are two types of equality constraints
# constraints that set a parameter equal to a value
# and constraints that set all parameter instances of this type
# as equal but let that value vary



# a parameterization keeps track of parameters and constraints

mutable struct parameterization
    paramArray::Array{parameter}
    constraints::Dict{Edge,constraint}
    nodeDict::Dict{parameter,Int64}
    intDict::Dict{Int64,parameter}
    depGraph::DiGraph
end

function parameterizationGen()
    return parameterization(parameter[],Dict{Edge,constraint}(),Dict{parameter,Int64}(),Dict{Int64,parameter}(),DiGraph())
end
# Now, we can add constraints one by one in a directed manner. 
# This means that we have manual control over the dependency graph
function addConstant(pSpace::parameterization,value)
    constnt=constant(value)
    push!(pSpace.paramArray,constnt)
    pSpace.nodeDict[constnt]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=constnt
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

# function to add a discrete random variable as a parameter
function addDiscreteParam(pSpace::parameterization,dist::DiscreteUnivariateDistribution)
    param=discreteParam(dist)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

function addContinuousParam(pSpace::parameterization,dist::ContinuousUnivariateDistribution)
    param=continuousParam(dist)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

function addOrdinalParam(pSpace::parameterization,values::AbstractArray)
    param=equiOrdinal(values)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

function addOrdinalParam(pSpace::parameterization,values::AbstractArray,probs::Array{Float64})
    param=nonEquiOrdinal(values,probs)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

function addCategoricalParam(pSpace::parameterization,values::AbstractArray)
    param=equiCategorical(values)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

function addCategoricalParam(pSpace::parameterization,values::AbstractArray,probs::Array{Float64})
    param=nonEquiCategorical(values,probs)
    push!(pSpace.paramArray,param)
    pSpace.nodeDict[param]=len(pSpace.paramArray)
    pSpace.intDict[len(pSpace.paramArray)]=param
    add_vertices(pSpace.depGraph,1)
    return pSpace
end

# now, we need functions to add constraints
function addEqualityConstraint(pSpace::parameterization,param1::parameter,param2::parameter)
    node1=pSpace.nodeDict[param1]
    node2=pSpace.nodeDict[param2]
    constrnt=equalityConstraint(param1,param2)
    add_edge!(pSpace.depGraph,node1,node2)
    pSpace.constraints[Edge(node1,node2)]=constrnt
    return pSpace
end

function addInEqualityConstraint(pSpace::parameterization,param1::categorical,param2::categorical)
    node1=pSpace.nodeDict[param1]
    node2=pSpace.nodeDict[param2]
    constrnt=categoricalInequalityConstraint(param1,param2)
    add_edge!(pSpace.depGraph,node1,node2)
    pSpace.constraints[Edge(node1,node2)]=constrnt
    return pSpace
end

function addInequalityConstraint(pSpace::parameterization,param1::cardinal,param2::cardinal,lessThan::Bool)
    node1=pSpace.nodeDict[param1]
    node2=pSpace.nodeDict[param2]
    constrnt=cardinalInequalityConstraint(param1,param2,lessThan)
    add_edge!(pSpace.depGraph,node1,node2)
    pSpace.constraints[Edge(node1,node2)]=constrnt
    return pSpace
end

function addInequalityConstraint(pSpace::parameterization,param1::ordinal,param2::ordinal,lessThan::Bool)
    node1=pSpace.nodeDict[param1]
    node2=pSpace.nodeDict[param2]
    constrnt=ordinalInequalityConstraint(param1,param2,lessThan)
    add_edge!(pSpace.depGraph,node1,node2)
    pSpace.constraints[Edge(node1,node2)]=constrnt
    return pSpace
end

# now we can calculate the degrees of freedom which is the total number of non-constant parameters minus the total number of equality constraints. 
function degreesOfFreedom(pSpace::parameterization)
    paramCount=0
    for param in pSpace.paramArray
        if typeof(param)!=constant
            paramCount=paramCount+1
        end
    end
    eqConstraints=0
    for constr in pSpace.constraints
        if typeof(constr)==equalityConstraint
            eqConstraints=eqConstraints+1
        end
    end
    return paramCount-eqConstraints
end

# and use quasi-random / space filling methods to fill the unit n-cube


function uniformFill(dim::Int64,n::Int64)
    # get the first dim prime numbers
    primeNumbers=Int64[]
    tick::Int64=0
    while length(primeNumbers) < dim
        nextP=nextprime(tick)
        push!(primeNumbers,nextP)
        tick=nextP+1
    end
    #println(primeNumbers)
    haltSeq=[]
    for prm in primeNumbers
        push!(haltSeq,collect(Halton(prm)[1:n]))
    end
    return hcat(haltSeq...)
end

# then, making use of quantile functions and truncated distributions where necessary, we can turn the data in the unit n-cube into the correct parameters
# we will need a number of functions for this
# we want functions that return whether we need to advance to the next dimension of the matrix or not
struct valueEqualityConstraint <: equalityConstraint 
    param1::constant
    param2::parameter
end

struct paramEqualityConstraint <: equalityConstraint 
    param1::parameter
    param2::parameter
end

function constraintProc(constr::valueEqualityConstraint,dimTicker::Int64,n::Int64,UMat::Matrix{Float64})
    # now, if the first parameter is a constant, we return the same value and do not advance the dimension ticker
    return (repeat([constr.param1.value],n),dimTicker)
end

function constraintProc(constr::paramEqualityConstraint,dimTicker::Int64,n::Int64,UMat::Matrix{Float64})
    # now, if the first parameter is a variable, we return the variable values and do not advance the dimension ticker
    return (repeat([constr.param1.value],n),dimTicker)
end

struct categoricalInequalityConstraint
    param1::categorical
    param2::categorical
end

struct cardinalInequalityConstraint
    param1::cardinal
    param2::cardinal
    lessThan::Bool
end

struct ordinalInequalityConstraint
    param1::ordinal
    param2::ordinal
    lessThan::Bool
end



function paramGen(pSpace::parameterization,n::Int64)
    dim=degreesOfFreedom(pSpace)
    uMat=uniformFill(dim,n)
    # now get the edges at the "edge" of the network.
    border=Edge[]
    for edg in edges(pSpace.depGraph)
        if length(inneighbors(src(edg)))==0
            push!(border,edg)
        end
    end


end

