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

mutable struct Process
    self::Int
    left::Union{Int, Nothing}
    right::Union{Int, Nothing}
    neighbors::Array{Int}
    storage::Dict{Float64, Int}
    combines::Dict{Tuple{Command, Float64}, Array{Int}}
    levels::Dict{Int, Array{Int}}
end

function Process(rank::Int, size::Int)
    nodes, ids = props(size)
    idsh, permh, permh⁻¹ = hash_props(nodes)
    context = (nodes, ids, permh, permh⁻¹, idsh, permh, permh⁻¹)
    left = predᵢ(nothing, 0, rank, context...)
    right = succᵢ(nothing, 0, rank, context...)

    N, levels = neighbors(rank, size)

    storage = Dict()

    combines = Dict()

    return Process(rank, left, right, N, storage, combines, levels)
end


function EmptyProcess(rank::Int)
    N = []
    left = nothing
    right = nothing

    storage = Dict()

    combines = Dict()

    levels = Dict()

    return Process(rank, left, right, N, storage, combines, levels)
end