# ITF1788

[![Build Status](https://github.com/gwater/ITF1788.jl/workflows/CI/badge.svg)](https://github.com/gwater/ITF1788.jl/actions)
[![Coverage](https://codecov.io/gh/gwater/ITF1788.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/gwater/ITF1788.jl)

This package is a parser of the Interval Tests Libraries (ITL) testsuite, created by Oliver Heimlich and available [here](https://github.com/oheim/ITF1788). The tests are to verify whether an interval arithmetic implementation is complying to the IEEE 1788-2015 standard for interval arithmetic. This package converts the test suite to tests in Julia, which can be used to test [IntervalArithmetic.jl](https://github.com/gwater/intervalarithmetic.jl)

## This Fork

This fork has several goals:
- switch to stream-based IO with better performance
- avoid regular expressions
- switch to a more expressive style
- match the reduced scope of https://github.com/gwater/IntervalArithmetic.jl

This fork includes many contributions from Josua Grawitter.

## How to use

Install and import the fork with 

```julia
julia> using Pkg; Pkg.add("https://github.com/gwater/ITF1788.jl.git") # only once to install
julia> using ITF1788
```

then run

```
julia> generate()
```

and this function will convert all the test into Julia tests, actually check the tests and mark as broken those not passing.

For example, if the original `.itl` file had a line like

```
add [1.0, 2.0] [1.0, 2.0] = [2.0, 4.0]
```

this will become
```julia
@test +(interval(1.0, 2.0), interval(1.0, 2.0)) == interval(2.0, 4.0)
```

if the test is successful and
```julia
@test_broken +(interval(1.0, 2.0), interval(1.0, 2.0)) == interval(2.0, 4.0)
```

if the test is unsuccessful.

If the test causes an exception, the translation is probably invalid and we return the original test case as a comment:
```julia
# add [1.0, 2.0] [1.0, 2.0] = [2.0, 4.0]
```

By default, all test files are created into a folder `test_ITF1788` in your current directory. You can change the output directory with the
keyword `output`, e.g. `generate(; output="mydirectory")`.

The function will also create a `run_ITF1788.jl` which includes all the tests files, i.e. all you have to do to test `IntervalArithmetic.jl` against this test suite is

```julia
include("test_ITF1788/run_ITF1788.jl")
```

## Original Author

- [Luca Ferranti](https://github.com/lucaferranti)



