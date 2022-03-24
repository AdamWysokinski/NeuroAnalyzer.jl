################################
#                              #
# Low-level internal functions #
#                              #
################################

################################

"""
    eeg_reference_channel(eeg; channel)

Reference the `eeg` to specific `channel`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: index of channels used as reference; if multiple channels are specified, their average is used as the reference

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_reference_channel(eeg::NeuroJ.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_ref = zeros(size(eeg.eeg_signals))

    channel_list = collect(1:channel_n)
    for idx in 1:length(channel)
        if (channel[idx] in channel_list) == false
            throw(ArgumentError("channel does not match signal channels."))
        end
    end

    @inbounds @simd for epoch in 1:epoch_n
        s = @view eeg.eeg_signals[channel, :, epoch]
        if length(channel) == 1
            reference_channel = mean(s, dims=2)
        else
            reference_channel = vec(mean(s, dims=1))
        end
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_ref[idx, :, epoch] = s .- reference_channel
        end
        length(channel) == 1 && (s_ref[channel, :, epoch] = reference_channel)
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_ref
    eeg_new.eeg_header[:reference] = "channel: $channel"
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_reference_channel(EEG, channel=$channel)")

    return eeg_new
end

"""
    eeg_reference_channel!(eeg; channel)

Reference the `eeg` to specific channel `channel`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: index of channels used as reference; if multiple channels are specified, their average is used as the reference
"""
function eeg_reference_channel!(eeg::NeuroJ.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    eeg.eeg_signals = eeg_reference_channel(eeg, channel=channel).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_reference_channel!(EEG, channel=$channel)")

    return
end

"""
    eeg_reference_car(eeg)

