"""
    eeg_add_component(eeg; c, v)

Add component name `c` of value `v` to `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `c::Symbol`: component name
- `v::Any`: component value

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_add_component(eeg::NeuroAnalyzer.EEG; c::Symbol, v::Any)

    eeg_new = deepcopy(eeg)
    c in eeg_new.eeg_header[:components] && throw(ArgumentError("Component $c already exists. Use eeg_delete_component() to remove it prior the operation."))
    push!(eeg_new.eeg_header[:components], c)
    push!(eeg_new.eeg_components, v)
    push!(eeg_new.eeg_header[:history], "eeg_add_component(EEG, c=$c, v=$v)")

    return eeg_new
end

"""
    eeg_add_component!(eeg; c, v)

Add component name `c` of value `v` to `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `c::Symbol`: component name
- `v::Any`: component value
"""
function eeg_add_component!(eeg::NeuroAnalyzer.EEG; c::Symbol, v::Any)

    c in eeg.eeg_header[:components] && throw(ArgumentError("Component $c already exists. Use eeg_delete_component!() to remove it prior the operation."))
    push!(eeg.eeg_header[:components], c)
    push!(eeg.eeg_components, v)
    push!(eeg.eeg_header[:history], "eeg_add_component!(EEG, c=$c, v=$v)")
end

"""
    eeg_list_components(eeg)

List `eeg` components.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `components::Vector{Symbol}`
"""
function eeg_list_components(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:components]
end

"""
    eeg_extract_component(eeg, c)

Extract component `c` of `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `c::Symbol`: component name

# Returns

- `component::Any`
"""
function eeg_extract_component(eeg::NeuroAnalyzer.EEG; c::Symbol)

    c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c does not exist. Use eeg_list_component() to view existing components."))
    
    for idx in 1:length(eeg.eeg_header[:components])
        if c == eeg.eeg_header[:components][idx]
            return eeg.eeg_components[idx]
        end
    end
end

"""
    eeg_delete_component(eeg; c)

Delete component `c` of `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `c::Symbol`: component name

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_component(eeg::NeuroAnalyzer.EEG; c::Symbol)

    eeg_new = deepcopy(eeg)
    c in eeg_new.eeg_header[:components] || throw(ArgumentError("Component $c does not exist. Use eeg_list_component() to view existing components."))
    for idx in 1:length(eeg.eeg_header[:components])
        if c == eeg_new.eeg_header[:components][idx]
            deleteat!(eeg_new.eeg_components, idx)
            deleteat!(eeg_new.eeg_header[:components], idx)
            push!(eeg_new.eeg_header[:history], "eeg_delete_component(EEG, c=$c)")
            return eeg_new
        end
    end
end

"""
    eeg_delete_component!(eeg; c)

Delete component `c` of `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `c::Symbol`: component name
"""
function eeg_delete_component!(eeg::NeuroAnalyzer.EEG; c::Symbol)

    c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c does not exist. Use eeg_list_component() to view existing components."))
    
    for idx in length(eeg.eeg_header[:components]):-1:1
        if c == eeg.eeg_header[:components][idx]
            deleteat!(eeg.eeg_components, idx)
            deleteat!(eeg.eeg_header[:components], idx)
            push!(eeg.eeg_header[:history], "eeg_delete_component(EEG, c=$c)")
        end
    end
end

"""
    eeg_reset_components(eeg)

Remove all `eeg` components.

# Arguments

- `eeg:EEG`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_reset_components(eeg::NeuroAnalyzer.EEG)

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:components] = []
    eeg_new.eeg_components = []

    return eeg_new
end

"""
    eeg_reset_components!(eeg)

Remove all `eeg` components.

# Arguments

- `eeg:EEG`
"""
function eeg_reset_components!(eeg::NeuroAnalyzer.EEG)

    eeg.eeg_header[:components] = []
    eeg.eeg_components = []
end

"""
    eeg_component_idx(eeg, c)

Return index of `eeg` component.

# Arguments

- `eeg:EEG`
- `c::Symbol`: component name

# Return

- `c_idx::Int64`
"""
function eeg_component_idx(eeg::NeuroAnalyzer.EEG; c::Symbol)

    c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c does not exist. Use eeg_list_component() to view existing components."))
    c_idx = findfirst(isequal(c), eeg.eeg_header[:components])

    return c_idx
end

"""
    eeg_component_type(eeg, c)

Return type of `eeg` components.

# Arguments

- `eeg:EEG`
- `c::Symbol`: component name

# Return

- `c_type::DataType`
"""
function eeg_component_type(eeg::NeuroAnalyzer.EEG; c::Symbol)

    c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c does not exist. Use eeg_list_component() to view existing components."))
    c_idx = eeg_component_idx(eeg; c=c)
    c_type = typeof(eeg.eeg_components[c_idx])

    return c_type
end

"""
    eeg_rename_component(eeg, c_old, c_new)

Return type of `eeg` components.

# Arguments

- `eeg:EEG`
- `c_old::Symbol`: old component name
- `c_new::Symbol`: new component name

# Return

- `eeg_new:EEG`
"""
function eeg_rename_component(eeg::NeuroAnalyzer.EEG; c_old::Symbol, c_new::Symbol)

    c_old in eeg.eeg_header[:components] || throw(ArgumentError("Component $c_old does not exist. Use eeg_list_component() to view existing components."))
    c_new in eeg.eeg_header[:components] && throw(ArgumentError("Component $c_new already exists. Use eeg_list_component() to view existing components."))

    eeg_new = deepcopy(eeg)
    c_idx = eeg_component_idx(eeg, c=c_old)
    eeg_new.eeg_header[:components][c_idx] = c_new

    push!(eeg_new.eeg_header[:history], "eeg_rename_component(EEG, c_old=$c_old, c_new=$c_new)")

    return eeg_new
end

"""
    eeg_rename_component(eeg, c_old, c_new)

Return type of `eeg` components.

# Arguments

- `eeg:EEG`
- `c_old::Symbol`: old component name
- `c_new::Symbol`: new component name
"""
function eeg_rename_component!(eeg::NeuroAnalyzer.EEG; c_old::Symbol, c_new::Symbol)

    c_old in eeg.eeg_header[:components] || throw(ArgumentError("Component $c_old does not exist. Use eeg_list_component() to view existing components."))
    c_new in eeg.eeg_header[:components] && throw(ArgumentError("Component $c_new already exists. Use eeg_list_component() to view existing components."))

    c_idx = eeg_component_idx(eeg, c=c_old)
    eeg.eeg_header[:components][c_idx] = c_new

    push!(eeg.eeg_header[:history], "eeg_rename_component!(EEG, c_old=$c_old, c_new=$c_new)")
end

"""
    eeg_delete_channel(eeg; channel)

Remove `channel` from the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel index to be removed, vector of numbers or range

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    typeof(channel) <: AbstractRange && (channel = collect(channel))
    channel_n = eeg_channel_n(eeg)
    length(channel) == channel_n && throw(ArgumentError("You cannot delete all channels."))

    length(channel) > 1 && (channel = sort!(channel, rev=true))

    if channel[end] < 1 || channel[1] > eeg_channel_n(eeg)
        throw(ArgumentError("channel does not match signal channels."))
    end

    eeg_new = deepcopy(eeg)

    # update headers
    eeg_new.eeg_header[:channel_n] = channel_n - length(channel)
    for idx1 in 1:length(channel)
        for idx2 in 1:channel_n
            if idx2 == channel[idx1]
                deleteat!(eeg_new.eeg_header[:labels], idx2)
                deleteat!(eeg_new.eeg_header[:channel_type], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_theta]) > 0) && deleteat!(eeg_new.eeg_header[:loc_theta], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_radius]) > 0) && deleteat!(eeg_new.eeg_header[:loc_radius], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_x]) > 0) && deleteat!(eeg_new.eeg_header[:loc_x], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_y]) > 0) && deleteat!(eeg_new.eeg_header[:loc_y], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_z]) > 0) && deleteat!(eeg_new.eeg_header[:loc_z], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_radius_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_radius_sph], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_theta_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_theta_sph], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_phi_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_phi_sph], idx2)
                deleteat!(eeg_new.eeg_header[:transducers], idx2)
                deleteat!(eeg_new.eeg_header[:physical_dimension], idx2)
                deleteat!(eeg_new.eeg_header[:physical_minimum], idx2)
                deleteat!(eeg_new.eeg_header[:physical_maximum], idx2)
                deleteat!(eeg_new.eeg_header[:digital_minimum], idx2)
                deleteat!(eeg_new.eeg_header[:digital_maximum], idx2)
                deleteat!(eeg_new.eeg_header[:prefiltering], idx2)
                deleteat!(eeg_new.eeg_header[:samples_per_datarecord], idx2)
                deleteat!(eeg_new.eeg_header[:sampling_rate], idx2)
                deleteat!(eeg_new.eeg_header[:gain], idx2)
            end
        end 
    end

    # remove channel
    eeg_new.eeg_signals = eeg_new.eeg_signals[setdiff(1:end, (channel)), :, :]

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_delete_channel(EEG, $channel)")

    return eeg_new
end

"""
    eeg_delete_channel!(eeg; channel)

