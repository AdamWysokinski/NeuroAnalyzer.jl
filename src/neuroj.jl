"""
    neuroj_version()

Show NeuroJ and imported packages versions.
"""
function neuroj_version()

    println("    Julia version: $VERSION")
    println("   NeuroJ version: $neuroj_ver")
    if CUDA.functional()
        println("     CUDA version: $(CUDA.version()) (use_cuda = $use_cuda)")
    else
        println("     CUDA version: CUDA not available (use_cuda = $use_cuda)")
    end
    println("     Plugins path: $plugins_path")
    println("          Threads: $(Threads.nthreads()) [set using using the `JULIA_NUM_THREADS` environment variable]")
    if "JULIA_COPY_STACKS" in keys(ENV) && ENV["JULIA_COPY_STACKS"] == "1"
        @info "Environment variable JULIA_COPY_STACKS is set to 1, multi-threading may not work correctly"
    end

    println("Imported packages:")
    required_packages = [
        "ColorSchemes",
        "CSV",
        "CubicSplines",
        "CUDA",
        "DataFrames",
        "Deconvolution",
        "Distances",
        "DSP",
        "FFTW",
        "FileIO",
        "FindPeaks1D",
        "Git",
        "GLM",
        "GLMakie",
        "HypothesisTests",
        "InformationMeasures",
        "Interpolations",
        "JLD2",
        "Loess",
        "MultivariateStats",
        "Plots",
        "Polynomials",
        "Preferences",
        "ScatteredInterpolation",
        "Simpson",
        "StatsFuns",
        "StatsKit",
        "StatsModels",
        "StatsPlots",
        "Wavelets"]
    if isfile("Manifest.toml")
        versions = TOML.parsefile("Manifest.toml")["deps"]
        for idx in 1:length(required_packages)
            pkg = lpad(required_packages[idx], 25 - length(idx), " ")
            pkg_ver = versions[required_packages[idx]][1]["version"]
            println("$pkg $pkg_ver ")
        end
    else
        @warn "Manifest.toml file could not be found in $(pwd())"
    end
end

"""
    neuroj_plugins_reload()

Reload NeuroJ plugins.
"""
function neuroj_plugins_reload()
    plugins_path[end] == '/' || (plugins_path *= '/')
    isdir(expanduser(plugins_path)) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(expanduser(plugins_path))
    plugins = readdir(expanduser(plugins_path))
    for idx1 in 1:length(plugins)
        plugin = readdir(plugins[idx1] * "/src/")
        for idx2 in 1:length(plugin)
            if splitext(plugin[idx2])[2] == ".jl"
                include(expanduser(plugins_path) * plugins[idx1] * "/src/" * plugin[idx2])
            end
        end
    end
end

"""
    neuroj_plugins_list()

List NeuroJ plugins.
"""
function neuroj_plugins_list()
    plugins_path[end] == '/' || (plugins_path *= '/')
    isdir(expanduser(plugins_path)) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(expanduser(plugins_path))
    plugins = readdir(expanduser(plugins_path))
    for idx in 1:length(plugins)
        println("$idx. $(replace(plugins[idx]))")
    end
end

"""
    neuroj_plugins_remove(plugin)

Remove NeuroJ `plugin`.

# Attributes

- `plugin::String`: plugin name
"""
function neuroj_plugins_remove(plugin::String)
    plugins_path[end] == '/' || (plugins_path *= '/')
    @info "This will remove the whole $plugin directory, along with its file contents."
    isdir(expanduser(plugins_path)) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(expanduser(plugins_path))
    plugins = readdir(expanduser(plugins_path))
    plugin in plugins || throw(ArgumentError("Plugin $plugin does not exist."))
    try
        rm(plugin, recursive=true)
    catch err
        @error "Cannot remove $plugin directory."
    end
    neuroj_plugins_reload()
end

"""
    neuroj_plugins_install(plugin)

Install NeuroJ `plugin`.

# Attributes

- `plugin::String`: plugin Git repository URL
"""
function neuroj_plugins_install(plugin::String)
    plugins_path[end] == '/' || (plugins_path *= '/')
    isdir(expanduser(plugins_path)) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(expanduser(plugins_path))
    try
        run(`$(git()) clone $plugin`)
    catch err
        @error "Cannot install $plugin."
    end
    neuroj_plugins_reload()
end

"""
    neuroj_plugins_update(plugin)

Install NeuroJ `plugin`.

# Attributes

- `plugin::String`: plugin to update; if empty, update all
"""
function neuroj_plugins_update(plugin::Union{String, Nothing}=nothing)
    plugins_path[end] == '/' || (plugins_path *= '/')
    isdir(expanduser(plugins_path)) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(expanduser(plugins_path))
    plugins = readdir(expanduser(plugins_path))
    if plugin === nothing
        for idx in 1:length(plugins)
            cd(plugins[idx])
            println(plugins[idx])
            try
                run(`$(git()) pull`)
            catch err
                @error "Cannot update $(plugins[idx])."
            end
            cd(expanduser(plugins_path))
        end
    else
        plugin in plugins || throw(ArgumentError("Plugin $plugin does not exist."))
        cd(plugin)
        try
            run(`$(git()) pull`)
        catch err
            @error "Cannot update $plugin."
        end
        cd(expanduser(plugins_path))
    end
    neuroj_plugins_reload()
end

"""
    neuroj_use_cuda(use_cuda)

Set `use_cuda` preference and store in LocalPreferences.toml.

# Attributes

- `use_cuda::Bool=true`
"""
function neuroj_use_cuda(use_cuda::Bool=true)
    @set_preferences!("use_cuda" => use_cuda)
    @info("Preference use_cuda set; restart your Julia session for this change to take effect!")
end

"""
    neuroj_plugins_path(new_plugins_path)

Set `new_plugins_path` preference and store in LocalPreferences.toml.

# Attributes

- `new_plugins_path::String`
"""
function neuroj_plugins_path(new_plugins_path::String)
    new_plugins_path[end] == '/' || (new_plugins_path *= '/')
    isdir(expanduser(new_plugins_path)) || throw(ArgumentError("Folder $new_plugins_path does not exist."))
    @set_preferences!("plugins_path" => new_plugins_path)
    @info("Preference plugins_path set; restart your Julia session for this change to take effect!")
end