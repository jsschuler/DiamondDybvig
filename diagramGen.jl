#################################################################################################
#                                                                                               #
#                     Diamond-Dybvig Diagram Generation Functions                               #
#                     June 2024                                                                 #
#                     John S. Schuler                                                           #
#                                                                                               #
#                                                                                               #
#################################################################################################

using Luxor


function draw_rectangle(dLength, dWidth,margin,rows,circMarg)
    Drawing(dWidth, dLength, "luxor-drawing.svg")
    # now, translate the origin down by the margin
    background("white")
    sethue("black")
    # now what is the area we can draw in?
    lowerY=dLength-2*margin
    lowerX=dWidth-2*margin
    # now how vertically long is each row?
    yLong=lowerY/rows
    # now draw the first line
    pointArray::Array{Point}=Array{Point}[]
    finArray::Array{Point}=Array{Point}[]
    originArray::Array{Point}=Array{Point}[]
    Org=Point(0,0)

    # now, what is the length of the 

    for k in 0:rows
        push!(pointArray,Point(Org.x,Org.y+k*yLong))
        push!(finArray,Point(Org.x+dWidth-2*margin,Org.y+k*yLong))
    end
    println(pointArray)
    println(finArray)
    println(typeof(pointArray))
    println(pointArray)
    translate(margin,margin)
    for i in 1:(length(pointArray)-1)
        box(pointArray[i], finArray[i+1], action=:stroke)
    end
    #box(Point(0, 0), 100, 100, action=:stroke)
    finish()
    preview()




end

draw_rectangle(800, 600,10,10,2)
dLength=800
dWidth=800
margin=10
rows=10

function draw_diagram(mX::Int64,mY::Int64,w::Int64,l::Int64,n::Int64,k::Int64)
    # Step 1: margin
    margin=Point(mX,mY)
    # Now, we need a matrix of points that the lines will connect
    boundPoints=Point[]
    # since the reshape works in column major format, use two loops
    for i in 0:k
        push!(boundPoints,margin + Point(0,(i*l/k)))
    end
    for i in 0:k
        push!(boundPoints,margin+Point(w,(i*l)/k))
    end
    boundPoints=reshape(boundPoints, floor(Int64,length(boundPoints)/2), 2)
    println(boundPoints)
    println(size(boundPoints))
    # now assemble into a matrix
    for t in 1:size(boundPoints)[1]
        println(boundPoints[t,:])
    end
end

draw_diagram(10,10,600,800,10,10)