Remove `channel` from the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel index to be removed
"""
function eeg_delete_channel!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    typeof(channel) <: AbstractRange && (channel = collect(channel))
    channel_n = eeg_channel_n(eeg)
    length(channel) == channel_n && throw(ArgumentError("You cannot delete all channels."))

    length(channel) > 1 && (channel = sort!(channel, rev=true))

    if channel[end] < 1 || channel[1] > eeg_channel_n(eeg)
        throw(ArgumentError("channel does not match signal channels."))
    end

    # update headers
    eeg.eeg_header[:channel_n] = channel_n - length(channel)
    for idx1 in 1:length(channel)
        for idx2 in 1:channel_n
            if idx2 == channel[idx1]
                deleteat!(eeg.eeg_header[:labels], idx2)
                deleteat!(eeg.eeg_header[:channel_type], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_theta]) > 0) && deleteat!(eeg.eeg_header[:loc_theta], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_radius]) > 0) && deleteat!(eeg.eeg_header[:loc_radius], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_x]) > 0) && deleteat!(eeg.eeg_header[:loc_x], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_y]) > 0) && deleteat!(eeg.eeg_header[:loc_y], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_z]) > 0) && deleteat!(eeg.eeg_header[:loc_z], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_radius_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_radius_sph], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_theta_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_theta_sph], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_phi_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_phi_sph], idx2)
                deleteat!(eeg.eeg_header[:transducers], idx2)
                deleteat!(eeg.eeg_header[:physical_dimension], idx2)
                deleteat!(eeg.eeg_header[:physical_minimum], idx2)
                deleteat!(eeg.eeg_header[:physical_maximum], idx2)
                deleteat!(eeg.eeg_header[:digital_minimum], idx2)
                deleteat!(eeg.eeg_header[:digital_maximum], idx2)
                deleteat!(eeg.eeg_header[:prefiltering], idx2)
                deleteat!(eeg.eeg_header[:samples_per_datarecord], idx2)
                deleteat!(eeg.eeg_header[:sampling_rate], idx2)
                deleteat!(eeg.eeg_header[:gain], idx2)
            end
        end 
    end

    # remove channel
    eeg.eeg_signals = eeg.eeg_signals[setdiff(1:end, (channel)), :, :]

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_delete_channel!(EEG, $channel)")
end

"""
    eeg_keep_channel(eeg; channel)

Keep `channels` in the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel index to keep

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_keep_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    typeof(channel) <: AbstractRange && (channel = collect(channel))

    length(channel) > 1 && (channel = sort!(channel, rev=true))
    if channel[end] < 1 || channel[1] > eeg_channel_n(eeg)
        throw(ArgumentError("channel does not match signal channels."))
    end

    channel_list = collect(1:eeg_channel_n(eeg))
    channel_to_remove = setdiff(channel_list, channel)

    length(channel_to_remove) > 1 && (channel_to_remove = sort!(channel_to_remove, rev=true))

    eeg_new = deepcopy(eeg)
    channel_n = eeg_new.eeg_header[:channel_n]

    # update headers
    eeg_new.eeg_header[:channel_n] = channel_n - length(channel_to_remove)
    for idx1 in 1:length(channel_to_remove)
        for idx2 in channel_n:-1:1
            if idx2 == channel_to_remove[idx1]
                deleteat!(eeg_new.eeg_header[:labels], idx2)
                deleteat!(eeg_new.eeg_header[:channel_type], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_theta]) > 0) && deleteat!(eeg_new.eeg_header[:loc_theta], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_radius]) > 0) && deleteat!(eeg_new.eeg_header[:loc_radius], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_x]) > 0) && deleteat!(eeg_new.eeg_header[:loc_x], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_y]) > 0) && deleteat!(eeg_new.eeg_header[:loc_y], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_z]) > 0) && deleteat!(eeg_new.eeg_header[:loc_z], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_radius_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_radius_sph], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_theta_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_theta_sph], idx2)
                (eeg_new.eeg_header[:channel_locations] == true && length(eeg_new.eeg_header[:loc_phi_sph]) > 0) && deleteat!(eeg_new.eeg_header[:loc_phi_sph], idx2)
                deleteat!(eeg_new.eeg_header[:transducers], idx2)
                deleteat!(eeg_new.eeg_header[:physical_dimension], idx2)
                deleteat!(eeg_new.eeg_header[:physical_minimum], idx2)
                deleteat!(eeg_new.eeg_header[:physical_maximum], idx2)
                deleteat!(eeg_new.eeg_header[:digital_minimum], idx2)
                deleteat!(eeg_new.eeg_header[:digital_maximum], idx2)
                deleteat!(eeg_new.eeg_header[:prefiltering], idx2)
                deleteat!(eeg_new.eeg_header[:samples_per_datarecord], idx2)
                deleteat!(eeg_new.eeg_header[:sampling_rate], idx2)
                deleteat!(eeg_new.eeg_header[:gain], idx2)
            end
        end
    end

    # remove channel
    eeg_new.eeg_signals = eeg_new.eeg_signals[setdiff(1:end, (channel_to_remove)), :, :]

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_keep_channel(EEG, $channel)")

    return eeg_new
end

"""
    eeg_keep_channel!(eeg; channel)

Keep `channels` in the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel index to keep
"""
function eeg_keep_channel!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    typeof(channel) <: AbstractRange && (channel = collect(channel))

    length(channel) > 1 && (channel = sort!(channel, rev=true))
    if channel[end] < 1 || channel[1] > eeg_channel_n(eeg)
        throw(ArgumentError("channel does not match signal channels."))
    end

    channel_list = collect(1:eeg_channel_n(eeg))
    channel_to_remove = setdiff(channel_list, channel)

    length(channel_to_remove) > 1 && (channel_to_remove = sort!(channel_to_remove, rev=true))

    channel_n = eeg_channel_n(eeg)

    # update headers
    eeg.eeg_header[:channel_n] = channel_n - length(channel_to_remove)
    for idx1 in 1:length(channel_to_remove)
        for idx2 in 1:channel_n
            if idx2 == channel_to_remove[idx1]
                deleteat!(eeg.eeg_header[:labels], idx2)
                deleteat!(eeg.eeg_header[:channel_type], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_theta]) > 0) && deleteat!(eeg.eeg_header[:loc_theta], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_radius]) > 0) && deleteat!(eeg.eeg_header[:loc_radius], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_x]) > 0) && deleteat!(eeg.eeg_header[:loc_x], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_y]) > 0) && deleteat!(eeg.eeg_header[:loc_y], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_z]) > 0) && deleteat!(eeg.eeg_header[:loc_z], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_radius_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_radius_sph], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_theta_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_theta_sph], idx2)
                (eeg.eeg_header[:channel_locations] == true && length(eeg.eeg_header[:loc_phi_sph]) > 0) && deleteat!(eeg.eeg_header[:loc_phi_sph], idx2)
                deleteat!(eeg.eeg_header[:transducers], idx2)
                deleteat!(eeg.eeg_header[:physical_dimension], idx2)
                deleteat!(eeg.eeg_header[:physical_minimum], idx2)
                deleteat!(eeg.eeg_header[:physical_maximum], idx2)
                deleteat!(eeg.eeg_header[:digital_minimum], idx2)
                deleteat!(eeg.eeg_header[:digital_maximum], idx2)
                deleteat!(eeg.eeg_header[:prefiltering], idx2)
                deleteat!(eeg.eeg_header[:samples_per_datarecord], idx2)
                deleteat!(eeg.eeg_header[:sampling_rate], idx2)
                deleteat!(eeg.eeg_header[:gain], idx2)
            end
        end
    end

    # remove channel
    eeg.eeg_signals = eeg.eeg_signals[setdiff(1:end, (channel_to_remove)), :, :]

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_keep_channel!(EEG, channel=$channel)")
end

"""
    eeg_get_channel(eeg; channel)

Return the `channel` index / name.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`: channel name

# Returns

- `channel_idx::Int64`
"""
function eeg_get_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String})

    labels = eeg_labels(eeg)
    if typeof(channel) == String
        channel_idx = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                channel_idx = idx
            end
        end
        if channel_idx === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
        return channel_idx
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        end
        return labels[channel]
    end
end

"""
    eeg_rename_channel(eeg; channel, name)

Rename the `eeg` `channel`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`
- `name::String`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_rename_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, name::String)

    # create new dataset
    eeg_new = deepcopy(eeg)
    labels = eeg_labels(eeg_new)
    
    if typeof(channel) == String
        channel_found = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                labels[idx] = name
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        else
            labels[channel] = name
        end
    end
    eeg_new.eeg_header[:labels] = labels
    
    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_rename_channel(EEG, channel=$channel, name=$name)")

    return eeg_new
end

"""
    eeg_rename_channel!(eeg; channel, name)

Rename the `eeg` `channel`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`
- `name::String`
"""
function eeg_rename_channel!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, name::String)

    labels = eeg_labels(eeg)
    
    if typeof(channel) == String
        channel_found = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                labels[idx] = name
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        else
            labels[channel] = name
        end
    end
    eeg.eeg_header[:labels] = labels
    
    push!(eeg.eeg_header[:history], "eeg_rename_channel!(EEG, channel=$channel, name=$name)")
end

"""
    eeg_extract_channel(eeg; channel)

Extract `channel` number or name.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`

# Returns

- `channel::Vector{Float64}`
"""
function eeg_extract_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String})

    labels = eeg_labels(eeg)
    if typeof(channel) == String
        channel_idx = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                channel_idx = idx
            end
        end
        if channel_idx === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        end
        channel_idx = channel
    end    
    eeg_channel = reshape(eeg.eeg_signals[channel_idx, :, :], 1, eeg_epoch_len(eeg), eeg_epoch_n(eeg))

    return eeg_channel
end

"""
    eeg_history(eeg)

Show processing history.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_history(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:history]
end

"""
    eeg_labels(eeg)

Return `eeg` labels.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `labels::Vector{String}`
"""
function eeg_labels(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:labels]
end

"""
    eeg_sr(eeg)

Return `eeg` sampling rate.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `sr::Int64`
"""
function eeg_sr(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:sampling_rate][1]
end

"""
    eeg_channel_n(eeg; type=:eeg)

Return number of `eeg` channels of `type`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `type::Vector{Symbol}=:all`: channel type :all, :eeg, :ecg, :eog, :emg

# Returns

- `channel_n::Int64`
"""
function eeg_channel_n(eeg::NeuroAnalyzer.EEG; type::Symbol=:all)

    channel_n = 0
    for idx in 1:eeg.eeg_header[:channel_n]
        eeg.eeg_header[:channel_type][idx] == string(type) && (channel_n += 1)
    end
    type === :all && (channel_n = size(eeg.eeg_signals, 1))

    return channel_n
end

"""
    eeg_epoch_n(eeg)

Return number of `eeg` epochs.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `epoch_n::Int64`
"""
function eeg_epoch_n(eeg::NeuroAnalyzer.EEG)

    epoch_n = eeg.eeg_header[:epoch_n]

    return epoch_n
end

"""
    eeg_signal_len(eeg)

Return length of `eeg` signal.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `signal_len::Int64`
"""
function eeg_signal_len(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:eeg_duration_samples]
end

"""
    eeg_epoch_len(eeg)

Return length of `eeg` signal.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `epoch_len::Int64`
"""
function eeg_epoch_len(eeg::NeuroAnalyzer.EEG)

    epoch_len = eeg.eeg_header[:epoch_duration_samples]

    return epoch_len
