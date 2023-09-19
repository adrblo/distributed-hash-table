function _search(p, ←, from, data_hash::Float64)
    self_hash = h(p.self)

    if p.left !== nothing
        left_hash = h(p.left)
    else
        left_hash = 0
    end

    if p.right !== nothing
        right_hash = h(p.right)
    else
        right_hash = 1
    end
    if !(data_hash >= left_hash && data_hash <= right_hash) && !(p.circ !== nothing && data_hash < h(p.circ))
        not_already_requested = combine!(p.combines, response_search, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Search" data_hash from r self_hash p.combines
            r ← search(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash && p.right !== nothing
            @info "Search near" data_hash from self_hash
            if p.left !== nothing
                p.left ← search(data_hash, from)
            else
                p.circ ← search(data_hash, from)
            end
        else
            # search is at correct node
            @info "Search ARRIVED" data_hash from self_hash

            # callback
            p.self ← callback(response_search, data_hash, p.self, from, 0)
        end
    end
end

function search(data_hash, from)
    return (_search, (data_hash, from))
end

function _callback(p, ←, type, requesting_node, data_hash::Float64, data_node, data)
    nodes = split!(p.combines, type, data_hash)
    if isempty(nodes)
        if requesting_node == p.self
            @info "Callback ARRIVED" type data_hash requesting_node data_node
            return
        end
        r = route(p.self, p.neighbors, requesting_node)
        @info "Callback NoSplit" type data_hash r requesting_node data_node p.combines
        r ← callback(type, data_hash, data_node, requesting_node, data)
    else
        for s_node in nodes
            r = route(p.self, p.neighbors, s_node)
            @info "Callback" type data_hash r s_node data_node p.combines
            r ← callback(type, data_hash, data_node, s_node, data)
        end
    end
end

function callback(type, data_hash, data_node, requesting_node, data)
    return (_callback, (type, data_hash, data_node, requesting_node, data))
end

function _lookup(p, ←, from, data_hash)
    self_hash = h(p.self)

    if p.left !== nothing
        left_hash = h(p.left)
    else
        left_hash = 0
    end

    if p.right !== nothing
        right_hash = h(p.right)
    else
        right_hash = 1
    end
    if !(data_hash >= left_hash && data_hash <= right_hash) && !(p.circ !== nothing && data_hash < h(p.circ))
        not_already_requested = combine!(p.combines, response_lookup, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Lookup" data_hash from r self_hash
            r ← lookup(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash && p.right !== nothing
            @info "Lookup near" data_hash from self_hash
            if p.left !== nothing
                p.left ← lookup(data_hash, from)
            else
                p.circ ← lookup(data_hash, from)
            end
        else
            # search is at correct node
            data = get(p.storage, data_hash, 0) # 0 means not found
            @info "Lookup ARRIVED" data_hash from self_hash data

            # callback
            p.self ← callback(response_lookup, data_hash, p.self, from, data)
        end
    end
end

function lookup(data_key, from)
    return (_lookup, (data_key, from))
end

function _insert(p, ←, from, data)
    data_hash = g(data)
    self_hash = h(p.self)

    if p.left !== nothing
        left_hash = h(p.left)
    else
        left_hash = 0
    end

    if p.right !== nothing
        right_hash = h(p.right)
    else
        right_hash = 1
    end
    if !(data_hash >= left_hash && data_hash <= right_hash) && !(p.circ !== nothing && data_hash < h(p.circ))
        not_already_requested = combine!(p.combines, response_insert, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Insert Forward" data_hash from r self_hash
            r ← insert(data, p.self)
        end
        return
    else
        if data_hash < self_hash && p.right !== nothing
            @info "Insert near" data_hash from self_hash
            if p.left !== nothing
                p.left ← insert(data, from)
            else
                p.circ ← insert(data, from)
            end
        else
            # insert is at correct node
            p.storage[data_hash] = data
            @info "Insert COMPLETE" data_hash from self_hash p.storage

            # callback
            p.self ← callback(response_insert, data_hash, p.self, from, data)
        end
    end
    return
end

function insert(data, from)
    return (_insert, (data, from))
end

function _delete(p, ←, data_hash, from)
    self_hash = h(p.self)

    if p.left !== nothing
        left_hash = h(p.left)
    else
        left_hash = 0
    end

    if p.right !== nothing
        right_hash = h(p.right)
    else
        right_hash = 1
    end
    if !(data_hash >= left_hash && data_hash <= right_hash) && !(p.circ !== nothing && data_hash < h(p.circ))
        not_already_requested = combine!(p.combines, response_delete, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Delete Forward" data_hash from r self_hash
            r ← delete(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash && p.right !== nothing
            @info "Delete near" data_hash from self_hash
            if p.left !== nothing
                p.left ← delete(data_hash, from)
            else
                p.circ ← delete(data_hash, from)
            end
        else
            # insert is at correct node
            delete!(p.storage, data_hash)
            @info "Delete COMPLETE" data_hash from self_hash p.storage

            # callback
            p.self ← callback(response_delete, data_hash, p.self, from, 0)
        end
    end
    return
end

function delete(data_key, from)
    return (_delete, (data_key, from))
end

function _trace(p::Process, node, ←, from)
    if node == p.self
        @info "Trace ARRIVED" from
        return
    else
        r = route(p.self, p.neighbors, node)
        @info "Trace" node from r
        r ← trace(node, from)
    end
end

function trace(node::Int, from::Int)
    (_trace, (node, from))
end


function _info(p::Process, content::Int)
    println(p.self, ": ", content)
end


function info(content::Int)
    return (_info, (content,))
end

function _linearize(p::Process, node, ←)
    if node in p.neighbors || node == p.self
        return
    end
    
    (new_neighbors, left, right, levels) = calc_neighbors(p.self, union(p.neighbors, node))
    
    # handle redirect
    diffset = setdiff(p.neighbors, new_neighbors)
    if isempty(diffset) && !(node in new_neighbors)
        diffset = [node]
    end
    
    @info "DEBUG Linearize 1" new_neighbors p.neighbors node p diffset

    for was_neighbor in diffset
        new_neighbors_with_node = union(new_neighbors, was_neighbor)
        ids_new_neighborswn = [bitstring(id(x)) for x in new_neighbors_with_node]
        ids_nnwn_perm = sortperm(ids_new_neighborswn)
        ids_nnwn_perm⁻¹ = sortperm(ids_nnwn_perm)

        #pos = ids_nnwn_perm⁻¹[length(new_neighbors_with_node)]
        pos = findfirst(new_neighbors_with_node[ids_nnwn_perm] .== was_neighbor)

        @info "DEBUG Linearize 2" was_neighbor bitstring(id(p.self)) bitstring(id(node))
        if pos == 1
            new_neighbors_with_node[ids_nnwn_perm][1] ← linearize(was_neighbor)
        elseif pos == length(new_neighbors_with_node)
            new_neighbors_with_node[ids_nnwn_perm][length(new_neighbors_with_node)] ← linearize(was_neighbor)
        else
            pre = 0
            after = 0
            for bitlen in 1:length(ids_new_neighborswn[1])
                if ids_new_neighborswn[ids_nnwn_perm][pos - 1][1:bitlen] == bitstring(id(was_neighbor))[1:bitlen]
                    pre = bitlen
                else
                    break
                end
            end

            for bitlen in 1:length(ids_new_neighborswn[1])
                if ids_new_neighborswn[ids_nnwn_perm][pos + 1][1:bitlen] ==  bitstring(id(was_neighbor))[1:bitlen]
                    after = bitlen
                else
                    break
                end
            end
            
            if pre > after
                @info "DEBUG Linearize" pre ids_new_neighborswn[ids_nnwn_perm][pos - 1] bitstring(id(was_neighbor)) new_neighbors_with_node
                new_neighbors_with_node[ids_nnwn_perm][pos - 1] ← linearize(was_neighbor)
            else
                @info "DEBUG Linearize" after ids_new_neighborswn[ids_nnwn_perm][pos + 1] bitstring(id(was_neighbor)) new_neighbors_with_node
                new_neighbors_with_node[ids_nnwn_perm][pos + 1] ← linearize(was_neighbor)
            end
        end
    end

    # ugly hack
    if left == p.self
        left = p.left
    end

    if right == p.self
        right = p.right
    end

    circ = p.circ
    if p.circ !== nothing
        if left !== nothing && p.left === nothing && p.right !== nothing
            left ← become_circ(p.circ, p.self)
            circ = nothing
            @info "Linearize Circ lost" p.circ p.left p.right left right
        elseif right !== nothing && p.right === nothing && p.left !== nothing
            right ← become_circ(p.circ, p.self)
            circ = nothing
            @info "Linearize Circ lost" p.circ p.left p.right left right
        end
    end

    if p.right !== right && right !== nothing && right !== p.self
        dict_join!(p, ←, right)
    end

    # re set direct neighbors
    p.left = left
    p.right = right
    p.neighbors = new_neighbors
    p.levels = levels
    p.circ = circ
end

function linearize(node)
    return (_linearize, (node,))
end

function _become_circ(p::Process, ←, circ, from)
    @info "BecomeCirc" p.self p.left p.right p.circ p.storage
    if !(from == circ)
        circ ← become_circ(p.self, p.self)
    else
        if p.right === nothing
            @info "BecomeCirc DictJoin" p.storage circ h(circ)
            for (k, v) in p.storage
                if k >= h(circ) && k < h(p.self)
                    circ ← leave_transfer(k, v)
                    delete!(p.storage, k)
                end
            end
        end
    end
    p.circ = circ
    @info "BecomeCirc END" p.left p.right p.circ 
end

function become_circ(circ, from)
    (_become_circ, (circ, from))
end

function dict_join!(p::Process, ←, right_node)
    @info "DictJoin" p.storage right_node h(right_node)
    for (k, v) in p.storage
        if k >= h(right_node)
            right_node ← leave_transfer(k, v)
            delete!(p.storage, k)
        end
    end
end

function combine!(combines::Dict{Tuple{Command, Float64}, Array{Int}}, command::Command, data_key::Float64, from::Int)::Bool
    """
    Returns true if a request was not send already
    """
    nodes::Array{Int} = get(combines, (command, data_key), [])
    if !(from in nodes)
        if isempty(nodes)
            combines[(command, data_key)] = [from]
        else
            push!(combines[(command, data_key)], from)
        end
    end
    if isempty(nodes)
        return true
    else
        return false
    end
end

function split!(combines::Dict{Tuple{Command, Float64}, Array{Int}}, command::Command, data_key::Float64)::Array{Int}
    """
    Returns nodes which requested
    """
    @info "Split" combines command data_key
    nodes::Array{Int} = get(combines, (command, data_key), [])
    if !isempty(nodes)
        delete!(combines, (command, data_key))
    end
    return nodes
end

function _leave_transfer(p::Process, data_hash, data)
    p.storage[data_hash] = data
    @info "Leave TRANSFER" data data_hash p.storage
end

function leave_transfer(data_hash, data)
    return (_leave_transfer, (data_hash, data))
end

function _leave_forward(p::Process, from, node)
    if p.left == from
        p.left = node
    elseif p.right == from
        p.right == node
    end
    @info "Leave FORWARD" from node p
end

function leave_forward(from, node)
    return (_leave_forward, (from, node))
end

function _leave(p::Process, node, ←)
    if p.self == node
        for neighbor in p.neighbors
            if neighbor !== node
                neighbor ← leave(node)
            end
        end
        @info "Leave INITIATED" node
        for (k, v) in p.storage
            p.left ← leave_transfer(k, v)
        end
        p.left ← leave_forward(p.self, p.right)
        p.right ← leave_forward(p.self, p.left)
        @info "Leave COMPLETE" p
    else 
        deleteat!(p.neighbors, findall(x->x==node,p.neighbors))
        @info "Leave ARRIVED" node p.neighbors
    end
end

function leave(node)
    return (_leave, (node))
end

function _join(p::Process, node, ←)
    #linearize v auf Knoten u aufrufen
    @info "Join INITIATED" p.self node
    if p.left === nothing
        left = 0
    else
        left = h(p.left)
    end

    if p.right === nothing
        right = 1
    else
        right = h(p.right)
    end

    if left < h(node) < right
        p.self ← linearize(node)
    else
        r = hash_route(p.self, p.neighbors, h(node))
        r ← join(node)
    end
end

function join(node)
    return (_join, (node,))
end


function timeout(p::Process, ←)
    # rule 1a
    for (level, nodes) in copy(p.levels) # CHECK if necessary
        # case list of one
        if length(nodes) == 1
            @info "Timeout 1a" level, length(nodes) nodes[1] nodes p.self
            nodes[1] ← linearize(p.self)
        else
            pos = trunc(Int, length(nodes)/2) + 1
            insert!(nodes, pos, p.self)

            for i in 1:pos-1
                @info "Timeout 1a" level, length(nodes) nodes[i] nodes[i+1] nodes p.self
                nodes[i] ← linearize(nodes[i + 1])
            end

            for i in reverse(pos+1:length(nodes))
                @info "Timeout 1a" level, length(nodes) nodes[i] nodes[i-1] nodes p.self
                nodes[i] ← linearize(nodes[i - 1])
            end
        end
        sleep(1)
    end

    # rule 1b
    for (level, nodes) in p.levels
        if length(nodes) < 2
            continue
        end

        for node in nodes
            @info "Timeout 1b 1" node nodes level p.self
            ids = [bitstring(id(x)) for x in nodes]
            perm_ids = sortperm(ids)

            pos = findfirst(nodes[perm_ids] .== node)

            if pos == 1
                prev = nothing
            else
                prev = pos - 1
            end

            if pos == length(nodes)
                after = nothing
            else
                after = pos + 1
            end

            for other in nodes
                if other == p.self
                    continue
                end

                if bitstring(id(other)) < bitstring(id(node))
                    if after !== nothing
                        other ← linearize(nodes[perm_ids][after])
                    end
                else 
                    if prev !== nothing
                        other ← linearize(nodes[perm_ids][prev])
                    end
                end
            end
        end
    end
end