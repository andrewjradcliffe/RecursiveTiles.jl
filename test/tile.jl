# Tests of Tile construction

####
# Canonical example
i400_10_1_1 = [1,1,1]
i400_10_1_2 = [2,2,2]
i400_10_1_3 = [3,3,3,3,3]
i400_10_2_1 = [1,1,1]
i400_10_2_2 = [2,2,2,2]
i400_20_1_1 = [1,1,1,1,1]
i400_20_2_1 = [1,1,1]
i400_20_2_2 = [2]
i400_20_2_3 = [3]
i400_20_2_4 = [4,4]
i400_20_3_1 = [1]
i400_20_3_2 = [2,2]
i400_20_3_3 = [3]

i400_10_1 = [1,1,1,1,1,1,1,1,1,1,1]
i400_10_2 = [2,2,2,2,2,2,2]
i400_20_1 = [1,1,1,1,1]
i400_20_2 = [2,2,2,2,2,2,2]
i400_20_3 = [3,3,3,3]

i400_10 = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
i400_20 = [20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20]

i400 = fill(400, 34)

col2 = [i400_10; i400_20]
col3 = [i400_10_1; i400_10_2; i400_20_1; i400_20_2; i400_20_3]
col4 = [i400_10_1_1; i400_10_1_2; i400_10_1_3; i400_10_2_1; i400_10_2_2; i400_20_1_1; i400_20_2_1; i400_20_2_2; i400_20_2_3; i400_20_2_4; i400_20_3_1; i400_20_3_2; i400_20_3_3]
A = [i400 col2 col3 col4]

x1 = Scheme(sum, last)
x2 = ExtendScheme(x1, third)
x3 = ExtendScheme(x2, second)
x4 = ExtendScheme(x3, first)
x5 = ExtendScheme(x4, last)
x6 = ExtendScheme(x3, nothing)
x7 = ExtendScheme(ExtendScheme(ExtendScheme(x6, nothing), nothing), nothing)

B = eachrow(A);

y4 = tile(x4, B)
y3 = tile(x3, B)
y2 = tile(x2, B)
y1 = tile(x1, B)
y5 = tile(x5, B)
z5 = tile(ExtendScheme(x4, string ∘ first), B)

####

@testset "Basic properties" begin
    @test all(y1 .== sum(A, dims=2))
    @test length(y1) == size(A, 1)

    @test parent(y2) == tiles(x1, B)
    @test length(y2) == 12
    @test y2.I == (1,)
    @test all(getproperty.(y2, :I) .== [(1,), (2,), (3,), (1,), (2,), (1,), (2,), (3,), (4,), (1,), (2,), (3,)])
    @test all(map(length, y2) .== [3, 3, 5, 3, 4, 8, 1, 1, 2, 1, 2, 1])
    @test all(vcat(y2...) .== sum(A, dims=2))

    @test parent(y3) == tiles(x2, B)
    @test length(y3) == 5
    @test y3.I == (10,)
    @test all(getproperty.(y3, :I) .== [(1,), (2,), (1,), (2,), (3,)])
    @test all(map(length, y3) .== [3, 2, 1, 4, 3])
    @test all(map(x -> sum(length, x), y3) .== [11, 7, 5, 7, 4])
    i2s = map(x -> getproperty.(x, :I), y3)
    @test all(i2s[1] .== [(1,),(2,),(3,)])
    @test all(i2s[2] .== [(1,),(2,)])
    @test all(i2s[3] .== [(1,)])
    @test all(i2s[4] .== [(1,),(2,),(3,),(4,)])
    @test all(i2s[5] .== [(1,),(2,),(3,)])
    @test y3[1] == y2[1:3]
    @test y3[2] == y2[4:5]
    @test y3[3] != y2[6]
    @test length(y3[3][1]) == 5
    @test y3[4][2:4] == y2[7:9]
    @test length(y3[4][1]) == 3
    @test y3[5] == y2[10:12]

    @test parent(y4) == tiles(x3, B)
    @test length(y4) == 2
    @test y4.I == (400,)
    @test all(getproperty.(y4, :I) .== [(10,), (20,)])
    @test all(map(length, y4) .== [2, 3])
    @test all(map(x -> sum(length, x), y4) .== [5, 8])
    @test all(map(x -> sum(y -> sum(length, y), x), y4) .== (18, 16))
    i3s = map(x -> getproperty.(x, :I), y4)
    @test all(i3s[1] .== [(1,),(2,)])
    @test all(i3s[2] .== [(1,),(2,),(3,)])
    i2s_1 = map(x -> getproperty.(x, :I), y4[1])
    i2s_2 = map(x -> getproperty.(x, :I), y4[2])
    @test i2s_1 == i2s[1:2]
    @test i2s_2 == i2s[3:5]
    @test y4[1] == y3[1:2]
    @test y4[2] == y3[3:5]
