include("function_neighborhood.jl")

nsize = [length(neighborhood(x, 12)) for x in range(0,12)]

print(nsize)
