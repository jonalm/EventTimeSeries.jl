"""
    neighbors(iterator)

returns an iterator over neighboring pairs

```julia
julia> neighbors([1,2,3]) |> collect
2-element Array{Tuple{Int64,Int64},1}:
 (1, 2)
 (2, 3)
 ```
 """
function neighbors(iterator)
    first  = @view iterator[1:end-1]
    second = @view iterator[2:end]
    zip(first, second)
end
