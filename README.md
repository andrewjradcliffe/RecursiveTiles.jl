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
in which the slices are arranged such that repetitions of an index
are contiguous. In such a scenario, the non-repeated information forms
a contiguous partition. We shall refer to this contiguous partition of
value(s) under a common index as a tile. In the abstract, this tile is
but one piece of the mosaic which is the host array.

As the contiguous repetition of an index across slices serves to
demarcate the extent of a tile, one might naturally consider
augmentation with an additional index which spans multiple tiles. We
may view the additional index as defining a contiguous partition, the
elements of which are themselves partitions defined by the original
index. In other words, a tile of tiles. Thus, we arrive at the
following abstraction: a tile is comprised of elements, and the
demarcation of said tile occurs by the contiguous repetition of an
index. Consequently, through augmentation with an index, we define a
partitioning of elements; through multiple augmentations, we
may recursively define partitions the elements of which are
partitions. Construction then proceeds from the outermost index, which
defines the outermost partition, which is then partitioned according
to the next successive index, and so on.

This package provides composable types which provide a succinct method
for construction of recursively tiled slices of arrays.

## Usage
The recursive partitioning (by quantities which serve as indices) can
be fruitfully expressed through a composition of types. The composite
may then be used to direct the construction of tiles of arbitrary depth.

To direct the construction of individual tiles, one uses a `Scheme`,
consisting of a transformation, `f`, which constructs the element of a
tile, and a transformation, `g`, which constructs the index of the
tile.  A single tile may be constructed as `tile(Scheme(f,g), A)`, or
multiple tiles, using `g` to partition, as `tiles(Scheme(f,g), A)`.
An index may be added by extending the `s = Scheme(f,g)` by wrapping
it as `ExtendScheme(s, h)` where `s` is the `Scheme` or `ExtendScheme`
to which an index is being added and `h` is the transformation which
constructs the index.  In the presence of multiple indices, as
indicated by the `ExtendScheme` type, one or more inner partitions
exist, hence, a `tile(ExtendScheme(s, h), A)` call will partition `A`
by the inner index, then call `tile(s, B)` on each partition `B`,
ultimately returning a tile with outer index given by `h` and a vector
of ≥ 1 tiles, each with their respective inner index.  This proceeds
recursively, such that an arbitrary number of indices may be added by
extending via `ExtendScheme` wraps.

It can be tedious to write out each `ExtendScheme` wrap, hence,
`@scheme` macro is provided to facilitate this, such that `@scheme f g
h1 h2 h3` is equivalent to
`ExtendScheme(ExtendScheme(ExtendScheme(Scheme(f, g), h1), h2), h3)`.
The reader will likely agree that specification via the macro is also
much easier to read.

Note that anything may serve as an index -- naturally one thinks in
terms of, an `Integer`, or `NTuple` thereof, but no type-based
limitations exist. One may choose to use, for example, `Tuple{String,
Int, Float64}`, `Vector{Any}`, or any other type, if the application
calls for it; the only requirement is that `isequal(a,b)` return a
sensible result.

## Type Interface
The `AbstractTile` type is a subtype of `AbstractVector`, hence,
the interface for types returned by this package is that of
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
desired state, and will be treated as an `AbstractArray`. Commonly,
this means using `eachrow`, `eachcol` or `eachslice`, such that one
actually passes `B = eachslice(A, dims=...)`.

The distinction between `Scheme` and `ExtendScheme` exists for
signaling purposes. In the call to `tile`, a `Scheme` is always the
base case, and signals that it should be applied to the entirety of
`A`, whereas an `ExtendScheme` signals that `A` should be partitioned
according to the outer index defined by `h`, and the (Extend)Scheme
applied to each partition. Each partition consists of a contiguous
range, across which `h` has the same value; hence, this value serves
as the index of the partition.
### `tile(s, A)`
- When `tile(s::AbstractScheme, A)` is called, it is assumed that an
  outermost index applies to the entirety of `A`, and that the `Scheme` is
  to be applied to the entirety of `A`.
- When `tile(s::AbstractExtendScheme, A)` is called, it is assumed
  that the outermost index applies to the entirety of `A`, and that
  the inner index -- the index of the `Scheme/ExtendScheme` being
  extended -- defines ≥ 1 ranges on `A`. These ranges are found, and
  the entity-being-wrapped is called on each contiguous range, thereby
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