end

"""
    eeg_info(eeg)

Show info.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_info(eeg::NeuroAnalyzer.EEG)

    println("          EEG file name: $(eeg.eeg_header[:eeg_filename])")
    println("        EEG file format: $(eeg.eeg_header[:eeg_filetype])")
    println("          EEG size [MB]: $(eeg.eeg_header[:eeg_filesize_mb])")
    println("   EEG memory size [MB]: $(round(Base.summarysize(eeg) / 1024^2, digits=2))")
    println("     Sampling rate (Hz): $(eeg_sr(eeg))")
    if eeg.eeg_header[:annotations] == false
        println("            Annotations: no")
    else
        println("            Annotations: yes")
    end
    println("Signal length (samples): $(eeg_signal_len(eeg))")
    println("Signal length (seconds): $(round(eeg.eeg_header[:eeg_duration_seconds], digits=2))")
    println("     Number of channels: $(eeg_channel_n(eeg))")
    println("       Number of epochs: $(eeg_epoch_n(eeg))")
    println(" Epoch length (samples): $(eeg_epoch_len(eeg))")
    println(" Epoch length (seconds): $(round(eeg.eeg_header[:epoch_duration_seconds], digits=2))")
    if eeg.eeg_header[:reference] == ""
        println("         Reference type: unknown")
    else
        println("         Reference type: $(eeg.eeg_header[:reference])")
    end
    if length(eeg_labels(eeg)) == 0
        println("                 Labels: no")
    else
        println("                 Labels: yes")
    end
    if eeg.eeg_header[:channel_locations] == false
        println("      Channel locations: no")
    else
        println("      Channel locations: yes")
    end
    if eeg.eeg_header[:components] != []
        print("             Components: ")
        c = eeg_list_components(eeg)
        if length(c) == 1
            println(c[1])
        else
            for idx in 1:(length(c) - 1)
                print(c[idx], ", ")
            end
            println(c[end])
        end
    else
        println("             Components: no")
    end
    println("               Channels:")
    for idx in 1:length(eeg.eeg_header[:labels])
        println("                channel: $idx\tlabel: $(rpad(eeg.eeg_header[:labels][idx], 16, " "))\ttype: $(uppercase(eeg.eeg_header[:channel_type][idx]))")
    end
end

"""
    eeg_epochs(eeg; epoch_n=nothing, epoch_len=nothing, average=false)

Splits `eeg` into epochs.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch_n::Union{Int64, Nothing}`: number of epochs
- `epoch_len::Union{Int64, Nothing}`: epoch length in samples
- `average::Bool`: average all epochs, return one averaged epoch; if false than return array of epochs, each row is one epoch

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_epochs(eeg::NeuroAnalyzer.EEG; epoch_n::Union{Int64, Nothing}=nothing, epoch_len::Union{Int64, Nothing}=nothing, average::Bool=false)

    # unsplit epochs
    s_merged = reshape(eeg.eeg_signals,
                       eeg_channel_n(eeg),
                       eeg_epoch_len(eeg) * eeg_epoch_n(eeg))
    
    # split into epochs
    s_split = _make_epochs(s_merged, epoch_n=epoch_n, epoch_len=epoch_len, average=average)

    # convert into Array{Float64, 3}
    s_split = reshape(s_split, size(s_split, 1), size(s_split, 2), size(s_split, 3))

    # create new dataset
    epoch_n = size(s_split, 3)
    epoch_duration_samples = size(s_split, 2)
    epoch_duration_seconds = size(s_split, 2) / eeg.eeg_header[:sampling_rate][1]
    eeg_duration_samples = size(s_split, 2) * size(s_split, 3)
    eeg_duration_seconds = eeg_duration_samples / eeg.eeg_header[:sampling_rate][1]
    eeg_time = collect(0:(1 / eeg.eeg_header[:sampling_rate][1]):epoch_duration_seconds)
    eeg_time = eeg_time[1:(end - 1)]
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_split
    eeg_new.eeg_time = eeg_time

    # update epochs time
    fs = eeg_sr(eeg_new)
    ts = eeg.eeg_epochs_time[1]
    new_epochs_time = linspace(ts, ts + (epoch_duration_samples / fs), epoch_duration_samples)
    eeg_new.eeg_epochs_time = new_epochs_time

    eeg_new.eeg_header[:eeg_duration_samples] = eeg_duration_samples
    eeg_new.eeg_header[:eeg_duration_seconds] = eeg_duration_seconds
    eeg_new.eeg_header[:epoch_n] = epoch_n
    eeg_new.eeg_header[:epoch_duration_samples] = epoch_duration_samples
    eeg_new.eeg_header[:epoch_duration_seconds] = epoch_duration_seconds

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_epochs(EEG, epoch_n=$epoch_n, epoch_len=$epoch_len, average=$average)")

    return eeg_new
end

"""
    eeg_epochs!(eeg; epoch_n=nothing, epoch_len=nothing, average=false)

Splits `eeg` into epochs.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch_n::Union{Int64, Nothing}`: number of epochs
- `epoch_len::Union{Int64, Nothing}`: epoch length in samples
- `average::Bool`: average all epochs, return one averaged epoch
"""
function eeg_epochs!(eeg::NeuroAnalyzer.EEG; epoch_n::Union{Int64, Nothing}=nothing, epoch_len::Union{Int64, Nothing}=nothing, average::Bool=false)

    # unsplit epochs
    s_merged = reshape(eeg.eeg_signals,
                       eeg_channel_n(eeg),
                       eeg_epoch_len(eeg) * eeg_epoch_n(eeg))
    
    # split into epochs
    s_split = _make_epochs(s_merged, epoch_n=epoch_n, epoch_len=epoch_len, average=average)

    # convert into Array{Float64, 3}
    s_split = reshape(s_split, size(s_split, 1), size(s_split, 2), size(s_split, 3))

    # create new dataset
    epoch_n = size(s_split, 3)
    epoch_duration_samples = size(s_split, 2)
    epoch_duration_seconds = size(s_split, 2) / eeg.eeg_header[:sampling_rate][1]
    eeg_duration_samples = size(s_split, 2) * size(s_split, 3)
    eeg_duration_seconds = eeg_duration_samples / eeg.eeg_header[:sampling_rate][1]
    eeg_time = collect(0:(1 / eeg.eeg_header[:sampling_rate][1]):epoch_duration_seconds)
    eeg_time = eeg_time[1:(end - 1)]
    eeg.eeg_signals = s_split
    eeg.eeg_time = eeg_time

    # update epochs time
    fs = eeg_sr(eeg)
    ts = eeg.eeg_epochs_time[1]
    new_epochs_time = linspace(ts, ts + (epoch_duration_samples / fs), epoch_duration_samples)
    eeg.eeg_epochs_time = new_epochs_time

    eeg.eeg_header[:eeg_duration_samples] = eeg_duration_samples
    eeg.eeg_header[:eeg_duration_seconds] = eeg_duration_seconds
    eeg.eeg_header[:epoch_n] = epoch_n
    eeg.eeg_header[:epoch_duration_samples] = epoch_duration_samples
    eeg.eeg_header[:epoch_duration_seconds] = epoch_duration_seconds

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_epochs!(EEG, epoch_n=$epoch_n, epoch_len=$epoch_len, average=$average)")
end

"""
    eeg_extract_epoch(eeg; epoch)

