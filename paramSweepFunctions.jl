# for reasons of book keeping, each of these parameters gets a struct
struct parameter
    name::Symbol
    distrib::UnivariateDistribution
end
# global parameter list
paramList=parameter[]
function parameterGen(name::Symbol,distribution::UnivariateDistribution)
    global paramList
    push!(paramList,parameter(name,distribution))
end

# We have a unit 3-cube that we must fill with quasi-random points
function vanderCorput(n::Int64,base::Int64)
    # take the log base b and round down
    remainder=n
    coefficients=[]
    exponents=[]
    while remainder > 0
        expon=floor(Int64,log(base,remainder))
        alpha=floor(Int64,remainder/(base^expon))
        chunk=alpha*base^expon
        remainder=remainder-chunk
        push!(coefficients,alpha)
        push!(exponents,expon)
    end
    #println(n)
    #println(coefficients)
    #println(exponents)
    return sum(coefficients./(base.^(exponents.+1)))
end

# we need a global variable of how many quasi-random points have been generated
pointCount=1
function unifGenerate(count::Int64)
    dim=length(paramList)
    dArray=[]
    global pointCount
    lo=1
    for i in lo:(count)
        pointCount=pointCount+1
        col=[]
        for j in 1:dim
            if j==1
                push!(col,i/(count+1))
            else
                push!(col,vanderCorput(i,prime(j)))
            end
        end
        push!(dArray,col)
    end
    return DataFrame(transpose(hcat(dArray...)),:auto)
end

function parameterGenerate(count::Int64)
    unifData=unifGenerate(count::Int64)
    global paramList
    quantileList=[]
    for j in 1:size(unifData)[2]
        tmpFunc= (x) -> quantile(paramList[j].distrib,x)
        unifData[:,j]=tmpFunc.(unifData[:,j])
    end
    paramNames=[]
    for param in paramList
        push!(paramNames,param.name)
    end
    rename!(unifData,Symbol.("x".*string.(1:length(paramList))).=> paramNames)
    return unifData
end