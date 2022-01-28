"""
    signal_derivative(signal)

Returns the derivative of the `signal` vector with length same as the signal.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
"""
signal_derivative(signal::Vector{Float64}) = vcat(diff(signal), diff(signal)[end])

"""
    signal_derivative(signal)

Returns the derivative of each the `signal` matrix channels with length same as the signal.

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze (rows: channels, columns: time).
"""
function signal_derivative(signal::Matrix{Float64})
    channels_no = size(signal, 1)
    signal_der = zeros(size(signal))

    for idx in 1:channels_no
        signal_der[idx, :] = signal_derivative(signal[idx, :])
    end

    return signal_der
end

"""
    signal_total_power(signal)

Calculates total power for the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
"""
function signal_total_power(signal::Vector{Float64}, fs)
    psd = welch_pgram(signal, 4*fs, fs=fs)
    # dx: frequency resolution
    dx = psd.freq[2] - psd.freq[1]
    stp = simpson(psd.power, dx=dx)

    return stp
end

"""
    signal_total_power(signal)

Calculates total power for each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze (rows: channels, columns: time).
"""
function signal_total_power(signal::Matrix{Float64}, fs)
    channels_no = size(signal, 1)
    stp = zeros(size(signal, 1))

    for idx in 1:channels_no
        stp[idx] = signal_total_power(signal[idx, :])
    end

    return stp
end

"""
    signal_band_power(signal, f1, f2)

Calculates absolute band power between frequencies `f1` and `f2` for the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
- `fs::Float64` - Sampling rate of the signal
- `f1::Float64` - Lower frequency bound
- `f2::Float64` - Upper frequency bound
"""
function signal_band_power(signal::Vector{Float64}, fs::Float64, f1::Float64, f2::Float64)
    psd = welch_pgram(signal, 4*fs, fs=fs)
    frq_idx = [vsearch(Vector(psd.freq), f1), vsearch(Vector(psd.freq), f2)]
    # dx: frequency resolution
    dx = psd.freq[2] - psd.freq[1]
    sbp = simpson(psd.power[frq_idx[1]:frq_idx[2]], psd.freq[frq_idx[1]:frq_idx[2]], dx=dx)

    return sbp
end

"""
    signal_band_power(signal, f1, f2)

Calculates absolute band power between frequencies `f1` and `f2` for each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze
- `fs::Float64` - Sampling rate of the signal
- `f1::Float64` - Lower frequency bound
- `f2::Float64` - Upper frequency bound
"""
function signal_band_power(signal::Matrix{Float64}, fs, f1, f2)
    channels_no = size(signal, 1)
    sbp = zeros(size(signal, 1))

    for idx in 1:channels_no
        sbp[idx] = signal_band_power(signal[idx, :], fs, f1, f2)
    end

    return sbp
end

"""
    make_spectrum(signal, fs)

Returns FFT and DFT sample frequencies for a DFT for the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
- `fs::Float64` - Sampling rate of the signal
"""
function signal_make_spectrum(signal::Vector{Float64}, fs)
    signal_fft = fft(signal)
    # number of samples
    n = length(signal)
    # time between samples
    d = 1 / fs
    signal_sf = fftfreq(n, d)

    return signal_fft, signal_sf
end

"""
    make_spectrum(signal, fs)

Returns FFT and DFT sample frequencies for a DFT for each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze
- `fs::Float64` - Sampling rate of the signal
"""
function signal_make_spectrum(signal::Matrix{Float64}, fs)
    channels_no = size(signal, 1)
    signal_fft = zeros(ComplexF64, size(signal))
    signal_sf = zeros(size(signal))

    for idx in 1:channels_no
        signal_fft[idx, :], signal_sf[idx, :] = signal_make_spectrum(signal[idx, :], fs)
    end

    return signal_fft, signal_sf
end

