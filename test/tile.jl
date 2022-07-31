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

@testset "::Nothing mixed at various places" begin
    s1 = @scheme sum nothing last
    s1_1 = @scheme sum nothing last nothing
    tile(x1, B) == tile(s1, B) == tile(s1_2, B)
    s2 = @scheme sum nothing last third
    s2_1 = @scheme sum nothing last nothing third
    s2_2 = @scheme sum nothing last nothing nothing third
    s2_3 = @scheme sum nothing last nothing nothing third nothing
    tile(x2, B) == tile(s2, B) == tile(s2_1, B) == tile(s2_2, B) == tile(s2_3, B)
    s3 = @scheme sum nothing last third second
    s3_1 = @scheme sum nothing last nothing third second
    s3_2 = @scheme sum nothing last nothing nothing third second
    s3_3 = @scheme sum nothing last nothing nothing third nothing second
    s3_4 = @scheme sum nothing last nothing nothing third nothing second
    s3_5 = @scheme sum nothing last nothing nothing third nothing second nothing
    tile(x3, B) == tile(s3, B) == tile(s3_1, B) == tile(s3_2, B) == tile(s3_3, B) == tile(s3_4, B) == tile(s3_5, B)
    s4 = @scheme sum nothing last third second first
    s4_1 = @scheme sum nothing last nothing third second first
    s4_2 = @scheme sum nothing last nothing nothing third second first
    s4_3 = @scheme sum nothing last nothing nothing third nothing second first
    s4_4 = @scheme sum nothing last nothing nothing third nothing second first
    s4_5 = @scheme sum nothing last nothing nothing third nothing second nothing first
    tile(x4, B) == tile(s4, B) == tile(s4_1, B) == tile(s4_2, B) == tile(s4_3, B) == tile(s4_4, B) == tile(s4_5, B)

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

################

