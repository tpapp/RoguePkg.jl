# RoguePkg

![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg?style=flat-square)
[![Build Status](https://travis-ci.org/tpapp/RoguePkg.jl.svg?branch=master)](https://travis-ci.org/tpapp/RoguePkg.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/RoguePkg.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/RoguePkg.jl?branch=master)
[![codecov.io](http://codecov.io/github/tpapp/RoguePkg.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/RoguePkg.jl?branch=master)

**This package was made obsolete by the new `Pkg` framework of Julia v0.7, which simplifies development for local packages.** It is retired, and unlikely to receive any updates.

## Description

This package defines some methods for functions in `Base.Pkg` that should make testing, benchmarking, and locating files in packages outside the default directory (which is returned by `Pkg.dir()`, eg `~/.julia/v0.6`) easier.

## Usage

First, load the module:

```julia
using RoguePkg
```

Then you can refer to packages by the module they contain:

```julia
pkg_for"MyFancyModule"
```

A path:
```julia
pkg_at"~/this_is/where_I/keep/FancyPkg"
```

Or, if you set `ENV[JULIA_LOCAL_PACKAGES]`, by their subdirectory:
```julia
pkg_local"FancyPkg"
```

Then you can use the resulting objects with some functions, including `Pkg.test`, `Pkg.dir`. The methods for the latter even make `PkgBenchmark.benchmarkpkg` work. For example,

```julia
Pkg.test(pkg_for"FancyModule")
```
