include("function_neighborhood.jl")
include("methods.jl")

for i in 1:100
    if h(17) < g(i) < h(6)
        println(i, " ", g(i))
    end
end