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
