using Base

# Idee:
# ranks: Zahlenfolge 0..size <- x
# Ranks mit Liste verbunden
# id(x) = hash(x * mult)

const mult = 10

function id(x::Int)::UInt64
    return hash((x + 1) * mult)
end

function neighborhood(x::Integer, size::Integer)
    bin_length = Int(log2(typemax(UInt64)))
    x_bin = last(bitstring(id(x)), bin_length)
    nbh_array = Int64[x-1, x+1]

    ranks = range(0, size)
    order = [id(x) for x in ranks]

    #Loop over Levels in Skip+ 
    for i in range(1, round(log(2, size))-1)
        direct_nbs = Int64[]
        min_el = -1
        max_el = -1

        #pred_0 und pred_1
        pred_0 = pred(id(x), bin_length, "0", floor(Int, i), order)
        pred_1 = pred(id(x), bin_length, "1", floor(Int, i), order)
        if(pred_0 !== nothing)
            if(!(pred_0 in nbh_array))
                push!(nbh_array, pred_0)
            end
            push!(direct_nbs, pred_0)
        else
            push!(direct_nbs, -1)
        end
        if(pred_1 !== nothing)
            if(!(pred_1 in nbh_array))
                push!(nbh_array, pred_1)
            end
            push!(direct_nbs, pred_1)
        else
            push!(direct_nbs, -1)
        end

        #succ_0 und succ_1
        succ_0 = succ(id(x), bin_length, "0", floor(Int,i), size, order)
        succ_1 = succ(id(x), bin_length, "1", floor(Int,i), size, order)
        if(succ_0 !== nothing)
            if(!(succ_0 in nbh_array))
                push!(nbh_array, succ_0)
            end
            push!(direct_nbs, succ_0)
        else
            push!(direct_nbs, size+1)
        end
        if(succ_1 !== nothing)
            if(!(succ_1 in nbh_array))
                push!(nbh_array, succ_1)
            end
            push!(direct_nbs, succ_1)
        else
            push!(direct_nbs, size+1)
        end

        #range of Node x
        min_el = minimum(direct_nbs)
        max_el = maximum(direct_nbs)

        #loop over elements in range
        for j in range(min_el+1, max_el-1)
            if j != x
                j_bin = last(bitstring(j), bin_length)
                comp = SubString(j_bin, 1, floor(Int,i))
                if(comp == SubString(x_bin, 1, floor(Int,i)))
                    if(!(j in nbh_array))
                        push!(nbh_array, j)
                    end
                end
            end
        end
    end
    return nbh_array
end

#Calculates pred_i(x,b) for Node x in Level i with extension b for b=0 or b=1
function pred(x, length::Integer, extension::String, level::Integer, order)
    sorder = sort(order)
    x_bin = last(bitstring(x), length)
    x_ext = SubString(x_bin, 1, floor(Int,level))*extension
    x_key = findfirst(e -> e == x,  sorder)
    for j=x_key-1:-1:1
        j_bin = last(bitstring(id(j)), length)
        comp = SubString(j_bin, 1, floor(Int,level+1))
        if(comp == x_ext)
            return findfirst(e -> e == sorder[j],  order)
        end
    end
end

#Calculates succ_i(x,b) for Node x in Level i with extension b for b=0 or b=1
function succ(x, length::Integer, extension::String, level::Integer, size::Integer, order)
    sorder = sort(order)
    x_bin = last(bitstring(x), length)
    x_ext = SubString(x_bin, 1, floor(Int,level))*extension
    x_key = findfirst(e -> e == x,  sorder)
    for j in range(x_key+1, size)
        j_bin = last(bitstring(j), length)
        comp = SubString(j_bin, 1, floor(Int,level+1))
        if(comp == x_ext)
            return findfirst(e -> e == sorder[j],  order)
        end
    end
end
