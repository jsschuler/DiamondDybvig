# Objects for DD Model

mutable struct Agent
end

mutable struct Bank
    vault::Int64
end

mutable struct Model
    nonBankingList::Array{Agent}
    bankingList::Array{Agent}
    endow::Int64
    deposit::Int64
    objP::Float64
    subjP::Float64
    insur::Float64
    prod::Float64
    riskAver::Float64
    theBank::Bank
end
