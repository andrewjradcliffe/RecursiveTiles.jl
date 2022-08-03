#
# Date created: 2022-07-28
# Author: aradclif
#
#
############################################################################################
# Allowing any type of AbstractVector -- helps to resolve type inference issues

"""
    AbstractTile{P,T,U,S,N} <: AbstractVector{T}

Supertype for tile abstraction, which is a struct containing an `P<:AbstractVector{T}`
and an index `U<:Tuple{Vararg{S,N}}`.
"""
abstract type AbstractTile{P,T,U,S,N} <: AbstractVector{T} end
Base.size(x::AbstractTile{P,T,U,S,N}) where {P,T,U,S,N} = size(x.t)
Base.IndexStyle(::Type{<:AbstractTile}) = IndexLinear()
Base.@propagate_inbounds Base.getindex(x::AbstractTile{P,T,U,S,N}, I::Vararg{Int,M}) where {P,T,U,S,N,M} = getindex(x.t, I...)
Base.@propagate_inbounds Base.setindex!(x::AbstractTile{P,T,U,S,N}, v, I::Vararg{Int,M}) where {P,T,U,S,N,M} = x.t[I...] = v
Base.parent(x::AbstractTile{P,T,U,S,N}) where {P,T,U,S,N} = x.t
# If comparing two tiles, then one should consider both fields
Base.:(==)(x::AbstractTile, y::AbstractTile) = x.t == y.t && x.I == y.I
Base.hash(x::AbstractTile, h::UInt) = hash(x.t, hash(x.I, h))
Base.isequal(x::AbstractTile, y::AbstractTile) = isequal(x.t, y.t) && isequal(x.I, y.I)
# Ordering is a bit questionable.
Base.:(<)(x::AbstractTile, y::AbstractTile) = (xt = x.t; yt = y.t;
                                               # (xt < yt || xt == yt) && x.I < y.I
                                               xt < yt || (xt == yt && x.I < y.I)
                                               )
Base.isless(x::AbstractTile, y::AbstractTile) = (xt = x.t; yt = y.t;
                                                 # (isless(xt, yt) || isequal(xt, yt)) && isless(x.I, y.I)
                                                 isless(xt, yt) || (isequal(xt, yt) && isless(x.I, y.I))
                                                 )
# Other things which must also make sense -- or just leave these as AbstractArray?
# Base.copy(x::AbstractTile) = Tile(copy(x.t), x.I)
# Method forwarding to parent
Base.deleteat!(x::AbstractTile{P,T,U,S,N}, I) where {P,T,U,S,N} = deleteat!(parent(x), I)
Base.insert!(x::AbstractTile{P,T,U,S,N}, I, item) where {P,T,U,S,N} = insert!(parent(x), I, item)
Base.pop!(x::AbstractTile{P,T,U,S,N}) where {P,T,U,S,N} = pop!(parent(x))
Base.popat!(x::AbstractTile{P,T,U,S,N}, I) where {P,T,U,S,N} = popat!(parent(x), I)
Base.popat!(x::AbstractTile{P,T,U,S,N}, I, default) where {P,T,U,S,N} = popat!(parent(x), I, default)
Base.resize!(x::AbstractTile{P,T,U,S,N}, n) where {P,T,U,S,N} = resize!(parent(x), n)
Base.sizehint!(x::AbstractTile{P,T,U,S,N}, n) where {P,T,U,S,N} = sizehint!(parent(x), n)
Base.pushfirst!(x::AbstractTile{P,T,U,S,N}, item) where {P,T,U,S,N} = pushfirst!(parent(x), item)
Base.prepend!(x::AbstractTile{P,T,U,S,N}, item) where {P,T,U,S,N} = prepend!(parent(x), item)
Base.splice!(x::AbstractTile{P,T,U,S,N}, I) where {P,T,U,S,N} = splice!(parent(x), I)
Base.splice!(x::AbstractTile{P,T,U,S,N}, I, ins) where {P,T,U,S,N} = splice!(parent(x), I, ins)

####
"""
    Tile{P,T,U,S,N} <: AbstractTile{P,T,U,S,N}

Concrete tile abstraction, which specifies an index `U<:Tuple{Vararg{S,N}} where {S,N}`.

See also: [`AbstractTile`](@ref)
"""
struct Tile{P<:AbstractVector{T} where {T}, T, U<:Tuple{Vararg{S,N}} where {S,N}, S,N} <: AbstractTile{P,T,U,S,N}
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
tiles(x::AbstractExtendScheme{S,H}, A, rs) where {S,H} = #map(r -> tile(x, view(A, r)), rs)
    map(Base.Fix1(tile, x), (view(A, r) for r ∈ rs))
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


"""
    tile(s::AbstractScheme, A)
    tile(s::AbstractExtendScheme, A)

Construct a `Tile` by applying the scheme, `s`, to the entirety of `A`.

The distinction between `AbstractScheme` and `AbstractExtendScheme` exists for
signaling purposes. An `AbstractScheme` is always the base case, and signals
application to the entirety of `A`, whereas an `ExtendScheme` signals that `A`
should first be partitioned according to the inner index defined by the entity-being wrapped
(`e.s.g` if `ExtendScheme(Scheme)`, or `e.s.h` if `ExtendScheme(ExtendScheme(...))`),
and the `Scheme`/`ExtendScheme` applied to each partition. Each partition consists of a
contiguous range, across which `g` (or `h`) has the same value; hence, this value serves as
the index of the partition.

See also: [`tiles`](@ref)

# Examples
```jldoctest
julia> A = [10 1 1
            20 1 1
            30 1 1
            10 2 1
            20 2 1
            30 2 2
            10 3 2
            20 3 2
            10 4 2
            20 4 2];

julia> B = eachrow(A);

julia> s = @scheme sum x -> x[begin+1] last;


julia> x = tile(s, B)
4-element Tile{Vector{Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}}, Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}:
 [12, 22, 32]
 [13, 23, 34]
 [15, 25]
 [16, 26]
```
"""
function tile end

"""
    tiles(s::AbstractScheme, A)
    tiles(s::AbstractExtendScheme, A)

Construct 1 or more `Tiles` by partitioning `A` according to the index
(`s.g` if `AbstractScheme`, `s.h` if `AbstractExtendScheme`), then calling
`tile(s, B)` on each partition `B`. Returns a vector of tiles, each of which
bears the index that defined the partition.

See also: [`tile`](@ref)

# Examples
```jldoctest
julia> A = reshape(-12:12, 5, 5); B = eachcol(A);

julia> s = @scheme sum signbit ∘ (x -> x[begin+2]);

julia> tiles(s, B)
2-element Vector{Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}}:
 [-50, -25]
 [0, 25, 50]
```
"""
function tiles end