Extract the `epoch` epoch.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch::Int64`: epoch index

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_extract_epoch(eeg::NeuroAnalyzer.EEG; epoch::Int64)

    if epoch < 1 || epoch > eeg_epoch_n(eeg)
        throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    end

    s_new = reshape(eeg.eeg_signals[:, :, epoch], eeg_channel_n(eeg), eeg_signal_len(eeg), 1)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_new
    eeg_new.eeg_epochs_time = eeg.eeg_epochs_time
    eeg_new.eeg_header[:epoch_n] = 1
    eeg_new.eeg_header[:eeg_duration_samples] = eeg_new.eeg_header[:epoch_duration_samples]
    eeg_new.eeg_header[:eeg_duration_seconds] = eeg_new.eeg_header[:epoch_duration_seconds]

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_get_epoch(EEG, epoch=$epoch)")

    return eeg_new
end

"""
    eeg_trim(eeg:EEG; len, offset=0, from=:start, keep_epochs::Bool=true)

Remove `len` samples from the beginning + `offset` (`from` = :start, default) or end (`from` = :end) of the `eeg`.

# Arguments

- `eeg:EEG`
- `len::Int64`: number of samples to remove
- `offset::Int64`: offset from which trimming starts, only works for `from` = :start
- `from::Symbol[:start, :end]`: trims from the signal start (default) or end
- `keep_epochs::Bool`: remove epochs containing signal to trim (keep_epochs=true) or remove signal and remove epoching

# Returns

- `eeg:EEG`
"""
function eeg_trim(eeg::NeuroAnalyzer.EEG; len::Int64, offset::Int64=1, from::Symbol=:start, keep_epochs::Bool=true)

    eeg_epoch_n(eeg) == 1 && (keep_epochs = false)

    if keep_epochs == false
        @info "This operation will remove epochs, to keep epochs use keep_epochs=true."

        eeg_new = deepcopy(eeg)
        eeg_epoch_n(eeg) > 1 && (eeg_epochs!(eeg_new, epoch_n=1))
        channel_n = eeg_channel_n(eeg_new)
        epoch_n = eeg_epoch_n(eeg_new)
        s_trimmed = zeros(channel_n, (size(eeg_new.eeg_signals, 2) - len), epoch_n)
        @inbounds @simd for epoch_idx in 1:epoch_n
            Threads.@threads for idx in 1:channel_n
                s_trimmed[idx, :, epoch_idx] = @views s_trim(eeg_new.eeg_signals[idx, :, epoch_idx], len=len, offset=offset, from=from)
            end
        end
        t_trimmed = collect(0:(1 / eeg_sr(eeg)):(size(s_trimmed, 2) / eeg_sr(eeg)))[1:(end - 1)]
        eeg_new.eeg_signals = s_trimmed
        eeg_new.eeg_time = t_trimmed
        eeg_new.eeg_epochs_time = t_trimmed
        eeg_new.eeg_header[:eeg_duration_samples] -= len
        eeg_new.eeg_header[:eeg_duration_seconds] -= len * (1 / eeg_sr(eeg))
        eeg_new.eeg_header[:epoch_duration_samples] -= len
        eeg_new.eeg_header[:epoch_duration_seconds] -= len * (1 / eeg_sr(eeg))
    else
        if from === :start
            epoch_from = floor(Int64, (offset / eeg_epoch_len(eeg)) + 1)
            epoch_to = ceil(Int64, ((offset + len) / eeg_epoch_len(eeg)) + 1)
        else
            epoch_from = floor(Int64, ((eeg.eeg_header[:eeg_duration_samples] - len) / eeg_epoch_len(eeg)) + 1)
            epoch_to = eeg_epoch_n(eeg)
        end
        eeg_new = eeg_delete_epoch(eeg, epoch=epoch_from:epoch_to)
    end

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_trim(EEG, len=$len, offset=$offset, from=$from, keep_epochs=$keep_epochs)")

    return eeg_new
end

"""
    eeg_trim!(eeg:EEG; len, offset=0, from=:start, keep_epochs::Bool=true)

Remove `len` samples from the beginning + `offset` (`from` = :start, default) or end (`from` = :end) of the `eeg`.

# Arguments

- `eeg:EEG`
- `len::Int64`: number of samples to remove
- `offset::Int64`: offset from which trimming starts, only works for `from` = :start
- `from::Symbol[:start, :end]`: trims from the signal start (default) or end
- `keep_epochs::Bool`: remove epochs containing signal to trim (keep_epochs=true) or remove signal and remove epoching
"""
function eeg_trim!(eeg::NeuroAnalyzer.EEG; len::Int64, offset::Int64=1, from::Symbol=:start, keep_epochs::Bool=true)

    eeg_len = eeg_signal_len(eeg)
    from in [:start, :end] || throw(ArgumentError("from must be :start or :end."))
    len < 0 && throw(ArgumentError("len must be ≥ 1."))
    len >= eeg_len && throw(ArgumentError("len must be < $(eeg_len)."))
    offset < 0 && throw(ArgumentError("offset must be ≥ 1."))
    offset >= eeg_len - 1 && throw(ArgumentError("offset must be < $(eeg_len)."))
    (from ===:start && 1 + offset + len > eeg_len) && throw(ArgumentError("offset + len must be < $(eeg_len)."))

    eeg_epoch_n(eeg) == 1 && (keep_epochs = false)
    
    if keep_epochs == false
        @info "This operation will remove epochs, to keep epochs use keep_epochs=true."
        eeg_epoch_n(eeg) > 1 && (eeg_epochs!(eeg, epoch_n=1))
        channel_n = eeg_channel_n(eeg)
        epoch_n = eeg_epoch_n(eeg)
        s_trimmed = zeros(channel_n, (size(eeg.eeg_signals, 2) - len), epoch_n)
        @inbounds @simd for epoch_idx in 1:epoch_n
            Threads.@threads for idx in 1:channel_n
                s_trimmed[idx, :, epoch_idx] = @views s_trim(eeg.eeg_signals[idx, :, epoch_idx], len=len, offset=offset, from=from)
            end
        end
        t_trimmed = collect(0:(1 / eeg_sr(eeg)):(size(s_trimmed, 2) / eeg_sr(eeg)))[1:(end - 1)]
        eeg.eeg_signals = s_trimmed
        eeg.eeg_time = t_trimmed
        eeg.eeg_epochs_time = t_trimmed
        eeg.eeg_header[:eeg_duration_samples] -= len
        eeg.eeg_header[:eeg_duration_seconds] -= len * (1 / eeg_sr(eeg))
        eeg.eeg_header[:epoch_duration_samples] -= len
        eeg.eeg_header[:epoch_duration_seconds] -= len * (1 / eeg_sr(eeg))
    else
        if from === :start
            epoch_from = floor(Int64, (offset / eeg_epoch_len(eeg))) + 1
            epoch_to = floor(Int64, ((offset + len) / eeg_epoch_len(eeg))) + 1
        else
            epoch_from = floor(Int64, ((eeg.eeg_header[:eeg_duration_samples] - len) / eeg_epoch_len(eeg)) + 1)
            epoch_to = eeg_epoch_n(eeg)
        end
        eeg_delete_epoch!(eeg, epoch=epoch_from:epoch_to)
    end

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_trim!(EEG, len=$len, offset=$offset, from=$from, keep_epochs=$keep_epochs)")
end

"""
    eeg_edit_header(eeg; field, value)

Change value of `eeg` `field` to `value`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `field::Symbol`
- `value::Any`

# Returns

- `eeg:EEG`
"""
function eeg_edit_header(eeg::NeuroAnalyzer.EEG; field::Symbol, value::Any)

    field === nothing && throw(ArgumentError("field cannot be empty."))
    value === nothing && throw(ArgumentError("value cannot be empty."))

    eeg_new = deepcopy(eeg)
    fields = keys(eeg_new.eeg_header)
    field in fields || throw(ArgumentError("$field does not exist."))
    typeof(eeg_new.eeg_header[field]) == typeof(value) || throw(ArgumentError("field type ($(typeof(eeg_new.eeg_header[field]))) does not mach value type ($(typeof(value)))."))
    eeg_new.eeg_header[field] = value
    push!(eeg_new.eeg_header[:history], "eeg_edit(EEG, field=$field, value=$value)")    

    return eeg_new
end

"""
    eeg_edit_header!(eeg; field, value)

Change value of `eeg` `field` to `value`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `field::Symbol`
- `value::Any`

# Returns

- `eeg:EEG`
"""
function eeg_edit_header!(eeg::NeuroAnalyzer.EEG; field::Symbol, value::Any)

    value === nothing && throw(ArgumentError("value cannot be empty."))

    fields = keys(eeg.eeg_header)
    field in fields || throw(ArgumentError("field does not exist."))
    typeof(eeg.eeg_header[field]) == typeof(value) || throw(ArgumentError("field type ($(typeof(eeg_new.eeg_header[field]))) does not mach value type ($(typeof(value)))."))
    eeg.eeg_header[field] = value
    push!(eeg.eeg_header[:history], "eeg_edit!(EEG, field=$field, value=$value)")    
end

"""
    eeg_show_header(eeg)

Show keys and values of `eeg` header.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_show_header(eeg::NeuroAnalyzer.EEG)

    for (key, value) in eeg.eeg_header
        println("$key: $value")
    end
end

"""
    eeg_delete_epoch(eeg; epoch)

Remove `epoch` from the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch::Union{Int64, Vector{Int64}, AbstractRange}`: epoch index to be removed, vector of numbers or range

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_epoch(eeg::NeuroAnalyzer.EEG; epoch::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_epoch_n(eeg) == 1 && throw(ArgumentError("You cannot delete the last epoch."))

    if typeof(epoch) <: AbstractRange
        epoch = collect(epoch)
    end

    length(epoch) == eeg_epoch_n(eeg) && throw(ArgumentError("You cannot delete all epochs."))

    length(epoch) > 1 && (epoch = sort!(epoch, rev=true))

    if epoch[end] < 1 || epoch[1] > eeg_epoch_n(eeg)
        throw(ArgumentError("epoch does not match signal epochs."))
    end

    eeg_new = deepcopy(eeg)

    # remove epoch
    eeg_new.eeg_signals = eeg_new.eeg_signals[:, :, setdiff(1:end, (epoch))]

    # update headers
    eeg_new.eeg_header[:epoch_n] -= length(epoch)
    epoch_n = eeg_new.eeg_header[:epoch_n]
    eeg_new.eeg_header[:eeg_duration_samples] = epoch_n * size(eeg.eeg_signals, 2)
    eeg_new.eeg_header[:eeg_duration_seconds] = round((epoch_n * size(eeg.eeg_signals, 2)) / eeg_sr(eeg), digits=2)
    eeg_new.eeg_header[:epoch_duration_samples] = size(eeg.eeg_signals, 2)
    eeg_new.eeg_header[:epoch_duration_seconds] = round(size(eeg.eeg_signals, 2) / eeg_sr(eeg), digits=2)

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_delete_epoch(EEG, $epoch)")
    
    return eeg_new
end

"""
    eeg_delete_epoch!(eeg; epoch)

Remove `epoch` from the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch::Union{Int64, Vector{Int64}, AbstractRange}`: epoch index to be removed, vector of numbers or range
"""
function eeg_delete_epoch!(eeg::NeuroAnalyzer.EEG; epoch::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_epoch_n(eeg) == 1 && throw(ArgumentError("You cannot delete the last epoch."))

    if typeof(epoch) <: AbstractRange
        epoch = collect(epoch)
    end

    length(epoch) == eeg_epoch_n(eeg) && throw(ArgumentError("You cannot delete all epochs."))

    length(epoch) > 1 && (epoch = sort!(epoch, rev=true))

    if epoch[end] < 1 || epoch[1] > eeg_epoch_n(eeg)
        throw(ArgumentError("epoch does not match signal epochs."))
    end

    # remove epoch
    eeg.eeg_signals = eeg.eeg_signals[:, :, setdiff(1:end, (epoch))]

    # update headers
    eeg.eeg_header[:epoch_n] -= length(epoch)
    epoch_n = eeg.eeg_header[:epoch_n]
    eeg.eeg_header[:eeg_duration_samples] = epoch_n * size(eeg.eeg_signals, 2)
    eeg.eeg_header[:eeg_duration_seconds] = round((epoch_n * size(eeg.eeg_signals, 2)) / eeg_sr(eeg), digits=2)
    eeg.eeg_header[:epoch_duration_samples] = size(eeg.eeg_signals, 2)
    eeg.eeg_header[:epoch_duration_seconds] = round(size(eeg.eeg_signals, 2) / eeg_sr(eeg), digits=2)

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_delete_epoch!(EEG, $epoch)")
end

"""
    eeg_keep_epoch(eeg; epoch)

Keep `epoch` in the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch::Union{Int64, Vector{Int64}, AbstractRange}`: epoch index to keep, vector of numbers or range

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_keep_epoch(eeg::NeuroAnalyzer.EEG; epoch::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_epoch_n(eeg) == 1 && throw(ArgumentError("EEG contains only one epoch."))

    if typeof(epoch) <: AbstractRange
        epoch = collect(epoch)
    end

    length(epoch) > 1 && (epoch = sort!(epoch, rev=true))
    if epoch[end] < 1 || epoch[1] > eeg_epoch_n(eeg)
        throw(ArgumentError("epoch does not match signal epochs."))
    end

    epoch_list = collect(1:eeg_epoch_n(eeg))
    epoch_to_remove = setdiff(epoch_list, epoch)

    length(epoch_to_remove) > 1 && (epoch_to_remove = sort!(epoch_to_remove, rev=true))

    eeg_new = deepcopy(eeg)

    # remove epoch
    eeg_new.eeg_signals = eeg_new.eeg_signals[:, :, setdiff(1:end, (epoch_to_remove))]

    # update headers
    eeg_new.eeg_header[:epoch_n] = eeg_new.eeg_header[:epoch_n] - length(epoch_to_remove)
    epoch_n = eeg_new.eeg_header[:epoch_n]
    eeg_new.eeg_header[:eeg_duration_samples] = epoch_n * eeg_epoch_len(eeg)
    eeg_new.eeg_header[:eeg_duration_seconds] = round(epoch_n * (eeg_epoch_len(eeg) / eeg_sr(eeg)), digits=2)
    eeg_new.eeg_header[:epoch_duration_samples] = eeg_epoch_len(eeg)
    eeg_new.eeg_header[:epoch_duration_seconds] = round(eeg_epoch_len(eeg) / eeg_sr(eeg), digits=2)

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_keep_epoch(EEG, $epoch)")    

    return eeg_new
end

"""
    eeg_keep_epoch!(eeg; epoch)

Keep `epoch` in the `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `epoch::Union{Int64, Vector{Int64}, AbstractRange}`: epoch index to keep, vector of numbers or range
"""
function eeg_keep_epoch!(eeg::NeuroAnalyzer.EEG; epoch::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_epoch_n(eeg) == 1 && throw(ArgumentError("EEG contains only one epoch."))

    if typeof(epoch) <: AbstractRange
        epoch = collect(epoch)
    end

    length(epoch) > 1 && (epoch = sort!(epoch, rev=true))
    if epoch[end] < 1 || epoch[1] > eeg_epoch_n(eeg)
        throw(ArgumentError("epoch does not match signal epochs."))
    end

    epoch_list = collect(1:eeg_epoch_n(eeg))
    epoch_to_remove = setdiff(epoch_list, epoch)

    length(epoch_to_remove) > 1 && (epoch_to_remove = sort!(epoch_to_remove, rev=true))

    # remove epoch
    eeg.eeg_signals = eeg.eeg_signals[:, :, setdiff(1:end, (epoch_to_remove))]

    # update headers
    eeg.eeg_header[:epoch_n] = eeg_epoch_n(eeg) - length(epoch_to_remove)
    epoch_n = eeg_epoch_n(eeg)
    eeg.eeg_header[:eeg_duration_samples] = epoch_n * eeg_epoch_len(eeg)
    eeg.eeg_header[:eeg_duration_seconds] = round(epoch_n * (eeg_epoch_len(eeg) / eeg_sr(eeg)), digits=2)
    eeg.eeg_header[:epoch_duration_samples] = eeg_epoch_len(eeg)
    eeg.eeg_header[:epoch_duration_seconds] = round(eeg_epoch_len(eeg) / eeg_sr(eeg), digits=2)

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_keep_epoch(EEG, $epoch)")
end

"""
    eeg_detect_bad_epochs(eeg; method=[:flat, :rmse, :rmsd, :euclid, :p2p], ch_t)

Detect bad `eeg` epochs based on:
- flat channel(s)
- RMSE
- RMSD
- Euclidean distance
- peak-to-peak amplitude

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `method::Vector{Symbol}=[:flat, :rmse, :rmsd, :euclid, :p2p]`
- `ch_t::Float64`: percentage of bad channels to mark the epoch as bad

# Returns

- `bad_epochs_idx::Vector{Int64}`
"""
function eeg_detect_bad_epochs(eeg::NeuroAnalyzer.EEG; method::Vector{Symbol}=[:flat, :rmse, :rmsd, :euclid, :p2p], ch_t::Float64=0.1)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    for idx in method
        idx in [:flat, :rmse, :rmsd, :euclid, :p2p] || throw(ArgumentError("method must be :flat, :rmse, :rmsd, :euclid, :p2p"))
    end

    bad_epochs_idx = zeros(Int64, eeg_epoch_n(eeg))

    if :flat in method
        bad_epochs = s_detect_epoch_flat(eeg.eeg_signals)
        bad_epochs_idx[bad_epochs .> ch_t] .= 1
    end

    if :rmse in method
        bad_epochs = s_detect_epoch_rmse(eeg.eeg_signals)
        bad_epochs_idx[bad_epochs .> ch_t] .= 1
    end

    if :rmsd in method
        bad_epochs = s_detect_epoch_rmsd(eeg.eeg_signals)
        bad_epochs_idx[bad_epochs .> ch_t] .= 1
    end

    if :euclid in method
        bad_epochs = s_detect_epoch_euclid(eeg.eeg_signals)
        bad_epochs_idx[bad_epochs .> ch_t] .= 1
    end

    if :p2p in method
        bad_epochs = s_detect_epoch_p2p(eeg.eeg_signals)
        bad_epochs_idx[bad_epochs .> ch_t] .= 1
    end

    return bad_epochs_idx
end

"""
    eeg_add_labels(eeg::NeuroAnalyzer.EEG, labels::Vector{String})

Add `labels` to `eeg` channels.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `labels::Vector{String}`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_add_labels(eeg::NeuroAnalyzer.EEG, labels::Vector{String})

    length(labels) == eeg_channel_n(eeg) || throw(ArgumentError("labels length must be $(eeg_channel_n(eeg))."))
    
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:labels] = labels

    push!(eeg_new.eeg_header[:history], "eeg_add_labels(EEG, labels=$labels")
 
    return eeg_new
end

"""
    eeg_add_labels!(eeg::NeuroAnalyzer.EEG, labels::Vector{String})

Add `labels` to `eeg` channels.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `labels::Vector{String}`
"""
function eeg_add_labels!(eeg::NeuroAnalyzer.EEG, labels::Vector{String})

    length(labels) == eeg_channel_n(eeg) || throw(ArgumentError("labels length must be $(eeg_channel_n(eeg))."))
    eeg.eeg_header[:labels] = labels
    push!(eeg.eeg_header[:history], "eeg_add_labels(EEG, labels=$labels")
    end

"""
    eeg_edit_channel(eeg; channel, field, value)
Edits `eeg` `channel` properties.

# Arguments

- `eeg:EEG`
- `channel::Int64`
- `field::Any`
- `value::Any`

# Returns

- `eeg_new::NeuroAnalyzer.EEG`
"""
function eeg_edit_channel(eeg::NeuroAnalyzer.EEG; channel::Int64, field::Any, value::Any)
    
    field === nothing && throw(ArgumentError("field cannot be empty."))
    value === nothing && throw(ArgumentError("value cannot be empty."))
    (channel < 0 || channel > eeg_channel_n(eeg, type=:all)) && throw(ArgumentError("channel must be > 0 and ≤ $(eeg_channel_n(eeg, type=:all))."))
    
    field in [:channel_type, :loc_theta, :loc_radius, :loc_x, :loc_y, :loc_z, :loc_radius_sph, :loc_theta_sph, :loc_phi_sph, :labels] || throw(ArgumentError("field must be: :channel_type, :loc_theta, :loc_radius, :loc_x, :loc_y, :loc_z, :loc_radius_sph, :loc_theta_sph, :loc_phi_sph, :labels."))

    eeg_new = deepcopy(eeg)
    typeof(eeg_new.eeg_header[field][channel]) == typeof(value) || throw(ArgumentError("field type ($(eltype(eeg_new.eeg_header[field]))) does not mach value type ($(typeof(value)))."))
    eeg_new.eeg_header[field][channel] = value

    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_edit_channel(EEG, channel=$channel, field=$field, value=$value)")   

    return eeg_new
end

"""
    eeg_edit_channel!(eeg; channel, field, value)

Edit `eeg` `channel` properties.

# Arguments

- `eeg:EEG`
- `channel::Int64`
- `field::Any`
- `value::Any`
"""
function eeg_edit_channel!(eeg::NeuroAnalyzer.EEG; channel::Int64, field::Any, value::Any)
    
    field === nothing && throw(ArgumentError("field cannot be empty."))
    value === nothing && throw(ArgumentError("value cannot be empty."))
    (channel < 0 || channel > eeg_channel_n(eeg, type=:all)) && throw(ArgumentError("channel must be > 0 and ≤ $(eeg_channel_n(eeg, type=:all))."))
    
    field in [:channel_type, :loc_theta, :loc_radius, :loc_x, :loc_y, :loc_z, :loc_radius_sph, :loc_theta_sph, :loc_phi_sph, :labels] || throw(ArgumentError("field must be: :channel_type, :loc_theta, :loc_radius, :loc_x, :loc_y, :loc_z, :loc_radius_sph, :loc_theta_sph, :loc_phi_sph, :labels."))

    typeof(eeg.eeg_header[field][channel]) == typeof(value) || throw(ArgumentError("field type ($(eltype(eeg.eeg_header[field]))) does not mach value type ($(typeof(value)))."))
    eeg.eeg_header[field][channel] = value

    push!(eeg.eeg_header[:history], "eeg_edit_channel(EEG, channel=$channel, field=$field, value=$value)")
end

"""
    eeg_keep_channel_type(eeg; type)

Keep `type` channels.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `type::Symbol=:eeg`: type of channels to keep

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_keep_channel_type(eeg::NeuroAnalyzer.EEG; type::Symbol=:eeg)

    string(type) in eeg.eeg_header[:channel_type] || throw(ArgumentError("EEG does not contain channel type $type, available types are: $(unique(eeg.eeg_header[:channel_type]))."))
    eeg_channels_idx = Vector{Int64}()
    for idx in 1:eeg_channel_n(eeg, type=:all)
        eeg.eeg_header[:channel_type][idx] === string(type) && push!(eeg_channels_idx, idx)
    end
    eeg_new = eeg_keep_channel(eeg, channel=eeg_channels_idx)
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_keep_channel_type(EEG, type=$type")

    return eeg_new
end

"""
    eeg_keep_channel_type!(eeg)

Keep `type` channels.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `type::Symbol=:eeg`: type of channels to keep
"""
function eeg_keep_channel_type!(eeg::NeuroAnalyzer.EEG; type::Symbol=:eeg)

    string(type) in eeg.eeg_header[:channel_type] || throw(ArgumentError("EEG does not contain channel type $type, available types are: $(unique(eeg.eeg_header[:channel_type]))."))
    eeg_channels_idx = Vector{Int64}()
    for idx in 1:eeg_channel_n(eeg, type=:all)
        eeg.eeg_header[:channel_type][idx] === string(type) && push!(eeg_channels_idx, idx)
    end
    eeg_keep_channel!(eeg, channel=eeg_channels_idx)
    push!(eeg.eeg_header[:history], "eeg_keep_channel_type!(EEG, type=$type")
end

"""
    eeg_view_note(eeg)

Return `eeg` note.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_view_note(eeg::NeuroAnalyzer.EEG)

    return eeg.eeg_header[:note]
end

"""
    eeg_copy(eeg)

Make copy of `eeg`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `eeg_copy::NeuroAnalyzer.EEG`
"""
function eeg_copy(eeg::NeuroAnalyzer.EEG)
    
    return deepcopy(eeg)
end

"""
    eeg_epochs_time(eeg; ts)

Edit `eeg` epochs time start.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `ts::Real`: time start in seconds

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_epochs_time(eeg::NeuroAnalyzer.EEG; ts::Real)

    epoch_n = eeg_epoch_n(eeg)
    epoch_len = eeg_epoch_len(eeg)
    fs = eeg_sr(eeg)
    new_epochs_time = linspace(ts, ts + (epoch_len / fs), epoch_len)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_epochs_time = new_epochs_time
    push!(eeg_new.eeg_header[:history], "eeg_epochs_time(EEG, ts=$ts)")

    return eeg_new
end

"""
    eeg_epochs_time!(eeg; ts)

Edit `eeg` epochs time start.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `ts::Real`: time start in seconds

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_epochs_time!(eeg::NeuroAnalyzer.EEG; ts::Real)

    epoch_n = eeg_epoch_n(eeg)
    epoch_len = eeg_epoch_len(eeg)
    fs = eeg_sr(eeg)
    new_epochs_time = linspace(ts, ts + (epoch_len / fs), epoch_len)
    eeg.eeg_epochs_time = new_epochs_time
    push!(eeg.eeg_header[:history], "eeg_epochs_time!(EEG, ts=$ts)")
end

"""
    eeg_add_note(eeg; note)

Return `eeg` note.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `note::String`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_add_note(eeg::NeuroAnalyzer.EEG; note::String)

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:note] = note

    return eeg_new
end

"""
    eeg_add_note!(eeg; note)

Return `eeg` note.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `note::String`
"""
function eeg_add_note!(eeg::NeuroAnalyzer.EEG; note::String)

    eeg.eeg_header[:note] = note
    end

"""
    eeg_delete_note(eeg)

Return `eeg` note.

# Arguments

- `eeg::NeuroAnalyzer.EEG`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_note(eeg::NeuroAnalyzer.EEG)

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:note] = ""

    return eeg_new
end

"""
    eeg_delete_note!(eeg)

Return `eeg` note.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_note!(eeg::NeuroAnalyzer.EEG)

    eeg.eeg_header[:note] = ""
    end

"""
    eeg_replace_channel(eeg; channel, signal)

Replace the `channel` index / name with `signal`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`: channel name
- `signal::Array{Float64, 3}

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_replace_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, signal::Array{Float64, 3})


    channel_idx = nothing
    labels = eeg_labels(eeg)
    if typeof(channel) == String
        for idx in 1:length(labels)
            if channel == labels[idx]
                channel_idx = idx
            end
        end
        channel_idx === nothing && throw(ArgumentError("channel name does not match signal labels."))
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        end
        channel_idx = channel
    end

    eeg_new = deepcopy(eeg)
    size(signal) == (1, eeg_epoch_len(eeg_new), eeg_epoch_n(eeg_new)) || throw(ArgumentError("signal size must be the same as EEG channel size ($(size(eeg_new.eeg_signals[channel_idx, :, :]))."))
    eeg_new.eeg_signals[channel_idx, :, :] = signal
    eeg_reset_components!(eeg_new)

    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_replace_channel(EEG, channel=$channel, signal=$signal")

    return eeg_new
end

"""
    eeg_replace_channel!(eeg; channel, signal)

Replace the `channel` index / name with `signal`.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`: channel name
- `signal::Array{Float64, 3}
"""
function eeg_replace_channel!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, signal::Array{Float64, 3})

    labels = eeg_labels(eeg)
    channel_idx = nothing
    if typeof(channel) == String
        for idx in 1:length(labels)
            if channel == labels[idx]
                channel_idx = idx
            end
        end
        channel_idx === nothing && throw(ArgumentError("channel name does not match signal labels."))
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        end
        channel_idx = channel
    end

    size(signal) == (1, eeg_epoch_len(eeg_new), eeg_epoch_n(eeg_new)) || throw(ArgumentError("signal size must be the same as EEG channel size ($(size(eeg.eeg_signals[channel_idx, :, :]))."))
    eeg.eeg_signals[channel_idx, :, :] = signal
    eeg_reset_components!(eeg)

    # add entry to :history field
    push!(eeg.eeg_header[:history], "eeg_replace_channel(EEG, channel=$channel, signal=$signal")
end

"""
    eeg_interpolate_channel(eeg; channel, m, q)

Interpolate `eeg` channel using planar interpolation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}}`: channel number(s) to interpolate
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `q::Float64=1.0`: interpolation quality (0 to 1.0)

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_interpolate_channel(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}}, m::Symbol=:shepard, q::Float64=1.0)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG)."))
    m in [:shepard, :mq, :tp] || throw(ArgumentError("m must be :shepard, :mq or :tp."))
    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() or eeg_add_electrodes() first."))
    for idx in 1:length(channel)
        (channel[idx] < 1 || channel[idx] > eeg_channel_n(eeg)) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))
    end
    typeof(channel) == Vector{Int64} && sort!(channel, rev=true)

    eeg_tmp = eeg_delete_channel(eeg, channel=channel).eeg_signals
    eeg_new = deepcopy(eeg)

    loc_x = zeros(eeg_channel_n(eeg))
    loc_y = zeros(eeg_channel_n(eeg))
    for idx in 1:eeg_channel_n(eeg)
        loc_y[idx], loc_x[idx] = pol2cart(pi / 180 * eeg.eeg_header[:loc_theta][idx],
                                          eeg.eeg_header[:loc_radius][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)
    ch_loc_x = zeros(length(channel))
    ch_loc_y = zeros(length(channel))
    for idx in length(channel):-1:1
        ch_loc_x[idx] = loc_x[channel[idx]]
        ch_loc_y[idx] = loc_y[channel[idx]]
        deleteat!(loc_x, channel[idx])
        deleteat!(loc_y, channel[idx])
    end
    # interpolate
    x_lim_int = (findmin(loc_x)[1] * 1.4, findmax(loc_x)[1] * 1.4)
    y_lim_int = (findmin(loc_y)[1] * 1.4, findmax(loc_y)[1] * 1.4)
    interpolation_factor = round(Int64, 100 * q)
    interpolated_x = linspace(x_lim_int[1], x_lim_int[2], interpolation_factor)
    interpolated_y = linspace(y_lim_int[1], y_lim_int[2], interpolation_factor)
    interpolated_x = round.(interpolated_x, digits=2)
    interpolated_y = round.(interpolated_y, digits=2)
    interpolation_m = Matrix{Tuple{Float64, Float64}}(undef, interpolation_factor, interpolation_factor)
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            interpolation_m[idx1, idx2] = (interpolated_x[idx1], interpolated_y[idx2])
        end
    end
    epoch_n = eeg_epoch_n(eeg)
    epoch_len = eeg_epoch_len(eeg)
    electrode_locations = [loc_x loc_y]'
    s_interpolated = zeros(Float64, length(channel), epoch_len, epoch_n)
    ch_pos = Vector{Tuple{Int64, Int64}}()
    for idx in 1:length(channel)
        push!(ch_pos, f_nearest(interpolation_m, (ch_loc_x[idx], ch_loc_y[idx])))
    end
    @inbounds @simd for epoch_idx in 1:epoch_n
        Threads.@threads for length_idx in 1:epoch_len
            s_interpolated_tmp = zeros(interpolation_factor, interpolation_factor)
            m === :shepard && (itp = @views ScatteredInterpolation.interpolate(Shepard(), electrode_locations, eeg_tmp[:, length_idx, epoch_idx]))
            m === :mq && (itp = @views ScatteredInterpolation.interpolate(Multiquadratic(), electrode_locations, eeg_tmp[:, length_idx, epoch_idx]))
            m === :tp && (itp = @views ScatteredInterpolation.interpolate(ThinPlate(), electrode_locations, eeg_tmp[:, length_idx, epoch_idx]))
            for idx1 in 1:interpolation_factor
                for idx2 in 1:interpolation_factor
                    s_interpolated_tmp[idx1, idx2] = @views ScatteredInterpolation.evaluate(itp, [interpolation_m[idx1, idx2][1]; interpolation_m[idx1, idx2][2]])[1]
                end
            end
            for idx in 1:length(channel)
                s_interpolated[idx, length_idx, epoch_idx] = @views s_interpolated_tmp[ch_pos[idx][1], ch_pos[idx][2]]
            end
        end
    end
    for idx in 1:length(channel)
        eeg_new.eeg_signals[channel[idx], :, :] = @views s_interpolated[idx, :, :]
    end
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_interpolate_channel(EEG, channel=$channel, m=$m, q=$q)")

    return eeg_new
end

"""
    eeg_interpolate_channel(eeg; channel, m, q)

Interpolate `eeg` channel using planar interpolation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, Vector{Int64}}`: channel number(s) to interpolate
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `q::Float64=1.0`: interpolation quality (0 to 1.0)
"""
function eeg_interpolate_channel!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, Vector{Int64}}, m::Symbol=:shepard, q::Float64=1.0)

    eeg.eeg_signals = eeg_interpolate_channel(eeg, channel=channel, m=m, q=q).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_interpolate_channel!(EEG, channel=$channel, m=$m, q=$q)")
