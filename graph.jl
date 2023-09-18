using Graphs
using GraphPlot
using Compose
import Cairo, Fontconfig

include("methods.jl")
include("function_neighborhood.jl")

size = 64
g = SimpleDiGraph(size)

for node in 0:(size-1)
    N = neighbors(node, size)
end

#draw(PNG("graph.png", 16cm, 16cm), gplot(g))
