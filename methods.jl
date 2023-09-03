function h(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function g(x::Int)::Float64
    return hash(x)/typemax(UInt64)
end

function hsucc(hvalues::Array, x::Int)::Float64
    """
    Return next hash in Array
    """
    svalues = sort(hvalues)
    index = findfirst(==(x), svalues)

    if (index == size(hvalues, 1))
        return 1
    else
        return index + 1
    end
end

function hpred(hvalues::Array, x::Int)::Float64
    """
    Return previous hash in Array
    """
    svalues = sort(hvalues)
    index = findfirst(==(x), svalues)

    if (index == 1)
        return size(hvalues, 1)
    else
        return index - 1
    end
end