Reference the `eeg` to common average reference.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_reference_car(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_ref = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        reference_channel = vec(mean(eeg.eeg_signals[:, :, epoch], dims=1))
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_ref[idx, :, epoch] = s .- reference_channel
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_ref
    eeg_new.eeg_header[:reference] = "CAR"
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_reference_car(EEG)")

    return eeg_new
end

"""
    eeg_reference_car!(eeg)

Reference the `eeg` to common average reference.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_reference_car!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_reference_car(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_reference_car!(EEG)")

    return
end

"""
    eeg_derivative(eeg)

Return the derivative of the `eeg` with length same as the signal.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_derivative(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_der = zeros(size(eeg.eeg_signals))
    
    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_der[idx, :, epoch] = s_derivative(s)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_der
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_derivative(EEG)")

    return eeg_new
end

"""
    eeg_derivative!(eeg)

Return the derivative of the `eeg` with length same as the signal.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_derivative!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_derivative(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_derivative(EEG)")

    return
end

"""
    eeg_detrend(eeg; type)

Perform piecewise detrending of `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `type::Symbol`, optional
    - `:ls`: the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `:linear`: linear trend is subtracted from `signal`
    - `:constant`: `offset` or the mean of `signal` (if `offset` = 0) is subtracted
    - `:poly`: polynomial of `order` is subtracted
    - `:loess`: fit and subtract loess approximation
- `offset::Union{Int64, Float64}=0`: constant for :constant detrending
- `order::Int64=1`: polynomial fitting order
- `span::Float64=0.5`: smoothing of loess

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_detrend(eeg::NeuroJ.EEG; type::Symbol=:linear, offset::Union{Int64, Float64}=0, order::Int64=1, span::Float64=0.5)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    type in [:ls, :linear, :constant, :poly, :loess] || throw(ArgumentError("type must be :ls, :linear, :constant, :poly, :loess."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_det = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_det[idx, :, epoch] = s_detrend(s, type=type, offset=offset, order=order, span=span)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_det
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_detrend(EEG, type=$type, offset=$offset, order=$order, span=$span)")

    return eeg_new
end

"""
    eeg_detrend!(eeg; type)

Remove linear trend from the `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `type::Symbol`, optional
    - `:ls`: the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `:linear`: linear trend is subtracted from `signal`
    - `:constant`: `offset` or the mean of `signal` (if `offset` = 0) is subtracted
    - `:poly`: polynomial of `order` order is subtracted
    - `:loess`: fit and subtract loess approximation
- `offset::Union{Int64, Float64}=0`: constant for :constant detrending
- `order::Int64=1`: polynomial fitting order
- `span::Float64`: smoothing of loess
"""
function eeg_detrend!(eeg::NeuroJ.EEG; type::Symbol=:linear, offset::Union{Int64, Float64}=0, order::Int64=1, span::Float64=0.5)

    eeg.eeg_signals = eeg_detrend(eeg, type=type, offset=offset, order=order, span=span).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_detrend(EEG, type=$type, offset=$offset, order=$order, span=$span)")

    return
end

"""
    eeg_taper(eeg; taper)

Taper `eeg` with `taper`.

# Arguments

- `eeg::NeuroJ.EEG`
- `taper::Union{Vector{Real, Vector{ComplexF64}}``

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_taper(eeg::NeuroJ.EEG; taper::Union{Vector{<:Real}, Vector{ComplexF64}})

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)

    s_tap = zeros(eltype(taper), size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_tap[idx, :, epoch] = s_taper(s, taper=taper)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_tap
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_taper(EEG, taper=$taper)")

    return eeg_new
end

"""
    eeg_taper!(eeg; taper)

Taper `eeg` with `taper`.

# Arguments

- `eeg::NeuroJ.EEG`
- `taper::Union{Vector{<:Real}, Vector{ComplexF64}}``
"""
function eeg_taper!(eeg::NeuroJ.EEG; taper::Union{Vector{<:Real}, Vector{ComplexF64}})

    eeg.eeg_signals = eeg_taper(eeg, taper=taper).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_taper(EEG, taper=$taper)")

    return
end

"""
    eeg_demean(eeg)

Remove mean value (DC offset).

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_demean(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_demeaned = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_demeaned[idx, :, epoch] = s_demean(s)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_demeaned
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_demean(EEG)")

    return eeg_new
end

"""
    eeg_demean!(eeg)

Remove mean value (DC offset).

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_demean!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_demean(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_demean(EEG)")

    return
end

"""
    eeg_normalize_zscore(eeg)

Normalize each `eeg` channel by z-score.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_normalize_zscore(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_normalized = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_normalized[idx, :, epoch] = s_normalize_zscore(s)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_normalized
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_normalize_zscore(EEG)")

    return eeg_new
end

"""
    eeg_normalize_zscore!(eeg)

Normalize by z-score.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_normalize_zscore!(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    eeg.eeg_signals = eeg_normalize_zscore(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_normalize_zscore!(EEG)")

    return
end

"""
    eeg_normalize_minmax(eeg)

Normalize to 0...1

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_normalize_minmax(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_normalized = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_normalized[idx, :, epoch] = s_normalize_minmax(s)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_normalized
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_normalize_minmax(EEG)")

    return eeg_new
end

"""
    eeg_normalize_minmax!(eeg)

Normalize to 0...1

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_normalize_minmax!(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    eeg.eeg_signals = eeg_normalize_minmax(eeg.eeg_signals).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_normalize_minmax!(EEG)")

    return
end

"""
    eeg_add_noise(eeg)

Add random noise to the `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_add_noise(eeg::NeuroJ.EEG)

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)

    s_noise = zeros(size(eeg.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_noise[idx, :, epoch] = s_add_noise(s)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_noise
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_add_noise(EEG)")

    return eeg_new
end

"""
    eeg_add_noise!(eeg)

Add random noise to the `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_add_noise!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_add_noise(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_add_noise(EEG)")

    return
end

"""
    eeg_filter(eeg; <keyword arguments>)

Filter `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`
- `fprototype::Symbol`: filter prototype:
    - `:butterworth`
    - `:chebyshev1`
    - `:chebyshev2`
    - `:elliptic`
    - `:fir`
    - `:mavg`: moving average (with threshold and/or weight window)
    - `:mmed`: moving median (with threshold and/or weight window)
    - `:poly`: polynomial of `order` order
- `ftype::Symbol`: filter type:
    - `:lp`: low pass
    - `:hp`: high pass
    - `:bp`: band pass
    - `:bs`: band stop
- `cutoff::Union{Int64, Float64, Tuple}`: filter cutoff in Hz (vector for `:bp` and `:bs`)
- `order::Int64=2`: filter order
- `rp::Union{Int64, Float64}=-1`: ripple amplitude in dB in the pass band; default: 0.0025 dB for :elliptic, 2 dB for others
- `rs::Union{Int64, Float64}=-1`: ripple amplitude in dB in the stop band; default: 40 dB for :elliptic, 20 dB for others
- `dir:Symbol=:twopass`: filter direction (`:onepass`, `:onepass_reverse`, `:twopass`), for causal filter use `:onepass`
- `d::Int64=1`: window length for mean average and median average filter
- `t::Union{Int64, Float64}`: threshold for `:mavg` and `:mmed` filters; threshold = threshold * std(signal) + mean(signal) for `:mavg` or threshold = threshold * std(signal) + median(signal) for `:mmed` filter
- `window::Union{Vector{Float64}, Nothing} - window, required for FIR filter

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_filter(eeg::NeuroJ.EEG; fprototype::Symbol, ftype::Union{Symbol, Nothing}=nothing, cutoff::Union{Int64, Float64, Tuple}=0, order::Int64=2, rp::Union{Int64, Float64}=-1, rs::Union{Int64, Float64}=-1, dir::Symbol=:twopass, d::Int64=1, t::Union{Int64, Float64}=0, window::Union{Vector{Float64}, Nothing}=nothing)

    channel_n = eeg_channel_n(eeg)
    epoch_n = eeg_epoch_n(eeg)
    s_filtered = zeros(size(eeg.eeg_signals))
    fs = eeg_sr(eeg)
    
    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s = @view eeg.eeg_signals[idx, :, epoch]
            s_filtered[idx, :, epoch] = s_filter(s,
                                                 fprototype=fprototype,
                                                 ftype=ftype,
                                                 cutoff=cutoff,
                                                 fs=fs,
                                                 order=order,
                                                 rp=rp,
                                                 rs=rs,
                                                 dir=dir,
                                                 d=d,
                                                 t=t,
                                                 window=window)
        end
    end

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_filtered
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_filter(EEG, fprototype=$fprototype, ftype=$ftype, cutoff=$cutoff, order=$order, rp=$rp, rs=$rs, dir=$dir, d=$d, t=$t, window=$window)")

    return eeg_new
end

"""
    eeg_filter!(eeg; <keyword arguments>)

Filter `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `fprototype::Symbol`: filter prototype:
    - `:butterworth`
    - `:chebyshev1`
    - `:chebyshev2`
    - `:elliptic`
    - `:fir`
    - `:mavg`: moving average (with threshold and/or weight window)
    - `:mmed`: moving median (with threshold and/or weight window)
    - `:poly`: polynomial of `order` order
- `ftype::Symbol`: filter type:
    - `:lp`: low pass
    - `:hp`: high pass
    - `:bp`: band pass
    - `:bs`: band stop
- `cutoff::Union{Int64, Float64, Tuple}`: filter cutoff in Hz (vector for `:bp` and `:bs`)
- `order::Int64=2`: filter order
- `rp::Union{Int64, Float64}=-1`: ripple amplitude in dB in the pass band; default: 0.0025 dB for :elliptic, 2 dB for others
- `rs::Union{Int64, Float64}=-1`: ripple amplitude in dB in the stop band; default: 40 dB for :elliptic, 20 dB for others
- `dir:Symbol=:twopass`: filter direction (`:onepass`, `:onepass_reverse`, `:twopass`), for causal filter use `:onepass`
- `d::Int64=1`: window length for mean average and median average filter
- `t::Union{Int64, Float64}`: threshold for `:mavg` and `:mmed` filters; threshold = threshold * std(signal) + mean(signal) for `:mavg` or threshold = threshold * std(signal) + median(signal) for `:mmed` filter
- `window::Union{Vector{Float64}, Nothing} - window, required for FIR filter
"""
function eeg_filter!(eeg::NeuroJ.EEG; fprototype::Symbol, ftype::Union{Symbol, Nothing}=nothing, cutoff::Union{Int64, Float64, Tuple}=0, order::Int64=2, rp::Union{Int64, Float64}=-1, rs::Union{Int64, Float64}=-1, dir::Symbol=:twopass, d::Int64=1, t::Union{Int64, Float64}=0, window::Union{Vector{Float64}, Nothing}=nothing)

    s_filtered = eeg_filter(eeg,
                            fprototype=fprototype,
                            ftype=ftype,
                            cutoff=cutoff,
                            order=order,
                            rp=rp,
                            rs=rs,
                            dir=dir,
                            d=d,
                            t=t,
                            window=window).eeg_signals
    eeg.eeg_signals = s_filtered
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_filter!(EEG, fprototype=$fprototype, ftype=$ftype, cutoff=$cutoff, order=$order, rp=$rp, rs=$rs, dir=$dir, d=$d, window=$window)")

    return
end

"""
    eeg_pca(eeg; n)

Calculate `n` first PCs for `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `n::Int64`: number of PCs

# Returns

Named tuple containing:
- `pc::Array{Float64, 3}:`: PC(1)..PC(n) × epoch
- `pc_var::Matrix{Float64}`: variance of PC(1)..PC(n) × epoch
- `pc_m::PCA{Float64}`: PC mean
"""
function eeg_pca(eeg::NeuroJ.EEG; n::Int64)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    pc, pc_var, pc_m = s_pca(eeg.eeg_signals, n=n)

    return (pc=pc, pc_var=pc_var, pc_m=pc_m)
end

"""
    eeg_pca_reconstruct(eeg)

Reconstruct `eeg` signals using PCA components.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_pca_reconstruct(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    :pc in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :pc component. Perform eeg_pca(EEG) first."))
    :pc_m in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :pc_m component. Perform eeg_pca(EEG) first."))

    eeg_new = deepcopy(eeg)
    pc_idx = findfirst(isequal(:pc), eeg.eeg_header[:components])
    pc_m_idx = findfirst(isequal(:pc_m), eeg.eeg_header[:components])
    eeg_new.eeg_signals = s_pca_reconstruct(eeg_new.eeg_signals, pc=eeg_new.eeg_components[pc_idx], pc_m=eeg_new.eeg_components[pc_m_idx])
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_pca_reconstruct(EEG)")

    return eeg_new
end

"""
    eeg_pca_reconstruct!(eeg)

Reconstruct `eeg` signals using PCA components.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_pca_reconstruct!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_pca_reconstruct(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_pca_reconstruct!(EEG)")

    return
end

"""
    eeg_ica(eeg; <keyword arguments>)

Calculate `n` first ICs for `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `n::Int64`: number of ICs
- `tol::Float64=1.0e-6`: tolerance for ICA
- `iter::Int64=100`: maximum number of iterations
- `f::Symbol=:tanh`: neg-entropy functor: :tanh, :gaus

# Returns

Named tuple containing:
- `ic::Array{Float64, 3}`: IC(1)..IC(n) × epoch (W * data)
- `ic_mw::Array{Float64, 3}`: IC(1)..IC(n) × epoch inv(W)
"""
function eeg_ica(eeg::NeuroJ.EEG; n::Int64, tol::Float64=1.0e-6, iter::Int64=100, f::Symbol=:tanh)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    ic, ic_mw = s_ica(eeg.eeg_signals, n=n, tol=tol, iter=iter, f=f)

    return (ic=ic, ic_mw=ic_mw)
end

"""
    eeg_average(eeg)

Return the average signal of all `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_average(eeg::NeuroJ.EEG)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    eeg_new = deepcopy(eeg)
    eeg_keep_channel!(eeg_new, channel=1)
    eeg_new.eeg_signals = s_average(eeg.eeg_signals)
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_average(EEG)")

    return eeg_new
end

"""
    eeg_average!(eeg)

Return the average signal of all `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`
"""
function eeg_average!(eeg::NeuroJ.EEG)

    eeg.eeg_signals = eeg_average(eeg).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_average!(EEG)")

    return
end

"""
    eeg_average(eeg1, eeg2)

Return the average signal of all `eeg1` and `eeg2` channels.

# Arguments

- `eeg1::NeuroJ.EEG`
- `eeg2::NeuroJ.EEG`

# Returns

- `eeg_new::NeuroJ.EEG`
"""
function eeg_average(eeg1::NeuroJ.EEG, eeg2::NeuroJ.EEG)

    size(eeg1.eeg_signals) == size(eeg2.eeg_signals) || throw(ArgumentError("Both signals must have the same size."))
    channel_n = eeg_channel_n(eeg1)
    epoch_n = eeg_epoch_n(eeg1)
    s_averaged = zeros(size(eeg1.eeg_signals))

    @inbounds @simd for epoch in 1:epoch_n
        Threads.@threads for idx in 1:channel_n
            s1 = @view signal1[idx, :, epoch]
            s2 = @view signal2[idx, :, epoch]
            s_averaged[idx, :, epoch] = s2_average(s1, s2)
        end
    end

    eeg_new = deepcopy(eeg1)
    eeg_new.eeg_signals = s_averaged
    eeg_reset_components!(eeg_new)
    push!(eeg.eeg_header[:history], "eeg_average(EEG1, EEG2)")

    return eeg_new
end

"""
    eeg_ica_reconstruct(eeg; ica)

Reconstruct `eeg` signals using removal of `ica` ICA components.

# Arguments

- `eeg::NeuroJ.EEG`
- `ica::Union{Int64, Vector{Int64}, AbstractRange} - list of ICs to remove

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_ica_reconstruct(eeg::NeuroJ.EEG; ica::Union{Int64, Vector{Int64}, AbstractRange})

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))

    :ica in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :ica component. Perform eeg_ica(EEG) first."))
    :ica_mw in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :ica_mw component. Perform eeg_ica(EEG) first."))

    eeg_new = deepcopy(eeg)
    ica_a_idx = findfirst(isequal(:ica), eeg.eeg_header[:components])
    ica_mw_idx = findfirst(isequal(:ica_mw), eeg.eeg_header[:components])
    eeg_new.eeg_signals = s_ica_reconstruct(eeg_new.eeg_signals, ic=eeg_new.eeg_components[ica_a_idx], ic_mw=eeg_new.eeg_components[ica_mw_idx], ic_v=ica)
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_ica_reconstruct(EEG, ica=$ica)")

    return eeg_new
end

"""
    eeg_ica_reconstruct!(eeg; ica)

Reconstruct `eeg` signals using removal of `ica` ICA components.

# Arguments

- `eeg::NeuroJ.EEG`
- `ica::Union{Int64, Vector{Int64}, AbstractRange} - list of ICs to remove
"""
function eeg_ica_reconstruct!(eeg::NeuroJ.EEG; ica::Union{Int64, Vector{Int64}, AbstractRange})

    eeg.eeg_signals = eeg_ica_reconstruct(eeg, ica=ica).eeg_signals
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_ica_reconstruct!(EEG, ica=$ica)")

    return
end

"""
    eeg_invert_polarity(eeg; channel)

Invert polarity of `channel` of `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Int64`: channel to invert

# Returns

- `eeg_new::NeuroJ.EEG`
"""
function eeg_invert_polarity(eeg::NeuroJ.EEG; channel::Int64)

    (channel < 1 || channel > eeg_channel_n(eeg)) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))

    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals[channel, :, :] = .- eeg_new.eeg_signals[channel, :, :]
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_invert_polarity(EEG, channel=$channel)")

    return eeg_new
end

"""
    eeg_invert_polarity!(eeg; channel)

Invert polarity of `channel` of `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel(s) to invert
"""
function eeg_invert_polarity!(eeg::NeuroJ.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange})

    (channel < 1 || channel > eeg_channel_n(eeg)) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))

    eeg.eeg_signals[channel, :, :] = .- eeg.eeg_signals[channel, :, :]
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_invert_polarity!(EEG, channel=$channel)")

    return
