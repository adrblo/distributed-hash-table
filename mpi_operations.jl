@enum Command begin
    noCommand = 0
    otherCommand = 1
    trace = 2

    insert = 100
    delete = 101
    lookup = 102
    join = 103
    leave = 104
end

struct Message
    command::Command
    from::Int
    node::Int
    data::Int
end

function Message(command::Command, from::Int; node=0, data=0)
    return Message(command, from, node, data)
end

←(node::Int, op::Tuple) = begin
    println(node, "←", op)
end