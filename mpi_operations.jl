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

