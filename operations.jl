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
            _callback_search => (data_hash, from, node) -> Message(response_search; data_hash=data_hash, from=from, node=node),
            _lookup => (data_key, from) -> Message(lookup_element; data_key=data_key, from=from),
            _insert => (data, from) -> Message(insert_element; data=data, from=from),
            _delete => (data_key, from) -> Message(delete_element; data_key=data_key, from=from)
        )

    map_from_message = Dict(
            noCommand => (f, n, d, s, dh, dk, p, ←)-> nothing,
            otherCommand => (f, n, d, s, dh, dk, p, ←)-> nothing,
            command_info => (f, n, d, s, dh, dk, p, ←)-> _info(p, d),
            command_linearize => (f, n, d, s, dh, dk, p, ←) -> _linearize(p, n, ←),
            command_trace => (f, n, d, s, dh, dk, p, ←) -> _trace(p, n, ←, f),
            request_search => (f, n, d, s, dh, dk, p, ←) -> _search(p, ←, f, dh),
            response_search => (f, n, d, s, dh, dk, p, ←) -> _callback_search(p, ←, f, dh, n),
            lookup_element => (f, n, d, s, dh, dk, p, ←) -> _lookup(p, ←, f, dk),
            insert_element => (f, n, d, s, dh, dk, p, ←) -> _insert(p, ←, f, d),
            delete_element => (f, n, d, s, dh, dk, p, ←) -> _delete(p, ←, dk, f),
        )

    function handle_message(message::Message)
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
        r = hash_route(p.self, p.neighbors, data_hash)
        @info "Search" data_hash from r self_hash
        r ← search(data_hash, from)
        return
    else
        if data_hash < self_hash
            @info "Search near" data_hash from self_hash
            p.left ← search(data_hash, from)
        else
            # search is at correct node
            @info "Search ARRIVED" data_hash from self_hash

            # callback
            p.self ← callback_search(data_hash, from, p.self)
        end
    end
end

function search(data_hash, from)
    return (_search, (data_hash, from))
end

function _callback_search(p, ←, from, data_hash::Float64, node)
    if p.self == from
        # do something
        @info "CallbackSearch ARRIVED" data_hash from node
    else
        r = route(p.self, p.neighbors, from)
        @info "CallbackSearch" data_hash r from node
        r ← callback_search(data_hash, from, node)
    end
end

function callback_search(data_hash, from, node)
    return (_callback_search, (data_hash, from, node))
end

function _lookup(p, ←, from, data_hash)
    self_hash = h(p.self)
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        r = hash_route(p.self, p.neighbors, data_hash)
        @info "Lookup" data_hash from r self_hash
        r ← lookup(data_hash, from)
        return
    else
        if data_hash < self_hash
            @info "Lookup near" data_hash from self_hash
            p.left ← lookup(data_hash, from)
        else
            # search is at correct node
            data = get(p.storage, data_hash, "Sorry, not found :(")
            @info "Lookup ARRIVED" data_hash from self_hash data

            # possible callback
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
        r = hash_route(p.self, p.neighbors, data_hash)
        @info "Insert Forward" data_hash from r self_hash
        r ← insert(data, from)
        return
    else
        if data_hash < self_hash
            @info "Insert near" data_hash from self_hash
            p.left ← insert(data, from)
        else
            # insert is at correct node
            p.storage[data_hash] = data
            @info "Insert COMPLETE" data_hash from self_hash p.storage

            # possible callback
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
        r = hash_route(p.self, p.neighbors, data_hash)
        @info "Delete Forward" data_hash from r self_hash
        r ← delete(data_hash, from)
        return
    else
        if data_hash < self_hash
            @info "Delete near" data_hash from self_hash
            p.left ← delete(data_hash, from)
        else
            # insert is at correct node
            delete!(p.storage, data_hash)
            @info "Delete COMPLETE" data_hash from self_hash p.storage

            # possible callback
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
    p.left ← linearize(0)
end

function linearize(node)
    return (_linearize, (node,))
end