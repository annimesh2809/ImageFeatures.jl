
#function to compute local maximum lines with values > threshold and return a vector containing them
function findlocalmaxima(accumulator_matrix::Array{Integer,2},threshold::Integer)
    validLines = Vector{CartesianIndex}(0)
    for val in CartesianRange(size(accumulator_matrix))
        if  accumulator_matrix[val] > threshold &&
            accumulator_matrix[val] > accumulator_matrix[val[1],val[2] - 1] &&
            accumulator_matrix[val] >= accumulator_matrix[val[1],val[2] + 1] &&
            accumulator_matrix[val] > accumulator_matrix[val[1] - 1,val[2]] &&
            accumulator_matrix[val] >= accumulator_matrix[val[1] + 1,val[2]]
            push!(validLines,val)
        end
    end
    validLines
end

"""
```
lines = hough_transform_standard(image, ρ, θ, threshold, linesMax)
```

Returns an vector of tuples corresponding to the tuples of (r,t) where r and t are parameters for normal form of line:
    x*cos(t) + y*sin(t) = r

r = length of perpendicular from (1,1) to the line
t = angle between perpendicular from (1,1) to the line and x-axis

The lines are generated by applying hough transform on the image.

Parameters:
    image       = Image to apply hough transform on (eltype should be `Bool`)
    ρ           = Discrete step size for perpendicular length of line
    θ           = Discrete steps for angle of line (should be `range` object)
    threshold   = No of points to pass through line for considering it valid
    linesMax    = Maximum no of lines to return

"""

function hough_transform_standard{T<:Union{Bool,Gray{Bool}}}(
            img::AbstractArray{T,2},
            ρ::Number, θ::Range,
            threshold::Integer, linesMax::Integer)
   
    ρ > 0 || error("Discrete step size must be positive")
    
    height, width = size(img)
    ρinv = 1 / ρ
    numangle = length(θ)
    numrho = round(Integer,(2(width + height) + 1)*ρinv)

    accumulator_matrix = zeros(Integer, numangle + 2, numrho + 2)

    #Pre-Computed sines and cosines in tables
    sinθ, cosθ = sin.(θ).*ρinv, cos.(θ).*ρinv

    #Hough Transform implementation
    constadd = round(Integer,(numrho -1)/2)
    for pix in CartesianRange(size(img))
        if img[pix]
            for i in 1:numangle
                dist = round(Integer, pix[1] * sinθ[i] + pix[2] * cosθ[i])
                dist += constadd
                accumulator_matrix[i + 1, dist + 1] += 1
            end
        end
    end

    #Finding local maximum lines
    validLines = findlocalmaxima(accumulator_matrix, threshold)
    
    #Sorting by value in accumulator_matrix
    sort!(validLines, by = (x)->accumulator_matrix[x], rev = true)

    linesMax = min(linesMax, length(validLines))

    lines = Vector{Tuple{Number,Number}}(0)

    #Getting lines with Maximum value in accumulator_matrix && size(lines) < linesMax
    for l in 1:linesMax
        lrho = ((validLines[l][2]-1) - (numrho - 1)*0.5)*ρ
        langle = θ[validLines[l][1]-1]
        push!(lines,(lrho,langle))
    end

    lines

end