"""
    signal_detrend(signal, type=:linear)

Removes linear trend from the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
- `type::Symbol[:linear, :constant]`, optional
    - `linear` - the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `constant` - the mean of `signal` is subtracted
"""
function signal_detrend(signal::Vector{Float64}; trend=:linear)
    trend in [:linear, :constant] || throw(ArgumentError("""Trend type must be ":linear" or ":constant"."""))

    if trend == :constant
        signal_det = demean(signal)
    else
        A = ones(length(signal))
        coef = A \ signal
        signal_det = @. signal - dot(A, coef)
    end

    return signal_det
end

"""
    signal_detrend(signal, type=:linear)

Removes linear trend for each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` the signal matrix to analyze
- `type::Symbol[:linear, :constant]`, optional
    - `linear` - the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `constant` - the mean of `signal` is subtracted
"""
function signal_detrend(signal::Matrix{Float64}; trend=:linear)
    trend in [:linear, :constant] || throw(ArgumentError("""Trend type must be ":linear" or ":constant"."""))
    channels_no = size(signal, 1)
    signal_det = zeros(size(signal))

    for idx in 1:channels_no
        signal_det[idx, :] = signal_detrend(signal[idx, :], trend=trend)
    end

    return signal_det
end

"""
    signal_ci95(signal, n=3; method=:normal)

Calculates mean, std and 95% confidence interval for each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze
- `n::Int` - number of bootstraps.
- `method::Symbol[:normal, :boot]` - use normal method or `n`-times boostrapping.
"""
function signal_ci95(signal::Matrix{Float64}; n=3, method=:normal)
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

- `signal1::Matrix{Float64}` - the signal 1 matrix to analyze
- `signal2:Matrix{Float64}` - the signal 2 matrix to analyze
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
    signal_difference(signal1::Matrix, signal2::Matrix, n=3; method=:absdiff)

Calculates mean difference and 95% confidence interval for 2 signals.

# Arguments

- `signal1::Matrix` - the signal 1 matrix to analyze
- `signal2:Matrix` - the signal 2 matrix to analyze
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
        signals_statistic_single = findmax(abs.(signals_diff))[1]
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
            signals_statistic[idx1] = findmax(abs.(signals_diff))[1]
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
   signal_autocov(signal, lag=1, remove_dc=false, normalize=false)

Calculates autocovariance of the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
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
   signal_autocov(signal, lag=1, remove_dc=false, normalize=false)

Calculates autocovariance of each the `signal` matrix channels.

# Arguments

