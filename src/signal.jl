"""
    signal_derivative(signal)

Returns the derivative of the `signal` vector with length same as the signal.

# Arguments

- `signal::Vector{Float64}`
"""
signal_derivative(signal::Vector{Float64}) = vcat(diff(signal), diff(signal)[end])

"""
    signal_derivative(signal)

Returns the derivative of each the `signal` matrix channels with length same as the signal.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_derivative(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    signal_der = zeros(size(signal))
    epochs_no = size(signal, 3)

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_der[idx, :, epoch] = signal_derivative(signal[idx, :, epoch])
        end
    end

    return signal_der
end

"""
    signal_total_power(signal; fs)

Calculates total power for the `signal`.

# Arguments
- `signal::Vector{Float64}`
- `fs::Int64` - sampling rate
"""
function signal_total_power(signal::Vector{Float64}; fs::Int64)
    psd = welch_pgram(signal, 4*fs, fs=fs)
    # dx: frequency resolution
    dx = psd.freq[2] - psd.freq[1]
    stp = simpson(psd.power, dx=dx)

    return stp
end

"""
    signal_total_power(signal; fs)

Calculates total power for each the `signal` matrix channels.

# Arguments

- `signal::Array{Float64, 3}` - the signal array (rows: channels, columns: time)
- `fs::Int64` sampling rate
"""
function signal_total_power(signal::Array{Float64, 3}; fs::Int64)
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)
    stp = zeros(channels_no, epochs_no)

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            stp[idx, epoch] = signal_total_power(signal[idx, :, epoch], fs=fs)
        end
    end

    return stp
end

"""
    signal_band_power(signal; fs, f1, f2)

Calculates absolute band power between frequencies `f1` and `f2` for the `signal`.

# Arguments

- `signal::Vector{Float64}`
- `fs::Int64` - sampling rate of the signal
- `f1::Union{Int64, Float64}` - lower frequency bound
- `f2::Union{Int64, Float64}` - upper frequency bound
"""
function signal_band_power(signal::Vector{Float64}; fs::Int64, f1::Union{Int64, Float64}, f2::Union{Int64, Float64})
    psd = welch_pgram(signal, 4*fs, fs=fs)
    frq_idx = [vsearch(Vector(psd.freq), f1), vsearch(Vector(psd.freq), f2)]
    # dx: frequency resolution
    dx = psd.freq[2] - psd.freq[1]
    sbp = simpson(psd.power[frq_idx[1]:frq_idx[2]], psd.freq[frq_idx[1]:frq_idx[2]], dx=dx)

    return sbp
end

"""
    signal_band_power(signal, fs, f1, f2)

Calculates absolute band power between frequencies `f1` and `f2` for each the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
- `fs::Int64` - sampling rate
- `f1::Float64` - lower frequency bound
- `f2::Float64` - upper frequency bound
"""
function signal_band_power(signal::Array{Float64, 3}; fs::Int64, f1::Union{Int64, Float64}, f2::Union{Int64, Float64})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)
    sbp = zeros(channels_no, epochs_no)

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            sbp[idx, epoch] = signal_band_power(signal[idx, :, epoch], fs=fs, f1=f1, f2=f2)
        end
    end

    return sbp
end

"""
    signal_make_spectrum(signal, fs)

Returns FFT and DFT sample frequencies for a DFT for the `signal`.

# Arguments

- `signal::Vector{Float64}`
- `fs::Int64` - sampling rate
"""
function signal_make_spectrum(signal::Vector{Float64}, fs::Int64)
    signal_fft = fft(signal)
    # number of samples
    n = length(signal)
    # time between samples
    d = 1 / fs
    signal_sf = fftfreq(n, d)

    return signal_fft, signal_sf
end

"""
    signal_make_spectrum(signal, fs)

Returns FFT and DFT sample frequencies for a DFT for each the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
- `fs::Int64` - sampling rate
"""
function signal_make_spectrum(signal::Array{Float64, 3}, fs::Int64)
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)
    signal_fft = zeros(ComplexF64, size(signal))
    signal_sf = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_fft[idx, :, epoch], signal_sf[idx, :, epoch] = signal_make_spectrum(signal[idx, :, epoch], fs)
        end
    end

    return signal_fft, signal_sf
end

"""
    signal_detrend(signal; type=:linear)

Removes linear trend from the `signal`.

# Arguments

- `signal::Vector{Float64}`
- `type::Symbol[:linear, :constant]`, optional
    - `linear` - the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `constant` - the mean of `signal` is subtracted
