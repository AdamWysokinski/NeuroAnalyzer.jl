export plot_save

"""
    plot_save(p; file_name::String)

Saves plot as file (PNG/PDF). File format is determined using `file_name` extension.

# Arguments

- `p::Plots.Plot{Plots.GRBackend}`
- `file_name::String`
"""
function plot_save(p::Plots.Plot{Plots.GRBackend}; file_name::String)

    ext = splitext(file_name)[2]
    _check_var(ext, [".png", ".pdf"], "File format")

    (isfile(file_name) && verbose == true) && _warn("File $file_name will be overwritten.")
    savefig(p, file_name)

    return nothing

end
