# Tests of Scheme/ExtendScheme

# macro properties
@testset "@scheme macro" begin
    s = @scheme sum last third second first
    s2 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), third), second), first)
    @test s === s2

    a1 = [400, 10, 1, 1]
    a2 = [400, 10, 1, 2]
    @test s(a1) == s2(a1)
    @test s(a2) == s2(a2)

    s3 = @scheme sum last x -> x[begin+2] + 1000 second first
    s4 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), x -> x[begin+2] + 1000), second), first)

    @test s3(a1) == s4(a1)
    @test s3(a2) == s4(a2)

    s5 = @scheme sum x -> x[end] + 2 x -> x[begin+2] + 1000 second first
    s6 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, x -> x[end] + 2), x -> x[begin+2] + 1000), second), first)

    @test s5(a1) == s6(a1)
    @test s5(a2) == s6(a2)

    s7 = @scheme sum nothing
    s8 = @scheme sum
    s9 = Scheme(sum, nothing)
    @test s7(a1) == s8(a1) == s9(a1)
    @test s7(a2) == s8(a2) == s9(a2)

    s7_2 = @scheme x -> x[begin] + x[begin+1] + x[begin+2] + x[begin+3] nothing
    s8_2 = @scheme x -> x[begin] + x[begin+1] + x[begin+2] + x[begin+3]
    @test s7_2(a1) == s8_2(a1) == s9(a1)
    @test s7_2(a2) == s8_2(a2) == s9(a2)

    s7_3 = @scheme (+) nothing
    s8_3 = @scheme (+)
    s9_3 = Scheme(+, nothing)
    @test s7_3(a1) == s8_3(a1) == s9_3(a1)
    @test s7_3(a2) == s8_3(a2) == s9_3(a2)


    s10 = @scheme sum nothing nothing nothing nothing nothing nothing
    @test s9(a1) == s10(a1)
    @test s9(a2) == s10(a2)
end