## Examples
### Simple

<details>
 <summaryClick me!></summary>
<p>

As a simple example, consider a matrix in which the second and third columns contain
indices which may be used to partition the matrix. Under normal circumstances, one
might not use an `f` which is applied to the entire slice, but here we opt for `sum`
as this produces distinct values which aids the illustration.
```julia
julia> second(x) = x[begin+1];

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

# This partitions by `second` only (as the call is via `tile`), yielding
# 4 total tiles.

julia> x = tile(s, B)
4-element Tile{Vector{Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}}, Tile{Vector{Int64}, Int64, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}:
 [12, 22, 32]
 [13, 23, 34]
 [15, 25]
 [16, 26]

julia> x.I
(1,)

julia> (x...,)
([12, 22, 32], [13, 23, 34], [15, 25], [16, 26])

julia> getproperty.(x, :I)
4-element Vector{Tuple{Int64}}:
 (1,)
 (2,)
 (3,)
 (4,)

# This partitions by `last`, then partitions each resultant slice by `second`,
# yielding 2 tiles, the first of which consists of 2 tiles and and the second
# of which consists of 3 tiles.

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
</p>
</details>

### Sort before tiling

<details>
 <summaryClick me! ></summary>
<p>

As an example where it may be necessary to sort the array prior to
tiling, consider the following matrix.
```julia
julia> second(x) = x[begin+1]; third(x) = x[begin+2];

julia> A = [1 7 1 'a'
            1 7 2 'a'
            1 8 1 'b'
            1 8 1 'c'
            2 7 1 'c'
            2 7 1 'a'
            2 7 2 'b'
            2 7 2 'c'
            2 7 2 'b'
            1 8 1 'b'
            1 8 2 'a'
            1 8 2 'c'
            1 7 1 'b'
            1 7 2 'a'
            1 8 3 'a'
            ];

# Here, it is necessary to first sort the array in order to form contiguous repetitions.
# Conversely, if the contiguous repetitions of the original array are intentional,
# then sorting would destroy said structure.
julia> A′ = sortslices(A, dims=1, by=x -> (x[1], x[2], x[3]))
15×4 Matrix{Any}:
 1  7  1  'a'
 1  7  1  'b'
 1  7  2  'a'
 1  7  2  'a'
 1  8  1  'b'
 1  8  1  'c'
 1  8  1  'b'
 1  8  2  'a'
 1  8  2  'c'
 1  8  3  'a'
 2  7  1  'c'
 2  7  1  'a'
 2  7  2  'b'
 2  7  2  'c'
 2  7  2  'b'

julia> s = @scheme last third second first;

julia> B′ = eachrow(A′);

julia> xs = tiles(s, B′)
2-element Vector{Tile{Vector{Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}}, Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}}:
 [[['a', 'b'], ['a', 'a']], [['b', 'c', 'b'], ['a', 'c'], ['a']]]
 [[['c', 'a'], ['b', 'c', 'b']]]

julia> x1, x2 = xs;

julia> x1
2-element Tile{Vector{Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}}, Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}:
 [['a', 'b'], ['a', 'a']]
 [['b', 'c', 'b'], ['a', 'c'], ['a']]

julia> x2
1-element Tile{Vector{Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}}, Tile{Vector{Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}}, Tile{Vector{Char}, Char, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}, Tuple{Int64}, Int64, 1}:
 [['c', 'a'], ['b', 'c', 'b']]

# Let's look at the indices
julia> x1.I, x2.I
((1,), (2,))

julia> getproperty.(x1, :I)
2-element Vector{Tuple{Int64}}:
 (7,)
 (8,)

julia> getproperty.(x2, :I)
1-element Vector{Tuple{Int64}}:
 (7,)

julia> map(x -> getproperty.(x, :I), x1)
2-element Vector{Vector{Tuple{Int64}}}:
 [(1,), (2,)]
 [(1,), (2,), (3,)]

julia> map(x -> getproperty.(x, :I), x2)
1-element Vector{Vector{Tuple{Int64}}}:
 [(1,), (2,)]
```
</p>
</details>

### Various `AbstractArray`s; multidimensional
<details>
 <summaryClick me! ></summary>
<p>

The methods apply are agnostic to the particular subtype of `AbstractArray`, as demonstrated by
the somewhat contrived examples below.
```julia
julia> second(x) = x[begin+1]; third(x) = x[begin+2];