end

@testset "::Nothing, mixed at various places" begin
    s1 = @scheme sum nothing last
    s1_1 = @scheme sum nothing last nothing
    @test tile(x1, B) == tile(s1, B) == tile(s1_1, B)
    s2 = @scheme sum nothing last third
    s2_1 = @scheme sum nothing last nothing third
    s2_2 = @scheme sum nothing last nothing nothing third
    s2_3 = @scheme sum nothing last nothing nothing third nothing
    @test tile(x2, B) == tile(s2, B) == tile(s2_1, B) == tile(s2_2, B) == tile(s2_3, B)
    s3 = @scheme sum nothing last third second
    s3_1 = @scheme sum nothing last nothing third second
    s3_2 = @scheme sum nothing last nothing nothing third second
    s3_3 = @scheme sum nothing last nothing nothing third nothing second
    s3_4 = @scheme sum nothing last nothing nothing third nothing second
    s3_5 = @scheme sum nothing last nothing nothing third nothing second nothing
    @test tile(x3, B) == tile(s3, B) == tile(s3_1, B) == tile(s3_2, B) == tile(s3_3, B) == tile(s3_4, B) == tile(s3_5, B)
    s4 = @scheme sum nothing last third second first
    s4_1 = @scheme sum nothing last nothing third second first
    s4_2 = @scheme sum nothing last nothing nothing third second first
    s4_3 = @scheme sum nothing last nothing nothing third nothing second first
    s4_4 = @scheme sum nothing last nothing nothing third nothing second first
    s4_5 = @scheme sum nothing last nothing nothing third nothing second nothing first
    @test tile(x4, B) == tile(s4, B) == tile(s4_1, B) == tile(s4_2, B) == tile(s4_3, B) == tile(s4_4, B) == tile(s4_5, B)
end

function myfunc(A)
    B = eachrow(A)
    x1 = Scheme(sum, last)
    x2 = ExtendScheme(x1, third)
    x3 = ExtendScheme(x2, second)
    x4 = ExtendScheme(x3, first)
    tile(x4, B)
end
function myfunc2(A)
    B = eachrow(A)
    x1 = Scheme(sum, last)
    x2 = ExtendScheme(x1, third)
    x3 = ExtendScheme(x2, second)
    x4 = ExtendScheme(x3, first)
    x5 = ExtendScheme(x4, last)
    tile(x5, B)
end
function myfunc3(A)
    B = eachrow(A)
    s = @scheme sum last third second first last
    tile(s, B)
end
function myfunc4(A)
    B = eachrow(A)
    s = @scheme sum last third second first last nothing
    tile(s, B)
end
# function myfunc5(A)
#     B = eachrow(A)
#     s = @scheme sum nothing last third second
#     tile(s, B)
# end


