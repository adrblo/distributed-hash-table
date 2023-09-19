function ∇(message, node, comm)
    MPI.Isend(message, comm; dest=node)
end

function ∘(handle_message, message)
    handle_message(message)
end

function build_handle_message(rank, comm, p)
    message_map = Dict(
            _info => (content) -> Message(command_info; data=content),
            _linearize => (node) -> Message(command_linearize; node=node),
            _trace => (node, from) -> Message(command_trace; node=node, from=from),
            _search => (data_hash, from) -> Message(request_search; data_hash=data_hash, from=from),
            _callback => (type, data_hash, data_node, requesting_node, data) -> Message(type; data_hash=data_hash, from=data_node, node=requesting_node, data=data),
            _lookup => (data_key, from) -> Message(lookup_element; data_key=data_key, from=from),
            _insert => (data, from) -> Message(insert_element; data=data, from=from),
            _delete => (data_key, from) -> Message(delete_element; data_key=data_key, from=from),
            _join => (node) -> Message(process_join; node=node),
            _leave => (node) -> Message(process_leave; node=node),
            _leave_transfer => (data_hash, data) -> Message(transfer_element; data_hash=data_hash, data=data),
            _leave_forward => (from, node) -> Message(forward_node; from=from, node=node)
        )

    map_from_message = Dict(
            noCommand => (f, n, d, s, dh, dk, p, ←)-> nothing,
            otherCommand => (f, n, d, s, dh, dk, p, ←)-> nothing,
            command_info => (f, n, d, s, dh, dk, p, ←)-> _info(p, d),
            command_linearize => (f, n, d, s, dh, dk, p, ←) -> _linearize(p, n, ←),
            command_trace => (f, n, d, s, dh, dk, p, ←) -> _trace(p, n, ←, f),
            request_search => (f, n, d, s, dh, dk, p, ←) -> _search(p, ←, f, dh),
            response_search => (f, n, d, s, dh, dk, p, ←) -> _callback(p, ←, response_search, n, dh, f, d),
            response_insert => (f, n, d, s, dh, dk, p, ←) -> _callback(p, ←, response_insert, n, dh, f, d),
            response_delete => (f, n, d, s, dh, dk, p, ←) -> _callback(p, ←, response_delete, n, dh, f, d),
            response_lookup => (f, n, d, s, dh, dk, p, ←) -> _callback(p, ←, response_lookup, n, dh, f, d),
            lookup_element => (f, n, d, s, dh, dk, p, ←) -> _lookup(p, ←, f, dk),
            insert_element => (f, n, d, s, dh, dk, p, ←) -> _insert(p, ←, f, d),
            delete_element => (f, n, d, s, dh, dk, p, ←) -> _delete(p, ←, dk, f),
            process_join => (f, n, d, s, dh, dk, p, ←) -> _join(p, n, ←),
            process_leave => (f, n, d, s, dh, dk, p, ←) -> _leave(p, n, ←),
            transfer_element => (f, n, d, s, dh, dk, p, ←) -> _leave_transfer(p, dh, d),
            forward_node => (f, n, d, s, dh, dk, p, ←) -> _leave_forward(p, f, n)
        )

    function handle_message(message::Message)
        @info "Command handle" message.command
        if get(map_from_message, message.command, nothing) === nothing
            @info "Command ERROR"
            return
        end
        map_from_message[message.command](message.from, message.node, message.data, message.success, message.data_hash, message.data_key, p, ←)
        @info string("Call_self: " * string(rank) * " ← " * string(message.command) * " from " * string(rank)) message
    end

    ←(node::Union{Int, Nothing}, op::Tuple) = begin
        if node === nothing
            return
        end

        message = message_map[op[1]](op[2]...)
        @info string("Call: " * string(node) * " ← " * string(op[1]) * " from " * string(rank)) node, message.command, op[2]
        if node == rank
            ∘(handle_message, message)
        else
            ∇(message, node, comm)
        end
    end

    return handle_message, ←
end

function _search(p, ←, from, data_hash::Float64)
    self_hash = h(p.self)
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        not_already_requested = combine!(p.combines, response_search, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Search" data_hash from r self_hash p.combines
            r ← search(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash
            @info "Search near" data_hash from self_hash
            p.left ← search(data_hash, from)
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
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        not_already_requested = combine!(p.combines, response_lookup, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Lookup" data_hash from r self_hash
            r ← lookup(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash
            @info "Lookup near" data_hash from self_hash
            p.left ← lookup(data_hash, from)
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
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        not_already_requested = combine!(p.combines, response_insert, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Insert Forward" data_hash from r self_hash
            r ← insert(data, p.self)
        end
        return
    else
        if data_hash < self_hash
            @info "Insert near" data_hash from self_hash
            p.left ← insert(data, from)
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
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        not_already_requested = combine!(p.combines, response_delete, data_hash, from)
        if not_already_requested
            r = hash_route(p.self, p.neighbors, data_hash)
            @info "Delete Forward" data_hash from r self_hash
            r ← delete(data_hash, p.self)
        end
        return
    else
        if data_hash < self_hash
            @info "Delete near" data_hash from self_hash
            p.left ← delete(data_hash, from)
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

    # re set direct neighbors
    p.left = left
    p.right = right
    p.neighbors = new_neighbors
    p.levels = levels
    # TODO circle
end

function linearize(node)
    return (_linearize, (node,))
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
        return true
    end
    return false
end

function split!(combines::Dict{Tuple{Command, Float64}, Array{Int}}, command::Command, data_key::Float64)::Array{Int}
    """
    Returns nodes which requested
    """
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
    p.self ← linearize(node)
    
    #alle relevante daten aus speicher von pred(v) an v abgeben
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