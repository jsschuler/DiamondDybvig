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

struct valueCardinalInequalityConstraint <: inequalityConstraint
    param::Array{cardinal}
    value::Real
    lessThan::Bool
end

struct rangeEqualityConstraint <: equalityConstraint
    param::Array{parameter}
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

mutable struct parameterization
    paramArray::Array{parameter}
    constraints::Array{constraint}
    nodeDict::Dict{Union{parameter,constant},Int64}
    intDict::Dict{Int64,Union{parameter,constant}}
    depGraph::DiGraph
end



# we need functions that will populated the directed graph depending on what kind of constraint

function edgeGen(pSpace::parameterization,constr::valueEqualityConstraint)
    t=length(pSpace.nodeDict)
    # now, check what nodes we have already seen and add any missing ones
    allVert=vertices(pSpace.depGraph)
    currVert=[]
    for vert in allVert
        push!(currVert,pSpace.intDict[vert])
    end
    # the constant should not have been referenced as a node before
    t=t+1
    baseConst=constant(constr)
    pSpace.nodeDict[baseConst]=t
    pSpace.intDict[t]=baseConst
    add_vertex!(pSpace.depGraph)
    for param in constr.param
        if !in(param,currVert)
            t=t+1
            pSpace.nodeDict[param]=t
            pSpace.intDict[t]=param
            add_vertex!(pSpace.depGraph)
        end
        println("Adding")
        add_edge!(pSpace.depGraph,pSpace.nodeDict[baseConst],pSpace.nodeDict[param])
    end
    println(pSpace.depGraph)
    return pSpace.depGraph
end


# now, add edges between parameters in both directions. We will figure out the 
# order of information flow later.
function edgeGen(pSpace::parameterization,constr::rangeEqualityConstraint)
    t=length(pSpace.nodeDict)
    # now, check what nodes we have already seen and add any missing ones
    allVert=vertices(pSpace.depGraph)
    currVert=[]
    for vert in allVert
        push!(currVert,pSpace.intDict[vert])
    end
    for param1 in constr.param
        for param2 in constr.param
            if param1 != param2
                if !in(param1,currVert)
                    t=t+1
                    pSpace.nodeDict[param1]=t
                    pSpace.intDict[t]=param1
                    add_vertex!(pSpace.depGraph)
                end
                if !in(param1,currVert)
                    t=t+1
                    pSpace.nodeDict[param2]=t
                    pSpace.intDict[t]=param2
                    add_vertex!(pSpace.depGraph)
                end
                println("Adding")
                add_edge!(pSpace.depGraph,pSpace.nodeDict[param1],pSpace.nodeDict[param2])
                println("Adding")
                add_edge!(pSpace.depGraph,pSpace.nodeDict[param2],pSpace.nodeDict[param1])
            end
        end
    end
    println(pSpace.depGraph)
    return pSpace.depGraph
end



function edgeGen(pSpace::parameterization,constr::valueCardinalInequalityConstraint)
    t=length(pSpace.nodeDict)
    allVert=vertices(pSpace.depGraph)
    currVert=[]
    for vert in allVert
        push!(currVert,pSpace.intDict[vert])
    end
    t=t+1
    baseConst=constant(constr)
    pSpace.nodeDict[baseConst]=t
    pSpace.intDict[t]=baseConst
    add_vertex!(pSpace.depGraph)
    for param in constr.param
        if !in(param,currVert)
            t=t+1
            pSpace.nodeDict[param]=t
            pSpace.intDict[t]=param
            add_vertex!(pSpace.depGraph)
        end
        println("Adding")
        add_edge!(pSpace.depGraph,pSpace.nodeDict[baseConst],pSpace.nodeDict[param])
    end
    println(pSpace.depGraph)
    return pSpace.depGraph
end

function edgeGen(pSpace::parameterization,constr::valueOrdinalInequalityConstraint)
    t=length(pSpace.nodeDict)
    allVert=vertices(pSpace.depGraph)
    currVert=[]
    for vert in allVert
        push!(currVert,pSpace.intDict[vert])
    end
    t=t+1
    baseConst=constant(constr)
    pSpace.nodeDict[baseConst]=t
    pSpace.intDict[t]=baseConst
    add_vertex!(pSpace.depGraph)
    for param in constr.param
        if !in(param,currVert)
            t=t+1
            pSpace.nodeDict[param]=t
            pSpace.intDict[t]=param
            add_vertex!(pSpace.depGraph)
        end
        println("Adding")
        add_edge!(pSpace.depGraph,pSpace.nodeDict[baseConst],pSpace.nodeDict[param])
    end
    println(pSpace.depGraph)
    return pSpace.depGraph
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
function graphGen(pSpace::parameterization)
    # first, generate an undirected edge for each constraint
    for constr in pSpace.constraints
        pSpace.depGraph=edgeGen(pSpace,constr)
    end
    return pSpace
end


#function parameterizationSetup!(pSetup::parameterization)

#end

# test some stuff
paramSpace=parameterizationGen()
# add two real parameters
parameterAdd!(paramSpace,nonEquiOrdinal([1,2],[.6,.4]))
parameterAdd!(paramSpace,nonEquiOrdinal([4,5],[.2,.8]))
parameterAdd!(paramSpace,nonEquiOrdinal([4,5],[.2,.8]))
parameterAdd!(paramSpace,nonEquiOrdinal([4,5],[.2,.8]))
# now add a constraint
constr1=valueEqualityConstraint(parameter[paramSpace.paramArray[1]],2)
constr2=rangeEqualityConstraint(parameter[paramSpace.paramArray[3],paramSpace.paramArray[4],])
constraintAdd!(paramSpace,constr1)
constraintAdd!(paramSpace,constr2)
println(paramSpace)

println("Graph")
paramSpace=graphGen(paramSpace)
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

# first, we need a function that checks if any pairs of nodes
# have arrows pointing in both directions

function bothWays(grph::DiGraph)
    retVal=false
    for node1 in vertices(grph)
        for node2 in vertices(grph)
            if node1!=node2
                if has_edge(grph,node1,node2) & has_edge(grph,node2,node1)
                    retVal=true
                end
            end
        end
    end
end

function orderGraph(pSpace::parameterization)
    # now, if an edge has a constant, it points away from it
    # if an edge has a source toward which there are only in-arrows, it points away
    # do this until there are no pair of nodes with arrows pointing in both directions
    while bothWays(pSpace.depGraph)
        for edg in edges(pSpace.depGraph)
            eSrc=src(pSpace.depGraph,edg)
            eDst=dst(pSpace.depGraph,edg)
            # are there edges in both directions?
            bothDi=has_edge(pSpace.depGraph,eSrc,eDst) & has_edge(pSpace.depGraph,eDst,eSrc)
            if bothDi
                # now, if the only edges
            # now identify the source of both edges
            src1=src(edg)
            src2=dst(edg)
            # which src has only the edge pointed in the opposite direction as in-neighbors?
            inneighbors(pSpace.depGraph,src1)==Edge[pSpace.depGraph,src1,src2]
            
        end
    end

end