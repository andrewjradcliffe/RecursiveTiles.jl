# Tests of Tile construction

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
@test y4[1] == y3[1:2]
@test y4[2] == y3[3:5]
