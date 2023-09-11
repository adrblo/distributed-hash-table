function h(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function g(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function hsucc(hvalues::Array, x::Int)::Float64
    """
    Return next hash in Array
    """
    svalues = sort(hvalues)
    index = findfirst(==(x), svalues)

    if (index == size(hvalues, 1))
        return 1
    else
        return index + 1
    end
end

function hpred(hvalues::Array, x::Int)::Float64
    """
    Return previous hash in Array
    """
    svalues = sort(hvalues)
    index = findfirst(==(x), svalues)

    if (index == 1)
        return size(hvalues, 1)
    else
        return index - 1
    end
end


function route(self::Int, N::Vector{Int}, x::Int)
    # TODO: check if x doesnt exist
    push!(N, self) # uggly hack
    nodes = N
    ids::Vector{String} = [bitstring(id(node)) for node in N]
    perm_ids = sortperm(ids)
    perm_ids⁻¹ = sortperm(perm_ids)

    self_pos_sort = perm_ids⁻¹[length(N)]

    if id(x) == id(self)
        return x
    elseif id(x) < id(self)
        if bitstring(id(x)) < ids[perm_ids][1]
            return nodes[perm_ids][1]
        end

        # left between or non existent
        for index in 1:self_pos_sort-1
            if bitstring(id(x)) <= ids[perm_ids][index]
                return nodes[perm_ids][index]
            end
        end
    else
        if bitstring(id(x)) > ids[perm_ids][length(N)]
            return nodes[perm_ids][length(N)]
        end

        # right between or non existent
        for index in length(N):-1:self_pos_sort+1
            if bitstring(id(x)) >= ids[perm_ids][index]
                return nodes[perm_ids][index]
            end
        end 
    end
end