include("skip_plus.jl")
include("hash_table.jl")

for i in 1:1000
    if h(14) < g(i) < h(28)
        println(i, " ", g(i))
    end
end