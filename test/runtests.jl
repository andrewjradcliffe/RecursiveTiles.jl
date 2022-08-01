using RecursiveTiles
using Test

second(x) = x[begin+1]
third(x) = x[begin+2]

const tests = [
    "schemes.jl",
    "tile.jl",
    "findrange.jl",
]

for t ∈ tests
    @testset "Test $t" begin
        include(t)
    end
end
