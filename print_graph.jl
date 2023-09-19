include("function_neighborhood.jl")
include("methods.jl")

size = parse(Int, ARGS[2])
mode = parse(Int, ARGS[1])

nodes = Array(range(0, size-1))
ids = props(nodes)
(idsh, permh, permh⁻¹) = hash_props(nodes)

if mode == 0    
    for index in 1:size
        println(string("Pos ", index, " Node: ", nodes[permh][index], " Hash: ", idsh[permh][index]))
    end
elseif mode == 1
    nodes = range(0, size-1)
    for index in 1:size
        println(string("Pos ", index, " Node: ", nodes[permh][index], " Hash: ", bitstring(id(nodes[permh][index]))))
    end
end