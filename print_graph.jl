include("function_neighborhood.jl")

size = parse(Int, ARGS[1])

(nodes, ids, perm_ids, perm_ids⁻¹) = props(size)

A = Matrix{String}(undef, size, 3)
for index in 1:size
    println(string("Pos ", index, " Node: ", nodes[perm_ids][index], " Hash: ", ids[perm_ids][index]))
end
