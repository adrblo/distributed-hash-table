using Base
using Logging

# Idee:
# ranks: Zahlenfolge 0..size <- x
# Ranks mit Liste verbunden
# id(x) = hash(x * mult)

const mult = 2500

function id(x::Int)::UInt64
    return hash((x + 1) * mult)
end

function props(nodes)
    ids::Vector{String} = [bitstring(id(x)) for x in nodes]

    return ids
end

function hash_props(nodes)
    hs::Vector{Float64} = [h(x) for x in nodes]
    perm = sortperm(hs)
    perm⁻¹ = sortperm(perm)

    return hs, perm, perm⁻¹
end

function neighbors(self::Int, nodes)
    # ⇒ ids[perm_ids] := sorted array of ids
    ids = props(nodes)
    
    idsh, permh, permh⁻¹ = hash_props(nodes)
    perm_ids = permh
    perm_ids⁻¹ = permh⁻¹
    context = (nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹)

    N = Set()
    levels::Dict{Int, Array{Int}} = Dict()

    left = predᵢ(nothing, 0, self, context...) 
    right = succᵢ(nothing, 0, self, context...)

    pos = findfirst(nodes[permh] .== self)
    circ = nothing
    if pos == 1
        circ = nodes[permh][length(nodes)]
    elseif pos == length(nodes)
        circ = nodes[permh][1]
    end

    if left !== nothing
        push!(N, left)
    end

    if right !== nothing
        push!(N, right)
    end

    for i in 0:length(ids[1])
        r = rangeᵢ(i, self, context...)
        
        prefix = bitstring(id(self))[1:i]

        level_N = []
        r1_pos = findfirst(nodes[permh] .== r[1])
        r2_pos = findfirst(nodes[permh] .== r[2])

        for j in r1_pos:r2_pos
            idj = ids[perm_ids][j]
            if idj[1:i] == prefix
                push!(N, nodes[perm_ids][j])
                if nodes[perm_ids][j] !== self
                    push!(level_N, nodes[perm_ids][j])
                end
            end
        end

        # add to levels
        if !isempty(level_N)
            levels[i] = level_N
        end
    end

    delete!(N, self)
    Narray = collect(N)
    nids = [bitstring(id(x)) for x in Narray]
    perm_ids = sortperm(nids)

    return Narray[perm_ids], levels, circ
end

function predᵢ(i::Union{Int, Nothing}, b::Int, x::Int, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹)::Union{Int, Nothing}
    """
    Returns node

    x+1 := Index of node x
    """
    pos = findfirst(nodes[permh] .== x)
    if i === nothing
        if pos == 1
            return nothing
        else 
            return nodes[permh][pos - 1]
        end
    end

    for index in (pos - 1):-1:1
        if startswith(ids[perm_ids][index], bitstring(id(x))[1:i] * string(b))
            return nodes[perm_ids][index]
        end
    end
    return nodes[perm_ids][1]
end

function succᵢ(i::Union{Int, Nothing}, b::Int, x::Int, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹)::Union{Int, Nothing}
    """
    Returns node

    x+1 := Index of node x
    """
    pos = findfirst(nodes[permh] .== x)
    if i === nothing
        if pos == size(nodes, 1)
            return nothing
        else
            return nodes[permh][pos + 1]
        end
    end

    for index in (pos + 1):+1:size(nodes, 1)
        if startswith(ids[perm_ids][index], bitstring(id(x))[1:i] * string(b))
            return nodes[perm_ids][index]
        end
    end
    return nodes[perm_ids][size(nodes, 1)]
end

function rangeᵢ(i::Union{Int, Nothing}, x::Int, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹)::Tuple{Int, Int}
    pos_pred_0 = findfirst(nodes .== predᵢ(i, 0, x, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹))
    pos_pred_1 = findfirst(nodes .== predᵢ(i, 1, x, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹))
    pos_succ_0 = findfirst(nodes .== succᵢ(i, 0, x, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹))
    pos_succ_1 = findfirst(nodes .== succᵢ(i, 1, x, nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹))
    return(
        nodes[perm_ids][min(perm_ids⁻¹[pos_pred_0], perm_ids⁻¹[pos_pred_1])],
        nodes[perm_ids][max(perm_ids⁻¹[pos_succ_0], perm_ids⁻¹[pos_succ_1])]
    )
end


function calc_neighbors(self::Int, neighbors)
    push!(neighbors, self)
    ids = [bitstring(id(x)) for x in neighbors]
    nodes = neighbors
    
    idsh, permh, permh⁻¹ = hash_props(neighbors)
    perm_ids = permh
    perm_ids⁻¹ = permh⁻¹
    context = (nodes, ids, perm_ids, perm_ids⁻¹, idsh, permh, permh⁻¹)

    N = Set()
    levels::Dict{Int, Array{Int}} = Dict()

    left = predᵢ(nothing, 0, self, context...)
    right = succᵢ(nothing, 0, self, context...)

    if left !== nothing
        push!(N, left)
    end

    if right !== nothing
        push!(N, right)
    end

    for i in 0:length(ids[1])
        
        r = rangeᵢ(i, self, context...)
        r1_pos = findfirst(nodes .== r[1])
        r2_pos = findfirst(nodes .== r[2])

        prefix = bitstring(id(self))[1:i]

        level_N = []

        for j in perm_ids⁻¹[r1_pos]:perm_ids⁻¹[r2_pos]
            idj = ids[perm_ids][j]
            if idj[1:i] == prefix
                push!(N, nodes[perm_ids][j])
                if nodes[perm_ids][j] !== self
                    push!(level_N, nodes[perm_ids][j])
                end
            end
        end

        # add to levels
        if !isempty(level_N)
            levels[i] = level_N
        end
    end

    delete!(N, self)
    Narray = collect(N)

    return (Narray, left, right, levels)
end