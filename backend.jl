@enum Command begin
    noCommand = 0
    otherCommand = 1
    command_trace = 2
    command_info = 3

    request_search = 100
    response_search = 200
    insert_element = 101
    response_insert = 201
    delete_element = 102
    response_delete = 202
    lookup_element = 103
    response_lookup = 203
    process_join = 104
    process_leave = 105
    command_linearize = 106
    transfer_element = 107
    forward_node = 108
    forward_circ = 109
end

struct Message
    command::Command
    from::Int
    node::Int
    data::Int
    success::Bool
    data_hash::Float64
    data_key::Float64
end

function Message(command::Command; from::Int=0, node=0, data=0, success=false, data_hash=0.0, data_key=0)
    return Message(command, from, node, data, success, data_hash, data_key)
end

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
            _leave_forward => (from, node) -> Message(forward_node; from=from, node=node),
            _become_circ => (node, from) -> Message(forward_circ; node=node, from=from)
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
            forward_node => (f, n, d, s, dh, dk, p, ←) -> _leave_forward(p, f, n),
            forward_circ => (f, n, d, s, dh, dk, p, ←) -> _become_circ(p, ←, n, f)
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
