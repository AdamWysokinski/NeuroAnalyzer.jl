export frqinst

"""
    frqinst(s; <keyword arguments>)

Calculate instantaneous frequency.

# Arguments

- `s::AbstractVector`

# Returns

- `f::Vector{Float64}`
"""
function frqinst(s::AbstractVector)::Vector{Float64}

    _, _, _, pha = hspectrum(s)
    f = 1 / (2 * pi) * derivative(DSP.unwrap(pha))

    return f

end

"""
    frqinst(s; <keyword arguments>)

Calculate instantaneous frequency.

# Arguments

- `s::AbstractVector`

# Returns

- `f::Matrix{Float64}`
"""
function frqinst(s::AbstractArray)::Matrix{Float64}

    _warn("frqinst() uses Hilbert transform, the signal should be narrowband for best results.")

    ch_n = size(s, 1)
    ep_len = size(s, 2)
    ep_n = size(s, 3)

    f = zeros(ch_n, ep_len, ep_n)

    @inbounds for ep_idx in 1:ep_n
        Threads.@threads for ch_idx in 1:ch_n
            f[ch_idx, :, ep_idx] = @views frqinst(s[ch_idx, :, ep_idx])
        end
    end

    return f

end

"""
    frqinst(obj; <keyword arguments>)

Calculate instantaneous frequency.

# Arguments

- `obj::NeuroAnalyzer.NEURO`
- `ch::Union{String, Vector{String}}`: channel name or list of channel names

# Returns

- `f::Array{Float64, 3}`
"""
function frqinst(obj::NeuroAnalyzer.NEURO; ch::Union{String, Vector{String}})::Array{Float64, 3}

    ch = get_channel(obj, ch=ch)
    f = @views frqinst(obj.data[ch, :, :])

    return f

end
