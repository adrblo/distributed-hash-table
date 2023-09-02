using SHA

function hash(x::Int)::Float16
    # todo implement
    return 0.20
end

function hsucc(values::Array, x::Int)::Float16
    """
    Return next hash in Array
    """
    svalues = sort(values)
    index = findfirst(==(x), svalues)

    if (index == size(values, 1))
        return 1
    else
        return index + 1
    end
end

function hsucc(values::Array, x::Int)::Float16
    """
    Return previous hash in Array
    """
    svalues = sort(values)
    index = findfirst(==(x), svalues)

    if (index == 1)
        return size(values, 1)
    else
        return index - 1
    end
end
