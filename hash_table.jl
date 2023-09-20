function h(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function g(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function route(self::Int, N::Vector{Int}, x::Int)
    return hash_route(self, N, h(x))
end


function hash_route(self::Int, N::Vector{Int}, data_hash)
    nodes = N
    if !(self in nodes)
        push!(nodes, self)
    end
    ids::Vector{Float64} = [h(node) for node in nodes]
    perm_ids = sortperm(ids)
    perm_ids⁻¹ = sortperm(perm_ids)

    self_pos_sort = perm_ids⁻¹[length(nodes)]

    if data_hash == h(self)
        return self
    elseif data_hash < h(self)
        if data_hash < ids[perm_ids][1]
            return nodes[perm_ids][1]
        end

        # left between or non existent
        for index in 1:self_pos_sort-1
            if data_hash <= ids[perm_ids][index]
                return nodes[perm_ids][index]
            end
        end
    else
        if data_hash > ids[perm_ids][length(nodes)]
            return nodes[perm_ids][length(nodes)]
        end

        # right between or non existent
        for index in length(nodes):-1:self_pos_sort+1
            if data_hash >= ids[perm_ids][index]
                return nodes[perm_ids][index]
            end
        end 
    end
end