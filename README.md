# UnixTimes

[![Build Status](https://github.com/emmt/UnixTimes.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/emmt/UnixTimes.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Build Status](https://ci.appveyor.com/api/projects/status/github/emmt/UnixTimes.jl?svg=true)](https://ci.appveyor.com/project/emmt/UnixTimes-jl) [![Coverage](https://codecov.io/gh/emmt/UnixTimes.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/emmt/UnixTimes.jl)

`UnixTimes` is a Julia interface to Unix/POSIX times.

Examples:

``` julia
using UnixTimes
t1 = TimeVal() # get current time with microsecond resolution
t1.sec  # number of seconds
t1.usec # number of microseconds
t2 = TimeSpec() # get current time with nanosecond resolution
t2.sec  # number of seconds
t2.nsec # number of nanoseconds
t3 = TimeSpec(:realtime) # get realtime clock time with nanosecond resolution
t3 = TimeSpec(:monotonic) # get monotonic clock time with nanosecond resolution
```

To build a normalized time structure, call one of:

``` julia
TimeVal(sec, usec)
TimeSpec(sec, nsec)
```

with `sec` an integer number of seconds, `usec` an integer number of microseconds, and
`nsec` an integer number of nanoseconds.

Conversion from/to a fractional number of seconds is possible:

``` julia
TimeVal(sec)
TimeSpec(sec)
float(TimeVal())
float(TimeSpec(:realtime))
float(TimeSpec(:monotonic))
```

`float` may also be a specific floating-point type like `Float64` or `BigFloat`.

Addition and subtraction of times is supported:

``` julia
TimeVal(123, 89) + TimeVal(1, 15) -> TimeVal(124, 104)
```
