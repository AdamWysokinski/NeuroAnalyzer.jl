"""
    na_info()

Show NeuroAnalyzer and imported packages versions.
"""
function na_info()

    println("    NeuroAnalyzer: $na_ver")
    println("            Julia: $VERSION")
    if CUDA.functional()
        println("             CUDA: $(CUDA.version()) (use_cuda = $use_cuda)")
    else
        println("             CUDA: not available (use_cuda = $use_cuda)")
    end
    println("     Plugins path: $plugins_path")
    println("Show progress bar: $progress_bar")
    println("          Verbose: $verbose")
    println("          Threads: $(Threads.nthreads()) [set using `JULIA_NUM_THREADS` environment variable or Julia --threads command-line option]")
    Threads.nthreads() < length(Sys.cpu_info()) || @info "For best performance, `JULIA_NUM_THREADS` ($(Threads.nthreads())) should be less than number of CPU threads ($(length(Sys.cpu_info())))."
    if "JULIA_COPY_STACKS" in keys(ENV) && ENV["JULIA_COPY_STACKS"] == "1"
        @info "Environment variable `JULIA_COPY_STACKS` is set to 1, multi-threading may not work correctly"
    end
    println()
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
        "Lathe",
        "Loess",
        "MultivariateStats",
        "Plots",
        "Polynomials",
        "Preferences",
        "ProgressMeter",
        "ScatteredInterpolation",
        "Simpson",
        "StatsFuns",
        "StatsKit",
        "StatsModels",
        "StatsPlots",
        "Wavelets",
        "WaveletsExt",
        "ContinuousWavelets"]
    if isfile("Manifest.toml")
        versions = TOML.parsefile("Manifest.toml")["deps"]
        for idx in 1:length(required_packages)
            pkg = lpad(required_packages[idx], 25 - length(idx), " ")
            pkg_ver = versions[required_packages[idx]][1]["version"]
            println("$pkg $pkg_ver")
        end
    else
        @warn "Manifest.toml file could not be found in $(pwd())."
    end
end

"""
    na_plugins_reload()

Reload NeuroAnalyzer plugins.
"""
function na_plugins_reload()
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(plugins_path)
    plugins = readdir(plugins_path)
    for idx1 in 1:length(plugins)
        if Sys.isunix() || Sys.isapple()
            plugin = readdir(plugins[idx1] * "/src/")
        elseif Sys.iswindows()
            plugin = readdir(plugins[idx1] * "\\src\\")
        end
        for idx2 in 1:length(plugin)
            if splitext(plugin[idx2])[2] == ".jl"
                if Sys.isunix() || Sys.isapple()
                    verbose == true && @info "Loading plugin: $(plugin[idx2])"
                    include(plugins_path * plugins[idx1] * "/src/" * plugin[idx2])
                elseif Sys.iswindows()
                    include(plugins_path * plugins[idx1] * "\\src\\" * plugin[idx2])
                end
            end
        end
    end
end

"""
    na_plugins_list()

List NeuroAnalyzer plugins.
"""
function na_plugins_list()
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(plugins_path)
    plugins = readdir(plugins_path)
    for idx in 1:length(plugins)
        println("$idx. $(replace(plugins[idx]))")
    end
end

"""
    na_plugins_remove(plugin)

Remove NeuroAnalyzer `plugin`.

# Arguments

- `plugin::String`: plugin name
"""
function na_plugins_remove(plugin::String)
    verbose == true && @info "This will remove the whole $plugin directory, along with its file contents."
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(plugins_path)
    plugins = readdir(plugins_path)
    plugin in plugins || throw(ArgumentError("Plugin $plugin does not exist."))
    try
        rm(plugin, recursive=true)
    catch
        @error "Cannot remove $plugin directory."
    end
    na_plugins_reload()
end

"""
    na_plugins_install(plugin)

Install NeuroAnalyzer `plugin`.

# Arguments

- `plugin::String`: plugin Git repository URL
"""
function na_plugins_install(plugin::String)
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(plugins_path)
    try
        run(`$(git()) clone $plugin`)
    catch
        @error "Cannot install $plugin."
    end
    na_plugins_reload()
end

"""
    na_plugins_update(plugin)

Install NeuroAnalyzer `plugin`.

# Arguments

- `plugin::String`: plugin to update; if empty, update all
"""
function na_plugins_update(plugin::Union{String, Nothing}=nothing)
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    cd(plugins_path)
    plugins = readdir(plugins_path)
    if plugin === nothing
        for idx in 1:length(plugins)
            cd(plugins[idx])
            println(plugins[idx])
            try
                run(`$(git()) pull`)
            catch
                @error "Cannot update $(plugins[idx])."
            end
            cd(plugins_path)
        end
    else
        plugin in plugins || throw(ArgumentError("Plugin $plugin does not exist."))
        cd(plugin)
        try
            run(`$(git()) pull`)
        catch
            @error "Cannot update $plugin."
        end
        cd(plugins_path)
    end
    na_plugins_reload()
end

"""
    na_set_use_cuda(use_cuda)

Change `use_cuda` preference.

# Arguments

- `use_cuda::Bool`: value
"""
function na_set_use_cuda(use_cuda::Bool)
    @set_preferences!("use_cuda" => use_cuda)
    verbose == true && @info("New option value set, restart your Julia session for this change to take effect!")
end

"""
    na_set_progress_bar(progress_bar)

Change `progress_bar` preference.

# Arguments

- `progress_bar::Bool`: value
"""
function na_set_progress_bar(progress_bar::Bool)
    @set_preferences!("progress_bar" => progress_bar)
    verbose == true && @info("New option value set, restart your Julia session for this change to take effect!")
end

"""
    na_set_plugins_path(plugins_path)

Change `plugins_path` preference.

# Arguments

- `plugins_path::String`: value
"""
function na_set_plugins_path(plugins_path::String)
    plugins_path = expanduser(plugins_path)
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    plugins_path[end] == '/' || (plugins_path *= '/')
    @set_preferences!("plugins_path" => plugins_path)
    verbose == true && @info("New option value set, restart your Julia session for this change to take effect!")
end

"""
    na_set_prefs(use_cuda, plugins_path, progress_bar, verbose)

Save NeuroAnalyzer preferences.

# Arguments

- `use_cuda::Bool`
- `plugins_path::String`
- `progress_bar::Bool`
- `verbose::Bool`
"""
function na_set_prefs(; use_cuda::Bool, plugins_path::String, progress_bar::Bool, verbose::Bool)
    plugins_path = expanduser(plugins_path)
    isdir(plugins_path) || throw(ArgumentError("Folder $plugins_path does not exist."))
    plugins_path[end] == '/' || (plugins_path *= '/')
    @set_preferences!("use_cuda" => use_cuda)
    @set_preferences!("plugins_path" => plugins_path)
    @set_preferences!("progress_bar" => progress_bar)
    @set_preferences!("verbose" => verbose)
end

"""
    na_set_verbose(verbose)

Change `verbose` preference.

# Arguments

- `verbose::Bool`: value
"""
function na_set_verbose(verbose::Bool)
    @set_preferences!("verbose" => verbose)
    verbose == true && @info("New option value set, restart your Julia session for this change to take effect!")
end

"""
    na_version()

Convert NeuroAnalyzer version to string.

# Returns

- `na_ver::String`
"""
function na_version()
    return string(Int(na_ver.major)) * "." * string(Int(na_ver.minor)) * "." * string(Int(na_ver.patch))
end