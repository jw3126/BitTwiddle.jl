module TestADT
using Test
using BitTwiddle

using BitTwiddle: ADTPlan, ConstructorPlan, emit, ctorid
import BitTwiddle: ctorid, argtypes

plan = ADTPlan(:MaybeInt, [
        ConstructorPlan(:Just, Tuple{Int}),
        ConstructorPlan(:Nil, Tuple{}),
        ])

println(@macroexpand @adt MaybeInt begin
    Just(::Int)
    Nil()
end)

@adt MaybeInt begin
    Just(::Int)
    Nil()
end


one = @inferred Just(1)
two = @inferred Just(2)
nil = @inferred Nil()
@test one isa MaybeInt
@test nil isa MaybeInt
@test one == one
@test one != two
@test nil == nil
@test one != nil
@test typeof(one) == typeof(nil)

out = @inferred destructure(Just, one)
@test out === (1,)
@test destructure(Just, two) === (2,)
@test () === destructure(Nil, nil)
@test_throws ArgumentError destructure(Nil, one)
@test_throws ArgumentError destructure(Just, nil)

@test occursin("Just", sprint(show, one))
@test occursin("Nil", sprint(show, nil))
for o in [nil, one, two]
    @test eval(parse(sprint(show, o))) === o
end

end#module
