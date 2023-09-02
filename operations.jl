self = 0 # would be rank

←(node::Int, op::Tuple) = begin
    println(node, "←", op)
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


function info(x::Int)
    return (_info, (content,))
end


function _search(x::Float16)
    
end


function search(x::Float16)
    return (_info, (x,))
end