@testset "type (in)stability" begin
    # Inference should succeed for all the calls without an [AllowedType].
    # For those with an [AllowedType], if in the future inference successfully proceeds
    # to the correct type, then it is not problematic (in fact, is an improvement).
    @inferred Tile{_A, _B, Tuple{Int64}, Int64, 1} where {_A<:AbstractVector, _B} tile(x4, B)
    @inferred tile(x3, B)
    @inferred tile(x2, B)
    @inferred tile(x1, B)
    @inferred Tile{_A, _B, Tuple{Int64}, Int64, 1} where {_A<:AbstractVector, _B} tile(x5, B)
    @inferred tile(x6, B)
    #
    rs_b = findranges(second, B)
    @inferred Vector tiles(x3, B, rs_b)
    @inferred Vector tiles(x3, B)
    C = view(B, rs_b[1])
    @inferred tile(x3, C)
    rs_c = findranges(third, C)
    @inferred tiles(x2, C, rs_c)
    @inferred tiles(x2, C)
    D = view(C, rs_c[1])
    @inferred tile(x2, D)
    #
    @inferred myfunc(A)
    @inferred myfunc2(A)
    @inferred myfunc3(A)
    @inferred myfunc4(A)
    # @inferred myfunc5(A)
    #
end

@testset "comparison and uniqueness" begin
    A1 = [10 1 1
          20 1 1
          30 1 1
          10 2 1
          20 2 1
          30 2 2
          10 3 2
          20 3 2
          10 4 2
          20 4 2];
    B1 = eachrow(A1);
    s = @scheme sum second last
    x = tile(s, B1)
    @test x == [[12, 22, 32], [13, 23, 34], [15, 25], [16, 26]]
    @test x.I == (1,)
    xs = tiles(s, B1)
    x1, x2 = xs
    @test x1.I == (1,)
    @test x2.I == (2,)
    # purposefully constructing something which differs by an index
    A2 = copyto!(similar(A1), A1)
    A2[:, end] .= 2
    B2 = eachrow(A2)
    y = Tile(tiles(Scheme(sum, second), B1), (2,))
    #
    @test parent(x) == y
    @test !(parent(x) < y)
    @test x != y
    @test x < y
    @test parent(x) == parent(y)
    @test !isequal(x, y)
    @test allunique([x, y])
    @test first(setdiff([x, x, y], [x])) == y
    @test sort([y, x]) == [x, y]
    @test unique([x, y, y]) == [x, y]
end

# from README.md
@testset "from README, Example 1" begin
    A = [10 1 1
         20 1 1
         30 1 1
         10 2 1
         20 2 1
         30 2 2
         10 3 2
         20 3 2
         10 4 2
         20 4 2];
    B = eachrow(A);
    s = @scheme sum second last;
    x = tile(s, B)
    @test x.I == (1,)
    @test (x...,) == ([12, 22, 32], [13, 23, 34], [15, 25], [16, 26])
    @test getproperty.(x, :I) == [(1,), (2,), (3,), (4,)]
    xs = tiles(s, B)
    @test getproperty.(xs, :I) == [(1,), (2,)]
    @test map(x -> getproperty.(x, :I), xs) == [[(1,), (2,)], [(2,), (3,), (4,)]]
end

