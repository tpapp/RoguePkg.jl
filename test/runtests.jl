using RoguePkg
using Base.Test

mktempdir() do dir
    pkg_dir = joinpath(dir, "Foo")
    src_dir = joinpath(pkg_dir, "src")
    test_dir = joinpath(pkg_dir, "test")
    mkpath(src_dir)
    mkpath(test_dir)
    write(joinpath(src_dir, "Foo.jl"), "module Foo\nend")
    test_path = tempname()
    write(joinpath(test_dir, "runtests.jl"), "touch(\"$(test_path)\")")
    function all_tests(pkg)
        @test Pkg.dir(pkg, "src") == src_dir
        @test Pkg.dir("something", pkg) == Pkg.dir("something", "Foo") # NOTE hardcoded
        @test (Pkg.test(pkg); true)
        @test isfile(test_path)
        rm(test_path; force = true) # may not exist if test doesn't work, that should not error
    end
    # find by path
    all_tests(RoguePkg.PkgAtPath(pkg_dir))
    # find by module
    push!(LOAD_PATH, dir)
    all_tests(pkg_for"Foo")
    # find by path in environment
    withenv("JULIA_LOCAL_PACKAGES" => dir) do
        all_tests(pkg_local"Foo")
    end
end