end


"""
    eeg_resample(eeg; new_sr)

Resample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_resample(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr > eeg_sr(eeg) && (eeg_new = eeg_upsample(eeg, new_sr=new_sr))
    new_sr < eeg_sr(eeg) && (eeg_new = eeg_downsample(eeg, new_sr=new_sr))
    new_sr == eeg_sr(eeg) && (eeg_new = eeg)

    return eeg_new
end

"""
    eeg_resample!(eeg; new_sr)

Resample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate
"""
function eeg_resample!(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr > eeg_sr(eeg) && eeg_upsample!(eeg, new_sr=new_sr)
    new_sr < eeg_sr(eeg) && eeg_downsample!(eeg, new_sr=new_sr)

    return
end

"""
    eeg_upsample(eeg; new_sr)

Upsample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_upsample(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr / eeg_sr(eeg) != new_sr ÷ eeg_sr(eeg) && (@warn "New sampling rate should be easily captured by integer fractions e.g. 1000 Hz → 250 Hz or 256 Hz → 512 Hz.")
    
    t = eeg.eeg_time[1]:(1 / eeg.eeg_header[:sampling_rate][1]):eeg.eeg_time[end]
    s_upsampled, t_upsampled = s_resample(eeg.eeg_signals, t=t, new_sr=new_sr)

    t_upsampled = collect(t_upsampled)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_signals = s_upsampled
    eeg_new.eeg_time = t_upsampled
    eeg_new.eeg_header[:eeg_duration_samples] = size(s_upsampled, 2) * size(s_upsampled, 3)
    eeg_new.eeg_header[:eeg_duration_seconds] = (size(s_upsampled, 2) * size(s_upsampled, 3)) / new_sr
    eeg_new.eeg_header[:epoch_duration_samples] = size(s_upsampled, 2)
    eeg_new.eeg_header[:epoch_duration_seconds] = size(s_upsampled, 2) / new_sr
    eeg_new.eeg_header[:sampling_rate] = repeat([new_sr], eeg_channel_n(eeg_new))
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_upsample(EEG, new_sr=$new_sr)")

    return eeg_new
end

"""
    eeg_upsample!(eeg; new_sr)

Upsample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_upsample!(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr / eeg_sr(eeg) != new_sr ÷ eeg_sr(eeg) && (@warn "New sampling rate should be easily captured by integer fractions e.g. 1000 Hz → 250 Hz or 256 Hz → 512 Hz.")

    t = eeg.eeg_time[1]:(1 / eeg.eeg_header[:sampling_rate][1]):eeg.eeg_time[end]
    eeg.eeg_signals, t_upsampled = s_resample(eeg.eeg_signals, t=t, new_sr=new_sr)

    eeg.eeg_time = collect(t_upsampled)
    eeg.eeg_header[:eeg_duration_samples] = eeg_signal_len(eeg) * eeg_epoch_n(eeg)
    eeg.eeg_header[:eeg_duration_seconds] = (eeg_signal_len(eeg) * eeg_epoch_n(eeg)) / new_sr
    eeg.eeg_header[:epoch_duration_seconds] = eeg_signal_len(eeg)
    eeg.eeg_header[:epoch_duration_seconds] = eeg_signal_len(eeg) / new_sr
    eeg.eeg_header[:sampling_rate] = repeat([new_sr], eeg.eeg_header[:channel_n])
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_upsample!(EEG, new_sr=$new_sr)")

    return
end


"""
    eeg_downsample(eeg; new_sr)

Downsample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate

# Returns

- `eeg::NeuroJ.EEG`
"""
function eeg_downsample(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr < eeg_sr(eeg) && (@warn "To prevent aliasing due to down-sampling, a low-pass filter should be applied before removing data points. The filter cutoff should be the Nyquist frequency of the new down-sampled rate, ($(new_sr / 2) Hz), not the original Nyquist frequency ($(eeg_sr(eeg) / 2) Hz).")

    new_sr / eeg_sr(eeg) != new_sr ÷ eeg_sr(eeg) && (@warn "New sampling rate should be easily captured by integer fractions e.g. 1000 Hz → 250 Hz or 256 Hz → 512 Hz.")

    t = eeg.eeg_time[1]:(1 / eeg.eeg_header[:sampling_rate][1]):eeg.eeg_time[end]
    s_downsampled, t_downsampled = s_resample(eeg.eeg_signals, t=t, new_sr=new_sr)

    t_downsampled = collect(t_downsampled)
    eeg_new = deepcopy(eeg)
    eeg_new.eeg_time = t_downsampled
    eeg_new.eeg_signals = s_downsampled
    eeg_new.eeg_header[:eeg_duration_samples] = size(s_downsampled, 2) * size(s_downsampled, 3)
    eeg_new.eeg_header[:eeg_duration_seconds] = (size(s_downsampled, 2) * size(s_downsampled, 3)) / new_sr
    eeg_new.eeg_header[:epoch_duration_samples] = size(s_downsampled, 2)
    eeg_new.eeg_header[:epoch_duration_seconds] = size(s_downsampled, 2) / new_sr
    eeg_new.eeg_header[:sampling_rate] = repeat([new_sr], eeg_channel_n(eeg_new))
    eeg_reset_components!(eeg_new)
    push!(eeg_new.eeg_header[:history], "eeg_downsample(EEG, new_sr=$new_sr)")

    return eeg_new
end

"""
    eeg_downsample!(eeg; new_sr)

Downsample all channels of `eeg` to `new_sr` sampling frequency.

# Arguments

- `eeg::NeuroJ.EEG`
- `new_sr::Int64`: new sampling rate
"""
function eeg_downsample!(eeg::NeuroJ.EEG; new_sr::Int64)

    new_sr < eeg_sr(eeg) && (@warn "To prevent aliasing due to down-sampling, a low-pass filter should be applied before removing data points. The filter cutoff should be the Nyquist frequency of the new down-sampled rate, ($(new_sr / 2) Hz), not the original Nyquist frequency ($(eeg_sr(eeg) / 2) Hz).")

    new_sr / eeg_sr(eeg) != new_sr ÷ eeg_sr(eeg) && (@warn "New sampling rate should be easily captured by integer fractions e.g. 1000 Hz → 250 Hz or 256 Hz → 512 Hz.")

    t = eeg.eeg_time[1]:(1 / eeg.eeg_header[:sampling_rate][1]):eeg.eeg_time[end]
    eeg.eeg_signals, t_downsampled = s_resample(eeg.eeg_signals, t=t, new_sr=new_sr)

    eeg.eeg_time = collect(t_downsampled)
    eeg.eeg_header[:eeg_duration_samples] = eeg_signal_len(eeg) * eeg_epoch_n(eeg)
    eeg.eeg_header[:eeg_duration_seconds] = (eeg_signal_len(eeg) * eeg_epoch_n(eeg)) / new_sr
    eeg.eeg_header[:epoch_duration_samples] = eeg_signal_len(eeg)
    eeg.eeg_header[:epoch_duration_seconds] = eeg_signal_len(eeg) / new_sr
    eeg.eeg_header[:sampling_rate] = repeat([new_sr], eeg.eeg_header[:channel_n])
    eeg_reset_components!(eeg)
    push!(eeg.eeg_header[:history], "eeg_downsample!(EEG, new_sr=$new_sr)")

    return
end