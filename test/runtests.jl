using UnixTimes
using Test

@testset "UnixTimes.jl" begin

    @test UnixTimes.MILLISECONDS_PER_SECOND == 1_000
    @test UnixTimes.MICROSECONDS_PER_SECOND == 1_000_000
    @test UnixTimes.NANOSECONDS_PER_SECOND  == 1_000_000_000

    tv = @inferred TimeVal()
    @test tv isa TimeVal
    ts = TimeSpec(tv)
    @test ts isa TimeSpec
    @test ts.sec == tv.sec
    @test ts.nsec == tv.usec*1_000

    @test TimeVal(tv) === tv
    @test TimeSpec(ts) === ts

    # Check inference (an pre-compile).
    t = @inferred TimeVal()
    t = @inferred TimeSpec(:realtime)
    t = @inferred TimeSpec(:monotonic)
    t = @inferred TimeSpec(; clock = UnixTimes.CLOCK_REALTIME)
    t = @inferred TimeSpec(; clock = UnixTimes.CLOCK_MONOTONIC)

    t1 = @inferred TimeSpec(:realtime)
    t2 = @inferred TimeSpec(; clock = UnixTimes.CLOCK_REALTIME)
    @test abs(float(t1 - t2)) < 5.0
    t1 = @inferred TimeSpec(:monotonic)
    t2 = @inferred TimeSpec(; clock = UnixTimes.CLOCK_MONOTONIC)
    @test abs(float(t1 - t2)) < 5.0

    # Arithmetic.
    @test TimeVal(123, 999999) + TimeVal(0, 1) === TimeVal(124, 0)
    @test TimeVal(123, 0) - TimeVal(0, 1) === TimeVal(122, 999999)
    @test TimeVal(123, 847) + 1 === TimeVal(124, 847)
    @test TimeVal(123, 847) - 1 === TimeVal(122, 847)
    @test TimeVal(123, 847) + 1.5 === TimeVal(124, 500847)
    @test TimeVal(123, 847) - 1.5 === TimeVal(121, 500847)

    # Parse output of show.
    @test repr(TimeVal(123,456789)) == "TimeVal(123.456789)"
    @test repr(TimeSpec(123,456789)) == "TimeSpec(123.000456789)"
    @test repr(TimeSpec(1,23456789)) == "TimeSpec(1.023456789)"
end
