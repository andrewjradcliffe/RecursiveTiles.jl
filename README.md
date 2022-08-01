# RecursiveTiles

## Installation

```julia
using Pkg
Pkg.add("RecursiveTiles")
```

## Description

One has data arranged in an array, each slice of which corresponds to
a single data point.  Across slices, some information is
repeated. This repeated information may be viewed as an index common
to the non-repeated information of each slice. Let us consider cases
in which the slices are arranged such that repetition(s) of an index
are contiguous. In such a scenario, the non-repeated information forms
a contiguous partition. We shall refer to this contiguous partition of
value(s) under a common index as a tile. In the abstract, this tile is
but one piece of the mosaic which is the host array.

As the contiguous repetition of an index across slices serves to
demarcate the extent of a tile, one might naturally consider what
happens if we were to repeat an additional index which spans multiple
tiles (as defined by the original index). We may view the additional
index as defining a contiguous partition, the elements of which are
themselves partitions defined by the original index. In other words, a
tile of tiles. Thus, we arrive at the following abstraction: a tile is
comprised of elements, and the demarcation of said tile occurs by the
contiguous repetition of an index. Consequently, through the addition
of an index, we define a partitioning of elements; through the
addition of multiple indices, we may recursively define partitions the
elements of which are partitions. Construction then proceeds from the
outermost index, which defines the outermost partition, which is then
partitioned according to the next successive index, and so on.

This package provides composable types which provide a succinct method
for construction of recursively tiled slices of arrays.

## Usage
To direct the construction of individual tiles, one uses a `Scheme`,
consisting of a transformation, `f`, which constructs the element of a
tile, and a transformation, `g`, which constructs the index of the
tile.  A single tile may be constructed as `tile(Scheme(f,g), A)`, or
multiple tiles, using `g` to partition, as `tiles(Scheme(f,g), A)`.
An additional index may be added by extending the `s = Scheme(f,g)` by
wrapping it as `ExtendScheme(s, h)` where `s` is the `Scheme` or
`ExtendScheme` to which an index is being added and `h` is the
transformation which constructs the index.  In the presence of
multiple indices, as indicated by the `ExtendScheme` type, one or more
inner partitions exist, hence, a `tile(ExtendScheme(s, h), A)` call
will partition `A` by the inner index, then call `tile(s, B)` on each
partition `B`, ultimately returning a tile with outer index given by
`h` and a vector of ≥ 1 tiles, each with their respective inner index.
This proceeds recursively, such that an arbitrary number of additional
indices may be added by extending via `ExtendScheme` wraps.

It can be tedious to write out each `ExtendScheme` wrap, hence,
`@scheme` macro is provided to facilitate this, such that `@scheme f g
h1 h2 h3` is equivalent to
`ExtendScheme(ExtendScheme(ExtendScheme(Scheme(f, g), h1), h2), h3)`.
The reader will likely agree that specification via the macro is also
much easier to read.

The `AbstractTile` type is a subtype of `AbstractVector`, hence,
by the interface for types returned by this package is that of
`AbstractArray`; a small number of specializations
(`hash`, `==`, `isequal`, `<`, `isless`) exist so as to enable
set operations, sorting, comparison, etc. to respect the presence of
the index held by each tile. Such specializations would not normally
be visible to the user, and, as applied here, serve only to encourage
the user to treat `Tile`s as `AbstractArray`s.

## Recommendations
- As a tile is defined by contiguous repetition of some value (which
  we call an index) produced by the transformation of each slice,
  it can often be easier to achieve a given tiling
  by first transforming the array in the appropriate way, sorting it
  along the appropriate dimensions by the appropriate tuple(s), then
  finally constructing the tiling scheme. This may make it easier to
  reason about how the index (or indices) should be presented;
  naturally, this does not apply to the value in the base case (the
  value returned by `f`).
- The recursive tiling defines partitions based on the transformation
  of each slice, not the literal values (though, we might specify a
  literal value, e.g. `first`). This means that non-contiguous
  occurrences of the same index belong to separate partitions. Note
  the contrast with a `groupby` operation, which would imply that all
  occurrences of the same index belong to the same partition.

## Conventions
In calls to both `tile` and `tiles`, `A` is assumed to be in the
desired state, which will be treated as an `AbstractArray`. Commonly,
this means using `eachrow`, `eachcol` or `eachslice`, such that one
actually passes `B = eachslice(A, dims=...)`.

The distinction between `Scheme` and `ExtendScheme` exists for
signaling purposes. In the call of `tile`, a `Scheme` is always the
base case, and signals that it should be applied to the entirety of
`A`, whereas an `ExtendScheme` signals that `A` should be partitioned
according to the outer index defined by `h`, and the (Extend)Scheme
applied to each partition. Each partition consists of a contiguous
slice, across which `h` has the same value; hence, this value serves
as the index of the partition.
### `tile(s, A)`
- When `tile(s::AbstractScheme, A)` is called, it is assumed that an
  outermost index applies to the entirety of `A`, and that the `Scheme` is
  to be applied to the entirety of `A`.
- When `tile(s::AbstractExtendScheme, A)` is called, it is assumed
  that the outermost index applies to the entirety of `A`, and that
  the inner index -- the index of the `Scheme/ExtendScheme` being
  extended -- defines ≥ 1 ranges on `A`. These ranges are found, and
  the entity-being-wrapped is called on each contiguous slice, thereby
  returning a tile of inner tiles bearing an outer index given by `h`.
- If `g::Nothing`, no index exists for the tile. If `h::Nothing`, this
  is simply a no-op and the entity-being-wrapped is unwrapped and
  passed to `tile`.
- If a `Scheme` without an index (i.e. `s = Scheme(f, nothing)`) is
  wrapped in an `ExtendScheme` with an outer index (i.e. `e =
  ExtendScheme(s, h)`), then this is equivalent to the outer index
  being on the `Scheme` itself, hence, this could be expressed as
  `Scheme(f, h)`.
### `tiles(s, A)`
- When `tiles(s::AbstractScheme, A)` is called, the index is
  assumed to define ≥ 1 ranges on A; these are found and the `Scheme`
  is then called on each contiguous slice, producing a vector of
  tiles, each of which bears the index which defined its contiguous
  slice.
- When `tiles(s::AbstractExtendScheme, A)` is called, the behavior is
  the same: the outer index (defined by `h`) is assumed to define ≥ 1
  ranges on A, which are then found and the `ExtendScheme` is then
  called on each contiguous slice.

## Example
```julia
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

julia> s = @scheme sum second last;

julia> x = tile(s, B)
4-element Tile{Vector{Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}}, Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}:
 [12, 22, 32]
 [13, 23, 34]
 [15, 25]
 [16, 26]

julia> x.I
(1,)

julia> getproperty.(x, :I)
4-element Vector{Tuple{Int64}}:
 (1,)
 (2,)
 (3,)
 (4,)

julia> xs = tiles(s, B)
2-element Vector{Tile{Vector{Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}}, Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}}:
 [[12, 22, 32], [13, 23]]
 [[34], [15, 25], [16, 26]]

julia> getproperty.(xs, :I)
2-element Vector{Tuple{Int64}}:
 (1,)
 (2,)

julia> map(x -> getproperty.(x, :I), xs)
2-element Vector{Vector{Tuple{Int64}}}:
 [(1,), (2,)]
 [(2,), (3,), (4,)]
```
