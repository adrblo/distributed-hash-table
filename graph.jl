using Graphs
using GraphPlot
using Compose
import Cairo, Fontconfig

module M
    include("methods.jl")
    include("function_neighborhood.jl")
end
size = parse(Int, ARGS[1])
nodes = Array(range(0, size-1))
g = SimpleDiGraph(size)

for node in 0:(size-1)
    N, l, circ = M.neighbors(node, nodes)
    for neig in N
        add_edge!(g, node + 1, neig + 1)
    end
end

nodesize = [Graphs.outdegree(g, v) for v in Graphs.vertices(g)]
gp = gplot(g, nodelabel=0:(nv(g)-1), nodelabelsize=500, edgelinewidth=200, arrowlengthfrac=0.01)
draw(PDF("graph.pdf", 50cm, 50cm), gp)
