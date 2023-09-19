mutable struct Process
    self::Int
    left::Union{Int, Nothing}
    right::Union{Int, Nothing}
    circ::Union{Int, Nothing}
    neighbors::Array{Int}
    storage::Dict{Float64, Int}
    combines::Dict{Tuple{Command, Float64}, Array{Int}}
    levels::Dict{Int, Array{Int}}
end

function Process(rank::Int, nodes::Array{Int})
    ids = props(nodes)
    idsh, permh, permh⁻¹ = hash_props(nodes)
    context = (nodes, ids, permh, permh⁻¹, idsh, permh, permh⁻¹)
    left = predᵢ(nothing, 0, rank, context...)
    right = succᵢ(nothing, 0, rank, context...)

    N, levels, circ = neighbors(rank, nodes)

    storage = Dict()

    combines = Dict()

    return Process(rank, left, right, circ, N, storage, combines, levels)
end


function EmptyProcess(rank::Int)
    N = []
    left = nothing
    right = nothing
    circ = nothing

    storage = Dict()

    combines = Dict()

    levels = Dict()

    return Process(rank, left, right, circ, N, storage, combines, levels)
end

struct Event
    start::Int
    ranks::Vector{Int}
    func::Function
end