"""
function signal_detrend(signal::Vector{Float64}; type::Symbol=:linear)
    type in [:linear, :constant] || throw(ArgumentError("""Trend type must be ":linear" or ":constant"."""))

    if type == :constant
        signal_det = demean(signal)
    else
        A = ones(length(signal))
        coef = A \ signal
        signal_det = @. signal - dot(A, coef)
    end

    return signal_det
end

"""
    signal_detrend(signal; type=:linear)

Removes linear trend for each the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
- `type::Symbol[:linear, :constant]`, optional
    - `linear` - the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `constant` - the mean of `signal` is subtracted
"""
function signal_detrend(signal::Array{Float64, 3}; type::Symbol=:linear)
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)
    signal_det = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_det[idx, :, epoch] = signal_detrend(signal[idx, :, epoch], type=type)
        end
    end

    return signal_det
end

"""
    signal_ci95(signal; n=3, method=:normal)

Calculates mean, std and 95% confidence interval for each the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
- `n::Int` - number of bootstraps
- `method::Symbol[:normal, :boot]` - use normal method or `n`-times boostrapping
"""
function signal_ci95(signal::Array{Float64, 3}; n::Int=3, method::Symbol=:normal)
    method in [:normal, :boot] || throw(ArgumentError("""Method must be ":normal" or ":boot"."""))

    if method === :normal
        signal_mean = mean(signal, dims=1)'
        signal_sd = std(signal, dims=1)' / sqrt(size(signal, 1))
        upper_bound = signal_mean + 1.96 * signal_sd
        lower_bound = signal_mean - 1.96 * signal_sd
    else
        signal_tmp1 = zeros(size(signal, 1) * n, size(signal, 2))
        Threads.@threads for idx1 in 1:size(signal, 1) * n
            signal_tmp2 = zeros(size(signal))
            sample_idx = rand(1:size(signal, 1), size(signal, 1))
            for idx2 in 1:size(signal, 1)
                signal_tmp2[idx2, :] = signal[sample_idx[idx2], :]'
            end
            signal_tmp1[idx1, :] = mean(signal_tmp2, dims=1)
        end
        signal_mean = mean(signal_tmp1, dims=1)'
        signal_sd = std(signal_tmp1, dims=1)' / sqrt(size(signal_tmp1, 1))
        signal_sorted = sort(signal_tmp1, dims=1)
        lower_bound = signal_sorted[round(Int, 0.025 * size(signal_tmp1, 1)), :]
        upper_bound = signal_sorted[round(Int, 0.975 * size(signal_tmp1, 1)), :]
    end

    return Vector(signal_mean[:, 1]), Vector(signal_sd[:, 1]), Vector(upper_bound[:, 1]), Vector(lower_bound[:, 1])
end

"""
    signal_mean(signal1, signal2)

Calculates mean and 95% confidence interval for 2 signals.

# Arguments

- `signal1::Matrix{Float64}`
- `signal2:Matrix{Float64}`
"""
function signal_mean(signal1::Matrix{Float64}, signal2::Matrix{Float64})
    size(signal1) != size(signal2) && throw(ArgumentError("Both matrices must be of the same as size."))

    signal1_mean = mean(signal1, dims=1)'
    signal2_mean = mean(signal2, dims=1)'
    signals_mean = signal1_mean - signal2_mean
    signal1_sd = std(signal1, dims=1) / sqrt(size(signal1, 1))
    signal2_sd = std(signal2, dims=1) / sqrt(size(signal2, 1))
    signals_mean_sd = sqrt.(signal1_sd.^2 .+ signal2_sd.^2)'

    return Vector(signals_mean[:, 1]), Vector(signals_mean_sd[:, 1]), Vector((signals_mean + 1.96 * signals_mean_sd)[:, 1]), Vector((signals_mean - 1.96 * signals_mean_sd)[:, 1])
end

"""
    signal_difference(signal1::Matrix, signal2::Matrix; n=3, method=:absdiff)

Calculates mean difference and 95% confidence interval for 2 signals.

# Arguments

- `signal1::Matrix`
- `signal2:Matrix`
- `n::Int` - number of bootstraps.
- `method::Symbol[:absdiff, :diff2int]`
    - `:absdiff` - maximum difference
    - `:diff2int` - integrated area of the squared difference
