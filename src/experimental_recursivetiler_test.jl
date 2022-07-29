#
# Date created: 2022-07-29
# Author: aradclif
#
#
############################################################################################

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

second(x) = x[begin+1]
third(x) = x[begin+2]
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

# investigation of type instability
@code_warntype tile(x4, B)
@code_warntype tile(x3, B)
@code_warntype tile(x2, B)
@code_warntype tile(x1, B)
@code_warntype tile(x5, B)
@code_warntype tile(x6, B)

rs_b = findranges(second, B)
@code_warntype tiles(x3, B, rs_b)
@code_warntype tiles(x3, B)
C = view(B, rs_b[1])
@code_warntype tile(x3, C)
rs_c = findranges(third, C)
@code_warntype tiles(x2, C, rs_c)
@code_warntype tiles(x2, C)
D = view(C, rs_c[1])
@code_warntype tile(x2, D)

function myfunc(A)
    B = eachrow(A)
    x1 = Scheme(sum, last)
    x2 = ExtendScheme(x1, third)
    x3 = ExtendScheme(x2, second)
    x4 = ExtendScheme(x3, first)
    tile(x4, B)
end
@code_warntype myfunc(A)

function myfunc2(A)
    B = eachrow(A)
    x1 = Scheme(sum, last)
    x2 = ExtendScheme(x1, third)
    x3 = ExtendScheme(x2, second)
    x4 = ExtendScheme(x3, first)
    x5 = ExtendScheme(x4, last)
    tile(x5, B)
end
@code_warntype myfunc2(A)

Base.promote_op(x4, typeof(B))
x4(first(B))

using BenchmarkTools
@benchmark tile($x4, $B)
@benchmark myfunc($A)
@benchmark myfunc2($A)