- `signal::Matrix{Float64}` - the signal vector to analyze
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool[true, false]` - demean signal prior to analysis
- `normalize::Bool[true, false]` - normalize autocovariance
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
   signal_crosscov(signal1, signal2, lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance between `signal1` and `signal2` vectors.

# Arguments

- `signal1::Vector{Float64}` - the signal 1 vector to analyze
- `signal2::Vector{Float64}` - the signal 2 vector to analyze
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool[true, false]` - demean signal prior to analysis
- `normalize::Bool[true, false]` - normalize cross-covariance
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
   signal_crosscov(signal1, signal2, lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance between same channels in `signal1` and `signal2` matrices.

# Arguments

- `signal1::Matrix{Float64}` - the signal 1 matrix to analyze
- `signal2::Matrix{Float64}` - the signal 2 matrix to analyze
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool[true, false]` - demean signal prior to analysis
- `normalize::Bool[true, false]` - normalize cross-covariance
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
   signal_crosscov(signal, lag=1, remove_dc=false, normalize=false)

Calculates cross-covariance for all channels in the `signal` matrix. Return matrix of cross-covariances:
signal_1_channel_1 vs signal_2_channel_1, signal_1_channel_1 vs signal_2_channel_2, signal_1_channel_1 vs signal_2_channel_3, ..., signal_1_channel_n vs signal_2_channel_n, 

# Arguments

- `signal::Matrix{Float64}` - the signal matrix to analyze
- `lag::Int` - lags range is `-lag:lag`
- `remove_dc::Bool[true, false]` - demean `signal` prior to analysis
- `normalize::Bool[true, false]` - normalize cross-covariance
"""
function signal_crosscov(signal::Matrix{Float64}; lag=1, remove_dc=false, normalize=false)
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
    signal_spectrum(signal, pad=0, remove_dc=false, detrend=false, taper=nothing)

Calculates FFT, amplitudes, powers and phases of the `signal` vector.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
- `pad::Int` - pad the `signal` with `pad` zeros
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_spectrum(signal::Vector{Float64}; pad::Int=0, remove_dc=false, detrend=false, derivative=false, taper=nothing)
    pad < 0 && throw(ArgumentError("""Value of "pad" cannot be negative."""))

    remove_dc == true && (signal = demean(signal))
    detrend == true && (signal = signal_detrend(signal))
    derivative == true && (signal = signal_derivative(signal))
    taper !== nothing && (signal = signal .* taper)

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
    signal_spectrum(signal, pad=0, remove_dc=false, detrend=false, taper=nothing)

Calculates FFT, amplitudes, powers and phases for each channel of the `signal` matrix.

# Arguments

- `signal::Vector{Float64}` - the signal matrix to analyze
- `pad::Int` - pad the `signal` with `pad` zeros
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_spectrum(signal::Matrix{Float64}; pad::Int=0, remove_dc=false, detrend=false, derivative=false, taper=nothing)
    pad < 0 && throw(ArgumentError("""Value of "pad" cannot be negative."""))

    channels_no = size(signal, 1)

    signal_fft = zeros(ComplexF64, size(signal))
    signal_amplitudes = zeros(size(signal))
    signal_powers = zeros(size(signal))
    signal_phases = zeros(size(signal))

    for idx in 1:channels_no
        signal_fft[idx, :], signal_amplitudes[idx, :], signal_powers[idx, :], signal_phases[idx, :] = 
        signal_spectrum(signal[idx, :],
                        pad=pad,
                        remove_dc=remove_dc,
                        detrend=detrend,
                        derivative=derivative,
                        taper=taper)
    end

    return signal_fft, signal_amplitudes, signal_powers, signal_phases
end

"""
    signal_epoch(signal; epoch_no, epoch_len, average=true, remove_dc=false, detrend=false, derivative=false, taper=nothing)

Splits `signal` vector into epochs.

# Arguments
- `signal::Vector{Float64}` - the signal vector to analyze
- `epoch_no::Int` - number of epochs
- `epoch_len::Int` - epoch length in samples
- `average::Bool` - average all epochs, returns one averaged epoch; if false than returns array of epochs, each row is one epoch
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_epoch(signal::Vector{Float64}; epoch_no=nothing, epoch_len=nothing, average=true, remove_dc=false, detrend=false, derivative=false, taper=nothing)
    (epoch_len == nothing && epoch_no == nothing) && throw(ArgumentError("Either number of epochs or epoch length must be set."))
    (epoch_len != nothing && epoch_no != nothing) && throw(ArgumentError("Both number of epochs and epoch length cannot be set."))

    if epoch_no == nothing
        epoch_no = length(signal) ÷ epoch_len
    else
        epoch_len = length(signal) ÷ epoch_no
    end

    epochs = zeros(epoch_no, epoch_len)

    remove_dc == true && (signal = demean(signal))
    detrend == true && (signal = signal_detrend(signal))
    derivative == true && (signal = signal_derivative(signal))
    taper !== nothing && (signal = signal .* taper)

    idx1 = 1
    for idx2 in 1:epoch_len:(epoch_no * epoch_len - 1)
        epochs[idx1, :] = signal[idx2:(idx2 + epoch_len - 1)]
        idx1 += 1
    end

    if average == true
        epochs = Vector(mean(epochs, dims=1)[1, :])
    end

    return epochs
end

"""
    signal_epoch(signal, n; average=true, remove_dc=false, detrend=false, derivative=false, taper=nothing)

Splits `signal` matrix into epochs.

# Arguments
- `signal::Matrix{Float64}` - the signal matrix to analyze
- `epoch_no::Int` - number of epochs
- `epoch_len::Int` - epoch length in samples
- `average::Bool` - average all epochs, returns one averaged epoch; if false than returns array of epochs, each row is one epoch
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_epoch(signal::Matrix; epoch_no=nothing, epoch_len=nothing, average=true, remove_dc=false, detrend=false, derivative=false, taper=nothing)
    (epoch_len == nothing && epoch_no == nothing) && throw(ArgumentError("Either number of epochs or epoch length must be set."))
    (epoch_len != nothing && epoch_no != nothing) && throw(ArgumentError("Both number of epochs and epoch length cannot be set."))

    channels_no = size(signal, 1)

    if epoch_no == nothing
        epoch_no = size(signal, 2) ÷ epoch_len
    else
        epoch_len = size(signal, 2) ÷ epoch_no
    end

    epochs = zeros(channels_no, epoch_len, epoch_no)

    remove_dc == true && (signal = demean(signal))
    detrend == true && (signal = signal_detrend(signal))
    derivative == true && (signal = signal_derivative(signal))
    taper !== nothing && (signal = signal .* taper)

    idx1 = 1
    for idx2 in 1:epoch_len:(epoch_no * epoch_len - 1)
        epochs[:, :, idx1] = signal[:, idx2:(idx2 + epoch_len - 1)]
        idx1 += 1
    end

    if average == true
        epochs = mean(epochs, dims=3)[:, :]
    end

    return epochs
end

"""
    signal_filter_butter(signal; filter_type, cutoff, fs, poles=8)

Filters `signal` vector using Butterworth filter.

# Arguments

- `signal::Vector{Float64}` - the signal vector to analyze
- `filter_type::Symbol[:lp, :hp, :bp, :bs]` - filter type
- `cutoff::Float64` - filter cutoff in Hz (tuple or vector for `:bp` and `:bs`)
- `fs::Float64` - sampling rate
- `poles::Int` - filter pole
"""
function signal_filter_butter(signal::Vector{Float64}; filter_type, cutoff, fs, poles=8)
    filter_type in [:lp, :hp, :bp, :bs] || throw(ArgumentError("""Filter type must be ":bp", ":hp", ":bp" or ":bs"."""))

    if filter_type == :lp
        responsetype = Lowpass(cutoff; fs=fs)
        prototype = Butterworth(poles)
    elseif filter_type == :hp
        responsetype = Highpass(cutoff; fs=fs)
        prototype = Butterworth(poles)
    elseif filter_type == :bp
        length(cutoff) < 2 && throw(ArgumentError("For band-pass filter two frequencies must be given."))
        responsetype = Bandpass(cutoff[1], cutoff[2]; fs=fs)
        prototype = Butterworth(poles)
    elseif filter_type == :bs
        length(cutoff) < 2 && throw(ArgumentError("For band-stop filter two frequencies must be given."))
        responsetype = Bandstop(cutoff[1], cutoff[2]; fs=fs)
        prototype = Butterworth(poles)
    end

    filter = digitalfilter(responsetype, prototype)
    signal_filtered = filt(filter, signal)

    return signal_filtered
end

"""
    signal_filter_butter(signal; filter_type, cutoff, fs, poles=8)

Filters `signal` matrix using Butterworth filter.

# Arguments
- `signal::Matrix{Float64}` - the signal matrix to analyze
- `filter_type::Symbol[:lp, :hp, :bp, :bs]` - filter type
- `cutoff::Float64` - filter cutoff in Hz (tuple or vector for `:bp` and `:bs`)
- `fs::Float64` - sampling rate
- `poles::Int` - filter pole
"""
function signal_filter_butter(signal::Matrix{Float64}; filter_type, cutoff, fs, poles=8)
    filter_type in [:lp, :hp, :bp, :bs] || throw(ArgumentError("""Filter type must be ":bp", ":hp", ":bp" or ":bs"."""))

    no_channels = size(signal, 1)
    signal_filtered = zeros(size(signal))

    for idx in 1:no_channels
        signal_filtered[idx, :] = signal_filter_butter(signal[idx, :], filter_type=filter_type, cutoff=cutoff, fs=fs, poles=poles)
    end

    return signal_filtered
end

"""
    signal_plot(t, signal; labels=[], normalize=false, xlabel="Time [s]", ylabel="Amplitude [μV]")

Plots `signal` against `t`ime.

# Arguments
- `t::Vector{Float64}` - the time vector
- `signal::Vector{Float64}` - the signal vector
- `labels::Vector{String}` - channel labels vector
- `xlabel::String` - x-axis label
- `ylabel::String` - y-axis lable
- `yamp::Float64` - y-axis limits (-yamp:yamp)
- `normalize::Bool` - normalize the `signal` prior to calculations
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_plot(t::Vector{Float64}, signal::Vector{Float64}; labels=[], xlabel="Time [s]", ylabel="Amplitude [μV]", yamp=nothing, normalize=false, remove_dc=false, detrend=false, derivative=false, taper=nothing)

    normalize == true && (signal = normalize_mean(signal))
    remove_dc == true && (signal = demean(signal))
    detrend == true && (signal = signal_detrend(signal))
    derivative == true && (signal = signal_derivative(signal))
    taper !== nothing && (signal = signal .* taper)

    if yamp == nothing
        yamp, _ = findmax(signal)
        yamp = ceil(Int64, yamp)
    end

    p = plot(t, signal, xlabel=xlabel, ylabel=ylabel, legend=false, t=:line, c=:black, ylims=(-yamp, yamp))
    return p
end

"""
    signal_plot(t, signal; channels=[], labels=[], normalize=false, xlabel="Time [s]", ylabel="Channels")

Plots `signal` matrix.

# Arguments
- `t::Vector{Float64}` - the time vector
- `signal::Matrix{Float64}` - the signal matrix
- `channels::Float64` - channels to be plotted (all if empty), vector or range
- `labels::Vector{String}` - channel labels vector
- `xlabel::String` - x-axis label
- `ylabel::String` - y-axis lable
- `normalize::Bool` - normalize the `signal` prior to calculations
- `remove_dc::Bool` - demean the `signal` prior to calculations
- `detrend::Bool` - detrend the `signal` prior to calculations
- `derivative::Bool` - derivate `signal` prior to calculations
- `taper::Bool` - taper the `signal` with `taper`-window prior to calculations
"""
function signal_plot(t::Vector{Float64}, signal::Matrix{Float64}; channels=[], labels=[], xlabel="Time [s]", ylabel="Channels", normalize=true, remove_dc=false, detrend=false, derivative=false, taper=nothing)
    
    if typeof(channels) == UnitRange{Int64}
        channels = collect(channels)
    end

    channels_no = size(signal, 1)

    # drop channels not in the list
    channels_to_drop = collect(1:channels_no)
    if length(channels) > 1
        for idx in length(channels):-1:1
            channels_to_drop = deleteat!(channels_to_drop, channels[idx])
        end
        signal = eeg_drop_channel(signal, channels_to_drop)
    end

    channels_no = size(signal, 1)

    remove_dc == true && (signal = demean(signal))
    detrend == true && (signal = signal_detrend(signal))
    derivative == true && (signal = signal_derivative(signal))
    taper !== nothing && (signal = signal .* taper)

    # reverse so 1st channel is on top
    signal = reverse(signal, dims = 1)

    if normalize == true
        # normalize and shift so all channels are visible
        variances = var(signal; dims=2)
        mean_variance = mean(variances)
        for idx in 1:channels_no
            signal[idx, :] = (signal[idx, :] .- mean(signal[idx, :])) ./ mean_variance .+ (idx - 1)
        end
    end

    # plot channels
    p = plot(xlabel=xlabel, ylabel=ylabel, ylim=(-0.5, channels_no-0.5))
    for idx in 1:channels_no
        p = plot!(t, signal[idx, :], legend=false, t=:line, c=:black)
    end
    p = plot!(p, yticks = (channels_no-1:-1:0, labels))

    return p
end

"""
    signal_drop_channel(signal, channels)

Removes `channels` from the `signal` matrix.

# Arguments
- `signal::Matrix{Float64}` - the signal matrix
- `channels::Float64` - channels to be removed, vector of numbers or range
"""
function signal_drop_channel(signal::Matrix, channels)
    if typeof(channels) == UnitRange{Int64}
        channels = collect(channels)
    end

    channels = sort!(channels, rev=true)
    signal = signal[setdiff(1:end, (channels)), :]

    return signal
end