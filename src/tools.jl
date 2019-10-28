function unsafe_getbyoffset(::Type{T}, s::S, offset::Int) where {T, S}
    rt = Ref{T}()
    rs = Ref{S}(s)
    GC.@preserve rt rs begin
        pt = Ptr{UInt8}(Base.unsafe_convert(Ref{T}, rt))
        ps = Ptr{UInt8}(Base.unsafe_convert(Ref{S}, rs)) + offset
        Base._memcpy!(pt, ps, sizeof(T))
    end
    return rt[]
end

function check_getbyoffset(T, s, offset)
    S = typeof(s)
    isbitstype(T) || throw(ArgumentError("Can only cast into bitstype."))
    isbitstype(S) || throw(ArgumentError("Can only cast from bitstype."))
    @assert offset >= 0
    sizeof(T) + offset <= sizeof(S) || throw(ArgumentError("""
            sizeof(T) + offset <= sizeof(typeof(s)) must hold. Got:
            T = $(T), sizeof(T) = $(sizeof(T))
            S = $(S), sizeof(S) = $(sizeof(S))
            offset = $offset
            """)
    )
end

function getbyoffset(T, s, offset)
    @boundscheck check_getbyoffset(T, s, offset)
    unsafe_getbyoffset(T, s, offset)
end

function unsafe_setbyoffset(t::T, s::S, offset::Int) where {T, S}
    rt = Ref{T}(t)
    rs = Ref{S}(s)
    GC.@preserve rt rs begin
        pt = Ptr{UInt8}(Base.unsafe_convert(Ref{T}, rt)) + offset
        ps = Ptr{UInt8}(Base.unsafe_convert(Ref{S}, rs))
        Base._memcpy!(pt, ps, sizeof(T))
    end
    return rt[]::T
end

function check_setbyoffset(t, s, offset)
    T = typeof(t)
    S = typeof(s)
    isbitstype(T) || throw(ArgumentError("Can only set into bitstype."))
    isbitstype(S) || throw(ArgumentError("Can only set from bitstype."))
    @assert offset >= 0
    sizeof(T) >= sizeof(S) + offset || throw(ArgumentError("""
            sizeof(T) >= sizeof(typeof(s)) + offset must hold. Got:
            T = $(T), sizeof(T) = $(sizeof(T))
            S = $(S), sizeof(S) = $(sizeof(S))
            offset = $offset
            """)
    )
end

function setbyoffset(t, s, offset)
    @boundscheck check_setbyoffset(t, s, offset)
    unsafe_setbyoffset(t, s, offset)
end
