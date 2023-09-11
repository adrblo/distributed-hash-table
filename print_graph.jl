include("function_neighborhood.jl")
include("methods.jl")

size = parse(Int, ARGS[2])
mode = parse(Int, ARGS[1])

(nodes, ids, perm_ids, perm_ids⁻¹) = props(size)
(idsh, permh, permh⁻¹) = hash_props(nodes)

if mode == 0    
    for index in 1:size
        println(string("Pos ", index, " Node: ", nodes[permh][index], " Hash: ", ids[permh][index]))
    end
elseif mode == 1
    nodes = range(0, size-1)
    for index in 1:size
        println(string("Pos ", index, " Node: ", nodes[permh][index], " Hash: ", h(nodes[permh][index])))
    end
end