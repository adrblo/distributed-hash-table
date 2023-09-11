@enum Command begin
    noCommand = 0
    otherCommand = 1
    command_trace = 2
    command_info = 3

    request_search = 100
    response_search = 200
    insert = 101
    delete = 102
    lookup = 103
    join = 104
    leave = 105
    command_linearize = 106
end

struct Message
    command::Command
    from::Int
    node::Int
    data::Int
    success::Bool
end

function Message(command::Command; from::Int=0, node=0, data=0, success=false)
    return Message(command, from, node, data, success)
end

mutable struct Process
    self::Int
    left::Union{Int, Nothing}
    right::Union{Int, Nothing}
    neighbors::Array{Int}
    storage::Array{Int}
end

function Process(rank::Int, size::Int)
    context = props(size)
    left = predᵢ(nothing, 0, rank, context...)
    right = succᵢ(nothing, 0, rank, context...)

    N = neighbors(rank, size)

    storage = []

    return Process(rank, left, right, N, storage)
end
