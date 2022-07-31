#
# Date created: 2022-07-31
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

macro scheme(f, g, hs...)
    ex = :(Scheme($f, $g))
    for h ∈ hs
        ex = :(ExtendScheme($ex, $h))
    end
    ex
end
macro scheme(f)
    ex = :(Scheme($f, nothing))
end

# s = @scheme sum last third second first
# s2 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), third), second), first)

# s3 = @scheme sum last x -> x[begin+2] + 1000 second first
# s4 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), x -> x[begin+2] + 1000), second), first)
