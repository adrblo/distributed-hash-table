@enum Command begin
    noCommand = 0
    otherCommand = 1
    trace = 2
    cinfo = 3

    search = 100
    insert = 101
    delete = 102
    lookup = 103
    join = 104
    leave = 105
    clinearize = 106
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
end

function Process(rank::Int)
    return Process(rank, nothing, nothing, [])
end