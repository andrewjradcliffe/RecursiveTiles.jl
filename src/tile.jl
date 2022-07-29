#
# Date created: 2022-07-28
# Author: aradclif
#
#
############################################################################################

abstract type AbstractScheme{F,G} end
(x::AbstractScheme{F,G})(A) where {F,G} = ((; f, g) = x; (f(A), g(A)))
(x::AbstractScheme{F,G})(A) where {F,G<:Nothing} = ((; f, g) = x; f(A))

struct Scheme{F,G} <: AbstractScheme{F,G}
    f::F
    g::G
end
Scheme(f) = Scheme(f, nothing)

abstract type AbstractExtendScheme{S,H} end
(x::AbstractExtendScheme{S,H})(A) where {S,H} = ((; s, h) = x; (s(A), h(A)))
(x::AbstractExtendScheme{S,H})(A) where {S,H<:Nothing} = ((; s, h) = x; s(A))

struct ExtendScheme{S,H} <: AbstractExtendScheme{S,H}
    s::S
    h::H
end
ExtendScheme(s) = ExtendScheme(s, nothing)

####
# Allowing any type of AbstractVector -- helps to resolve type inference issues
abstract type AbstractTile{P,T,U,S,N} <: AbstractVector{T} end
Base.size(x::AbstractTile{P,T,U,S,N}) where {P,T,U,S,N} = size(x.t)
Base.IndexStyle(::Type{<:AbstractTile}) = IndexLinear()
Base.getindex(x::AbstractTile{P,T,U,S,N}, I::Vararg{Int,M}) where {P,T,U,S,N,M} = getindex(x.t, I...)
Base.setindex!(x::AbstractTile{P,T,U,S,N}, v, I::Vararg{Int,M}) where {P,T,U,S,N,M} = x.t[I...] = v
Base.parent(x::AbstractTile{P,T,U,S,N}) where {P,T,U,S,N} = x.t

struct Tile{P<:AbstractVector{T} where{T}, T, U<:Tuple{Vararg{S,N}} where {S,N}, S,N} <: AbstractTile{P,T,U,S,N}
    t::P
    I::U
end
Tile(t::P, I::U) where {P<:AbstractVector{T}} where {T} where {U<:Tuple{Vararg{S,N}}} where {S,N} = Tile{P,T,U,S,N}(t, I)
Tile(t::P, I::Vararg{S,N}) where {P<:AbstractVector{T}} where {T} where {S,N} = Tile(t, I)
Tile(t::P, ::Tuple{}) where {P<:AbstractVector{T}} where {T} = Tile{P, T, Tuple{}, Tuple{}, 0}(t, ())

####
tile(x::AbstractScheme{F,G}, A) where {F,G} = ((; f, g) = x; tile(f, g, A))

tiles(x::AbstractScheme{F,G}, A) where {F,G} = ((; f, g) = x; tiles(x, A, findranges(g, A)))
tiles(x::AbstractScheme{F,G}, A, rs) where {F,G} = map(r -> tile(x, view(A, r)), rs)
    # map(Base.Fix1(tile, x), (view(A, r) for r ∈ rs))
# As `g` promises to define ≥ 1 ranges, if g::Nothing, then there can only be one tile.
tiles(x::AbstractScheme{F,G}, A) where {F,G<:Nothing} = tile(x, A)

tile(x::AbstractExtendScheme{S,H}, A) where {S,H} = ((; s, h) = x; Tile(tiles(s, A), h(first(A))))
# As `h` promises to define ≥ 1 ranges, if h::Nothing, just unwrap.
tile(x::AbstractExtendScheme{S,H}, A) where {S,H<:Nothing} = ((; s, h) = x; tile(s, A))

tiles(x::AbstractExtendScheme{S,H}, A) where {S,H} = ((; s, h) = x; tiles(x, A, findranges(h, A)))
tiles(x::AbstractExtendScheme{S,H}, A, rs) where {S,H} = map(Base.Fix1(tile, x), (view(A, r) for r ∈ rs))
# Likewise: `h` promises to define ≥ 1 ranges, thus,just unwrap.
tiles(x::AbstractExtendScheme{S,H}, A) where {S,H<:Nothing} = ((; s, h) = x; tiles(s, A))

# Special handling.
# Consider the case of:
# x₁ = Scheme(f, nothing)
# x₂ = ExtendScheme(x₁, h) # where `h` is not nothing
# This should create an index tile since `h` defines an outer index for the tile
# defined by `x₁`. The standard case calls `tiles`, which, due to g::Nothing would return a Tile,
# hence the returned type would be IndexTile{Tile,U,S,N}, which is not what one might expect.
# Special behavior in this limited case allows for more natural handling, making
# the above equivalent to x = Scheme(f, h).
# Everywhere else, the general rule applies: extending a Scheme implies ≥ 1 ranges,
# hence, purposefully redundant indices are forbidden.
# This also means that it is not possible to use `tile`/`tiles` to construct a Vector{Tile},
# as the lack of an index always means that there is a single tile.
# Harmony is achieved by the special behavior, which would otherwise have allowed for
# either IndexTile{Tile} or IndexTile{Vector{Tile}}. This makes behavior easy to reason about.
# In fact, the dispatch eliminates what would otherwise be odd behavior.
tile(x::AbstractExtendScheme{S,H}, A) where {H} where {S<:AbstractScheme{F,G}} where {F,G<:Nothing} = ((; s, h) = x; Tile(tile(s.f, A), h(first(A))))

####
function tile(f::F, A) where {F}
    T = typeof(f(first(A))) #_typeoffirst(f, A)#
    x = similar(A, T)
    for i ∈ eachindex(A)
        x[i] = f(A[i])
    end
    x
end
tile(f, ::Nothing, A) = Tile(tile(f, A), ())
tile(f, g, A) = Tile(tile(f, A), g(first(A)))

# _typeoffirst(f::F, A::AbstractArray{T, N}) where {F,T,N} = Base.promote_op(f, T) #typeof(f(first(A)))

################
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
