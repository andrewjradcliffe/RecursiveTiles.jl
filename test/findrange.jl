# Tests of findrange, findranges

@testset "findrange" begin
    @test findrange(abs2, -1:1) == 1:1
    @test findrange(abs, -1:2:2) == 1:2
    @test findrange(signbit, -99:100) == 1:99
    @test findrange(signbit, -10:2:10) == 1:5

    @test findrange(abs2, [0, 0, 0, 1]) == 1:3
    @test findrange(abs2, [0, missing, 0, 1]) == 1:1
    @test findrange(abs2, [missing, 0, 0, 1]) == 1:1
    @test findrange(identity, [missing, missing, NaN, NaN, 0, 0, 1]) == 1:2
end

@testset "findranges" begin
    @test findranges(abs2, -1:1) == [1:1, 2:2, 3:3]
    @test findranges(abs, -1:2:3) == [1:2, 3:3]
    @test findranges(signbit, -99:100) == [1:99, 100:200]
    @test findranges(signbit, -10:2:10) == [1:5, 6:11]

    @test findranges(abs2, [0, 0, 0, 1]) == [1:3, 4:4]
    @test findranges(abs2, [0, missing, 0, 1]) == [1:1, 2:2, 3:3, 4:4]
    @test findranges(abs2, [missing, 0, 0, 1]) == [1:1, 2:3, 4:4]
    @test findranges(identity, [missing, missing, NaN, NaN, 0, 0, 1]) == [1:2, 3:4, 5:6, 7:7]
end
