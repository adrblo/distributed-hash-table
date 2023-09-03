function build_handle_message(rank, comm)
    message_map = Dict(
            _info => (content) -> Message(cinfo; data=content),
        )

    map_from_message = Dict(
            noCommand => (f, n, d, s) -> nothing,
            otherCommand => (f, n, d, s) -> nothing,
            cinfo => (f, n, d, s) -> _info(d),
        )

    function handle_message(message::Message)
        map_from_message[message.command](message.from, message.node, message.data, message.success)
    end

    ←(node::Int, op::Tuple) = begin
        message = message_map[op[1]](op[2]...)
        if node == rank
            handle_message(message)
        else
            MPI.Isend(message, comm; dest=node)
        end
    end

    return handle_message, ←
end

function _route(node::Int)
    """
    Returns the nearest node in routing strategy
    """
    return node+1
end


function _info(content::Int)
    println(content)
end


function info(content::Int)
    return (_info, (content,))
end


function _search(x::Float16, from, success)

end


function searchX(x::Float16)
    return (_info, (x, from, success))
end
