using MPI

@enum Command begin
    noCommand = 0
    otherCommand = 1
end

struct Message
    command::Command
end


function empty_message()
    return Message(noCommand)
end

function send_message(command::Command, dest, comm::MPI.Comm)
    MPI.Isend(Message(command), comm; dest=dest)
end


function occupied(arr::Array{Message})
    counter = 0
    for elem::Message in arr
        if elem.command !== noCommand
            counter += 1
        end
    end
    return counter
end

arr = [empty_message() for i in 1:100]
arr[1] = Message(otherCommand)

print(occupied(arr))
