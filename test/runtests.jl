using RoguePkg
using Base.Test

mktempdir() do dir
    pkg_dir = joinpath(dir, "Foo")
    src_dir = joinpath(pkg_dir, "src")
    test_dir = joinpath(pkg_dir, "test")
    deps_dir = joinpath(pkg_dir, "deps")
    mkpath(src_dir)
    mkpath(test_dir)
    mkpath(deps_dir)
    write(joinpath(src_dir, "Foo.jl"), "module Foo\nend")
    # this will test Pkg.Entry.resolve
    write(joinpath(test_dir, "REQUIRE"), "Parameters")
    # running tests will create an empty file, which we can check
    test_path = tempname()
    deps_path = tempname()
    write(joinpath(test_dir, "runtests.jl"), "touch(\"$(test_path)\")")
    write(joinpath(deps_dir, "build.jl"), "touch(\"$(deps_path)\")")

    function all_tests(pkg)
        @test Pkg.dir(pkg, "src") == src_dir
        @test Pkg.dir("something", pkg) == Pkg.dir("something", "Foo") # NOTE hardcoded
        Pkg.build(pkg)
        @test isfile(deps_path)
        rm(deps_path; force = true) # may not exist if test doesn't work, that should not error
        @test (Pkg.test(pkg); true)
        @test isfile(test_path)
        rm(test_path; force = true) # may not exist if test doesn't work, that should not error
    end

    # find by path
    pkg = RoguePkg.PkgAtPath(@eval @pkg_at_str($pkg_dir))
    all_tests(pkg)
    @test repr(pkg) == "package at path $pkg_dir"
    # find by module
    push!(LOAD_PATH, dir)
    pkg = pkg_for"Foo"
    @test repr(pkg) == "package for module \"Foo\" (located dynamically)"
    all_tests(pkg)
    # find by path in environment
    @test repr(pkg_local"Foo") ==
        "package \"Foo\" in ENV[\"JULIA_LOCAL_PACKAGES\"] \e[31m(not set)\e[39m"
    withenv("JULIA_LOCAL_PACKAGES" => dir) do
        pkg = pkg_local"Foo"
        @test repr(pkg) == "package \"Foo\" in $(dir)"
        all_tests(pkg)
    end
    @test_throws ErrorException Pkg.dir(pkg_for"this_better_not_exist")
end
