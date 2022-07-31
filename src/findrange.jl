#
# Date created: 2022-07-31
# Author: aradclif
#
#
############################################################################################
"""
    findrange(f, A::AbstractArray)

Find the range for which `f(i₀) == f(i₀+δ)` for δ = 0,…,lastindex(A)-1;
the search starts from `i₀=firstindex(A)`.

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
        x == x₀ || return i₀:i-1
    end
    return i₀:lastindex(A)
end

"""
    findranges(f, A::AbstractArray)

# Examples
```jldoctest
julia> findranges(signbit, -5:5)
2-element Vector{UnitRange{Int64}}:
 1:5
 6:11
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