"""
function signal_difference(signal1::Matrix, signal2::Matrix; n=3, method=:absdiff)
    size(signal1) != size(signal2) && throw(ArgumentError("Both matrices must be of the same as size."))
    method in [:absdiff, :diff2int] || throw(ArgumentError("""Method must be ":absdiff" or ":diff2int"."""))

    signal1_mean = mean(signal1, dims=1)'
    signal2_mean = mean(signal2, dims=1)'

    if method === :absdiff
        # statistic: maximum difference
        signals_diff = signal1_mean - signal2_mean
        signals_statistic_single = maximum(abs.(signals_diff))
    else
        # statistic: integrated area of the squared difference
        signals_diff_squared = (signal1_mean - signal2_mean).^2
        signals_statistic_single = simpson(signals_diff_squared)
    end

    signals = [signal1; signal2]
    signals_statistic = zeros(size(signal1, 1) * n)

    Threads.@threads for idx1 in 1:(size(signal1, 1) * n)
        signals_tmp1 = zeros(size(signal1, 1), size(signal1, 2))
        sample_idx = rand(1:size(signals, 1), size(signals, 1))
        # sample_idx = sample_idx[1:1000]
        for idx2 in 1:size(signal1, 1)
            signals_tmp1[idx2, :] = signals[sample_idx[idx2], :]'
        end
        signal1_mean = mean(signals_tmp1, dims=1)
        signals_tmp1 = zeros(size(signal1, 1), size(signal1, 2))
        sample_idx = rand(1:size(signals, 1), size(signals, 1))
        # sample_idx = sample_idx[1:1000]
        for idx2 in 1:size(signal1, 1)
            signals_tmp1[idx2, :] = signals[sample_idx[idx2], :]'
        end
        signal2_mean = mean(signals_tmp1, dims=1)
        if method === :absdiff
            # statistic: maximum difference
            signals_diff = signal1_mean - signal2_mean
            signals_statistic[idx1] = maximum(abs.(signals_diff))
        else
            # statistic: integrated area of the squared difference
            signals_diff_squared = (signal1_mean - signal2_mean).^2
            signals_statistic[idx1] = simpson(signals_diff_squared)
        end
    end

    p = length(signals_statistic[signals_statistic .> signals_statistic_single]) / size(signal1, 1) * n

    return signals_statistic, signals_statistic_single, p
end

"""
   signal_autocov(signal; lag=1, remove_dc=false, normalize=false)

Calculates autocovariance of the `signal`.

# Arguments

