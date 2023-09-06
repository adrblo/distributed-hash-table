using Base

# Idee:
# ranks: Zahlenfolge 0..size <- x
# Ranks mit Liste verbunden
# id(x) = hash(x * mult)

const mult = 10

function id(x::Int)::UInt64
    return hash((x + 1) * mult)
end

function neighbors(self::Int, size::Int)
    nodes::Vector{Int} = range(0, size-1)
    ids::Vector{String} = [bitstring(id(x)) for x in nodes]
    perm_ids = sortperm(ids)
    perm_ids⁻¹ = sortperm(perm_ids)

    # ⇒ ids[perm_ids] := sorted array of ids
    context = (nodes, ids, perm_ids, perm_ids⁻¹)
    
    # debug
    for index in 1:size
        println(string("Pos ", index, " Node: ", nodes[perm_ids][index], " Hash: ", ids[perm_ids][index]))
    end

    N = []

    left = predᵢ(nothing, 0, self, context...)
    right = succᵢ(nothing, 0, self, context...)

    if left !== nothing
        push!(N, left)
    end

    if right !== nothing
        push!(N, right)
    end
    

    return rangeᵢ(2, self, context...)
end

function predᵢ(i::Union{Int, Nothing}, b::Int, x::Int, nodes, ids, perm_ids, perm_ids⁻¹)::Union{Int, Nothing}
    """
    Returns node

    x+1 := Index of node x
    """
    if i === nothing
        if x == nodes[perm_ids][1]
            return nothing
        else 
            return nodes[perm_ids][perm_ids⁻¹[x+1] - 1]
        end
    end

    for index in (perm_ids⁻¹[x+1] - 1):-1:1
        if startswith(ids[perm_ids][index], bitstring(id(x))[1:i] * string(b))
            return nodes[perm_ids][index]
        end
    end
    return nodes[perm_ids][1]
end

function succᵢ(i::Union{Int, Nothing}, b::Int, x::Int, nodes, ids, perm_ids, perm_ids⁻¹)::Union{Int, Nothing}
    """
    Returns node

    x+1 := Index of node x
    """
    if i === nothing
        if x == nodes[perm_ids][size(nodes, 1)]
            return nothing
        else 
            return nodes[perm_ids][perm_ids⁻¹[x+1] + 1]
        end
    end

    for index in (perm_ids⁻¹[x+1] + 1):+1:size(nodes, 1)
        if startswith(ids[perm_ids][index], bitstring(id(x))[1:i] * string(b))
            return nodes[perm_ids][index]
        end
    end
    return nodes[perm_ids][size(nodes, 1)]
end

function rangeᵢ(i::Union{Int, Nothing}, x::Int, nodes, ids, perm_ids, perm_ids⁻¹)::Tuple{Int, Int}
    return (
        nodes[perm_ids][min(perm_ids⁻¹[predᵢ(i, 0, x, nodes, ids, perm_ids, perm_ids⁻¹) + 1], perm_ids⁻¹[predᵢ(i, 1, x, nodes, ids, perm_ids, perm_ids⁻¹) + 1])],
        nodes[perm_ids][max(perm_ids⁻¹[succᵢ(i, 0, x, nodes, ids, perm_ids, perm_ids⁻¹) + 1], perm_ids⁻¹[succᵢ(i, 1, x, nodes, ids, perm_ids, perm_ids⁻¹) + 1])]
    )
end

println(neighbors(7, 24))