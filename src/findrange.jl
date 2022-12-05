#
# Date created: 2022-07-31
# Author: aradclif
#
#
############################################################################################
"""
    findrange(f, A::AbstractArray)

Find the range for which `isequal(f(A[i₀]), f(A[i₀+δ]))` is true;
the search starts from `i₀=firstindex(A)` and proceeds through δ = 0,…,lastindex(A)-1.

# Examples
```jldoctest
julia> findrange(x -> x < 3 ? 1 : 0, 1:4)
1:2

julia> findrange(abs, -1:2:2)
1:2

julia> findrange(signbit, -5:5)
1:5
```
"""
function findrange(f::F, A::AbstractArray) where {F}
    i₀ = firstindex(A)
    x₀ = f(first(A))
    for i ∈ eachindex(A)
        x = f(A[i])
        # x == x₀ || return i₀:i-1
        isequal(x, x₀) || return i₀:i-1
    end
    return i₀:lastindex(A)
end

"""
    findranges(f, A::AbstractArray)

Find each range on `eachindex(A)` over which `isequal(f(A[i]), f(A[i+δ]))` is true,
with the first range starting at `i=firstindex(A)`; subsequent ranges start from
`i=i+δⱼ+1` where `δⱼ` is the difference between the stop and start of the previous range.

# Examples
```jldoctest
julia> findranges(signbit, -5:5)
2-element Vector{UnitRange{Int64}}:
 1:5
 6:11

julia> findranges(identity, [0, missing, missing, 1, 1])
3-element Vector{UnitRange{Int64}}:
 1:1
 2:3
 4:5
```
"""
function findranges(f::F, A::AbstractArray) where {F}
    i₀, N = firstindex(A), lastindex(A)
    B = Vector{UnitRange{Int}}()
    while i₀ ≤ N
        r₀ = findrange(f, view(A, i₀:N))
        (; start, stop) = r₀
        δ = stop - start
        r = i₀:i₀+δ
        push!(B, r)
        i₀ += δ + 1
    end
    B
end

# # TODO: Requires slightly more nuance for IndexCartesian()
# function findrange2(f::F, A::AbstractArray) where {F}
#     i₀ = firstindex(A)
#     x₀ = f(first(A))
#     for i ∈ eachindex(A)
#         x = f(A[i])
#         x == x₀ || return i₀:i-one(i₀)
#     end
#     return i₀:lastindex(A)
# end

# function findranges2(f::F, A::AbstractArray) where {F}
#     i₀, N = firstindex(A), lastindex(A)
#     B = Vector{typeof(i₀:N)}()
#     while i₀ ≤ N
#         r₀ = findrange2(f, view(A, i₀:N))
#         start = first(r₀)
#         stop = last(r₀)
#         δ = stop - start
#         r = i₀:i₀+δ
#         push!(B, r)
#         i₀ += δ + one(i₀)
#     end
#     B
# end

"""
    findfirstrange(predicate, A::AbstractArray)

Return the first consecutive index range for which the `predicate` returns `true`.
Return `nothing` if there is no such range.

# Examples
```jldoctest
julia> findfirstrange(isone, [2, 3, 1, 1, 1, 4, 1])
3:5

julia> findfirstrange(isone, [2, 3, 4, 1])
4:4

julia> findfirstrange(signbit, -5:5)
1:5
```
"""
function findfirstrange(f::F, A::AbstractArray) where {F}
    i₀ = firstindex(A)
    iₗ = lastindex(A)
    x₀ = f(A[i₀])
    if x₀
        for i ∈ i₀+1:iₗ
            x = f(A[i])
            x || return i₀:i-1
        end
        return i₀:iₗ
    else
        while !x₀ && i₀ < iₗ
            i₀ += 1
            x₀ = f(A[i₀])
        end
        x₀ || return nothing
        for i ∈ i₀+1:iₗ
            x = f(A[i])
            x || return i₀:i-1
        end
        return i₀:iₗ
    end
end

"""
    findlastrange(predicate, A::AbstractArray)

Return the last consecutive index range for which the `predicate` returns `true`.
Return `nothing` if there is no such range.

# Examples
```jldoctest
julia> findlastrange(isone, [2, 3, 1, 1, 1, 4, 1])
7:7

julia> findlastrange(isone, [2, 3, 4, 1])
4:4

julia> findlastrange(signbit, -5:5)
1:5
```
"""
function findlastrange(f::F, A::AbstractArray) where {F}
    i₀ = firstindex(A)
    iₗ = lastindex(A)
    xₗ = f(A[iₗ])
    if xₗ
        for i ∈ iₗ-1:-1:i₀
            x = f(A[i])
            x || return i+1:iₗ
        end
        return i₀:iₗ
    else
        while !xₗ && iₗ > i₀
            iₗ -= 1
            xₗ = f(A[iₗ])
        end
        xₗ || return nothing
        for i ∈ iₗ-1:-1:i₀
            x = f(A[i])
            x || return i+1:iₗ
        end
        return i₀:iₗ
    end
end

