export channel_type
export channel_type!
export get_channel
export rename_channel
export rename_channel!
export edit_channel
export edit_channel!
export replace_channel
export replace_channel!
export add_labels
export add_labels!

"""
    channel_type(obj; channel, type)

Change channel type.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`
- `type::String`

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function channel_type(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, type::String)

    type = lowercase(type)
    clabels = labels(obj)

    # create new dataset
    obj_new = deepcopy(obj)
    types = obj_new.header.recording[:channel_type]
    
    if typeof(channel) == String
        channel_found = nothing
        for idx in eachindex(clabels)
            if channel == clabels[idx]
                types[idx] = type
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("Channel name ($channel) does not match signal labels."))
        end
    else
        _check_channels(obj, channel)
        types[channel] = type
    end
    obj_new.header.recording[:channel_type] = types
    
    # add entry to :history field
    push!(obj_new.header.history, "channel_type(OBJ, channel=$channel, type=$type)")

    return obj_new
end

"""
    channel_type!(obj; channel, new_name)

Change channel type.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`
- `type::String`
"""
function channel_type!(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, type::String)

    obj_tmp = channel_type(obj, channel=channel, type=type)
    obj.header = obj_tmp.header

    return nothing
end

"""
    get_channel(obj; channel)

Return channel number (if provided by name) or name (if provided by number).

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`: channel number or name

# Returns

- `ch_idx::Union{Int64, String}`: channel number or name
"""
function get_channel(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String})

    clabels = labels(obj)
    if typeof(channel) == String
        # get channel by name
        ch_idx = nothing
        for idx in eachindex(clabels)
            if lowercase(channel) == lowercase(clabels[idx])
                ch_idx = idx
            end
        end
        if ch_idx === nothing
            throw(ArgumentError("Channel name ($channel) does not match signal labels."))
        end
        return ch_idx
    else
        # get channel by number
        _check_channels(obj, channel)
        return clabels[channel]
    end
end

"""
    rename_channel(obj; channel, name)

Rename channel.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`: channel number or name
- `name::String`: new name

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function rename_channel(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, name::String)

    # create new dataset
    obj_new = deepcopy(obj)
    clabels = labels(obj_new)
    name in clabels && throw(ArgumentError("Channel $name already exist."))

    if typeof(channel) == String
        # get channel by name
        channel_found = nothing
        for idx in eachindex(clabels)
            if channel == clabels[idx]
                clabels[idx] = name
                channel_found = idx
            end
        end
        if channel_found === nothing
            throw(ArgumentError("Channel name ($channel )does not match channel labels."))
        end
    else
        # get channel by number
        _check_channels(obj, channel)
        clabels[channel] = name
    end
    obj_new.header.recording[:labels] = clabels
    
    # add entry to :history field
    push!(obj_new.header.history, "rename_channel(OBJ, channel=$channel, name=$name)")

    return obj_new
end

"""
    rename_channel!(obj; channel, name)

Rename channel.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`: channel number or name
- `name::String`: new name
"""
function rename_channel!(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, name::String)

    obj.header.recording[:labels] = rename_channel(obj, channel=channel, name=name).header.recording[:labels]
    push!(obj.header.history, "rename_channel!(OBJ, channel=$channel, name=$name)")

    return nothing
end

"""
    edit_channel(obj; channel, field, value)

Edit channel properties.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Int64`
- `field::Symbol`
- `value::Any`

# Returns

- `obj_new::NeuroAnalyzer.NEURO`
"""
function edit_channel(obj::NeuroAnalyzer.NEURO; channel::Int64, field::Symbol, value::Any)
    
    value === nothing && throw(ArgumentError("value cannot be empty."))
    _check_channels(obj, channel)
    _check_var(field, [:channel_type, :labels], "field")    

    obj_new = deepcopy(obj)
    typeof(obj_new.header.recording[field][channel]) == typeof(value) || throw(ArgumentError("field type ($(eltype(obj_new.header.recording[field]))) does not mach value type ($(typeof(value)))."))
    obj_new.header.recording[field][channel] = value

    # add entry to :history field
    push!(obj_new.header.history, "edit_channel(OBJ, channel=$channel, field=$field, value=$value)")   

    return obj_new
end

"""
    edit_channel!(obj; channel, field, value)

Edit channel properties.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Int64`
- `field::Symbol`
- `value::Any`
"""
function edit_channel!(obj::NeuroAnalyzer.NEURO; channel::Int64, field::Symbol, value::Any)
    
    obj_tmp = edit_channel(obj, channel=channel, field=field, value=value)
    obj.header = obj_tmp.header

    return nothing
end

"""
    replace_channel(obj; channel, signal)

Replace channel.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`: channel number or name
- `signal::Array{Float64, 3}`

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function replace_channel(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, signal::Array{Float64, 3})

    ch_idx = nothing
    clabels = labels(obj)
    if typeof(channel) == String
        for idx in eachindex(clabels)
            if channel == clabels[idx]
                ch_idx = idx
            end
        end
        ch_idx === nothing && throw(ArgumentError("Channel name ($channel) does not match signal labels."))
    else
        _check_channels(obj, channel)
        ch_idx = channel
    end

    obj_new = deepcopy(obj)
    size(signal) == (1, epoch_len(obj_new), epoch_n(obj_new)) || throw(ArgumentError("signal size ($(size(signal))) must be the same as channel size ($(size(obj_new.data[ch_idx, :, :]))."))
    obj_new.data[ch_idx, :, :] = signal
    reset_components!(obj_new)

    # add entry to :history field
    push!(obj_new.header.history, "replace_channel(OBJ, channel=$channel, signal=$signal")

    return obj_new
end

"""
    replace_channel!(obj; channel, signal)

Replace channel.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `channel::Union{Int64, String}`: channel number or name
- `signal::Array{Float64, 3}`
"""
function replace_channel!(obj::NeuroAnalyzer.NEURO; channel::Union{Int64, String}, signal::Array{Float64, 3})

    obj_tmp = replace_channel(obj, channel=chanel, signal=signal)
    obj.header = obj_tmp.header
    obj.data = obj_tmp.data
    reset_components!(obj)

    return nothing
end

"""
    add_labels(obj; labels)

Add channel labels.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `clabels::Vector{String}`

# Returns

- `obj::NeuroAnalyzer.NEURO`
"""
function add_labels(obj::NeuroAnalyzer.NEURO; clabels::Vector{String})

    length(clabels) == channel_n(obj) || throw(ArgumentError("clabels length must be $(channel_n(obj))."))
    
    obj_new = deepcopy(obj)
    obj_new.header.recording[:labels] = clabels

    push!(obj_new.header.history, "add_labels(OBJ, clabels=$clabels")
 
    return obj_new
end

"""
    add_labels!(obj::NeuroAnalyzer.NEURO; clabels::Vector{String})

Add OBJ channel labels.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `clabels::Vector{String}`
"""
function add_labels!(obj::NeuroAnalyzer.NEURO; clabels::Vector{String})

    length(clabels) == channel_n(obj) || throw(ArgumentError("clabels length must be $(channel_n(obj))."))
    obj_tmp = add_labels(obj, clabels=clabels)
    obj.header = obj_tmp.header

    return nothing
end
