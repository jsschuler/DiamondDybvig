using TreeParzen

# we need a function to optimize

#function optim(x::Float64,y::Float64)
#    return x^2 + y^2+ 4*x+6+y-10x*y+40
#end


#optim(params)=params[:x]^2 + params[:y]^2+ params[:x]*params[:y] + params[:z]
function optim(params)
    println(params[:z])
    return params[:x]^2 + params[:y]^2+ params[:x]*params[:y]
end

space = Dict(
    :x => HP.QuantUniform(:x,-10000.0,.001, 10000.0),
    :y => HP.QuantUniform(:y,-10000.0,.001, 10000.0),
    :z => HP.Choice(:z,[1])
)


best = fmin(
    optim, # The function to be optimised.
    space,         # The space over which the optimisation should take place.
    200,          # The number of iterations to take.
)

println(best)