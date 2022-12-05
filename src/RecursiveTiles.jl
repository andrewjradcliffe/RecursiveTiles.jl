module RecursiveTiles

export findrange, findranges, findfirstrange, findlastrange
export AbstractTile, Tile, tile, tiles
export AbstractScheme, AbstractExtendScheme, Scheme, ExtendScheme, @scheme

include("schemes.jl")
include("findrange.jl")
include("tile.jl")

end
