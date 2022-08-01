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

As it can be tedious to write out each `ExtendScheme` wrap, the
`@scheme` macro is provided to facilitate this, such that `@scheme f g
h1 h2 h3` is equivalent to
`ExtendScheme(ExtendScheme(ExtendScheme(Scheme(f, g), h1), h2), h3)`.
The reader will likely agree that specification via the macro is also
much easier to read.
