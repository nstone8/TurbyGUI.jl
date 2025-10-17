module TurbyGUI
export gui, installapp

import Pkg
using GenieFramework

#helper function to run code inside the app environment
function inapp(f,appdir)
    ENV["TURBYDIR"] = pwd()
    curproject = Pkg.project().path
    cd(appdir) do
        Pkg.activate("Project.toml")
        f()
    end
    Pkg.activate(curproject)
    delete!(ENV,"TURBYDIR")
    return nothing
end

"""
```julia
installapp(appdir=joinpath(".","TurbyApp"))
```
Install the genie app at `appdir`
"""
function installapp(appdir=joinpath(".","TurbyApp"))
    #spin up a directory to serve the app from
    pkgdir = dirname(@__FILE__) |> dirname
    @info "creating app directory"
    cp(joinpath(pkgdir,"TurbyApp"),appdir)
    inapp(appdir) do
        Pkg.instantiate()
    end
end

"""
```julia
gui(appdir=joinpath(".","TurbyApp"))
```
Run the Turby genie app at `appdir`. If `appdir` is not an existing directory
the app will be installed.
"""
function gui(appdir=joinpath(".","TurbyApp"))
    if !isdir(appdir)
        installapp(appdir)
    end
    
    inapp(appdir) do
        Genie.loadapp()
        up(8000,"127.0.0.1",async=false)
    end

    return nothing
end

end # module TurbyGUI