- `signal::Vector{Float64}`
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool[true, false]` - demean `signal` prior to calculations
- `normalize::Bool[true, false]` - normalize autocovariance
"""
function signal_autocov(signal::Vector{Float64}; lag=1, remove_dc=false, normalize=false)
    signal_lags = collect(-lag:lag)

    if remove_dc == true
        signal_demeaned = signal .- mean(signal)
    else
        signal_demeaned = signal
    end

    signal_ac = zeros(length(signal_lags))

    for idx in 1:length(signal_lags)
        if signal_lags[idx] == 0
            # no lag
            signal_lagged = signal_demeaned
            signals_mul = signal_demeaned .* signal_lagged
        elseif signal_lags[idx] > 0
            # positive lag
            signal_lagged = signal_demeaned[1:(end - signal_lags[idx])]
            signals_mul = signal_demeaned[(1 + signal_lags[idx]):end] .* signal_lagged
        elseif signal_lags[idx] < 0
            # negative lag
            signal_lagged = signal_demeaned[(1 + abs(signal_lags[idx])):end]
            signals_mul = signal_demeaned[1:(end - abs(signal_lags[idx]))] .* signal_lagged
        end
        signals_sum = sum(signals_mul)
        if normalize == true
            signal_ac[idx] = signals_sum / length(signal)
        else
            signal_ac[idx] = signals_sum
        end
    end

    return signal_ac, signal_lags
end

"""
   signal_autocov(signal; lag=1, remove_dc=false, normalize=false)

Calculates autocovariance of each the `signal` channels.

# Arguments

- `signal::Matrix{Float64}`
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool` - demean signal prior to analysis
- `normalize::Bool` - normalize autocovariance
"""
function signal_autocov(signal::Matrix{Float64}; lag=1, remove_dc=false, normalize=false)
    signal_lags = collect(-lag:lag)
    channels_no = size(signal, 1)
    signal_ac = zeros(channels_no, length(signal_lags))

    for idx in 1:channels_no
        signal_ac[idx, :], _ = signal_autocov(signal[idx, :],
                                              lag=lag,
                                              remove_dc=remove_dc,
                                              normalize=normalize)
    end

    return signal_ac, signal_lags
end

"""
   signal_crosscov(signal1, signal2; lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance between `signal1` and `signal2`.

# Arguments

- `signal1::Vector{Float64}`
- `signal2::Vector{Float64}`
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool` - demean signal prior to analysis
- `normalize::Bool` - normalize cross-covariance
"""
function signal_crosscov(signal1::Vector{Float64}, signal2::Vector{Float64}; lag=1, remove_dc=false, normalize=false)
    length(signal1) != length(signal2) && throw(ArgumentError("Both vectors must be of the same as length."))

    lags = collect(-lag:lag)

    if remove_dc == true
        signal_demeaned1 = signal1 .- mean(signal1)
        signal_demeaned2 = signal2 .- mean(signal2)
    else
        signal_demeaned1 = signal1
        signal_demeaned2 = signal2
    end

    ac = zeros(length(lags))

    for idx in 1:length(lags)
        if lags[idx] == 0
            # no lag
            signal_lagged = signal_demeaned2
            signals_mul = signal_demeaned1 .* signal_lagged
        elseif lags[idx] > 0
            # positive lag
            signal_lagged = signal_demeaned2[1:(end - lags[idx])]
            signals_mul = signal_demeaned1[(1 + lags[idx]):end] .* signal_lagged
        elseif lags[idx] < 0
            # negative lag
            signal_lagged = signal_demeaned2[(1 + abs(lags[idx])):end]
            signals_mul = signal_demeaned1[1:(end - abs(lags[idx]))] .* signal_lagged
        end
        signals_sum = sum(signals_mul)
        if normalize == true
            ac[idx] = signals_sum / length(signal1)
        else
            ac[idx] = signals_sum
        end
    end

    return ac, lags
end

"""
   signal_crosscov(signal1, signal2; lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance between same channels in `signal1` and `signal2`.

# Arguments

- `signal1::Matrix{Float64}`
- `signal2::Matrix{Float64}`
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool` - demean signal prior to analysis
- `normalize::Bool` - normalize cross-covariance
"""
function signal_crosscov(signal1::Matrix{Float64}, signal2::Matrix{Float64}; lag=1, remove_dc=false, normalize=false)
    size(signal1) != size(signal2) && throw(ArgumentError("Both matrices must be of the same as size."))

    signal_lags = collect(-lag:lag)
    channels_no = size(signal1, 1)
    signal_ac = zeros(channels_no, length(signal_lags))

    for idx in 1:channels_no
        signal_ac[idx, :], _ = signal_crosscov(signal1[idx, :],
                                               signal2[idx, :],
                                               lag=lag,
                                               remove_dc=remove_dc,
                                               normalize=normalize)
    end

    return signal_ac, signal_lags
end

"""
   signal_crosscov(signal; lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance for all channels in the `signal`.

Returns matrix of cross-covariances:
- signal_1_channel_1 vs signal_2_channel_1
- signal_1_channel_1 vs signal_2_channel_2
- signal_1_channel_1 vs signal_2_channel_3
- ...
- signal_1_channel_n vs signal_2_channel_n

# Arguments

- `signal::Matrix{Float64}` - the signal
- `lag::Int64` - lags range is `-lag:lag`
- `remove_dc::Bool` - demean `signal` prior to analysis
- `normalize::Bool` - normalize cross-covariance
"""
function signal_crosscov(signal::Matrix{Float64}; lag::Int64=1, remove_dc::Bool=false, normalize::Bool=false)
    signal_lags = collect(-lag:lag)
    channels_no = size(signal, 1)
    signal_ac_packed = Array{Vector{Float64}}(undef, channels_no, channels_no)
    signal_ac = zeros(channels_no^2, channels_no)

    for idx1 in 1:channels_no
        for idx2 in 1:channels_no
            signal_ac_packed[idx1, idx2], _ = signal_crosscov(signal[idx1, :],
                                                              signal[idx2, :],
                                                              lag=lag,
                                                              remove_dc=remove_dc,
                                                              normalize=normalize)
        end
    end

    for idx in 1:channels_no^2
        signal_ac[idx, :] = signal_ac_packed[idx]
    end

    return reverse(signal_ac), signal_lags
end

"""
    signal_spectrum(signal; pad=0)

Calculates FFT, amplitudes, powers and phases of the `signal`.

# Arguments

- `signal::Vector{Float64}`
- `pad::Int64` - pad the `signal` with `pad` zeros
"""
function signal_spectrum(signal::Vector{Float64}; pad::Int64=0)
    pad < 0 && throw(ArgumentError("""Value of "pad" cannot be negative."""))

    if pad == 0
        signal_fft = fft(signal)
    else
        signal_fft = fft0(signal, pad)
    end

    # normalize
    signal_fft ./= length(signal)

    # amplitudes
    signal_amplitudes = @. 2 * abs(signal_fft)

    # power
    signal_powers = signal_amplitudes.^2

    # phases
    signal_phases = atan.(imag(signal_fft), real(signal_fft))

    return signal_fft, signal_amplitudes, signal_powers, signal_phases
end

"""
    signal_spectrum(signal; pad=0)

Calculates FFT, amplitudes, powers and phases for each channel of the `signal` matrix.

# Arguments

- `signal::Vector{Float64}` - the signal
- `pad::Int64` - pad the `signal` with `pad` zeros
"""
function signal_spectrum(signal::Array{Float64, 3}; pad::Int64=0)
    pad < 0 && throw(ArgumentError("""Value of "pad" cannot be negative."""))

    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_fft = zeros(ComplexF64, size(signal))
    signal_amplitudes = zeros(size(signal))
    signal_powers = zeros(size(signal))
    signal_phases = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_fft[idx, :, epoch], signal_amplitudes[idx, :, epoch], signal_powers[idx, :, epoch], signal_phases[idx, :, epoch] = signal_spectrum(signal[idx, :, epoch], pad=pad)
        end
    end

    return signal_fft, signal_amplitudes, signal_powers, signal_phases
end

"""
    signal_epochs(signal; epochs_no, epochs_len, average=true)

Splits `signal` into epochs.

# Arguments

- `signal::Vector{Float64}`
- `epochs_no::Union{Int64, Nothing}` - number of epochs
- `epochs_len::Union{Int64, Nothing}` - epoch length in samples
- `average::Bool` - average all epochs, returns one averaged epoch; if false than returns array of epochs, each row is one epoch
"""
function signal_epochs(signal::Vector{Float64}; epochs_no::Union{Int64, Nothing}=nothing, epochs_len::Union{Int64, Nothing}=nothing, average::Bool=true)
    (epochs_len === nothing && epochs_no === nothing) && throw(ArgumentError("Either number of epochs or epoch length must be set."))
    (epochs_len != nothing && epochs_no != nothing) && throw(ArgumentError("Both number of epochs and epoch length cannot be set."))

    if epochs_no === nothing
        epochs_no = length(signal) ÷ epochs_len
    else
        epochs_len = length(signal) ÷ epochs_no
    end

    epochs = zeros(epochs_no, epochs_len)

    idx1 = 1
    for idx2 in 1:epochs_len:(epochs_no * epochs_len - 1)
        epochs[idx1, :] = signal[idx2:(idx2 + epochs_len - 1)]
        idx1 += 1
    end

    if average == true
        epochs = Vector(mean(epochs, dims=1)[1, :])
    end

    return epochs
end

"""
    signal_epochs(signal; epochs_no=nothing, epochs_len=nothing, average=true)

Splits `signal` into epochs.

# Arguments

- `signal::Matrix{Float64}`
- `epochs_no::Union{Int64, Nothing}` - number of epochs
- `epochs_len::Union{Int64, Nothing}` - epoch length in samples
- `average::Bool` - average all epochs, returns one averaged epoch; if false than returns array of epochs, each row is one epoch
"""
function signal_epochs(signal::Matrix{Float64}; epochs_no::Union{Int64, Nothing}=nothing, epochs_len::Union{Int64, Nothing}=nothing, average::Bool=false)
    (epochs_len === nothing && epochs_no === nothing) && throw(ArgumentError("Either number of epochs or epoch length must be set."))
    (epochs_len != nothing && epochs_no != nothing) && throw(ArgumentError("Both number of epochs and epoch length cannot be set."))

    channels_no = size(signal, 1)

    if epochs_no === nothing
        epochs_no = size(signal, 2) ÷ epochs_len
    else
        epochs_len = size(signal, 2) ÷ epochs_no
    end

    epochs = zeros(channels_no, epochs_len, epochs_no)
    idx1 = 1
    for idx2 in 1:epochs_len:(epochs_no * epochs_len - 1)
        epochs[:, :, idx1] = signal[:, idx2:(idx2 + epochs_len - 1), 1]
        idx1 += 1
    end

    if average == true
        epochs = mean(epochs, dims=3)[:, :]
    end

    return epochs
end

"""
    signal_drop_channel(signal, channels)

Removes `channels` from the `signal`.

# Arguments

- `signal::Matrix{Float64}` - the signal
- `channels::Union{Int64, Vector{Int64}, UnitRange{Int64}}` - channels to be removed, vector of numbers or range
"""
function signal_drop_channel(signal::Matrix{Float64}, channels::Union{Int64, Vector{Int64}, UnitRange{Int64}})
    if typeof(channels) == UnitRange{Int64}
        channels = collect(channels)
    end

    channels = sort!(channels, rev=true)
    signal = signal[setdiff(1:end, (channels)), :, :]

    return signal
end

"""
    signal_reference_channel(signal, reference)

Re-references channels of the `signal` to specific signal channel.

# Arguments

- `signal::Array{Float64, 3}`
- `reference::Union{Int64, Vector{Int64}, UnitRange{Int64}}` - index of channels used as reference; if multiple channels are specified, their average is used as the reference
"""
function signal_reference_channel(signal::Array{Float64, 3}, reference_idx::Union{Int64, Vector{Int64}, UnitRange{Int64}})
    if typeof(reference_idx) == UnitRange{Int64}
        reference_idx = collect(reference_idx)
    end

    channels_no = size(signal, 1)
    signal_referenced = zeros(size(signal))

    channels_list = collect(1:channels_no)
    for idx in 1:length(reference_idx)
        if (reference_idx[idx] in channels_list) == false
            throw(ArgumentError("Reference channel index does not match signal channels."))
        end
    end

    reference_channel = mean(signal[reference_idx, :, :], dims=3)
    reference_channel = vec(mean(reference_channel, dims=1))

    epochs_no = size(signal, 3)

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_referenced[idx, :, epoch] = signal[idx, :, epoch] .- reference_channel
        end
    end

    return signal_referenced
end

"""
    signal_reference_channel(signal)

Re-references channels of the `signal` matrix to common average reference.

# Arguments

- `signal::Array{Float64, 3}` - signal
"""
function signal_reference_car(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_referenced = zeros(size(signal))
    reference_channel = mean(signal[:, :, :], dims=3)
    reference_channel = vec(mean(reference_channel, dims=1))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_referenced[idx, :, epoch] = signal[idx, :, epoch] .- reference_channel
        end
    end

    return signal_referenced
end

"""
    signal_taper(signal, taper)

Taper the `signal` with `taper`.

# Arguments

- `signal::Vector{Float64}`
- `taper::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}}`
"""
function signal_taper(signal::Vector{Float64}, taper::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}})
    length(taper) == length(signal) || throw(ArgumentError("Taper length and signal length must be equal."))
    signal_tapered = signal .* taper

    return signal_tapered
end

"""
    signal_taper(signal, taper)

Tapers channels of the `signal` with `taper`.

# Arguments

- `signal::Array{Float64, 3}`
- `taper::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}}`
"""
function signal_taper(signal::Array{Float64, 3}, taper::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}})
    length(taper) == size(signal, 2) || throw(ArgumentError("Taper length and signal length must be equal."))

    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)
    signal_tapered = zeros(eltype(taper), size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_tapered[idx, :, epoch] = signal_taper(signal[idx, :, epoch], taper)
        end
    end

    return signal_tapered
end

"""
    signal_demean(signal)

Removes mean value (DC offset) from the `signal`.

# Arguments

- `signal::Vector{Float64}`
"""
signal_demean(signal::Vector{Float64}) = signal .- mean(signal)

"""
    signal_demean(signal)

Removes mean value (DC offset) for each the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_demean(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_demeaned = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_demeaned[idx, :, epoch] = signal_demean(signal[idx, :, epoch])
        end
    end

    return signal_demeaned
end

"""
    signal_normalize_mean(signal)

Normalize (scales around the mean) `signal`.

# Arguments

- `signal::Vector{Float64}`
"""
signal_normalize_mean(signal::Vector{Float64}) = (signal .- mean(signal)) ./ std(signal)

"""
    signal_normalize_mean(signal)

Normalize (scales around the mean) each the `signal` channel.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_normalize_mean(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_normalized = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_normalized[idx, :, epoch] = signal_normalize_mean(signal[idx, :, epoch])
        end
    end

    return signal_normalized
end

"""
    signal_normalize_minmax(signal)

Normalize (to 0…1) `signal`.

# Arguments

- `signal::Vector{Float64}`
"""
signal_normalize_minmax(signal::Vector{Float64}) = (signal .- minimum(signal)) ./ (maximum(signal) - minimum(signal))

"""
    signal_normalize_minmax(signal)

Normalize (to 0…1) each the `signal` channel.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_normalize_minmax(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_normalized = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_normalized[idx, :, epoch] = signal_normalize_minmax(signal[idx, :, epoch])
        end
    end

    return signal_normalized
end

"""
   signal_cov(signal1, signal2; normalize=true)

Calculates covariance between `signal1` and `signal2`.

# Arguments

- `signal1::Vector{Float64}`
- `signal2::Vector{Float64}`
- `normalize::Bool` - normalize covariance
"""
function signal_cov(signal1::Vector{Float64}, signal2::Vector{Float64}; normalize::Bool=true)
    length(signal1) != length(signal2) && throw(ArgumentError("Both vectors must be of the same as length."))

    result = cov(signal1 * signal2')

    # divide so that components are centered at (0, 0)
    normalize == true && (result = result ./ length(signal1))

    return result
end

"""
   signal_cov(signal; normalize=true)

Calculates covariance between all channels of the `signal`.

# Arguments

- `signal::Array{Float64, 3}`
- `normalize::Bool` - normalize covariance
"""
function signal_cov(signal::Array{Float64, 3}; normalize::Bool=true)
    epochs_no = size(signal, 3)
    cov_mat = zeros(size(signal, 1), size(signal, 1), epochs_no)

    for epoch in 1:epochs_no
        # channels-vs-channels
        cov_mat[:, :, epoch] = cov(signal[:, :, epoch]')
    end

    # divide so that components are centered at (0, 0)
    normalize == true && (cov_mat = cov_mat ./ size(cov_mat, 2))

    return cov_mat
end

"""
   signal_cor(signal)

Calculates correlation coefficients between all channels of the `signal`.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_cor(signal::Array{Float64, 3})
    epochs_no = size(signal, 3)
    cor_mat = zeros(size(signal, 1), size(signal, 1), epochs_no)

    for epoch in 1:epochs_no
        # channels-vs-channels
        cor_mat[:, :, epoch] = cor(signal[:, :, epoch]')
    end

    return cor_mat
end

"""
    signal_add_noise(signal)

Add random noise to the `signal`.

# Arguments

- `signal::Vector{Float64}`
"""
signal_add_noise(x::Vector{Float64}) = x .+ mean(x) .* rand(length(x))

"""
    signal_add_noise(signal)

Add random noise to the `signal` channels.

# Arguments

- `signal::Array{Float64, 3}`
"""
function signal_add_noise(signal::Array{Float64, 3})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_noise = zeros(size(signal))

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_noise[idx, :, epoch] = signal_add_noise(signal[idx, :, epoch])
        end
    end

    return signal_noise
end

"""
    signal_upsample(signal; t, new_sr)

Upsamples the`signal` to `new_sr` sampling frequency.

# Arguments

- `signal::Vector{Float64}`
- `t::AbstractRange` - time range
- `new_sr::Int64` - new sampling rate
"""
function signal_upsample(signal::Vector{Float64}; t::AbstractRange, new_sr::Int64)
    # sampling interval
    dt = t[2] - t[1]
    # sampling rate
    sr = 1 / dt
    new_sr < sr && throw(ArgumentError("New sampling rate mu be larger than signal sampling rate."))
    new_sr == sr && return(signal)

    # interpolate
    signal_interpolation = CubicSplineInterpolation(t, signal)
    t_upsampled = t[1]:1/new_sr:t[end]
    signal_upsampled = signal_interpolation(t)

    return signal_upsampled, t_upsampled
end

"""
    signal_upsample(signal; t, new_sr)

Upsamples all channels of the`signal` to `new_sr` sampling frequency.

# Arguments

- `signal::Array{Float64, 3}`
- `t::AbstractRange` - the time range
- `new_sr::Int64` - new sampling rate
"""
function signal_upsample(signal::Array{Float64, 3}; t::AbstractRange, new_sr::Int64)
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_upsampled_length = length(signal_upsample(signal[1, :, 1], t=t, new_sr=new_sr)[1])
    signal_upsampled = zeros(channels_no, signal_upsampled_length, epochs_no) 

    t_upsampled = nothing
    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_upsampled[idx, :, epoch], t_upsampled = signal_upsample(signal[idx, :, epoch], t=t, new_sr=new_sr)
        end
    end

    return signal_upsampled, t_upsampled
end

"""
    morlet(fs, wt, wf)

Generates Morlet wavelet.

# Arguments

- `fs::Int64` - sampling frequency
- `wt::Union{Int64, Float64}` - length = -wt:1/fs:ws
- `wf::Union{Int64, Float64}` - frequency
- `ncyc::Int64` - number of cycles
- `complex::Bool` - if true, generates complex Morlet
"""
function morlet(fs::Int64, wt::Union{Int64, Float64}, wf::Union{Int64, Float64}; ncyc::Int64=5, complex::Bool=false)
    wt = -wt:1/fs:wt
    complex == false && (sin_wave = @. cos(2 * pi * wf * wt))           # for symmetry at x = 0
    complex == true && (sin_wave = @. exp(im * 2 * pi * wf * wt))       # for symmetry at x = 0
    w = 2 * (ncyc / (2 * pi * wf))^2                                    # ncyc: time-frequency precision
    gaussian = @. exp((-wt.^2) / w)
    morlet_wavelet = sin_wave .* gaussian
    return morlet_wavelet
end

"""
    signal_tconv(signal, kernel)

Performs convolution in the time domain between `signal` and `kernel`.

# Arguments

- `signal::Vector{Float64}`
- `kernel::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}}`
"""
function signal_tconv(signal::Vector{Float64}, kernel::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}})
    signal_convoluted = conv(signal, kernel)
    half_kernel = floor(Int, length(kernel) / 2)
    signal_convoluted = signal_convoluted[(half_kernel + 1):(end - half_kernel)]

    return signal_convoluted
end

"""
    signal_tconv(signal, kernel)

Performs convolution in the time domain between `signal` and `kernel`.

# Arguments

- `signal::Array{Float64, 3}`
- `kernel::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}}`
"""
function signal_tconv(signal::Array{Float64, 3}, kernel::Union{Vector{Int64}, Vector{Float64}, Vector{ComplexF64}})
    channels_no = size(signal, 1)
    epochs_no = size(signal, 3)

    signal_convoluted = zeros(eltype(kernel), size(signal)) 

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_convoluted[idx, :, epoch] = signal_tconv(signal[idx, :, epoch], kernel)
        end
    end

    return signal_convoluted
end

"""
    signal_filter(signal; fprototype, ftype, cutoff, fs, order=8, window=hanning(64))

Filters `signal` using zero phase distortion filter.

# Arguments

- `signal::Vector{Float64}`
- `fprototype::Symbol[:butterworth, :fir]
- `ftype::Symbol[:lp, :hp, :bp, :bs]` - filter type
- `cutoff::Union{Int64, Float64, Vector{Int64}, Vector{Float64}}` - filter cutoff in Hz (vector for `:bp` and `:bs`)
- `fs::Int64` - sampling rate
- `order::Int64` - filter order
- `window::Vector{Float64} - window, required for FIR filter
"""
function signal_filter(signal::Vector{Float64}; fprototype::Symbol, ftype::Symbol, cutoff::Union{Int64, Float64, Vector{Int64}, Vector{Float64}}, fs::Int64, order::Int64=8, window::Vector{Float64}=hanning(64))
    ftype in [:lp, :hp, :bp, :bs] || throw(ArgumentError("""Filter type must be ":bp", ":hp", ":bp" or ":bs"."""))
    fprototype in [:butterworth, :fir] || throw(ArgumentError("""Filter prototype must be ":butterworth" or ":fir"."""))

    if ftype == :lp
        length(cutoff) > 1 && throw(ArgumentError("For low-pass filter one frequency must be given."))
        responsetype = Lowpass(cutoff; fs=fs)
    elseif ftype == :hp
        length(cutoff) > 1 && throw(ArgumentError("For high-pass filter one frequency must be given."))
        responsetype = Highpass(cutoff; fs=fs)
        mod(length(window), 2) == 0 && (window = vcat(window[1:((length(window) ÷ 2) - 1)], window[((length(window) ÷ 2) + 1):end]))
    elseif ftype == :bp
        responsetype = Bandpass(cutoff[1], cutoff[2]; fs=fs)
        mod(length(window), 2) == 0 && (window = vcat(window[1:((length(window) ÷ 2) - 1)], window[((length(window) ÷ 2) + 1):end]))
    elseif ftype == :bs
        length(cutoff) < 2 && throw(ArgumentError("For band-stop filter two frequencies must be given."))
        responsetype = Bandstop(cutoff[1], cutoff[2]; fs=fs)
        mod(length(window), 2) == 0 && (window = vcat(window[1:((length(window) ÷ 2) - 1)], window[((length(window) ÷ 2) + 1):end]))
    end

    fprototype == :butterworth && (prototype = Butterworth(order))
    fprototype == :fir && (prototype = FIRWindow(window))

    filter = digitalfilter(responsetype, prototype)
    signal_filtered = filtfilt(filter, signal)

    return signal_filtered
end

"""
    signal_filter(signal; fprototype, ftype, cutoff, fs, order=8, window=hanning(64))

Filters `signal` using zero phase distortion filter.

# Arguments

- `signal::Array{Float64, 3}`
- `fprototype::Symbol[:butterworth, :fir]
- `ftype::Symbol[:lp, :hp, :bp, :bs]` - filter type
- `cutoff::Union{Int64, Float64, Vector{Int64}, Vector{Float64}}` - filter cutoff in Hz (vector for `:bp` and `:bs`)
- `fs::Int64` - sampling rate
- `order::Int64` - filter order
- `window::Vector{Float64} - window, required for FIR filter
"""
function signal_filter(signal::Array{Float64, 3}; fprototype::Symbol, ftype::Symbol, cutoff::Union{Int64, Float64, Vector{Int64}, Vector{Float64}}, fs::Int64, order::Int64=8, window::Vector{Float64}=hanning(64))
    channels_no = size(signal, 1)
    signal_filtered = zeros(size(signal))
    epochs_no = size(signal, 3)

    for epoch in 1:epochs_no
        for idx in 1:channels_no
            signal_filtered[idx, :, epoch] = signal_filter(signal[idx, :, epoch],
                                                           fprototype=fprototype,
                                                           ftype=ftype,
                                                           cutoff=cutoff,
                                                           fs=fs,
                                                           order=order,
                                                           window=window)
        end
    end

    return signal_filtered
end