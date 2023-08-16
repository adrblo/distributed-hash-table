using Base

function neighborhood(x::Integer, size::Integer)
    bin_length = length(digits(size, base = 2))
    x_bin = last(bitstring(x), bin_length)
    nbh_array = Int64[x-1, x+1]

    #Loop over Levels in Skip+ 
    for i in range(1, round(log(2, size))-1)
        direct_nbs = Int64[]
        min_el = -1
        max_el = -1

        #pred_0 und pred_1
        pred_0 = pred(x, bin_length, "0", floor(Int, i))
        pred_1 = pred(x, bin_length, "1", floor(Int, i))
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
        succ_0 = succ(x, bin_length, "0", floor(Int,i), size)
        succ_1 = succ(x, bin_length, "1", floor(Int,i), size)
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
function pred(x::Integer, length::Integer, extension::String, level::Integer)
    x_bin = last(bitstring(x), length)
    x_ext = SubString(x_bin, 1, floor(Int,level))*extension     
    for j=x-1:-1:0
        j_bin = last(bitstring(j), length)
        comp = SubString(j_bin, 1, floor(Int,level+1))
        if(comp == x_ext)
            return j
        end
    end
end

#Calculates succ_i(x,b) for Node x in Level i with extension b for b=0 or b=1
function succ(x::Integer, length::Integer, extension::String, level::Integer, size::Integer)
    x_bin = last(bitstring(x), length)
    x_ext = SubString(x_bin, 1, floor(Int,level))*extension     
    for j in range(x+1, size)
        j_bin = last(bitstring(j), length)
        comp = SubString(j_bin, 1, floor(Int,level+1))
        if(comp == x_ext)
            return j
        end
    end
end