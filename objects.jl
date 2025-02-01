# Objects for DD Model

mutable struct Agent
end

mutable struct Bank
    vault::Int64
end


abstract type ModBase end

mutable struct Model <: ModBase
    nonBankingList::Array{Agent}
    bankingList::Array{Agent}
    endow::Int64
    deposit::Int64
    objP::Float64
    subjP::Float64
    insur::Float64
    prod::Float64
    riskAversion::Float64
    theBank::Bank
end

mutable struct SimModel <: ModBase
    nonBankingList::Array{Agent}
    bankingList::Array{Agent}
    endow::Int64
    deposit::Int64
    objP::Float64
    subjP::Float64
    insur::Float64
    prod::Float64
    riskAversion::Float64
    theBank::Bank
end

