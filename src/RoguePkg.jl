module RoguePkg

import Base: Pkg.Dir.path, Pkg.test, show

export @pkg_for_str, @pkg_at_str, @pkg_local_str

######################################################################
# general
######################################################################

abstract type PackageSpec end

"""
    ensure_dirpath(path)

If `path` is not a directory, append a `/`.
"""
ensure_dirpath(path) = isdirpath(path) ? path : path * "/"

"""
    pkg_root(package_spec)

Return the root directory for a package specification.  See the documentation
for ways to specify a package.
"""
function pkg_root end

"""
    pkg_name(package_spec)

Return the name of the package as a string. See the documentation for ways to
specify a package.
"""
pkg_name(pkg::PackageSpec) = splitdir(splitdir(pkg_root(pkg))[1])[2]

# strings are passed through
pkg_name(s::AbstractString) = s

######################################################################
# package for a module
######################################################################

"""
    PkgForModule(module_name)

Package for the module `module_name`, located dynamically using.
"""
struct PkgForModule{S <: AbstractString} <: PackageSpec
    module_name::S
end

show(io::IO, pkg::PkgForModule) =
    print(io, "package for module \"$(pkg.module_name)\" (located dynamically)")

"""
    pkg_for"Module"

Package for `"Module"`, located dynamically.
"""
macro pkg_for_str(module_name)
    PkgForModule(module_name)
end

if VERSION ≥ v"0.7-"
    _find_package(name) = Base.find_package(name)
else
    _find_package(name) = Base.find_in_path(name, nothing)
end

function pkg_root(pkg::PkgForModule)
    module_path = _find_package(pkg.module_name)
    module_path == nothing &&
        error("module \"$(pkg.module_name)\" could not be found in the load path")
    src_dir = splitdir(module_path)[1]
    normpath(src_dir, "..")
end

######################################################################
# package at a path
######################################################################

"""
    PkgAtPath(path)

Package at the given path. `~` is resolved.
"""
struct PkgAtPath{S <: AbstractString} <: PackageSpec
    package_path::S
end

function show(io::IO, pkg::PkgAtPath)
    path = pkg.package_path
    print(io, "package at path $(path)")
    '~' in path && print(io, "(~ expanded dynamically)")
    nothing
end

"""
    pkg_at"path"

Package at the given path. `~` is resolved.
"""
macro pkg_at_str(package_path)
    PkgAtPath(package_path)
end

pkg_root(pkg::PkgAtPath) = ensure_dirpath(expanduser(pkg.package_path))

######################################################################
# package in a (specified) local directory
######################################################################

const PKG_LOCAL_DIR_KEY = "JULIA_LOCAL_PACKAGES"

const ENV_PKG_LOCAL_DIR_KEY = "ENV[\"" * PKG_LOCAL_DIR_KEY * "\"]"

"""
    PkgLocal(directory)

Package in `ENV[$(PKG_LOCAL_DIR_KEY)]/directory`.
"""
struct PkgLocal{S <: AbstractString} <: PackageSpec
    package_name::S
end

function pkg_local_dir(expand = true)
    haskey(ENV, PKG_LOCAL_DIR_KEY) ||
        error("Specify local package directory with $(ENV_PKG_LOCAL_DIR_KEY)")
    dir = ENV[PKG_LOCAL_DIR_KEY]
    expand ? expanduser(dir) : dir
end

function show(io::IO, pkg::PkgLocal)
    print(io, "package \"$(pkg.package_name)\" in ")
    if haskey(ENV, PKG_LOCAL_DIR_KEY)
        print(io, pkg_local_dir(false))
    else
        print(io, ENV_PKG_LOCAL_DIR_KEY * " ")
        print_with_color(:red, io, "(not set)")
    end
end

macro pkg_local_str(package_name)
    PkgLocal(package_name)
end

pkg_root(pkg::PkgLocal) =
    ensure_dirpath(normpath(pkg_local_dir(), pkg_name(pkg)))

pkg_name(pkg::PkgLocal) = pkg.package_name

######################################################################
# provide methods for types above
######################################################################

# when pkg is the first argument, use its root
Pkg.Dir.path(pkg::PackageSpec, names::Union{PackageSpec, AbstractString}...) =
    normpath(pkg_root(pkg), pkg_name.(names)...)

# when pkg is not the first argument, use its name
Pkg.Dir.path(names::Union{PackageSpec, AbstractString}...) =
    Pkg.Dir.path(pkg_name.(names)...)

# just works for a single package
function Pkg.test(pkg::PackageSpec; coverage = false)
    errs = AbstractString[]
    nopkgs = AbstractString[]
    notests = AbstractString[]
    Base.cd(() -> Pkg.Entry.test!(pkg_root(pkg), errs, nopkgs, notests; coverage = coverage),
            Pkg.Dir.path())
    # FIXME check errs, nopks, notests
    nothing
end

Pkg.build(pkgs::PackageSpec...) =
    Pkg.cd(Pkg.Entry.build, [Pkg.dir.(pkgs)...])

end # module
