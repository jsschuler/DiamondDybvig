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
    depth::Int64
    insur::Float64
    insur::Float64
    prod::Float64
    bargRes::Int64
    # we need an exogenous probability of withdrawal
    exogP::Float64
    # we need a model KeyCol
    sampSize::Int64
    seed::Int64
    theBank::Bank
    key::String
end