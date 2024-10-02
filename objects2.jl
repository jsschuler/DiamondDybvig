# Objects for DD Model

mutable struct Agent
    idx::Int64
    endow::Int64
    riskAversion::Float64
    deposit::Int64
    p::Float64
end

mutable struct Bank
    vault::Int64
end

mutable struct Model
    agtTicker::Int64
    agtList::Array{Agent}
    depth::Int64
    insur::Float64
    # prod is defined as a premium over insur
    prod::Float64
    bargRes::Int64
    # we need an exogenous probability of withdrawal
    exogP::Float64
    # now, since the agents are uniform, we need the uniform agent level parameters
    endow::Int64
    riskAversion::Float64
    p::Float64
    # we need a model KeyCol
    sampSize::Int64
    seed::Int64
    theBank::Bank
    key::String
end
# we need a struct for a study. We are optimizing parameters p, and exogP to give the agents ratEx. All other parameters are fixed for a given "study" 
struct Study
    insur::Float64
    prod::Float64
    riskAversion::Float64
end