julia> r = -12:12;

julia> A = reshape(r, 5, 5)
5×5 reshape(::UnitRange{Int64}, 5, 5) with eltype Int64:
 -12  -7  -2  3   8
 -11  -6  -1  4   9
 -10  -5   0  5  10
  -9  -4   1  6  11
  -8  -3   2  7  12

julia> B = eachcol(A);

julia> s = @scheme sum signbit ∘ third;

julia> xs = tiles(s, B)
2-element Vector{Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}}:
 [-50, -25]
 [0, 25, 50]

julia> x1, x2 = xs;

julia> x1
2-element Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}:
 -50
 -25

julia> x2
3-element Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}:
  0
 25
 50

julia> x1.I, x2.I
((true,), (false,))

julia> using OffsetArrays

julia> oA = reshape(r, -2:2, -3:1)
5×5 OffsetArray(reshape(::UnitRange{Int64}, 5, 5), -2:2, -3:1) with eltype Int64 with indices -2:2×-3:1: -12  -7  -2  3   8
 -11  -6  -1  4   9
 -10  -5   0  5  10
  -9  -4   1  6  11
  -8  -3   2  7  12

julia> ob = eachcol(oA);

julia> xs == tiles(s, oB)
true

# More than one dimension; this keeps the partition function simple for clarity

julia> r = -13:13
-13:13

julia> A = reshape(r, 3, 3,3)
3×3×3 reshape(::UnitRange{Int64}, 3, 3, 3) with eltype Int64:
[:, :, 1] =
 -13  -10  -7
 -12   -9  -6
 -11   -8  -5

[:, :, 2] =
 -4  -1  2
 -3   0  3
 -2   1  4

[:, :, 3] =
 5   8  11
 6   9  12
 7  10  13

julia> B = eachslice(A, dims=(2,3))
3×3 Slices{Base.ReshapedArray{Int64, 3, UnitRange{Int64}, Tuple{}}, Tuple{Colon, Int64, Int64}, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}, SubArray{Int64, 1, Base.ReshapedArray{Int64, 3, UnitRange{Int64}, Tuple{}}, Tuple{Base.Slice{Base.OneTo{Int64}}, Int64, Int64}, true}, 2}:
 [-13, -12, -11]  [-4, -3, -2]  [5, 6, 7]
 [-10, -9, -8]    [-1, 0, 1]    [8, 9, 10]
 [-7, -6, -5]     [2, 3, 4]     [11, 12, 13]

julia> s = @scheme sum signbit ∘ second;

julia> xs = tiles(s, B)
2-element Vector{Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}}:
 [-36, -27, -18, -9]
 [0, 9, 18, 27, 36]

julia> x1, x2 = xs;

julia> x1 == sum.(B[1:4])
true

julia> x2 == sum.(B[5:9])
true

julia> vcat(xs...) == vec(sum(A, dims=1))
true

# And one last example, just for fun

julia> s = @scheme sum x -> abs(sum(x)) > 9;

julia> xs = tiles(s, B)
3-element Vector{Tile{Vector{Int64}, Int64, Tuple{Bool}, Bool, 1}}:
 [-36, -27, -18]
 [-9, 0, 9]
 [18, 27, 36]

julia> getproperty.(xs, :I)
3-element Vector{Tuple{Bool}}:
 (1,)
 (0,)
 (1,)

julia> x1, x2, x3 = xs;

julia> x1 == sum.(B[1:3])
true

julia> x2 == sum.(B[4:6])
true

julia> x3 == sum.(B[7:9])
true

julia> vcat(xs...) == vec(sum(A, dims=1))
true
```
</p>
</details>

## Limitations
As originally indicated in the Project.toml, this package requires at
least Julia 1.9, which provides an updated `eachslice` which returns a
type which conforms to the `AbstractArray` interface.  In Julia 1.8
and older, `eachslice` returns an iterator, which does not permit
efficient partitioning algorithms; expect the methods in this package
to `throw` accordingly.

Note that while it is **not** supported, it may be feasible in some
circumstances to use this package with Julia 1.8 and older by calling
`collect` on the iterator returned by `eachslice`. Lack of support
side, the author does not recommend such a practice due to the
substantial performance degradation it entails.
