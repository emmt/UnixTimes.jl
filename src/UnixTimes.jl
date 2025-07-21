module UnixTimes

export TimeSpec, TimeVal

using Printf

const MILLISECONDS_PER_SECOND = 1_000
const MICROSECONDS_PER_SECOND = 1_000*MILLISECONDS_PER_SECOND
const  NANOSECONDS_PER_SECOND = 1_000*MICROSECONDS_PER_SECOND

abstract type TimeStruct end

let file = normpath(joinpath(@__DIR__, "..", "deps", "ctypes.jl"))
    if !isfile(file)
        error("File \"$file\" does not exists. You may may generate it by:\n",
              "    using Pkg\n",
              "    Pkg.build(\"$(@__MODULE__)\")")
    end
    include(file)
end

if !isdefined(Base, :fieldtypes)
    fieldtypes(::Type{T}) where {T} = ntuple(i -> fieldtype(T, i), Val(fieldcount(T)))
end

const _TimeValInteger = promote_type(fieldtypes(TimeVal)...,)::Type{<:Signed}
const _TimeSpecInteger = promote_type(fieldtypes(TimeSpec)...,)::Type{<:Signed}

"""
    TimeVal(sec::Real) -> t
    TimeVal(sec::Integer, usec::Integer) -> t

yield a time structure with *microsecond resolution*. Argument `sec` is a number of seconds.
If an integer number of microseconds is specified by `usec`, `sec` must be an integer
number of seconds; otherwise, `sec` may be a fractional number of seconds. The returned
time is normalized.

"""
TimeVal(sec::Integer, usec::Integer = zero(_TimeValInteger)) =
    _TimeVal(normalize(sec, usec, resolution(TimeVal))...)
TimeVal(sec::AbstractFloat) = TimeVal(split(sec, resolution(TimeVal))...)

"""
    TimeVal() -> t

yields the time with microsecond resolution as returned by C function `gettimeofday`.

"""
@inline function TimeVal()
    t = Ref{TimeVal}()
    ccall(:gettimeofday, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), t, C_NULL)
    return t[]
end

"""
    TimeSpec(sec::Real) -> t
    TimeSpec(sec::Integer, nsec::Integer) -> t

yield a time structure with *nanosecond resolution*. Argument `sec` is a number of
seconds. If an integer number of nanoseconds is specified by `nsec`, `sec` must be an
integer number of seconds; otherwise, `sec` may be a fractional number of seconds. The
returned time is normalized.

"""
TimeSpec(sec::Integer, usec::Integer = zero(_TimeSpecInteger)) =
    _TimeSpec(normalize(sec, usec, resolution(TimeSpec))...)
TimeSpec(sec::AbstractFloat) = TimeSpec(split(sec, resolution(TimeVal))...)

"""
    TimeSpec(; clock::Integer = UnixTimes.CLOCK_REALTIME) -> t
    TimeSpec(id::Symbol) -> t

yield the time with nanosecond resolution as returned by POSIX C function `clock_gettime`.
Clock identifier `id` may be an integer of a symbolic name `:realtime` for
`UnixTimes.CLOCK_REALTIME` or `:monotonic` for UnixTimes.CLOCK_MONOTONIC`.

"""
@inline function TimeSpec(; clock::Integer = CLOCK_REALTIME)
    t = Ref{TimeSpec}()
    ccall(:clock_gettime, Cint, (typeof(CLOCK_REALTIME), Ptr{Cvoid}), clock, t)
    return t[]
end

@inline function TimeSpec(id::Symbol)
    n = id === :realtime ? CLOCK_REALTIME :
        id === :monotonic ? CLOCK_MONOTONIC :
        throw(ArgumentError("clock identifier should be `:monotonic` or `:realtime`, got `$(repr(id))`"))
    return TimeSpec(; clock = n)
end

@inline function split(x::AbstractFloat, r::T) where {T<:Integer}
    i = floor(T, x)
    f = round(T, (x - i)*r)
    return i, f
end

"""
    UnixTimes.resolution(t)
    UnixTimes.resolution(typeof(t))

yield the resolution of time value `t`.

"""
resolution(t::TimeStruct) = resolution(typeof(t))
resolution(::Type{TimeVal}) = _TimeValInteger(MICROSECONDS_PER_SECOND)::_TimeValInteger
resolution(::Type{TimeSpec}) = _TimeSpecInteger(NANOSECONDS_PER_SECOND)::_TimeSpecInteger

for op in (:(+), :(-))
    @eval begin
        Base.$op(x::TimeStruct, y::TimeStruct) = $op(promote(x, y)...,)
        Base.$op(x::T, y::T) where {T<:TimeStruct} =
            T($op(getfield(x, 1), getfield(y, 1)), $op(getfield(x, 2), getfield(y, 2)))
        Base.$op(x::T, y::Real) where {T<:TimeStruct} = $op(x, T(y))
        Base.$op(x::Real, y::T) where {T<:TimeStruct} = $op(T(x), y)
    end
end

# `normalize(i, f, r)` yields `(i′,f′)` such that `i′ + f′//r == i + f//r` but with `0 ≤ f′ < r`
# and with i′ and f′ having the same type as r.
@inline normalize(i::Integer, f::Integer, r::T) where {T<:Integer} =
    normalize(T(i)::T, T(f)::T, r)
@inline function normalize(i::T, f::T, r::T) where {T<:Integer}
    t = fld(f, r)
    return (i + t, f - t*r)
end

@inline normalize(::Type{T}, i::Integer, f::Integer) where {T} = T(normalize(i, f, resolution(T))...)

fields(t::Union{TimeVal,TimeSpec}) = (getfield(t, 1), getfield(t, 2))

normalize(t::T) where {T<:TimeStruct} = T(fields(t)...,)

Base.promote_rule(::Type{TimeVal}, ::Type{TimeSpec}) = TimeSpec

# Conversion/copy constructors.
TimeVal(t::TimeVal) = t
function TimeVal(t::TimeSpec)
    usec, nsec = divrem(t.nsec, oftype(t.nsec, 1000))
    if nsec ≥ oftype(nsec, 500)
        usec += one(usec)
    elseif nsec ≤ oftype(nsec, -500)
        usec -= one(usec)
    end
    return TimeVal(t.sec, usec)
end
TimeSpec(t::TimeSpec) = t
TimeSpec(t::TimeVal) = TimeSpec(t.sec, t.usec*oftype(t.usec, 1000))

Base.convert(::Type{T}, t::T) where {T<:TimeStruct} = t
Base.convert(::Type{T}, t::TimeStruct) where {T<:TimeStruct} = T(t)::T

Base.convert(::Type{T}, t::TimeStruct) where {T<:AbstractFloat} =
    convert(T, getfield(t, 1)) + convert(T, getfield(t, 2)//resolution(t))

for T in (:Float16, :Float32, :Float64, :BigFloat)
    @eval begin
        Base.$T(t::TimeStruct) = convert($T, t)
    end
end
Base.float(t::TimeStruct) = Float64(t)

function Base.show(io::IO, t::T) where {T<:TimeStruct}
    t = normalize(t) # make sure `t` is normalized
    show(io, T)
    write(io, '(')
    i, f = fields(t)
    r = resolution(t)
    if i < zero(i)
        f = oftype(f, r) - f
        i += one(i)
        i < zero(i) || write(io, '-')
    end
    show(io, i)
    if r == MICROSECONDS_PER_SECOND
        @printf(io, ".%06d", f)
    elseif r == NANOSECONDS_PER_SECOND
        @printf(io, ".%09d", f)
    else
        error("unsupported time resolution")
    end
    write(io, ')')
    return nothing
end

end # module
