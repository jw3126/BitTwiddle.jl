struct ConstructorPlan
    name::Symbol
    argtypes::Type # Type{<:Tuple}
end

struct ADTPlan
    typename::Symbol
    constructors::Vector{ConstructorPlan}
end

function payload_sizeof(plan::ADTPlan)
    mapreduce(ctor -> sizeof(ctor.argtypes), max, plan.constructors, init=0)
end

ctorid_offset(plan::ADTPlan) = payload_sizeof(plan)

function ctor_sizeof(ctor::ConstructorPlan)
    # mapreduce(sizeof, +, ctor.argtypes, init=0)
    sizeof(ctor.argtypes)
end

function ctorid_sizeof(plan::ADTPlan)
    8
end

function total_sizeof(plan::ADTPlan)
    payload_sizeof(plan) + ctorid_sizeof(plan)
end

function unsafe_destructure(CTOR, adt)
    T = argtypes(CTOR)
    getbyoffset(T, adt, 0)
end

function constructors end

function argtypes end

function ctorid end

function invalid(ADT::Type{T}) where {T}
    data = ntuple(UInt8, sizeof(ADT))
    unsafe_getbyoffset(ADT, data, 0)
end

function emit(plan::ADTPlan)
    # TODO: esc
    ret = quote end
    ex = quote
        struct $(plan.typename)
            _data::NTuple{$(total_sizeof(plan)), UInt8}
        end
        function ctorid(adt::$(plan.typename))
            $(getbyoffset)(Int, adt, $(payload_sizeof(plan)))
        end
        function isctor(adt::$(plan.typename), CT)
            ctorid(CT) === ctorid(adt)
        end
    end
    append!(ret.args, ex.args)

    for (i, ctor) in enumerate(plan.constructors)
        CT = :(typeof($(ctor.name)))
        ex = quote
            function $(ctor.name)(args...)
                function doit(args::($(ctor.argtypes)))
                    id = ctorid($(CT))
                    ret = $(invalid)($(plan.typename))
                    ret = $(setbyoffset)(ret, args, 0)
                    ret = $(setbyoffset)(ret, id, $(ctorid_offset(plan)))
                    ret
                end
                doit(args)
            end
            function argtypes(::Type{$CT})
                $(ctor.argtypes)
            end
            function destructure(ctor::($CT), adt::$(plan.typename))
                @boundscheck if !isctor(adt, $CT)
                    msg = """
                    Constructor mismatch.
                    """
                    throw(ArgumentError(msg))
                end
                $(unsafe_destructure)($CT, adt)
            end
            function ctorid(::Type{$CT})
                $i
            end
        end
        append!(ret.args, ex.args)
    end

    ex = quote
        constructors(::($(plan.typename))) = tuple($(map(ctor -> ctor.name, plan.constructors)...))
    end
    append!(ret.args, ex.args)
    ret
end
