module TestADT
using Test
using BitTwiddle

using BitTwiddle: ADTPlan, ConstructorPlan, emit, ctorid
import BitTwiddle: ctorid, argtypes

plan = ADTPlan(:MaybeInt, [
        ConstructorPlan(:Just, Tuple{Int}),
        ConstructorPlan(:Nil, Tuple{}),
        ])

ex = emit(plan)
eval(ex)

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


end#module
