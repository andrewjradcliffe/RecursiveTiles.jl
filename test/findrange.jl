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

@testset "findfirstrange" begin
    @test findfirstrange(isone, [2,3,4]) === nothing
    @test findfirstrange(isone, [1, 2,3,4]) == 1:1
    @test findfirstrange(isone, [2,1,3,4]) == 2:2
    @test findfirstrange(isone, [2,1,1,3,4]) == 2:3
    @test findfirstrange(isone, [2,1,1,3,1,4]) == 2:3
    @test findfirstrange(isone, [1,2,1,1,3,1,4]) == 1:1
    @test findfirstrange(isone, [1,1,2,1,1,3,1,4]) == 1:2
    @test findfirstrange(isone, [2,3,4,1]) == 4:4

    # Missing, etc.
    @test_throws TypeError findfirstrange(isone, [missing])
    @test_throws TypeError findfirstrange(isone, [1, missing])

end
@testset "findlastrange" begin
    @test findlastrange(isone, [2,3,4]) === nothing
    @test findlastrange(isone, [1, 2,3,4]) == 1:1
    @test findlastrange(isone, [2,1,3,4]) == 2:2
    @test findlastrange(isone, [2,1,1,3,4]) == 2:3
    @test findlastrange(isone, [2,1,1,3,1,4]) == 5:5
    @test findlastrange(isone, [1,2,1,1,3,1,4]) == 6:6
    @test findlastrange(isone, [1,1,2,1,1,3,1,4]) == 7:7
    @test findlastrange(isone, [2,3,4,1]) == 4:4

    # Missing, etc.
    @test_throws TypeError findlastrange(isone, [missing])
    @test_throws TypeError findfirstrange(isone, [missing, 1])

end
