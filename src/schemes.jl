#
# Date created: 2022-07-31
# Author: aradclif
#
#
############################################################################################
"""
    AbstractScheme{F, G}

Supertype for base functor which constructs a value and index.
"""
abstract type AbstractScheme{F,G} end
(x::AbstractScheme{F,G})(A) where {F,G} = ((; f, g) = x; (f(A), g(A)))
(x::AbstractScheme{F,G})(A) where {F,G<:Nothing} = ((; f, g) = x; f(A))

"""
    Scheme(f, [g=nothing])

Functor comprised of `f`, the transformation applied to construct each element of a tile,
and `g`, the transformation applied to construct the index of tile. It may be
called directly, as shown below, but is most commonly passed to `tile` or `tiles`
(perhaps after being wrapped in one or more `ExtendScheme`s).

See also: [`ExtendScheme`](@ref)

# Examples
```jldoctest
julia> s = Scheme(sum, last);

julia> s([1, 2, 3])
(6, 3)

julia> Scheme(sum)([1, 2, 3])
6
```
"""
struct Scheme{F,G} <: AbstractScheme{F,G}
    f::F
    g::G
end
Scheme(f) = Scheme(f, nothing)

"""
    AbstractExtendScheme{S, H}

Supertype for extending base functor (`AbstractScheme`).
"""
abstract type AbstractExtendScheme{S,H} end
(x::AbstractExtendScheme{S,H})(A) where {S,H} = ((; s, h) = x; (s(A), h(A)))
(x::AbstractExtendScheme{S,H})(A) where {S,H<:Nothing} = ((; s, h) = x; s(A))

"""
    ExtendScheme(s, [h=nothing])

Functor for extending a scheme, `s`, through the addition on a transformation, `h`,
which constructs the index respective to each element on which it is called.
It may be called directly, as shown below, but is most commonly passed to `tile` or `tiles`.

# Examples
```jldoctest
julia> s = Scheme(sum, last);

julia> e = ExtendScheme(s, abs2 ∘ last);

julia> e([1, 2, 3])
((6, 3), 9)

julia> ExtendScheme(s)([1, 2, 3]) == s([1, 2, 3])
true

julia> e2 = ExtendScheme(e, first);

julia> e2([1, 2, 3])
(((6, 3), 9), 1)

julia> ExtendScheme(e)([1, 2, 3]) == e([1, 2, 3])
true
```
"""
struct ExtendScheme{S,H} <: AbstractExtendScheme{S,H}
    s::S
    h::H
end
ExtendScheme(s) = ExtendScheme(s, nothing)

"""
    @scheme f g h1 h2 ...

A macro to construct a nested `ExtendScheme` of the form
`ExtendScheme(ExtendScheme(Scheme(f, g), h1), h2)` by forming a base (`Scheme(f, g)`), then
wrapping with `ExtendScheme(s, h)` until all trailing `h`'s have been exhausted.

# Examples
```jldoctest
julia> (@scheme sum last first) == ExtendScheme(Scheme(sum, last), first)
true

julia> (@scheme sum last first last first) == ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), first), last), first)
true
```
"""
macro scheme(f, g, hs...)
    ex = :(Scheme($f, $g))
    for h ∈ hs
        ex = :(ExtendScheme($ex, $h))
    end
    esc(ex)
end
macro scheme(f)
    esc(:(Scheme($f, nothing)))
end