@testset "from README, Example 2" begin
    A = [1 7 1 'a'
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
    # Conversely, if the contiguous repetitions of the original array are identical,
    # then sorting would destroy said structure.
    A′ = sortslices(A, dims=1, by=x -> (x[1], x[2], x[3]))
    s = @scheme last third second first
    B′ = eachrow(A′)
    xs = tiles(s, B′)
    x1, x2 = xs
    @test length(xs) == 2
    @test sum.(x -> sum(length, x), xs) == [10, 5]
    @test map.(x -> sum(length, x), xs) == [[4, 6], [5]]
    @test map.(Broadcast.BroadcastFunction(length), xs) == [[[2, 2], [3, 2, 1]], [[2, 3]]]
    # first tile
    @test x1[1] == [['a', 'b'], ['a', 'a']]
    @test x1[2] == [['b', 'c', 'b'], ['a', 'c'], ['a']]
    @test length(x1) == 2
    @test x1.I == (1,)
    @test getproperty.(x1, :I) == [(7,), (8,)]
    x1_1, x1_2 = x1
    @test getproperty.(x1_1, :I) == [(1,),(2,)]
    @test getproperty.(x1_2, :I) == [(1,),(2,),(3,)]
    @test length.(x1_1) == [2, 2]
    @test length.(x1_2) == [3, 2, 1]
    # second tile
    @test x2[1] == [['c', 'a'], ['b', 'c', 'b']]
    @test x2.I == (2,)
    @test getproperty.(x2, :I) == [(7,)]
    x2_1 = x2[1]
    @test getproperty.(x2_1, :I) == [(1,),(2,)]
    @test length.(x2_1) == [2, 3]
end

@testset "from README, Example 3" begin
    r = -12:12
    A = reshape(r, 5, 5)
    B = eachcol(A)
    # s = @scheme x -> sum(abs, x) signbit ∘ third
    # xs = tiles(s, B)
    s = @scheme sum signbit ∘ third
    xs = tiles(s, B)
    x1, x2 = xs;
    @test (x1.I, x2.I) == ((true,), (false,))
    @test length.(xs) == [2, 3]
    @test x1 == [-50, -25]
    @test x2 == [0, 25, 50]
    oA = reshape(r, -2:2, -3:1)
    oB = eachcol(oA)
    @test xs == tiles(s, oB)
    #
    r = -13:13
    A = reshape(r, 3, 3,3)
    B = eachslice(A, dims=(2,3))
    s = @scheme sum signbit ∘ second
    xs = tiles(s, B)
    @test length.(xs) == [4, 5]
    x1, x2 = xs
    @test x1 == sum.(B[1:4])
    @test x2 == sum.(B[5:9])
    @test all(vcat(xs...) .== vec(sum(A, dims=1)))
    #
    s = @scheme sum x -> abs(sum(x)) > 9
    xs = tiles(s, B)
    @test length.(xs) == [3, 3, 3]
    @test getproperty.(xs, :I) == [(true,), (false,), (true,)]
    x1, x2, x3 = xs
    @test x1 == sum.(B[1:3])
    @test x2 == sum.(B[4:6])
    @test x3 == sum.(B[7:9])
    @test all(vcat(xs...) .== vec(sum(A, dims=1)))
end

################
@testset "other examples" begin
    rs1 = [1:3, 4:6, 7:8, 9:10];
    A1 = [1 1 10
          2 1 10
          3 1 10
          1 2 10
          2 2 10
          3 2 10
          1 3 10
          2 3 10
          1 4 10
          2 4 10];
    # A1 = sortslices(A1, dims=1, by=x -> (x[1], x[2], x[3]))
    B1 = eachrow(A1);

    rs2 = [1:6, 7:10];
    A2 = [1 1 10
          2 1 10
          3 1 10
          4 1 10
          5 1 10
          6 1 10
          1 2 10
          2 2 10
          3 2 10
          4 2 10];
    # A2 = sortslices(A2, dims=1, by=x -> (x[1], x[2], x[3]))
    B2 = eachrow(A2);

    z1 = Scheme(sum, first)
    z2 = ExtendScheme(z1, second)
    z3 = ExtendScheme(z2, last)
    z4 = ExtendScheme(z3, nothing)
    z5 = ExtendScheme(z4, nothing)

    @test rs1 == findranges(second, B1)
    @test rs2 == findranges(second, B2)

    # Basic functionality
    y = @inferred tile(z3, B1)
    @test all(y .== [[[12], [13], [14]], [[13], [14], [15]], [[14], [15]], [[15], [16]]])
    @test y.I == (10,)
    @test all(getproperty.(y, :I) .== [(1,),(2,),(3,),(4,)])
    @test length(y) == 4
    @test all(vcat(vcat(y...)...) .== sum(A1, dims=2))
    @test tile(z3, B1) == tile(z4, B1) == tile(z5, B1)

    y = @inferred tile(z3, B2)
    @test all(y .== [[[12], [13], [14], [15], [16], [17]], [[13], [14], [15], [16]]])
    @test y.I == (10,)
    @test all(getproperty.(y, :I) .== [(1,),(2,)])
    @test length(y) == 2
    @test all(vcat(vcat(y...)...) .== sum(A2, dims=2))
    @test tile(z3, B2) == tile(z4, B2) == tile(z5, B2)
end

@testset "interesting cases" begin
    s = @scheme identity signbit
    xs = tiles(s, -5:5)
    @test xs[1].I == (true,)
    @test xs[1] == collect(-5:-1)
    @test xs[2].I == (false,)
    @test xs[2] == collect(0:5)
end