end

"""
    eeg_loc_flipy(locs; planar, spherical)

Flip channel locations along y axis.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates

# Returns

- `locs_new::DataFrame`
"""
function eeg_loc_flipy(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = locs_new[!, :loc_theta][idx]
            q = _angle_quadrant(t)
            q == 1 && (t = 360 - t)
            q == 2 && (t = 180 + (180 - t))
            q == 3 && (t = 180 - (t - 180))
            q == 4 && (t = 360 - t)
            t = mod(t, 360)
            locs_new[!, :loc_theta][idx] = t
        end
        spherical == true && (locs_new[!, :loc_y][idx] = -locs_new[!, :loc_y][idx])
    end
    eeg_loc_cart2sph!(locs_new)

    return locs_new
end

"""
    eeg_loc_flipy!(locs; planar, spherical)

Flip channel locations along y axis.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates
"""
function eeg_loc_flipy!(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = locs[!, :loc_theta][idx]
            q = _angle_quadrant(t)
            q == 1 && (t = 360 - t)
            q == 2 && (t = 180 + (180 - t))
            q == 3 && (t = 180 - (t - 180))
            q == 4 && (t = 360 - t)
            t = mod(t, 360)
            locs[!, :loc_theta][idx] = t
        end
        spherical == true && (locs[!, :loc_y][idx] = -locs[!, :loc_y][idx])
    end
    eeg_loc_cart2sph!(locs)
end

"""
    eeg_loc_flipx(locs; planar, spherical)

Flip channel locations along x axis.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates

# Returns

- `locs_new::DataFrame`
"""
function eeg_loc_flipx(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = locs_new[!, :loc_theta][idx]
            q = _angle_quadrant(t)
            q == 1 && (t = 90 + (90 - t))
            q == 2 && (t = 90 - (t - 90))
            q == 3 && (t = 270 + (270 - t))
            q == 4 && (t = 270 - (t - 270))
            t = mod(t, 360)
            locs_new[!, :loc_theta][idx] = t
        end
        spherical == true && (locs_new[!, :loc_x][idx] = -locs_new[!, :loc_x][idx])
    end
    eeg_loc_cart2sph!(locs_new)

    return locs_new
end

"""
    eeg_loc_flipx!(locs; planar, spherical)

Flip channel locations along x axis.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates
"""
function eeg_loc_flipx!(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = locs[!, :loc_theta][idx]
            q = _angle_quadrant(t)
            q == 1 && (t = 90 + (90 - t))
            q == 2 && (t = 90 - (t - 90))
            q == 3 && (t = 270 + (270 - t))
            q == 4 && (t = 270 - (t - 270))
            t = mod(t, 360)
            locs[!, :loc_theta][idx] = t
        end
        spherical == true && (locs[!, :loc_x][idx] = -locs[!, :loc_x][idx])
    end
    eeg_loc_cart2sph!(locs)
end

"""
    eeg_loc_flipz(locs)

Flip channel locations along z axis.

# Arguments

- `locs::DataFrame`

# Returns

- `locs_new::DataFrame`
"""
function eeg_loc_flipz(locs::DataFrame)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        locs_new[!, :loc_z][idx] = -locs_new[!, :loc_z][idx]
    end
    eeg_loc_cart2sph!(locs_new)

    return locs_new
end

"""
    eeg_loc_flipz!(eeg)

Flip channel locations along z axis.

# Arguments

- `locs::DataFrame`
"""
function eeg_loc_flipz!(locs::DataFrame)

    for idx in 1:length(locs[!, :labels])
        locs[!, :loc_z][idx] = -locs[!, :loc_z][idx]
    end
    eeg_loc_cart2sph!(locs)
end

"""
    eeg_channel_type(eeg; channel, type)

Change the `eeg` `channel` type.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`
- `type::String`

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_channel_type(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, type::String)

    type = lowercase(type)
    labels = eeg_labels(eeg)

    # create new dataset
    eeg_new = deepcopy(eeg)
    types = eeg_new.eeg_header[:channel_type]
    
    if typeof(channel) == String
        channel_found = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                types[idx] = type
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        else
            types[channel] = type
        end
    end
    eeg_new.eeg_header[:channel_type] = types
    
    # add entry to :history field
    push!(eeg_new.eeg_header[:history], "eeg_channel_type(EEG, channel=$channel, type=$type)")

    return eeg_new
end

"""
    eeg_channel_type!(eeg; channel, new_name)

Change the `eeg` `channel` type.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`
- `type::String`
"""
function eeg_channel_type!(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, type::String)

    type = lowercase(type)
    labels = eeg_labels(eeg)
    types = eeg.eeg_header[:channel_type]
    
    if typeof(channel) == String
        channel_found = nothing
        for idx in 1:length(labels)
            if channel == labels[idx]
                types[idx] = type
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("channel name does not match signal labels."))
        end
    else
        if channel < 1 || channel > length(labels)
            throw(ArgumentError("channel index does not match signal channels."))
        else
            types[channel] = type
        end
    end
    eeg_new.eeg_header[:channel_type] = types
    
    push!(eeg.eeg_header[:history], "eeg_channel_type!(EEG, channel=$channel, type=$type)")
end

"""
    eeg_edit_electrode(eeg; <keyword arguments>)

Edit `eeg` electrode.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{String, Int64}`: channel number or name
- `x::Union{Real, Nothing}`: Cartesian X spherical coordinate
- `y::Union{Real, Nothing}`: Cartesian Y spherical coordinate
- `z::Union{Real, Nothing}`: Cartesian Z spherical coordinate
- `theta::Union{Real, Nothing}`: polar planar theta coordinate
- `radius::Union{Real, Nothing}`: polar planar radius coordinate
- `theta_sph::Union{Real, Nothing}`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `radius_sph::Union{Real, Nothing}`: spherical radius, the distance from the origin to the point
- `phi_sph::Union{Real, Nothing}`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees
- `name::String=""`: channel name
- `type::String=""`: channel type

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_edit_electrode(eeg::NeuroAnalyzer.EEG; channel::Union{String, Int64}, x::Union{Real, Nothing}=nothing, y::Union{Real, Nothing}=nothing, z::Union{Real, Nothing}=nothing, theta::Union{Real, Nothing}=nothing, radius::Union{Real, Nothing}=nothing, theta_sph::Union{Real, Nothing}=nothing, radius_sph::Union{Real, Nothing}=nothing, phi_sph::Union{Real, Nothing}=nothing, name::String="", type::String="")

    eeg_new = deepcopy(eeg)
    channel = _get_channel_idx(eeg_labels(eeg_new), channel)

    name != "" && eeg_rename_channel!(eeg_new, channel=channel, name=name)
    type != "" && eeg_channel_type!(eeg_new, channel=channel, type=type)

    x !== nothing && (eeg_new.eeg_header[:loc_x][channel] = x)
    y !== nothing && (eeg_new.eeg_header[:loc_y][channel] = y)
    z !== nothing && (eeg_new.eeg_header[:loc_z][channel] = z)
    theta !== nothing && (eeg_new.eeg_header[:loc_theta][channel] = theta)
    radius !== nothing && (eeg_new.eeg_header[:loc_radius][channel] = radius)
    theta_sph !== nothing && (eeg_new.eeg_header[:loc_theta_sph][channel] = theta_sph)
    radius_sph !== nothing && (eeg_new.eeg_header[:loc_radius_sph][channel] = radius_sph)
    phi_sph !== nothing && (eeg_new.eeg_header[:loc_phi_sph][channel] = phi_sph)

    (x !== nothing || y !== nothing || z !== nothing || theta !== nothing || radius !== nothing || theta_sph !== nothing  || radius_sph !== nothing || phi_sph !== nothing) && (eeg_new.eeg_header[:channel_locations] == true)

    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_edit_electrode(EEG; channel=$channel, x=$x, y=$y, z=$z, theta=$theta, radius=$radius, theta_sph=$theta_sph, radius_sph=$radius_sph, phi_sph=$phi_sph, name=$name, type=$type)")

    return eeg_new
end

"""
    eeg_edit_electrode!(eeg; <keyword arguments>)

Edit `eeg` electrode.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{String, Int64}`: channel number or name
- `x::Union{Real, Nothing}=nothing`: Cartesian X spherical coordinate
- `y::Union{Real, Nothing}=nothing`: Cartesian Y spherical coordinate
- `z::Union{Real, Nothing}=nothing`: Cartesian Z spherical coordinate
- `theta::Union{Real, Nothing}=nothing`: polar planar theta coordinate
- `radius::Union{Real, Nothing}=nothing`: polar planar radius coordinate
- `theta_sph::Union{Real, Nothing}=nothing`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `radius_sph::Union{Real, Nothing}=nothing`: spherical radius, the distance from the origin to the point
- `phi_sph::Union{Real, Nothing}=nothing`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees
- `name::String=""`: channel name
- `type::String=""`: channel type
"""
function eeg_edit_electrode!(eeg::NeuroAnalyzer.EEG; channel::Union{String, Int64}, x::Union{Real, Nothing}=nothing, y::Union{Real, Nothing}=nothing, z::Union{Real, Nothing}=nothing, theta::Union{Real, Nothing}=nothing, radius::Union{Real, Nothing}=nothing, theta_sph::Union{Real, Nothing}=nothing, radius_sph::Union{Real, Nothing}=nothing, phi_sph::Union{Real, Nothing}=nothing, name::String="", type::String="")

    channel = _get_channel_idx(eeg_labels(eeg), channel)

    name != "" && eeg_rename_channel!(eeg, channel=channel, name=name)
    type != "" && eeg_channel_type!(eeg, channel=channel, type=type)

    x !== nothing && (eeg.eeg_header[:loc_x][channel] = x)
    y !== nothing && (eeg.eeg_header[:loc_y][channel] = y)
    z !== nothing && (eeg.eeg_header[:loc_z][channel] = z)
    theta !== nothing && (eeg.eeg_header[:loc_theta][channel] = theta)
    radius !== nothing && (eeg.eeg_header[:loc_radius][channel] = radius)
    theta_sph !== nothing && (eeg.eeg_header[:loc_theta_sph][channel] = theta_sph)
    radius_sph !== nothing && (eeg.eeg_header[:loc_radius_sph][channel] = radius_sph)
    phi_sph !== nothing && (eeg.eeg_header[:loc_phi_sph][channel] = phi_sph)

    (x !== nothing || y !== nothing || z !== nothing || theta !== nothing || radius !== nothing || theta_sph !== nothing  || radius_sph !== nothing || phi_sph !== nothing) && (eeg.eeg_header[:channel_locations] == true)

    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_edit_electrode(EEG; channel=$channel, x=$x, y=$y, z=$z, theta=$theta, radius=$radius, theta_sph=$theta_sph, radius_sph=$radius_sph, phi_sph=$phi_sph, name=$name, type=$type)")
end

"""
    eeg_electrode_loc(eeg; channel, output)

Return locations of the `eeg` `channel` electrode.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `channel::Union{Int64, String}`
- `output::Bool=true`: print output if true

# Returns

Named tuple containing:
- `theta::Union{Real, Nothing}=nothing`: polar planar theta coordinate
- `radius::Union{Real, Nothing}=nothing`: polar planar radius coordinate
- `x::Union{Real, Nothing}=nothing`: Cartesian X spherical coordinate
- `y::Union{Real, Nothing}=nothing`: Cartesian Y spherical coordinate
- `z::Union{Real, Nothing}=nothing`: Cartesian Z spherical coordinate
- `theta_sph::Union{Real, Nothing}=nothing`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `radius_sph::Union{Real, Nothing}=nothing`: spherical radius, the distance from the origin to the point
- `phi_sph::Union{Real, Nothing}=nothing`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees
"""
function eeg_electrode_loc(eeg::NeuroAnalyzer.EEG; channel::Union{Int64, String}, output::Bool=true)

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() or eeg_add_electrodes() first."))

    channel = _get_channel_idx(eeg_labels(eeg), channel)

    x = eeg.eeg_header[:loc_x][channel]
    y = eeg.eeg_header[:loc_y][channel]
    z = eeg.eeg_header[:loc_z][channel]
    theta = eeg.eeg_header[:loc_theta][channel]
    radius = eeg.eeg_header[:loc_radius][channel]
    theta_sph = eeg.eeg_header[:loc_theta_sph][channel]
    radius_sph = eeg.eeg_header[:loc_radius_sph][channel]
    phi_sph = eeg.eeg_header[:loc_phi_sph][channel]

    if output
        println("Channel: $channel")
        println("  Label: $(eeg_labels(eeg)[channel])")
        println("  theta: $theta (planar)")
        println(" radius: $radius (planar)")
        println("      X: $x (spherical)")
        println("      Y: $y (spherical)")
        println("      Z: $z (spherical)")
        println(" radius: $radius_sph (spherical)")
        println("  theta: $theta_sph (spherical)")
        println("    phi: $phi_sph (spherical)")
    end
    
    return (theta=theta, radius=radius, x=x, y=y, z=z, theta_sph=theta_sph, radius_sph=radius_sph, phi_sph=phi_sph)
end

"""
    eeg_loc_swapxy(locs; planar, spherical)

Swap channel locations x and y axes.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_loc_swapxy(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = deg2rad(locs_new[!, :loc_theta][idx])
            t += pi / 2
            locs_new[!, :loc_theta][idx] = rad2deg(t)
        end
        if spherical == true
            locs_new[!, :loc_x][idx], locs_new[!, :loc_y][idx] = locs_new[!, :loc_y][idx], locs_new[!, :loc_x][idx]
        end
    end
    eeg_loc_cart2sph!(locs_new)

    return locs_new
end

"""
    eeg_loc_swapxy!(locs; planar, spherical)

Swap channel locations x and y axes.

# Arguments

- `locs::DataFrame`
- `planar::Bool=true`: modify planar coordinates
- `spherical::Bool=true`: modify spherical coordinates
"""
function eeg_loc_swapxy!(locs::DataFrame; planar::Bool=true, spherical::Bool=true)

    for idx in 1:length(locs[!, :labels])
        if planar == true
            t = deg2rad(locs[!, :loc_theta][idx])
            t += pi / 2
            locs[!, :loc_theta][idx] = rad2deg(t)
        end
        if spherical == true
            locs[!, :loc_x][idx], locs[!, :loc_y][idx] = locs[!, :loc_y][idx], locs[!, :loc_x][idx]
        end
    end
    eeg_loc_cart2sph!(locs)
end

"""
    eeg_loc_sph2cart(locs)

Convert spherical locations to Cartesian.

# Arguments

- `locs::DataFrame`

# Returns

- `locs_new::DataFrame`
"""
function eeg_loc_sph2cart(locs::DataFrame)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        r = locs_new[!, :loc_radius_sph][idx]
        t = locs_new[!, :loc_theta_sph][idx]
        p = locs_new[!, :loc_phi_sph][idx]
        x, y, z = sph2cart(r, t, p)
        locs_new[!, :loc_x][idx] = x
        locs_new[!, :loc_y][idx] = y
        locs_new[!, :loc_z][idx] = z
    end

    return locs_new
end

"""
    eeg_loc_sph2cart!(locs)

Convert spherical locations to Cartesian.

# Arguments

- `locs::DataFrame`
"""
function eeg_loc_sph2cart!(locs::DataFrame)

    for idx in 1:length(locs[!, :labels])
        r = locs[!, :loc_radius_sph][idx]
        t = locs[!, :loc_theta_sph][idx]
        p = locs[!, :loc_phi_sph][idx]
        x, y, z = sph2cart(r, t, p)
        locs[!, :loc_x][idx] = x
        locs[!, :loc_y][idx] = y
        locs[!, :loc_z][idx] = z
    end
end

"""
    eeg_loc_cart2sph(locs)

Convert Cartesian locations to spherical.

# Arguments

- `locs::DataFrame`

# Returns

- `locs_new::DataFrame`
"""
function eeg_loc_cart2sph(locs::DataFrame)

    locs_new = deepcopy(locs)

    for idx in 1:length(locs[!, :labels])
        idx = 2
        x = locs_new[!, :loc_x][idx]
        y = locs_new[!, :loc_y][idx]
        z = locs_new[!, :loc_z][idx]
        r, t, p = round.(cart2sph(x, y, z), digits=2)
        locs_new[!, :loc_radius_sph][idx] = r
        locs_new[!, :loc_theta_sph][idx] = t
        locs_new[!, :loc_phi_sph][idx] = p
    end

    return locs_new
end

"""
    eeg_loc_cart2sph!(locs)

Convert Cartesian locations to spherical.


# Arguments

- `locs::DataFrame`
"""
function eeg_loc_cart2sph!(locs::DataFrame)

    for idx in 1:length(locs[!, :labels])
        x = locs[!, :loc_x][idx]
        y = locs[!, :loc_y][idx]
        z = locs[!, :loc_z][idx]
        r, t, p = cart2sph(x, y, z)
        locs[!, :loc_radius_sph][idx] = r
        locs[!, :loc_theta_sph][idx] = t
        locs[!, :loc_phi_sph][idx] = p
    end
end

"""
    eeg_view_annotations(eeg)

Return `eeg` annotations.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_view_annotations(eeg::NeuroAnalyzer.EEG)
    eeg.eeg_header[:annotations] == true || throw(ArgumentError("EEG has no annotations."))
    for annotation_idx in 1:size(eeg.eeg_annotations, 1)
        println("onset [s]: $(rpad(eeg.eeg_annotations[!, :onset][annotation_idx], 8, " ")) event: $(eeg.eeg_annotations[!, :event][annotation_idx])")
    end
end

"""
    eeg_delete_annotation(eeg; n)

Delete `n`th annotation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `n::Int64`: annotation number

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_delete_annotation(eeg::NeuroAnalyzer.EEG; n::Int64)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:annotations] == true || throw(ArgumentError("EEG has no annotations."))
    nn = size(eeg_new.eeg_annotations, 1)
    n < 1 || n > nn && throw(ArgumentError("n has to be ≥ 1 and ≤ $nn."))
    deleteat!(eeg_new.eeg_annotations, n)
    size(eeg_new.eeg_annotations, 1) == 0 && (eeg_new.eeg_header[:annotations] = false)
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_delete_annotation(EEG; n=$n)")
    
    return eeg_new
end

"""
    eeg_delete_annotation!(eeg; n)

Delete `n`th annotation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `n::Int64`: annotation number
"""
function eeg_delete_annotation!(eeg::NeuroAnalyzer.EEG; n::Int64)
    eeg.eeg_header[:annotations] == true || throw(ArgumentError("EEG has no annotations."))
    nn = size(eeg.eeg_annotations, 1)
    n < 1 || n > nn && throw(ArgumentError("n has to be ≥ 1 and ≤ $nn."))
    deleteat!(eeg.eeg_annotations, n)
    size(eeg.eeg_annotations, 1) == 0 && (eeg.eeg_header[:annotations] = false)
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_delete_annotation!(EEG; n=$n)")
end

"""
    eeg_add_annotation(eeg; onset, event)

Add annotation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `onset::Float64`: time in seconds
- `event::String`: event description

# Returns

- `eeg::NeuroAnalyzer.EEG`
"""
function eeg_add_annotation(eeg::NeuroAnalyzer.EEG; onset::Real, event::String)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_header[:annotations] = true
    append!(eeg_new.eeg_annotations, DataFrame(:onset => Float64(onset), :event => event ))
    sort!(eeg_new.eeg_annotations)
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_add_annotation(EEG; onset=$onset, event=$event)")

    return eeg_new
end

"""
    eeg_add_annotation!(eeg; onset, event)

Delete `n`th annotation.

# Arguments

- `eeg::NeuroAnalyzer.EEG`
- `onset::Float64`: time onset in seconds
- `event::String`: event description
"""
function eeg_add_annotation!(eeg::NeuroAnalyzer.EEG; onset::Real, event::String)
    eeg.eeg_header[:annotations] = true
    append!(eeg.eeg_annotations, DataFrame(:onset => Float64(onset), :event => event ))
    sort!(eeg.eeg_annotations)
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_add_annotation!(EEG; onset=$onset, event=$event)")
end