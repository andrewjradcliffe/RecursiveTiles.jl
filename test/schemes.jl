s = @scheme sum last third second first
s2 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), third), second), first)

s3 = @scheme sum last x -> x[begin+2] + 1000 second first
s4 = ExtendScheme(ExtendScheme(ExtendScheme(Scheme(sum, last), x -> x[begin+2] + 1000), second), first)
