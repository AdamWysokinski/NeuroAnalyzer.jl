"""
    linspace(start, stop, length)

Generates a sequence of evenly spaced numbers between `start` and `stop`.

# Arguments

- `start::Number`
- `stop::Number`
- `n::Int64`: sequence length

# Returns

- `range::Vector`
"""
function linspace(start::Number, stop::Number, n::Int64)
    n < 2 && throw(ArgumentError("n must be ≥ 2."))
    return collect(range(start, stop, n))
end

"""
    logspace(start, stop, n)

Generates a sequence of log10-spaced numbers between `start` and `stop`.

# Arguments

- `start::Number`
- `stop::Number`
- `n::Int64`: sequence length

# Returns

- `range::Vector{<:Number}`
"""
function logspace(start::Number, stop::Number, n::Int64)
    n < 2 && throw(ArgumentError("n must be ≥ 2."))
    return collect(exp10.(range(start, stop, n)))
end

"""
    m_pad0(m)

Pad matrix with zeros to make it square.

# Arguments

- `m::Matrix{<:Number}`

# Returns

- `m::Matrix{<:Number}`
"""
function m_pad0(m::Matrix{<:Number})

    nr, nc = size(m)

    if nr > nc
        # horizontal
        return hcat(m, repeat(zeros(eltype(m), 1), nr, nr - nc))
    elseif nr < nc
        # vertical
        return vcat(m, repeat(zeros(eltype(m), 1), nc - nr, nc))
    else
        return m
    end
end

"""
    vsearch(y, x; return_distance)

Return the positions of the `y` value in the vector `x`.

# Arguments

- `y::Real`: value of interest
- `x::AbstractVector`: vector to search within
- `acc::Bool=false`: if true, return the difference between `y` and `x[y_idx]`

# Returns

- `y_idx::Int64`
- `y_dist::Real`: the difference between `y` and `x[y_idx]`
"""
function vsearch(y::Real, x::AbstractVector; acc::Bool=false)
    y_dist, y_idx = findmin(abs.(x .- y))
    return acc == true ? (y_idx, y_dist) : y_idx
end

"""
    vsearch(y, x; acc)

Return the positions of the `y` vector in the vector `x`.

# Arguments

- `y::AbstractVector`: vector of interest
- `x::AbstractVector`: vector to search within
- `acc::Bool=false`: if true, return the difference between `y` and `x[y_idx:y_idx + length(y)]`

# Returns

- `y_idx::Int64`
- `y_dist::Real`: the difference between `y` and `x[y_idx:y_idx + length(y)]`
"""
function vsearch(y::AbstractVector, x::AbstractVector; acc::Bool=false)

    length(y) > length(x) && throw(ArgumentError("Length of 'y' cannot be larger than length 'x'"))

    y_idx = zeros(length(y))
    y_dist = zeros(length(y))

    @inbounds @simd for idx in eachindex(y)
        y_dist[idx], y_idx[idx] = findmin(abs.(x .- y[idx]))
    end

    return acc == true ? (convert.(Int64, y_idx), y_dist) : y_idx
end

"""
    cart2pol(x, y)

Convert Cartesian coordinates to polar.

# Arguments

- `x::Real`
- `y::Real`

# Returns

- `radius::Float64`
- `theta::Float64`
"""
function cart2pol(x::Real, y::Real)

    radius = round(hypot(x, y), digits=3)
    theta = round(atand(y, x), digits=3)

    # q = _angle_quadrant(theta)
    # q == 2 && (theta += 180)
    # q == 3 && (theta += 180)
    # q == 4 && (theta += 360)

    # make theta positive - should not be required
    # theta < 0 && (theta = 360 - abs(theta))

    return radius, theta
end

"""
    pol2cart(radius, theta)

Convert polar coordinates to Cartesian.

# Arguments

- `radius::Real`: polar radius, the distance from the origin to the point, in degrees
- `theta::Real`: polar angle

# Returns

- `x::Float64`
- `y::Float64`
"""
function pol2cart(radius::Real, theta::Real)
    
    # theta = mod(theta, 360)
    x = round(radius * cosd(theta), digits=3)
    y = round(radius * sind(theta), digits=3)

    return x, y
end

"""
    sph2cart(radius, theta, phi)

Convert spherical coordinates to Cartesian.

# Arguments

- `radius::Real`: spherical radius, the distance from the origin to the point
- `theta::Real`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `phi::Real`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees

# Returns

- `x::Float64`
- `y::Float64`
- `z::Float64`
"""
function sph2cart(radius::Real, theta::Real, phi::Real)
    
    x = round(radius * sind(90 - phi) * cosd(theta), digits=3)
    y = round(radius * sind(90 - phi) * sind(theta), digits=3)
    z = round(radius * cosd(90 - phi), digits=3)

    return x, y, z
end

"""
    cart2sph(x, y, z)

Convert spherical coordinates to Cartesian.

# Arguments

- `x::Real`
- `y::Real`
- `z::Real`

# Returns

- `radius::Float64`: spherical radius, the distance from the origin to the point
- `theta::Float64`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `phi::Float64`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees
"""
function cart2sph(x::Real, y::Real, z::Real)
    
    # radius = sqrt(x^2 + y^2 + z^2)    
    radius = round(hypot(x, y, z), digits=3)
    # theta = tan^-1(x, y)
    theta = round(atand(y, x), digits=3)
    # phi = cos^-1(z / sqrt(x^2 + y^2 + z^2))
    phi = 90 - round(acosd(z / radius), digits=3)

    # make theta positive - should not be required
    # theta < 0 && (theta = 360 - abs(theta))
    
    return radius, theta, phi
end

"""
    sph2pol(radius, theta, phi)

Convert spherical coordinates to polar.

# Arguments

- `radius::Real`: spherical radius, the distance from the origin to the point
- `theta::Real`: spherical horizontal angle, the angle in the xy plane with respect to the x-axis, in degrees
- `phi::Real`: spherical azimuth angle, the angle with respect to the z-axis (elevation), in degrees

# Returns

- `radius::Float64`
- `theta::Float64`
"""
function sph2pol(radius::Real, theta::Real, phi::Real)
    radius = round(radius * abs(cosd(phi)), digits=3)
    return radius, theta
end

"""
    generate_window(type, n; even)

Return the `n`-point long symmetric window `type`.

# Arguments

- `type::Symbol`: window type:
    - `:hann`: Hann
    - `:bh`: Blackman-Harris
    - `:bohman`: Bohman
    - `:flat`: Flat-top window
    - `:bn`: Blackman-Nuttall
    - `:nutall`: Nuttall
    - `:triangle`: symmetric triangle (left half ↑, right half ↓)
    - `:exp`: symmetric exponential (left half ↑, right half ↓)
- `n::Int64`: window length
- `even::Bool=false`: if true, make the window of even length (+1 for odd n)

# Returns

- `w::Vector{Float64}`:: generated window
"""
function generate_window(type::Symbol, n::Int64; even::Bool=false)
    _check_var(type, [:hann, :bh, :bohman, :flat, :bn, :nutall, :triangle, :exp], "type")
    n < 1 && throw(ArgumentError("n must be ≥ 1."))

    even == true && mod(n, 2) != 0 && (n += 1)
    t = range(0, 1, n)

    if type === :hann
        return @. 0.5 * (1 - cos.(2 * pi * t))
    elseif type === :bh
        return @. 0.35875 - 0.48829 * cos.(2 * pi * t) + 0.14128 * cos.(4 * pi * t) - 0.01168 * cos.(6 * pi * t)
    elseif type === :bohman
        return @. (1 - abs.(t * 2 - 1)) * cos.(pi * abs.(t * 2 - 1)) + (1 / pi) * sin.(pi * abs.(t * 2 - 1))
    elseif type === :flat
        return @. 0.21557 - 0.41663 * cos.(2 * pi * t) + 0.27726 * cos.(4 * pi * t) - 0.08357 * cos.(6 * pi * t) + 0.00694 * cos.(8 * pi * t)
    elseif type === :bn
        return @. 0.3635819 - 0.4891775 * cos(2 * pi * t) + 0.1365995 * cos(4 * pi * t) - 0.0106411 * cos(6 * pi * t)
    elseif type === :nutall
        return @. 0.355768 - 0.487396 * cos(2 * pi * t) + 0.144232 * cos(4 * pi * t) - 0.012604 * cos(6 * pi * t)
    elseif type === :triangle
        w = zeros(n)
        @inbounds @simd for idx in 1:((n ÷ 2) + 1)
            w[idx] = @. (idx * (idx + 1)) / 2
        end
        w[((n ÷ 2) + 2):n] = reverse(w)[((n ÷ 2) + 2):n]
        w .= w ./ maximum(w)
        return w
    elseif type === :exp
        w = ones(n)
        if mod(n, 2) == 0
            @inbounds @simd for idx in 1:(n ÷ 2)
                w[idx] = 1 / idx
            end
            w[1:((n ÷ 2))] = reverse(w[1:((n ÷ 2))])
            w[((n ÷ 2) + 1):n] = reverse(w[1:(n ÷ 2)])
        else
            @inbounds @simd for idx in 1:((n ÷ 2) + 1)
                w[idx] = 1 / idx
            end
            w[1:((n ÷ 2) + 1)] = reverse(w[1:((n ÷ 2) + 1)])
            w[((n ÷ 2) + 2):n] = reverse(w[1:(n ÷ 2)])
        end
        return w
    end
end

"""
    fft0(x, n)

Zeros-padded FFT.

# Arguments

- `x::AbstractVector`
- `n::Int64`: number of zeros to add

# Returns

- `fft0::Vector{ComplexF64}`
"""
function fft0(x::AbstractVector, n::Int64=0)

    n < 0 && throw(ArgumentError("n must be ≥ 0."))

    if CUDA.functional() && use_cuda
        # _free_gpumem()
        CUDA.memory_status()
        if n == 0
            cx = CuArray(x)
        else
            cx = CuArray(pad0(x, n))
        end
        return Vector(fft(cx))
    else
        if n == 0
            return fft(x)
        else
            return fft(pad0(x, n))
        end
    end
end

"""
    ifft0(x, n)

IFFT of zero-padded vector.

# Arguments

- `x::AbstractVector`
- `n::Int64`: number of zeros added to `x`

# Returns

- `signal::Vector{Float64}`: real part of the signal trimmed to original length
"""
function ifft0(x::AbstractVector, n::Int64=0)

    n < 0 && throw(ArgumentError("n must be ≥ 0."))

    if CUDA.functional() && use_cuda
        # _free_gpumem()
        x = Vector(ifft(CuArray(x)))
    else
        x = ifft(x)
    end
    return round.(real.(x[1:(length(x) - n)]))
end

"""
    fft2(x)

Zeros-padded FFT, so the length of padded vector is a power of 2.

# Arguments

- `x::AbstractVector`

# Returns

- `fft2::Vector{ComplexF64}`
"""
function fft2(x::AbstractVector)
    n = nextpow2(length(x)) - length(x)
    fft0(x, n)
end

"""
    nextpow2(x)

Return the next power of 2 for given number `x`.

# Argument

- `x::Int64`

# Returns

- `nextpow::Int64`
"""
function nextpow2(x::Int64)
    # return x == 0 ? 1 : (2 ^ ndigits(x - 1, base=2))
    return nextpow(2, x)
end

"""
    vsplit(x, n)

Splits the vector `x` into `n`-long pieces.

# Argument

- `x::AbstractVector`
- `n::Int64`

# Returns

- `x::Vector{AbstractVector}`
"""
function vsplit(x::AbstractVector, n::Int64=1)

    n < 1 && throw(ArgumentError("n must be ≥ 1."))
    length(x) % n == 0 || throw(ArgumentError("Length of x must be a multiple of n."))

    x_m = reshape(x, length(x) ÷ n, n)
    result = [x_m[1, :]]
    @inbounds @simd for idx in 2:size(x_m, 1)
        result = vcat(result, [x_m[idx, :]])
    end

    return result
end

"""
    s_rms(signal)

Calculate Root Mean Square.

# Arguments

- `signal::AbstractVector`

# Returns

- rms::Float64`
"""
function s_rms(signal::AbstractVector)
    # rms = sqrt(mean(signal.^2))    
    return norm(signal) / sqrt(length(signal))
end

"""
    generate_sine(f, t, a, p)

Generates sine wave.

# Arguments

- `f::Real`: frequency [Hz]
- `t::Union{AbstractVector, AbstractRange}`: time vector
- `a::Real`: amplitude
- `p::Real`: initial phase

# Returns

- sine::Vector{Float64}`
"""
function generate_sine(f::Real, t::Union{AbstractVector, AbstractRange}, a::Real=1, p::Real=0)
    return @. a * sin(2 * pi * f * t + p)
end

"""
    generate_csine(f, t, a)

Generates complex sine wave.

# Arguments

- `f::Real`: frequency [Hz]
- `t::Union{AbstractVector, AbstractRange}`: time vector
- `a::Real`: amplitude

# Returns

- sine::Vector{Float64}`
"""
function generate_csine(f::Real, t::Union{AbstractVector, AbstractRange}, a::Real=1)
    return @. a * exp(1im * 2 * pi * f * t)
end

"""
    s_freqs(t)

Return vector of frequencies and Nyquist frequency for time vector.

# Arguments

- `t::AbstractVector, AbstractRange}`

# Returns

- `hz::Vector{Float64}`
- `nyquist_freq::Float64`
"""
function s_freqs(t::Union{AbstractVector, AbstractRange})

    typeof(t) <: AbstractRange && (t = collect(t))

    # sampling interval
    dt = t[2] - t[1]
    # sampling rate
    fs = round(Int64, 1 / dt)
    # Nyquist frequency
    nyquist_freq = fs / 2
    # frequency array
    hz = linspace(0, nyquist_freq, floor(Int64, length(t) / 2))

    return hz, nyquist_freq
end

"""
    s_freqs(signal, fs)

Return vector of frequencies and Nyquist frequency for signal.

# Arguments

- `signal::Vector{Float64}`
- `fs::Int64`

# Returns

- `hz::Vector{Float64`
- `nyquist_freq::Float64`
"""
function s_freqs(signal::Vector{Float64}, fs::Int64)

    fs < 0 && throw(ArgumentError("Sampling rate must be >0 Hz."))

    # Nyquist frequency
    nyquist_freq = fs / 2
    # frequency array
    hz = linspace(0, nyquist_freq, floor(Int64, length(signal) / 2))

    return hz, nyquist_freq
end

"""
    m_sortperm(m; rev=false, dims=1)

Generates sorting index for matrix `m` by columns (`dims` = 1) or by rows (`dims` = 2).

# Arguments

- `m::Matrix`
- `rev::Bool`
- `dims::Int64`

# Returns

- `m_idx::Matrix{Int64}`
"""
function m_sortperm(m::Matrix; rev::Bool=false, dims::Int64=1)

    dims in [1, 2] || throw(ArgumentError("dims must be 1 or 2."))
    
    m_idx = zeros(Int, size(m))
    if dims == 1
        @inbounds @simd for idx = 1:size(m, 2)
            # sort by columns
            m_idx[:, idx] = sortperm(m[:, idx], rev=rev)
        end
    else
        @inbounds @simd for idx = 1:size(m, 1)
            # sort by rows
            m_idx[idx, :] = sortperm(m[idx, :], rev=rev)'
        end     
    end

    return m_idx
end

"""
    m_sort(m, m_idx; rev=false, dims=1)

Sorts matrix `m` using sorting index `m_idx` by columns (`dims` = 1) or by rows (`dims` = 2).

# Arguments

- `m::Matrix`
- `m_idx::Vector{Int64}`
- `rev::Bool`
- `dims::Int64`

# Returns

- `m_sorted::Matrix`
"""
function m_sort(m::Matrix, m_idx::Vector{Int64}; rev::Bool=false, dims::Int64=1)

    dims in [1, 2] || throw(ArgumentError("dims must be 1 or 2."))

    m_sorted = zeros(eltype(m), size(m))
    if dims == 1
        @inbounds @simd for idx = 1:size(m, 2)
            # sort by columns
            m_sorted[:, idx] = @views m[:, idx][m_idx]
        end
    else
        @inbounds @simd for idx = 1:size(m, 1)
            # sort by rows
            m_sorted[idx, :] = @views m[idx, :][m_idx]
        end
    end

    return m_sorted
end

"""
    pad0(x, n)

Pad vector / rows of matrix / array with zeros. Works with 1-, 2- and 3-dimensional arrays.

# Arguments

- `x::Union{AbstractVector, AbstractArray`
- `n::Int64`: number of zeros to add

# Returns

- `v_pad::Union{AbstractVector, AbstractArray`
"""
function pad0(x::Union{AbstractVector, AbstractArray}, n::Int64)
    n < 0 && throw(ArgumentError("n must be ≥ 0."))
    ndims(x) == 1 && return vcat(x, zeros(eltype(x), n))
    ndims(x) == 2 && return hcat(x, zeros(eltype(x), size(x, 1), n))
    ndims(x) == 3 && return hcat(x, zeros(eltype(x), size(x, 1), n, size(x, 3)))
    ndims(x) > 3 && throw(ArgumentError("pad0() works only for 1-, 2- or 3-dimension array."))
end

"""
    pad2(x)

Pad vector / rows of matrix / array with zeros to the nearest power of 2 length.

# Arguments

- `x::Union{AbstractVector, AbstractArray`

# Returns

- `v_pad::Union{AbstractVector, AbstractArray`
"""
function pad2(x::Union{AbstractVector, AbstractArray})
    ndims(x) == 1 && return pad0(x, nextpow2(length(x)) - length(x))
    ndims(x) == 2 && return hcat(x, zeros(eltype(x), size(x, 1), nextpow2(size(x, 2)) - size(x, 2)))
    ndims(x) == 3 && return hcat(x, zeros(eltype(x), size(x, 1), nextpow2(size(x, 2)) - size(x, 2), size(x, 3)))
    ndims(x) > 3 && throw(ArgumentError("pad2() works only for 1-, 2- or 3-dimension array."))
end

"""
    hz2rads(f)

Convert frequency `f` in Hz to rad/s.

# Arguments

- `f::Real`

# Returns

- `f_rads::Float64`
"""
function hz2rads(f::Real)
    return 2 * pi * f
end

"""
    rads2hz(f)

Convert frequency `f` in rad/s to Hz.

# Arguments

- `f::Real`

# Returns

- `f_rads::Float64`
"""
function rads2hz(f::Real)
    return f / 2 * pi
end

"""
    cmax(x)

Return maximum value of the complex vector`x`.

# Arguments

- `x::Vector{ComplexF64}`

# Returns

- `cmax::ComplexF64`
"""
function cmax(x::Vector{ComplexF64})
    return argmax(abs, x)
end

"""
    cmin(x)

Return minimum value of the complex vector`x`.

# Arguments

- `x::Vector{ComplexF64}`

# Returns

- `cmin::ComplexF64`
"""
function cmin(x::Vector{ComplexF64})
    return argmin(abs, x)
end

"""
    generate_sinc(t, f, peak, norm)

Generate sinc function.

# Arguments

- `t::AbstractRange=-2:0.01:2`: time
- `f::Real=10.0`: frequency
- `peak::Real=0`: sinc peak time
- `norm::Bool=true`: generate normalized function

# Returns

- `sinc::Vector{Float64}`
"""
function generate_sinc(t::AbstractRange=-2:0.01:2; f::Real=1, peak::Real=0, norm::Bool=true)

    y_sinc = norm == true ? (@. sin(2 * pi * f * (t - peak)) / (pi * (t - peak))) : (@. sin(2 * f * (t - peak)) / (t - peak))
    nan_idx = isnan.(y_sinc)
    sum(nan_idx) != 0 && (y_sinc[findall(isnan, y_sinc)[1]] = (y_sinc[findall(isnan, y_sinc)[1] - 1] + y_sinc[findall(isnan, y_sinc)[1] + 1]) / 2)
    
    return y_sinc
end

"""
    generate_morlet(fs, f, t; ncyc, complex)

Generate Morlet wavelet.

# Arguments

- `fs::Int64`: sampling rate
- `f::Real`: frequency
- `t::Real=1`: length = -t:1/fs:t
- `ncyc::Int64=5`: number of cycles
- `complex::Bool=false`: generate complex Morlet

# Returns

- `morlet::Union{Vector{Float64}, Vector{ComplexF64}}`
"""
function generate_morlet(fs::Int64, f::Real, t::Real=1; ncyc::Int64=5, complex::Bool=false)
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    ncyc < 1 && throw(ArgumentError("ncyc must be ≥ 1."))
    t <= 0 && throw(ArgumentError("t must be > 0."))
    t = -t:1/fs:t
    sin_wave = complex == true ? (@. exp(im * 2 * pi * f * t)) : (@. sin(2 * pi * f * t))
    g = generate_gaussian(fs, f, t[end], ncyc=ncyc)
    return sin_wave .* g
end

"""
    generate_gaussian(fs, f, t; ncyc, a)

Generate Gaussian wave.

# Arguments

- `fs::Int64`: sampling rate
- `f::Real`: frequency
- `t::Real=1`: length = -t:1/fs:t
- `ncyc::Int64`: : number of cycles, width, SD of the Gaussian
- `a::Real=1`: peak amp

# Returns

- `gaussian::Vector{Float64}`
"""
function generate_gaussian(fs::Int64, f::Real, t::Real=1; ncyc::Int64=5, a::Real=1.0)
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    ncyc < 1 && throw(ArgumentError("ncyc must be ≥ 1."))
    t <= 0 && throw(ArgumentError("t must be > 0."))
    t = -t:1/fs:t
    s = ncyc / (2 * pi * f)             # Gaussian width (standard deviation)
    return @. a * exp(-(t/s)^2 / 2)     # Gaussian
end

"""
    tuple_order(t, rev)

Order tuple elements in ascending or descending (rev=true) order.

# Arguments

- `t::Tuple{Real, Real}`
- `rev::Bool=false`

# Returns

- `t::Tuple{Real, Real}`
"""
function tuple_order(t::Tuple{Real, Real}, rev::Bool=false)
    (rev == false && t[1] > t[2]) && (t = (t[2], t[1]))
    (rev == true && t[1] < t[2]) && (t = (t[2], t[1]))
    return t
end

"""
    s2_rmse(signal1, signal2)

Calculate RMSE between two signals.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`

# Returns

- `r::Float64`
"""
function s2_rmse(signal1::AbstractVector, signal2::AbstractVector)
    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))
    # r = sum(signal1 .* signal2) ./ (sqrt(sum(signal1.^2)) .* sqrt(sum(signal2.^2)))
    return sqrt(mean(signal2 - signal1)^2)
end

"""
    m_norm(m)

Normalize matrix.

# Arguments

- `m::AbstractArray`

# Returns

- `m_norm::AbstractArray`
"""
function m_norm(m::AbstractArray)
    return m ./ (size(m, 2) - 1)
end

"""
   s_cov(signal; norm=true)

Calculate covariance of `signal * signal'`.

# Arguments

- `signal::AbstractVector`
- `norm::Bool`: normalize covariance

# Returns

- `cov_mat::Matrix{Float64}`
"""
function s_cov(signal::AbstractVector; norm::Bool=false)

    # channels-vs-channels
    if CUDA.functional() && use_cuda
        cov_mat = Matrix(cov(CuVector(signal) * CuVector(signal)'))
    else
        cov_mat = cov(signal * signal')
    end

    # normalize
    norm == true && (cov_mat = m_norm(cov_mat))

    return cov_mat
end

"""
   s2_cov(signal1, signal2; norm=true)

Calculate covariance between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`
- `norm::Bool`: normalize covariance

# Returns

- `cov_mat::Matrix{Float64}`
"""
function s2_cov(signal1::AbstractVector, signal2::AbstractVector; norm::Bool=false)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must be of the same length."))

    # channels-vs-channels
    if CUDA.functional() && use_cuda
        cov_mat = Matrix(cov(CuVector(signal1) * CuVector(signal2)'))
    else
        cov_mat = cov(signal1 * signal2')
    end

    # normalize
    norm == true && (cov_mat = cov_mat ./ (size(cov_mat, 2) - 1))

    return cov_mat
end

"""
    s_dft(signal; fs, pad)

Return FFT and DFT sample frequencies for a DFT.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `pad::Int64=0`: number of zeros to add

# Returns

Named tuple containing:
- `s_fft::Vector{ComplexF64}`
- `s_sf::Vector{Float64}`
"""
function s_dft(signal::AbstractVector; fs::Int64, pad::Int64=0)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))

    s_fft = fft0(signal, pad)
    # number of samples
    n = length(signal)
    # time between samples
    d = 1 / fs
    s_sf = Vector(fftfreq(n, d))

    return (s_fft=s_fft, s_sf=s_sf)
end

"""
    s_msci95(signal)

Calculate mean, std and 95% confidence interval.

# Arguments

- `signal::Vector{Float64}`

# Returns

- `s_m::Float64`: mean
- `s_s::Float64`: standard deviation
- `s_u::Float64`: upper 95% CI
- `s_l::Float64`: lower 95% CI
"""
function s_msci95(signal::Vector{Float64})
    s_m = mean(signal)
    s_s = std(signal) / sqrt(length(signal))
    s_u = s_m + 1.96 * s_s
    s_l = s_m - 1.96 * s_s
    return s_m, s_s, s_u, s_l
end

"""
    s_msci95(signal; n, method)

Calculate mean, std and 95% confidence interval for each the channel.

# Arguments

- `signal::AbstractArray`
- `n::Int64=3`: number of bootstraps
- `method::Symbol=:normal`: use normal method (:normal) or `n`-times boostrapping (:boot)

# Returns

- `s_m::Vector{Float64}`: mean
- `s_s::Vector{Float64}`: standard deviation
- `s_u::Vector{Float64}`: upper 95% CI
- `s_l::Vector{Float64}`: lower 95% CI
"""
function s_msci95(signal::AbstractArray; n::Int64=3, method::Symbol=:normal)

    _check_var(method, [:normal, :boot], "method")
    n < 1 && throw(ArgumentError("n must be ≥ 1."))

    if method === :normal
        s_m = mean(signal, dims=1)'
        s_s = std(signal, dims=1)' / sqrt(size(signal, 1))
        s_u = s_m + 1.96 * s_s
        s_l = s_m - 1.96 * s_s
    else
        s_tmp1 = zeros(size(signal, 1) * n, size(signal, 2))
        Threads.@threads for idx1 in 1:size(signal, 1) * n
            s_tmp2 = zeros(size(signal))
            sample_idx = rand(1:size(signal, 1), size(signal, 1))
            @inbounds @simd for idx2 in 1:size(signal, 1)
                s_tmp2[idx2, :] = signal[sample_idx[idx2], :]'
            end
            s_tmp1[idx1, :] = mean(s_tmp2, dims=1)
        end

        s_m = mean(s_tmp1, dims=1)'
        s_s = std(s_tmp1, dims=1)' / sqrt(size(s_tmp1, 1))
        s_sorted = sort(s_tmp1, dims=1)
        s_l = s_sorted[round(Int, 0.025 * size(s_tmp1, 1)), :]
        s_u = s_sorted[round(Int, 0.975 * size(s_tmp1, 1)), :]
    end

    return vec(s_m[:, 1]), vec(s_s[:, 1]), vec(s_u[:, 1]), vec(s_l[:, 1])
end

"""
    s2_mean(signal1, signal2)

Calculate mean and 95% confidence interval for 2 signals.

# Arguments

- `signal1::Vector{Float64}`
- `signal2:Vector{Float64}`

# Returns

- `s_m::Float64`: mean
- `s_s::Float64`: standard deviation
- `s_u::Float64`: upper 95% CI
- `s_l::Float64`: lower 95% CI
"""
function s2_mean(signal1::Vector{Float64}, signal2::Vector{Float64})

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must be of the same as size."))

    s_m = zeros(length(signal1))
    s_s = zeros(length(signal1))
    s_u = zeros(length(signal1))
    s_l = zeros(length(signal1))

    s1_mean = mean(signal1)
    s2_mean = mean(signal2)
    s_m = s1_mean - s2_mean
    s1_sd = std(signal1) / sqrt(length(signal1))
    s2_sd = std(signal2) / sqrt(length(signal2))
    s_s = sqrt(s1_sd^2 + s2_sd^2)
    s_u = s_m + 1.96 * s_s
    s_l = s_m - 1.96 * s_s

    return s_m, s_s, s_u, s_l
end

"""
    s2_difference(signal1, signal2; n, method)

Calculate mean difference and 95% confidence interval for 2 signals.

# Arguments

- `signal1::AbstractArray`
- `signal2::AbstractArray`
- `n::Int64=3`: number of bootstraps
- `method::Symbol=:absdiff`: maximum difference (`:absdiff`), integrated area of the squared difference (`:diff2int`)

# Returns

Named tuple containing:
- `s_stat::Vector{Float64}`
- `s_stat_single::Float64`
- `p::Float64`
"""
function s2_difference(signal1::AbstractArray, signal2::AbstractArray; n::Int64=3, method::Symbol=:absdiff)

    size(signal1) == size(signal2) || throw(ArgumentError("Both signals must be of the same size."))
    _check_var(method, [:absdiff, :diff2int], "method")
    n < 1 && throw(ArgumentError("n must be ≥ 1."))

    s1_mean = vec(mean(signal1, dims=1))
    s2_mean = vec(mean(signal2, dims=1))

    if method === :absdiff
        # statistic: maximum difference
        s_diff = s1_mean - s2_mean
        s_stat_single = maximum(abs.(s_diff))
    else
        # statistic: integrated area of the squared difference
        s_diff_squared = (s1_mean - s2_mean).^2
        s_stat_single = simpson(s_diff_squared)
    end

    signals = [signal1; signal2]
    s_stat = zeros(size(signal1, 1) * n)

    Threads.@threads for idx1 in 1:(size(signal1, 1) * n)
        s_tmp1 = zeros(size(signal1, 1), size(signal1, 2))
        sample_idx = rand(1:size(signals, 1), size(signals, 1))
        @inbounds @simd for idx2 in 1:size(signal1, 1)
            s_tmp1[idx2, :] = @views signals[sample_idx[idx2], :]'
        end
        s1_mean = vec(mean(s_tmp1, dims=1))
        s_tmp1 = zeros(size(signal1, 1), size(signal1, 2))
        sample_idx = rand(1:size(signals, 1), size(signals, 1))
        @inbounds @simd for idx2 in 1:size(signal1, 1)
            s_tmp1[idx2, :] = @views signals[sample_idx[idx2], :]'
        end
        s2_mean = vec(mean(s_tmp1, dims=1))
        if method === :absdiff
            # statistic: maximum difference
            s_diff = s1_mean - s2_mean
            @inbounds s_stat[idx1] = maximum(abs.(s_diff))
        else
            # statistic: integrated area of the squared difference
            s_diff_squared = (s1_mean - s2_mean).^2
            @inbounds s_stat[idx1] = simpson(s_diff_squared)
        end
    end

    p = length(s_stat[s_stat .> s_stat_single]) / size(signal1, 1) * n
    p > 1 && (p = 1.0)

    return (s_stat=s_stat, s_stat_single=s_stat_single, p=p)
end

"""
   s_acov(signal; lag, demean, norm)

Calculate autocovariance.

# Arguments

- `signal::AbstractVector`
- `lag::Int64=1`: lags range is `-lag:lag`
- `demean::Bool=false`: demean `signal` prior to calculations
- `norm::Bool=false`: normalize autocovariance

# Returns

- `acov::Vector{Float64}`
- `lags::Vector{Int64}`
"""
function s_acov(signal::AbstractVector; lag::Int64=1, demean::Bool=false, norm::Bool=false)

    lag < 1 && throw(ArgumentError("lag must be ≥ 1."))
    lags = collect(-lag:lag)

    if demean == true
        s_demeaned = s_demean(signal)
    else
        s_demeaned = signal
    end

    acov = zeros(length(lags))
    l = length(signal)

    @simd for idx in eachindex(lags)
        # no lag
        @inbounds @fastmath lags[idx] == 0 && (acov[idx] = sum(s_demeaned.^2))
        # positive lag
        @inbounds @fastmath lags[idx] > 0 && (acov[idx] = @views sum(s_demeaned[(1 + lags[idx]):end] .* s_demeaned[1:(end - lags[idx])]))
        # negative lag
        @inbounds @fastmath lags[idx] < 0 && (acov[idx] = @views sum(s_demeaned[1:(end - abs(lags[idx]))] .* s_demeaned[(1 + abs(lags[idx])):end]))
    end
    norm == true && (acov ./ l)

    return acov, lags
end

"""
   s2_xcov(signal1, signal2; lag=1, demean=false, norm=false)

Calculate cross-covariance between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`
- `lag::Int64`: lags range is `-lag:lag`
- `demean::Bool`: demean signal prior to analysis
- `norm::Bool`: normalize cross-covariance

# Returns

- `ccov::Vector{Float64}`
- `lags::Vector{Int64}`
"""
function s2_xcov(signal1::AbstractVector, signal2::AbstractVector; lag::Int64=1, demean::Bool=false, norm::Bool=false)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must be of the same as length."))
    lag < 1 && throw(ArgumentError("lag must be ≥ 1."))
    lags = collect(-lag:lag)

    if demean == true
        signal1 = s_demean(signal1)
        signal2 = s_demean(signal2)
    end

    xcov = zeros(length(lags))
    l = length(signal1)

    @simd for idx in eachindex(lags)
        # no lag
        @inbounds @fastmath lags[idx] == 0 && (xcov[idx] = sum(signal1 .* signal2))
        # positive lag
        @inbounds @fastmath lags[idx] > 0 && (xcov[idx] = @views sum(signal1[(1 + lags[idx]):end] .* signal2[1:(end - lags[idx])]))
        # negative lag
        @inbounds @fastmath lags[idx] < 0 && (xcov[idx] = @views sum(signal1[1:(end - abs(lags[idx]))] .* signal2[(1 + abs(lags[idx])):end]))
    end
    norm == true && (xcov ./ l)

    return xcov, lags
end

"""
    s_spectrum(signal; pad)

Calculate FFT, amplitudes, powers and phases.

# Arguments

- `signal::AbstractArray`
- `pad::Int64=0`: number of zeros to add
- `norm::Bool=false`: normalize do dB

# Returns

Named tuple containing:
- `s_fft::Vector{ComplexF64}`
- `s_amp::Vector{Float64}`
- `s_pow::Vector{Float64}`
- `s_pha::Vector{Float64}`
"""
function s_spectrum(signal::AbstractArray; pad::Int64=0, norm::Bool=false)

    s_fft = fft0(signal, pad)

    # amplitudes
    s_amp = abs.(s_fft) ./ length(signal)       # normalize
    s_amp = s_amp[1:(length(s_amp) ÷ 2)]        # remove negative frequencies
    s_amp[2:end] .*= 2                          # double positive frequencies
    # power
    s_pow = s_amp.^2
    norm == true && (s_pow = pow2db.(s_pow))
    # phases
    s_pha = angle.(s_fft)

    return (s_fft=s_fft, s_amp=s_amp, s_pow=s_pow, s_pha=s_pha)
end

"""
    s_total_power(signal; fs, mt)

Calculate total power.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `mt::Bool=false`: if true use multi-tapered periodogram

# Returns

- `stp::Float64`: signal total power
"""
function s_total_power(signal::AbstractVector; fs::Int64, mt::Bool=false)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    if mt == true
        psd = mt_pgram(signal, fs=fs)
    else
        psd = welch_pgram(signal, 4*fs, fs=fs)
    end
    psd_pow = power(psd)
    psd_pow[1] = psd_pow[2]
    # dx: frequency resolution
    dx = psd.freq[2] - psd.freq[1]
    stp = simpson(psd_pow, dx=dx)

    return stp
end

"""
    s_band_power(signal; fs, f, mt)

Calculate power between `f[1]` and `f[2]`.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `f::Tuple{Real, Real}`: lower and upper frequency bounds
- `mt::Bool=false`: if true use multi-tapered periodogram

# Returns

- `sbp::Float64`: signal band power
"""
function s_band_power(signal::AbstractVector; fs::Int64, f::Tuple{Real, Real}, mt::Bool=false)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    f = tuple_order(f)
    f[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0.")) 
    f[2] > fs / 2 && throw(ArgumentError("Lower frequency bound must be ≤ $(fs / 2).")) 
    if mt == true
        psd = mt_pgram(signal, fs=fs)
    else
        psd = welch_pgram(signal, 4*fs, fs=fs)
    end

    psd_freq = Vector(psd.freq)
    f1_idx = vsearch(f[1], psd_freq)
    f2_idx = vsearch(f[2], psd_freq)
    frq_idx = [f1_idx, f2_idx]

    # dx: frequency resolution
    dx = psd_freq[2] - psd_freq[1]
    return simpson(psd.power[frq_idx[1]:frq_idx[2]], psd_freq[frq_idx[1]:frq_idx[2]], dx=dx)
end

"""
    s_taper(signal; taper)

Taper the signal.

# Arguments

- `signal::AbstractVector`
- `taper::Union{AbstractVector, Vector{ComplexF64}}`

# Returns

- `s_tapered::Vector{Union{Float64, ComplexF64}}`
"""
function s_taper(signal::AbstractVector; taper::Union{AbstractVector, Vector{ComplexF64}})
    length(taper) == length(signal) || throw(ArgumentError("Taper and signal lengths must be equal."))
    return signal .* taper
end

"""
    s_detrend(signal; type, offset, order, span, fs)

Perform piecewise detrending.

# Arguments

- `signal::AbstractVector`
- `type::Symbol=:ls`:
    - `:ls`: the result of a linear least-squares fit to `signal` is subtracted from `signal`
    - `:linear`: linear trend is subtracted from `signal`
    - `:constant`: `offset` or the mean of `signal` (if `offset` = 0) is subtracted
    - `:poly`: polynomial of `order` is subtracted
    - `:loess`: fit and subtract loess approximation
    - `:hp`: use HP filter
- `offset::Real=0`: constant for :constant detrending
- `order::Int64=1`: polynomial fitting order
- `f::Float64=1.0`: smoothing factor for `:loess` or frequency for `:hp`
- `fs::Int64=0`: sampling frequency

# Returns
- `s_det::Vector{Float64}`
"""
function s_detrend(signal::AbstractVector; type::Symbol=:linear, offset::Real=0, order::Int64=1, f::Float64=1.0, fs::Int64=0)

    _check_var(type, [:ls, :linear, :constant, :poly, :loess, :hp], "type")
    f <= 0 && throw(ArgumentError("f must be > 0."))
    order < 1 && throw(ArgumentError("order must be ≥ 1."))

    if type === :loess
        t = collect(1.0:1:length(signal))
        model = loess(t, signal, span=f)
        trend = Loess.predict(model, t)
        return signal .- trend
    elseif type === :poly
        t = collect(1:1:length(signal))        
        p = Polynomials.fit(t, signal, order)
        trend = zeros(length(signal))
        for idx in eachindex(signal)
            trend[idx] = p(t[idx])
        end
        return signal .- trend
    elseif type === :constant
        offset == 0 && (offset = mean(signal))
        return signal .- mean(signal)
    elseif type === :ls
        T = eltype(signal)
        N = size(signal, 1)
        # create linear trend matrix
        A = similar(signal, T, N, 2)
        A[:,2] .= T(1)
        A[:,1] .= range(T(0),T(1),length=N)
        # create linear trend matrix
        R = transpose(A) * A
        # do the matrix inverse for 2×2 matrix
        Rinv = inv(Array(R)) |> typeof(R)
        factor = Rinv * transpose(A)
        return signal .- A * (factor * signal)
    elseif type === :linear
        trend = linspace(signal[1], signal[end], length(signal))
        return signal .- trend
    elseif type === :hp
        fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
        flt = s_filter_create(fprototype=:fir, ftype=:hp, cutoff=f, fs=fs, n=length(signal))
        return s_filter_apply(signal, flt=flt)
    end
end

"""
    s_demean(signal)

Remove mean value (DC offset).

# Arguments

- `signal::AbstractVector`

# Returns

- `s_demeaned::Vector{Float64}`
"""
function s_demean(signal::AbstractVector)
    m = mean(signal)
    return signal .- m
end

"""
    s_normalize_zscore(signal)

Normalize (by z-score).

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_zscore(signal::AbstractArray)
    m = mean(signal)
    s = std(signal)
    return @. (signal - m) / s
end

"""
    s_normalize_minmax(signal)

Normalize in [-1, +1].

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::AbstractArray`
"""
function s_normalize_minmax(signal::AbstractArray)
    mi = minimum(signal)
    mx = maximum(signal)
    mxi = mx - mi
    return @. (2 * (signal - mi) / mxi) - 1
end

"""
    s_normalize_n(signal, n)

Normalize in [0, n], default is [0, +1].

# Arguments

- `signal::AbstractArray`
- `n::Real=1.0`

# Returns

- `s_normalized::AbstractArray`
"""
function s_normalize_n(signal::AbstractArray, n::Real=1.0)
    max_x = maximum(signal)
    min_x = minimum(signal)
    return n .* (signal .- min_x) ./ (max_x - min_x)
end

"""
    s_normalize_log(signal)

Normalize using log-transformation.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::AbstractArray`
"""
function s_normalize_log(signal::AbstractArray)
    m = abs(minimum(signal))
    return @. log(1 + signal + m)
end

"""
    s_add_noise(signal, noise)

Adds noise to signal.

# Arguments

- `signal::AbstractVector`
- `noise::AbstractVector`

# Returns

- `s_noisy::AbstractVector`
"""
function s_add_noise(signal::AbstractVector, noise::AbstractVector)
    length(signal) == length(noise) || throw(ArgumentError("Length of signal and noise must be equal."))
    return signal .+ noise
end

"""
    s_resample(signal; t, new_sr)

Resample to `new_sr` sampling frequency.

# Arguments

- `signal::AbstractVector`
- `t::AbstractRange`: time
- `new_sr::Int64`: new sampling rate

# Returns

- `s_resampled::Vector{Float64}`
- `t_resampled::AbstractRange`
"""
function s_resample(signal::AbstractVector; t::AbstractRange, new_sr::Int64)

    new_sr < 1 && throw(ArgumentError("new_sr must be ≥ 1."))

    # sampling interval
    dt = t[2] - t[1]
    # sampling rate
    sr = 1 / dt
    new_sr == sr && return(signal)

    # interpolate
    sr_ratio = new_sr / sr
    s_upsampled = DSP.resample(signal, sr_ratio)
    # s_interpolation = CubicSplineInterpolation(t, signal)
    t_upsampled = t[1]:1/new_sr:t[end]
    # s_upsampled = s_interpolation(t_upsampled)

    return s_upsampled, t_upsampled
end

"""
    s_resample(signal; t, new_sr)

Resamples all channels and time vector `t` to `new_sr` sampling frequency.

# Arguments

- `signal::AbstractArray`
- `t::AbstractRange`
- `new_sr::Int64`: new sampling rate

# Returns

- `s_downsampled::Array{Float64, 3}`
- `t_downsampled::AbstractRange`
"""
function s_resample(signal::AbstractArray; t::AbstractRange, new_sr::Int64)

    new_sr < 1 && throw(ArgumentError("new_sr must be ≥ 1."))

    channel_n, _, epoch_n = size(signal)

    s_resampled_len = length(s_resample(signal[1, :, 1], t=t, new_sr=new_sr)[1])
    s_resampled = zeros(channel_n, s_resampled_len, epoch_n) 

    t_resampled = nothing
    @inbounds @simd for epoch_idx in 1:epoch_n
        Threads.@threads for channel_idx in 1:channel_n
            s_resampled[channel_idx, :, epoch_idx], t_resampled = @views s_resample(signal[channel_idx, :, epoch_idx], t=t, new_sr=new_sr)
        end
    end

    return s_resampled, t_resampled
end

"""
    s_derivative(signal)

Return derivative of the same length.

# Arguments

- `signal::AbstractVector`
"""
function s_derivative(signal::AbstractVector)
    s_der = diff(signal)
    return vcat(s_der, s_der[end])
end

"""
    s_tconv(signal; kernel)

Performs convolution in the time domain.

# Arguments

- `signal::AbstractVector`
- `kernel::AbstractVector`

# Returns

- `s_conv::Vector{Float64}`
"""
function s_tconv(signal::AbstractVector; kernel::AbstractVector)

    s_conv = DSP.conv(signal, kernel)

    half_kernel = floor(Int, length(kernel) / 2)

    # remove in- and out- edges
    if mod(length(kernel), 2) == 0 
        return real.(s_conv)[half_kernel:(end - half_kernel)]
    else
        return real.(s_conv)[(half_kernel + 1):(end - half_kernel)]
    end
end

"""
    s_filter(signal; <keyword arguments>)

Filter signal.

# Arguments

- `signal::AbstractVector`
- `fprototype::Symbol`: filter prototype:
    - `:mavg`: moving average (with threshold)
    - `:mmed`: moving median (with threshold)
    - `:poly`: polynomial of `order`
    - `:conv`: convolution
    - `:sg`: Savitzky-Golay
- `order::Int64=8`: polynomial order for `:poly` filter, k-value for `:mavg` and `:mmed` (window length = 2 × k + 1)
- `t::Real`: threshold for `:mavg` and `:mmed` filters; threshold = threshold * std(signal) + mean(signal) for `:mavg` or threshold = threshold * std(signal) + median(signal) for `:mmed` filter
- `window::Union{Nothing, AbstractVector, Int64}=nothing`: kernel for the `:conv` filter, window length for `:sg` and `:poly` filters, weighting window for `:mavg` and `:mmed`

# Returns

- `s_filtered::Vector{Float64}`
"""
function s_filter(signal::AbstractVector; fprototype::Symbol, order::Int64=8, t::Real=0, window::Union{Nothing, AbstractVector, Int64}=nothing)

    _check_var(fprototype, [:mavg, :mmed, :poly, :conv, :sg], "fprototype")
    order > length(signal) && throw(ArgumentError("order must be ≤ signal length ($length(signal))."))

    (fprototype === :sg && window === nothing) && throw(ArgumentError("For :sg filter window must be specified."))
    
    if fprototype === :poly
        order < 1 && throw(ArgumentError("order must be > 1."))
        typeof(window) == Int64 || throw(ArgumentError("For :poly filter window must be an integer number."))
    else
        (order < 2 || mod(order, 2) != 0) && throw(ArgumentError("order must be even and ≥ 2."))
    end

    if fprototype === :mavg || fprototype === :mmed
        (window !== nothing && length(window) != (2 * order + 1)) && throw(ArgumentError("For :mavg and :mmed window length must be 2 × order + 1 ($(2 * order + 1))."))
    end

    if fprototype === :mavg
        s_filtered = zeros(length(signal))
        window === nothing && (window = ones(2 * order + 1))
        @inbounds for idx in (1 + order):(length(signal) - order)
            if t > 0
                if signal[idx] > t * std(signal) + mean(signal)
                    s_filtered[idx] = mean(signal[(idx - order):(idx + order)] .* window)
                end
            else
                s_filtered[idx] = mean(signal[(idx - order):(idx + order)] .* window)
            end
        end
        return s_filtered
    end

    if fprototype === :mmed
        s_filtered = zeros(length(signal))
        window === nothing && (window = ones(2 * order + 1))
        @inbounds for idx in (1 + order):(length(signal) - order)
            if t > 0
                if signal[idx] > t * std(signal) + median(signal)
                    s_filtered[idx] = median(signal[(idx - order):(idx + order)] .* window)
                end
            else
                s_filtered[idx] = median(signal[(idx - order):(idx + order)] .* window)
            end
        end
        return s_filtered
    end

    if fprototype === :poly
        # TO DO: smooth spikes between windows
        window_n = length(signal) ÷ window
        window_last = length(signal) - (window_n * window)
        s_filtered = zeros(length(signal))
        for window_idx in 1:window_n - 1
            s = signal[((window_idx - 1) * window + 1):window_idx * window]
            t = 1:length(s)       
            p = Polynomials.fit(t, s, order)
            @inbounds for idx in eachindex(s)
                s[idx] = p(t[idx])
            end
            @inbounds s_filtered[((window_idx - 1) * window + 1):window_idx * window] = s
        end
        s = signal[((window_n - 1) * window + 1):window_n * window + window_last]
        t = 1:length(s)
        p = Polynomials.fit(t, s, order)
        @inbounds for idx in eachindex(s)
            s[idx] = p(t[idx])
        end
        @inbounds s_filtered[((window_n - 1) * window + 1):window_n * window + window_last] = s

        for window_idx in window:window:window * (window_n - 1)
            s_filtered[window_idx-2] = median(s_filtered[window_idx-3:window_idx])
            s_filtered[window_idx-1] = median(s_filtered[window_idx-2:window_idx])
            s_filtered[window_idx] = median(s_filtered[window_idx-2:window_idx+2])
            s_filtered[window_idx+1] = median(s_filtered[window_idx:window_idx+2])
            s_filtered[window_idx+2] = median(s_filtered[window_idx:window_idx+3])
        end
        # for window_idx in window:window:window * (window_n - 1)
        #     s = s_filtered[window_idx - window ÷ 2 + 1:window_idx + window ÷ 2]
        #     t = 1:length(s)        
        #     p = Polynomials.fit(t, s, order)
        #     @inbounds for idx in eachindex(s)
        #         s[idx] = p(t[idx])
        #     end
        #     s_filtered[window_idx - window ÷ 2 + 1:window_idx + window ÷ 2] = s
        # end        
        
        return s_filtered
    end

    if fprototype === :conv
        window === nothing && throw(ArgumentError("For :conv filter window must be specified."))
        s_filtered = s_tconv(signal, kernel=window)
        return s_filtered
    end

    if fprototype === :sg
        typeof(window) == Int64 || throw(ArgumentError("For :sg filter window must be an integer number."))
        isodd(window) || throw(ArgumentError("For :sg filter window must be an odd number."))
        s_filtered = savitzky_golay(signal, window, order)
        return s_filtered.y
    end

end

"""
    s_filter_create(signal; <keyword arguments>)

Create IIR or FIR filter.

# Arguments

- `fprototype::Symbol`: filter prototype:
    - `:butterworth`
    - `:chebyshev1`
    - `:chebyshev2`
    - `:elliptic`
    - `:fir`
    - `:iirnotch`: second-order IIR notch filter
    - `:remez`: Remez FIR filter
- `ftype::Symbol`: filter type:
    - `:lp`: low pass
    - `:hp`: high pass
    - `:bp`: band pass
    - `:bs`: band stop
- `cutoff::Union{Real, Tuple{Real, Real}}`: filter cutoff in Hz (tuple for `:bp` and `:bs`)
- `n::Int64`: signal length in samples
- `fs::Int64`: sampling rate
- `order::Int64=8`: filter order (6 dB/octave), number of taps for `:remez`, attenuation (× 4 dB) for `:fir` filters
- `rp::Real=-1`: ripple amplitude in dB in the pass band; default: 0.0025 dB for `:elliptic`, 2 dB for others
- `rs::Real=-1`: ripple amplitude in dB in the stop band; default: 40 dB for `:elliptic`, 20 dB for others
- `bw::Real=-1`: bandwidth for `:iirnotch` and :remez filters
- `window::Union{Nothing, AbstractVector, Int64}=nothing`: window for `:fir` filter; default is Hamming window, number of taps is calculated using fred harris' rule-of-thumb

# Returns

- `flt::Union{Vector{Float64}, ZeroPoleGain{:z, ComplexF64, ComplexF64, Float64}, Biquad{:z, Float64}}`
"""
function s_filter_create(;fprototype::Symbol, ftype::Union{Symbol, Nothing}=nothing, cutoff::Union{Real, Tuple{Real, Real}}=0, n::Int64, fs::Int64, order::Int64=8, rp::Real=-1, rs::Real=-1, bw::Real=-1, window::Union{Nothing, AbstractVector, Int64}=nothing)

    _check_var(fprototype, [:butterworth, :chebyshev1, :chebyshev2, :elliptic, :fir, :iirnotch, :remez], "fprototype")
    typeof(ftype) == Symbol && _check_var(ftype, [:lp, :hp, :bp, :bs], "ftype")

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    order < 1 && throw(ArgumentError("order must be > 1."))
    order > n && throw(ArgumentError("order must be ≤ signal length ($n)."))
    ((order < 2 && fprototype !== :remez && fprototype !== :fir) && mod(order, 2) != 0) && throw(ArgumentError("order must be even and ≥ 2."))
    window !== nothing && length(window) > n && throw(ArgumentError("For :fir filter window must be ≤ signal length ($n)."))
    (fprototype !== :iirnotch && fprototype !== :remez) && (ftype in [:lp, :hp, :bp, :bs] || throw(ArgumentError("ftype must be :bp, :hp, :bp or :bs.")))


    if fprototype in [:butterworth, :chebyshev1, :chebyshev2, :elliptic]
        cutoff == 0 && throw(ArgumentError("cutoff must be specified."))
        bw != -1 && throw(ArgumentError("bw must not be specified."))
    end

    if fprototype === :iirnotch
        ftype !== nothing && _info("For :iirnotch filter ftype is ignored.")
    end

    if fprototype in [:iirnotch, :remez]
        cutoff == 0 && throw(ArgumentError("cutoff must be specified."))
        bw == -1 && throw(ArgumentError("bw must be specified."))
    end

    if fprototype === :remez
        bw > cutoff[1] && throw(ArgumentError("For :remez filter bw must be ≤ $(cutoff[1])."))
        (length(cutoff) == 2 && bw > cutoff[2] - cutoff[1]) && throw(ArgumentError("For :remez filter bw must be ≤ $(cutoff[2] - cutoff[1])."))
    end

    if fprototype === :fir
        if window === nothing
            if ftype === :bp
                f1_stop = cutoff[1] - ((cutoff[2] - cutoff[1]) / fs) / 2
                f1_pass = cutoff[1]
                f2_stop = cutoff[2] + ((cutoff[2] - cutoff[1]) / fs) / 2
                f2_pass = cutoff[2]
                trans_bandwidth = (f2_stop - f1_stop) / fs
                n_taps = round(Int64, order * 4 / (22 * trans_bandwidth))   
            elseif ftype === :bs
                # TO DO: CHECK
                f1_pass = cutoff[1]
                f1_stop = cutoff[1] + ((cutoff[2] - cutoff[1]) / fs) / 2
                f2_stop = cutoff[2] - ((cutoff[2] - cutoff[1]) / fs) / 2
                f2_pass = cutoff[2]
                trans_bandwidth = (f2_stop - f1_stop) / fs
                n_taps = round(Int64, order * 4 / (22 * trans_bandwidth))   
            elseif ftype === :lp
                f_pass = cutoff[1]
                f_stop = cutoff[1] + minimum([maximum([0.25 * cutoff[1], 2.0]), cutoff[1]])
                trans_bandwidth = (f_stop - f_pass) / fs
                n_taps = ceil(Int64, ((order * 4) / (22 * trans_bandwidth)))
            elseif ftype === :hp
                f_pass = cutoff[1]
                f_stop = cutoff[1] - minimum([maximum([0.25 * cutoff[1], 2.0]), cutoff[1]])
                trans_bandwidth = (f_pass - f_stop) / fs
                n_taps = ceil(Int64, ((order * 4) / (22 * trans_bandwidth)))
            end

            # next power of 2
            n_taps = 2 ^ ceil(Int64, log2(n_taps))

            # filter cannot be longer than signal
            if n_taps > n
                n_taps = n
                _info("Reducing window length to $n_taps taps.")
            end

            window = DSP.hamming(n_taps)

            if ftype === :hp || ftype === :bp || ftype === :bs
                mod(length(window), 2) == 0 && (window = vcat(window[1:((length(window) ÷ 2) - 1)], window[((length(window) ÷ 2) + 1):end]))
            end

            if ftype === :lp || ftype === :hp
                ftype === :lp && _info("Creating LP filter:")
                ftype === :hp && _info("Creating HP filter:")
                _info("\tUsing default window: hamming($n_taps)")
                _info("\tAttenuation: $(order * 4) dB")
                _info("\tF_pass: $(round(f_pass, digits=4)) Hz")
                _info("\tF_stop: $(round(f_stop, digits=4)) Hz")
                _info("\tTransition bandwidth: $(round(trans_bandwidth, digits=4)) Hz")
                _info("\tCutoff frequency: $(round((cutoff[1] - trans_bandwidth / 2), digits=4)) Hz")
            elseif ftype === :bp
                _info("Creating BP filter:")
                _info("\tUsing default window: hamming($n_taps)")
                _info("\tAttenuation: $(order * 4) dB")
                _info("\tF1_stop: $(round(f1_stop, digits=4)) Hz")
                _info("\tF1_pass: $f1_pass Hz")
                _info("\tF2_pass: $f2_pass Hz")
                _info("\tF2_stop: $(round(f2_stop, digits=4)) Hz")
                _info("\tTransition bandwidth: $(round(trans_bandwidth, digits=4)) Hz")
                _info("\tCutoff frequency: $(round((cutoff[1] - trans_bandwidth / 2), digits=4)) Hz")
            elseif ftype === :bs
                _info("Creating BS filter:")
                _info("\tUsing default window: hamming($n_taps)")
                _info("\tAttenuation: $(order * 4) dB")
                _info("\tF1_pass: $f1_pass Hz")
                _info("\tF1_stop: $(round(f1_stop, digits=4)) Hz")
                _info("\tF2_stop: $(round(f2_stop, digits=4)) Hz")
                _info("\tF2_pass: $f2_pass Hz")
                _info("\tTransition bandwidth: $(round(trans_bandwidth, digits=4)) Hz")
                _info("\tCutoff frequency: $(round((cutoff[1] - trans_bandwidth / 2), digits=4)) Hz")
            end
        end
    end

    if rp == -1
        if fprototype === :elliptic
            rp = 0.0025
        else
            rp = 2
        end
    end
    
    if rs == -1
        if fprototype === :elliptic
            rp = 40
        else
            rp = 20
        end
    end

    if ftype === :lp
        length(cutoff) != 1 && throw(ArgumentError("For :lp filter one frequency must be given."))
        responsetype = Lowpass(cutoff; fs=fs)
    elseif ftype === :hp
        length(cutoff) != 1 && throw(ArgumentError("For :hp filter one frequency must be given."))
        responsetype = Highpass(cutoff; fs=fs)
    elseif ftype === :bp
        length(cutoff) != 2 && throw(ArgumentError("For :bp filter two frequencies must be given."))
        responsetype = Bandpass(cutoff[1], cutoff[2]; fs=fs)
    elseif ftype === :bs
        length(cutoff) != 2 && throw(ArgumentError("For :bs filter two frequencies must be given."))
        responsetype = Bandstop(cutoff[1], cutoff[2]; fs=fs)
    end

    if fprototype === :butterworth
        prototype = Butterworth(order)
    elseif fprototype === :chebyshev1
        (rs < 0 || rs > fs / 2) && throw(ArgumentError("For :chebyshev1 filter rs must be ≥ 0 and ≤ $(fs / 2)."))
        prototype = Chebyshev1(order, rs)
    elseif fprototype === :chebyshev2
        (rp < 0 || rp > fs / 2) && throw(ArgumentError("For :chebyshev2 filter rp must be ≥ 0 and ≤ $(fs / 2)."))
        prototype = Chebyshev2(order, rp)
    elseif fprototype === :elliptic
        (rs < 0 || rs > fs / 2) && throw(ArgumentError("For :elliptic filter rs must be ≥ 0 and ≤ $(fs / 2)."))
        (rp < 0 || rp > fs / 2) && throw(ArgumentError("For :elliptic filter rp must be ≥ 0 and ≤ $(fs / 2)."))
        prototype = Elliptic(order, rp, rs)
    elseif fprototype === :fir
        prototype = FIRWindow(window)
    end

    if fprototype === :iirnotch
        flt = iirnotch(cutoff, bw, fs=fs)
    elseif fprototype === :remez
        ftype === :lp && (window = [(0, cutoff - bw) => 1, (cutoff + bw, fs / 2) => 0])
        ftype === :hp && (window = [(0, cutoff - bw) => 0, (cutoff + bw, fs / 2) => 1])
        ftype === :bp && (window = [(0, cutoff[1] - bw / 2) => 0, (cutoff[1] + bw / 2, cutoff[2] - bw / 2) => 1, (cutoff[2] + bw / 2, fs / 2) => 0])
        ftype === :bs && (window = [(0, cutoff[1] - bw / 2) => 1, (cutoff[1] + bw / 2, cutoff[2] - bw / 2) => 0, (cutoff[2] + bw / 2, fs / 2) => 1])
        flt = remez(order, window, Hz=fs)
    else
        flt = digitalfilter(responsetype, prototype)
    end

    return flt
end

"""
    s_filter_apply(signal; <keyword arguments>)

Apply IIR or FIR filter.

# Arguments

- `signal::AbstractVector`
- `flt::Union{Vector{Float64}, ZeroPoleGain{:z, ComplexF64, ComplexF64, Float64}, Biquad{:z, Float64}}`: filter
- `dir:Symbol=:twopass`: filter direction (for causal filter use `:onepass`):
    - `:twopass`
    - `:onepass`
    - `:reverse`: one pass, reverse direction

# Returns

- `s_filtered::Vector{Float64}`
"""
function s_filter_apply(signal::AbstractVector; flt::Union{Vector{Float64}, ZeroPoleGain{:z, ComplexF64, ComplexF64, Float64}, Biquad{:z, Float64}}, dir::Symbol=:twopass)

    _check_var(dir, [:twopass, :onepass, :reverse], "dir")

    dir === :twopass && (return filtfilt(flt, signal))
    dir === :onepass && (return filt(flt, signal))
    dir === :reverse && (return filt(flt, reverse(signal)))

end

"""
    s_psd(signal; fs, norm, mt)

Calculate power spectrum density.

# Arguments
- `signal::Vector{Float64}`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `mt::Bool=false`: if true use multi-tapered periodogram
- `nt::Int64=8`: number of Slepian tapers

# Returns

Named tuple containing:
- `psd_pow::Vector{Float64}`
- `psd_frq::Vector{Float64}`
"""
function s_psd(signal::Vector{Float64}; fs::Int64, norm::Bool=false, mt::Bool=false, nt::Int64=8)

    nt < 1 && throw(ArgumentError("nt must be ≥ 1."))
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    length(signal) < 4 * fs && (mt = true)

    if mt == true
        psd = mt_pgram(signal, fs=fs, nw=(nt÷2+1), ntapers=nt)
    else
        psd = welch_pgram(signal, 4*fs, fs=fs)
    end

    psd_pow = power(psd)
    psd_pow[1] = psd_pow[2]
    norm == true && (psd_pow = pow2db.(psd_pow))

    return (psd_pow=psd_pow, psd_frq=Vector(freq(psd)))
end

"""
    s_psd(signal; fs, norm, mt)

Calculate power spectrum density.

# Arguments
- `signal::Matrix{Float64}`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `mt::Bool=false`: if true use multi-tapered periodogram

# Returns

Named tuple containing:
- `psd_pow::Matrix{Float64}`
- `psd_frq::Matrix{Float64}`
"""
function s_psd(signal::Matrix{Float64}; fs::Int64, norm::Bool=false, mt::Bool=false)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    size(signal, 2) < 4 * fs && (mt = true)
    channel_n = size(signal, 1)
    psd_tmp, psd_frq = s_psd(signal[1, :], fs=fs, norm=norm, mt=mt)
    psd_pow = zeros(channel_n, length(psd_tmp))

    @inbounds @simd for channel_idx in 1:channel_n
        psd_pow[channel_idx, :], _ = s_psd(signal[channel_idx, :], fs=fs, norm=norm, mt=mt)
    end
    
    return (psd_pow=psd_pow, psd_frq=psd_frq)
end

"""
    s_psd(signal; fs, norm, mt)

Calculate power spectrum density.

# Arguments
- `signal::AbstractArray`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `mt::Bool=false`: if true use multi-tapered periodogram

# Returns

Named tuple containing:
- `psd_pow::Array{Float64, 3}`
- `psd_frq::Array{Float64, 3}`
"""
function s_psd(signal::AbstractArray; fs::Int64, norm::Bool=false, mt::Bool=false)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    size(signal, 2) < 4 * fs && (mt = true)
    channel_n = size(signal, 1)
    epoch_n = size(signal, 3)
    psd_tmp, psd_frq = s_psd(signal[1, :, 1], fs=fs, norm=norm, mt=mt)
    psd_pow = zeros(channel_n, length(psd_tmp), epoch_n)

    @inbounds @simd for epoch_idx in 1:epoch_n
        Threads.@threads for channel_idx in 1:channel_n
            psd_pow[channel_idx, :, epoch_idx], _ = s_psd(signal[channel_idx, :, epoch_idx], fs=fs, norm=norm, mt=mt)
        end
    end
    
    return (psd_pow=psd_pow, psd_frq=psd_frq)
end

"""
    s_stationarity_hilbert(signal)

Calculate phase stationarity using Hilbert transformation.

# Arguments

- `signal::AbstractVector`

# Returns

- `phase_stationarity::Vector{Float64}`
"""
function s_stationarity_hilbert(signal::AbstractVector)
    return diff(DSP.unwrap(angle.(hilbert(signal))))
end

"""
    s_stationarity_mean(signal; window)

Calculate mean stationarity. Signal is split into `window`-long windows and averaged across windows.

# Arguments

- `signal::AbstractVector`
- `window::Int64`: time window in samples

# Returns

- `mean_stationarity::Vector{Float64}`
"""
function s_stationarity_mean(signal::AbstractVector; window::Int64)
    window < 1 && throw(ArgumentError("window must be ≥ 1."))
    window > length(signal) && throw(ArgumentError("window must be ≤ $(length(signal))."))
    signal = signal[1:(window * floor(Int64, length(signal) / window))]
    signal = reshape(signal, Int(length(signal) / window), window)
    return mean(signal, dims=1)[:]
end

"""
    s_stationarity_var(signal; window)

Calculate variance stationarity. Signal is split into `window`-long windows and variance is calculated across windows.

# Arguments

- `signal::AbstractVector`
- `window::Int64`: time window in samples

# Returns

- `var_stationarity::Vector{Float64}`
"""
function s_stationarity_var(signal::AbstractVector; window::Int64)
    window < 1 && throw(ArgumentError("window must be ≥ 1."))
    window > length(signal) && throw(ArgumentError("window must be ≤ $(length(signal))."))
    signal = signal[1:(window * floor(Int64, length(signal) / window))]
    signal = reshape(signal, Int(length(signal) / window), window)
    return var(signal, dims=1)[:]
end

"""
    s_trim(signal; segment)

Remove segment from the signal.

# Arguments

- `signal::AbstractVector`
- `segment::Tuple{Int64, Int64}`: segment (from, to) in samples

# Returns

- `s_trimmed::Vector{Float64}`
"""
function s_trim(signal::AbstractVector; segment::Tuple{Int64, Int64})
    _check_segment(signal, segment[1], segment[2])
    return vcat(signal[1:segment[1] - 1], signal[(segment[2] + 1):end])
end

"""
    s_trim(signal; segment)

Remove segment from the signal.

# Arguments

- `signal::AbstractArray`
- `segment::Tuple{Int64, Int64}`: segment (from, to) in samples

# Returns

- `s_trimmed::Array{Float64}`
"""
function s_trim(signal::AbstractArray; segment::Tuple{Int64, Int64})
    _check_segment(signal[1, :, 1], segment[1], segment[2])
    return hcat(signal[:, 1:(segment[1] - 1), :], signal[:, (segment[2] + 1):end, :])
end

"""
    s2_mi(signal1, signal2)

Calculate mutual information between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`

# Returns

- `mi::Float64`
"""
function s2_mi(signal1::AbstractVector, signal2::AbstractVector)
    return get_mutual_information(signal1, signal2)
end

"""
    s_entropy(signal)

Calculate entropy.

# Arguments

- `signal::AbstractVector`

# Returns

- `ent::Float64`
- `sent::Float64`: Shanon entropy
- `leent::Float64`: log energy entropy
"""
function s_entropy(signal::AbstractVector)

    n = length(signal)
    maxmin_range = maximum(signal) - minimum(signal)
    fd_bins = ceil(Int64, maxmin_range/(2.0 * iqr(signal) * n^(-1/3))) # Freedman-Diaconis

    # recompute entropy with optimal bins for comparison
    h = StatsKit.fit(Histogram, signal, nbins=fd_bins)
    hdat1 = h.weights ./ sum(h.weights)

    # convert histograms to probability values
    return (ent=-sum(hdat1 .* log2.(hdat1 .+ eps())),
            sent=coefentropy(signal, ShannonEntropy()),
            leent=coefentropy(signal, LogEnergyEntropy()))
end

"""
    s_negentropy(signal)

Calculate negentropy.

# Arguments

- `signal::AbstractVector`

# Returns

- `ent::Float64`
"""
function s_negentropy(signal::AbstractVector)
    s = s_demean(signal)
    return 0.5 * log(2 * pi * exp(1) * var(s)) - s_entropy(s)[1]
end

"""
    s_average(signal)

Average all channels.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_averaged::AbstractArray`
"""
function s_average(signal::AbstractArray)
    return mean(signal, dims=1)
end

"""
    s2_average(signal1, signal2)

Averages `signal1` and `signal2`.

# Arguments

- `signal1::AbstractArray`
- `signal2::AbstractArray`

# Returns

- `s_averaged::Vector{Float64}`
"""
function s2_average(signal1::AbstractArray, signal2::AbstractArray)
    return mean(hcat(signal1, signal2), dims=2)
end

"""
    s2_tcoherence(signal1, signal2; pad)

Calculate coherence (mean over time), IC (imaginary coherence) and MSC (magnitude-squared coherence) between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`
- `pad::Int64=0`: number of zeros to add

# Returns

Named tuple containing:
- `c::Vector{Float64}`: coherence
- `msc::Vector{Float64}`: magnitude-squares coherence
- `ic::Vector{Float64}`: imaginary part of coherence
"""
function s2_tcoherence(signal1::AbstractVector, signal2::AbstractVector; pad::Int64=0)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))

    s1_fft = fft0(signal1, pad) ./ length(signal1)
    s2_fft = fft0(signal2, pad) ./ length(signal2)

    coh = @. (abs((s1_fft) * conj.(s2_fft))^2) / (s1_fft * s2_fft)

    msc = @. abs(coh)^2

    return (c=real.(coh), msc=msc, ic=imag.(coh))
end

"""
    s_pca(signal, n)

Calculate `n` first PCs.

# Arguments

- `signal::AbstractArray`
- `n::Int64`: number of PCs

# Returns

Named tuple containing:
- `pc::Array{Float64, 3}:`: PC(1)..PC(n) × epoch
- `pc_var::Matrix{Float64}`: variance of PC(1)..PC(n) × epoch
- `pc_m::PCA{Float64}`: PC mean
- `pca::MultivariateStats.PCA{Float64}`: PC model
"""
function s_pca(signal::AbstractArray; n::Int64)

    n < 0 && throw(ArgumentError("n must be ≥ 1."))
    n > size(signal, 1) && throw(ArgumentError("n must be ≤ $(size(signal, 1))."))

    epoch_n = size(signal, 3)
    pc_m = []

    # check maximum n
    n_tmp = n
    @inbounds @simd for epoch_idx in 1:epoch_n
        pc_m = @views MultivariateStats.fit(PCA, signal[:, :, epoch_idx], maxoutdim=n)
        size(pc_m)[2] < n_tmp && (n_tmp = size(pc_m)[2])
    end
    (n_tmp < n && verbose == true) && @info "Only $n_tmp PC components were generated."
    n = n_tmp
    
    pc = zeros(n, size(signal, 2), epoch_n)
    pc_var = zeros(n, epoch_n)
    pca = nothing
    
    @inbounds @simd for epoch_idx in 1:epoch_n
        # m_cov = s_cov(s)
        # eig_val, eig_vec = eigen(m_cov)
        # eig_val_idx = sortperm(eig_val, rev=true)
        # eig_val = eig_val[eig_val_idx]
        # eig_vec = m_sort(eig_vec, eig_val_idx)
        # eig_val = 100 .* eig_val / sum(eig_val) # convert to %

        pca = @views MultivariateStats.fit(PCA, signal[:, :, epoch_idx], maxoutdim=n)
        v = MultivariateStats.principalvars(pca) ./ MultivariateStats.var(pca) * 100

        for idx in 1:n
            pc_var[idx, epoch_idx] = v[idx]
            # pc[idx, :, epoch_idx] = (eig_vec[:, idx] .* s)[idx, :]
            pc[idx, :, epoch_idx] = @views MultivariateStats.predict(pca, signal[:, :, epoch_idx])[idx, :]
        end
    end

    return (pc=pc, pc_var=pc_var, pc_m=pca.mean, pca=pca)
end

"""
    s_pca_reconstruct(signal, pc, pca)

Reconstructs `signal` using PCA components.

# Arguments

- `signal::AbstractArray`
- `pc::AbstractArray:`: IC(1)..IC(n) × epoch
- `pca::MultivariateStats.PCA{Float64}:`: IC(1)..IC(n) × epoch

# Returns

- `s_reconstructed::Array{Float64, 3}`
"""
function s_pca_reconstruct(signal::AbstractArray; pc::AbstractArray, pca::MultivariateStats.PCA{Float64})

    s_reconstructed = similar(signal)
    epoch_n = size(signal, 3)
    @inbounds @simd for epoch_idx in 1:epoch_n
        s_reconstructed[:, :, epoch_idx] = @views MultivariateStats.reconstruct(pca, pc[:, :, epoch_idx])
    end

    return s_reconstructed
end

"""
    s_fconv(signal; kernel, norm)

Perform convolution in the frequency domain.

# Arguments

- `signal::AbstractArray`
- `kernel::AbstractVector`
- `pad::Int64=0`: number of zeros to add
- `norm::Bool=true`: normalize kernel

# Returns

- `s_conv::Vector{Float64}`
"""
function s_fconv(signal::AbstractArray; pad::Int64=0, kernel::AbstractVector, norm::Bool=true)

    n_signal = length(signal)
    n_kernel = length(kernel)
    half_kernel = floor(Int64, n_kernel / 2)
    s_fft = fft0(signal, pad + n_kernel - 1)
    kernel_fft = fft0(kernel, pad + n_signal - 1)
    norm == true && (kernel_fft ./= cmax(kernel_fft))
    s_conv = @views ifft0(s_fft .* kernel_fft, pad)

    # remove in- and out- edges
    if mod(n_kernel, 2) == 0 
        return s_conv[half_kernel:(end - half_kernel)]
    else
        return s_conv[(half_kernel + 1):(end - half_kernel)]
    end
end

"""
    s_ica(signal, n, tol, iter, f)

Calculate `n` first ICs for `signal`.

# Arguments

- `signal::AbstractArray`
- `n::Int64`: number of PCs
- `tol::Float64=1.0e-6`: tolerance for ICA
- `iter::Int64=100`: maximum number of iterations
- `f::Symbol=:tanh`: neg-entropy functor (:tanh or :gaus)

# Returns

Named tuple containing:
- `ica::Array{Float64, 3}:`: IC(1)..IC(n) × epoch
- `ica_mw::Array{Float64, 3}:`: IC(1)..IC(n) × epoch
"""
function s_ica(signal::AbstractArray; n::Int64, tol::Float64=1.0e-6, iter::Int64=100, f::Symbol=:tanh)

    _check_var(f, [:tanh, :gaus], "f")
    n < 0 && throw(ArgumentError("n must be ≥ 1."))
    n > size(signal, 1) && throw(ArgumentError("n must be ≤ $(size(signal, 1))."))
    channel_n, _, epoch_n = size(signal)
    ica = zeros(n, size(signal, 2), epoch_n)
    ica_mw = zeros(channel_n, n, epoch_n)

    @inbounds @simd for epoch_idx in 1:epoch_n
        f === :tanh && (M = @views MultivariateStats.fit(ICA, signal[:, :, epoch_idx], n, tol=tol, maxiter=iter, fun=MultivariateStats.Tanh(1.0)))
        f === :gaus && (M = @views MultivariateStats.fit(ICA, signal[:, :, epoch_idx], n, tol=tol, maxiter=iter, fun=MultivariateStats.Gaus()))

        n == size(signal, 1) && (mw = inv(M.W)')
        n < size(signal, 1) && (mw = pinv(M.W)')

        for idx in 1:n
            ica[idx, :, epoch_idx] = @views MultivariateStats.predict(M, signal[:, :, epoch_idx])[idx, :]
        end

        ica_mw[:, :, epoch_idx] = mw
    end

    return (ica=ica, ica_mw=ica_mw)
end

"""
    s_ica_reconstruct(signal, ica, ica_mw, ic)

Reconstructs `signal` using removal of `ic` ICA components.

# Arguments

- `signal::AbstractArray`
- `ica::AbstractArray:`: IC(1)..IC(n) × epoch
- `ica_mw::AbstractArray:`: IC(1)..IC(n) × epoch
- `ic::Union{Int64, Vector{Int64}, AbstractRange} - list of ICs to remove

# Returns

- `s_reconstructed::Array{Float64, 3}`
"""
function s_ica_reconstruct(signal::AbstractArray; ica::AbstractArray, ica_mw::AbstractArray, ic::Union{Int64, Vector{Int64}, AbstractRange})

    typeof(ic) <: AbstractRange && (ic = collect(ic))
    if typeof(ic) == Vector{Int64}
        sort!(ic)
        for idx in ic
            (idx < 1 || idx > size(ica_mw, 2)) && throw(ArgumentError("ic must be ≥ 1 and ≤ $(size(ica_mw, 2))"))
        end
    else
        (ic < 1 || ic > size(ica_mw, 2)) && throw(ArgumentError("ic must be ≥ 1 and ≤ $(size(ica_mw, 2))"))
    end
    ic_removal = setdiff(1:size(ica_mw, 2), ic)

    s_reconstructed = zeros(size(signal))

    _, _, epoch_n = size(signal)

    @inbounds @simd for epoch_idx in 1:epoch_n
        s_reconstructed[:, :, epoch_idx] = ica_mw[:, ic_removal, epoch_idx] * ica[ic_removal, :, epoch_idx]
    end

    return s_reconstructed
end

"""
    s_spectrogram(signal; fs, norm, mt, st, demean)

Calculate spectrogram.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling frequency
- `norm::Bool=true`: normalize powers to dB
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `st::Bool=false`: if true use short time Fourier transform
- `demean::Bool=true`: demean signal prior to analysis

# Returns

Named tuple containing:
- `s_pow::Matrix{Float64}`: powers
- `s_frq::Vector{Float64}`: frequencies
- `s_t::Vector{Float64}`: time
"""
function s_spectrogram(signal::AbstractVector; fs::Int64, norm::Bool=true, mt::Bool=false, st::Bool=false, demean::Bool=true)

    (mt == true && st == true) && throw(ArgumentError("Both mt and st must not be true."))
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))

    demean == true && (signal = s_demean(signal))

    nfft = length(signal)
    interval = fs
    overlap = round(Int64, fs * 0.75)

    if st == true
        s_pow = abs.(stft(signal, interval, overlap, nfft=nfft, fs=fs, window=hanning))
        norm == true && (s_pow = pow2db.(s_pow))
        t = 0:1/fs:(length(signal) / fs)
        s_t = linspace(t[1], t[end], size(s_pow, 2))
        s_frq = linspace(0, fs/2, size(s_pow, 1))
        return (s_pow=s_pow, s_frq=s_frq, s_t=s_t)
    end

    if mt == true
        spec = mt_spectrogram(signal, fs=fs)
    else
        spec = spectrogram(signal, interval, overlap, nfft=nfft, fs=fs, window=hanning)
    end    
    s_pow = spec.power
    norm == true ? s_pow = pow2db.(spec.power) : s_pow = spec.power

    #s_t = collect(spec.time)
    #s_frq = Vector(spec.freq)
    t = 0:1/fs:(length(signal) / fs)
    s_t = linspace(t[1], t[end], size(s_pow, 2))
    s_frq = linspace(0, fs/2, size(s_pow, 1))
    
    return (s_pow=s_pow, s_frq=s_frq, s_t=s_t)
end

"""
    s_detect_channel_flat(signal; w, tol)

Detect flat channel.

# Arguments

- `signal::AbstractVector`
- `w::Int64=4`: window width in samples (signal is averaged within `w`-width window)
- `tol::Float64=0.1`: tolerance (signal is flat within `-tol` to `+tol`), `eps()` gives very low tolerance

# Returns

Named tuple containing:
- `r::Float64`: flat to non-flat segments ratio
"""
function s_detect_channel_flat(signal::AbstractVector; w::Int64=4, tol::Float64=0.1)
    w < length(signal) || throw(ArgumentError("w must be < $(length(signal))"))
    sm = Vector{Float64}()
    for idx in 1:w:(length(signal) - w)
        @views push!(sm, mean(signal[idx:(idx + w)]))
    end
    return count(abs.(diff(sm)) .< tol) / length(sm)
end

"""
    s_snr(signal)

Calculate SNR.

# Arguments

- `signal::AbstractVector`

# Returns

- `snr::Float64`: SNR

# Source

D. J. Schroeder (1999). Astronomical optics (2nd ed.). Academic Press. ISBN 978-0-12-629810-9, p.278
"""
function s_snr(signal::AbstractVector)
    return mean(signal) / std(signal)
end

"""
    s_findpeaks(signal; d)

Find peaks.

# Arguments

- `signal::AbstractVector`
- `d::Int64=32`: distance between peeks in samples

# Returns

- `p_idx::Vector{Int64}`

"""
function s_findpeaks(signal::AbstractVector; d::Int64=32)
    d < 1 && throw(ArgumentError("d must be ≥ 1."))
    return findpeaks1d(signal, distance=d)[1]
end

"""
    s_wdenoise(signal; wt)

Perform wavelet denoising.

# Arguments

- `signal::AbstractVector`
- `wt<:DiscreteWavelet`: discrete wavelet, e.g. `wt = wavelet(WT.haar)`

# Returns

- `signal_denoised::Vector{Float64}`
"""
function s_wdenoise(signal::AbstractVector; wt::T) where {T <: DiscreteWavelet}

    # wt in [:db2, :db4, :db8, :db10, :haar, :coif2, :coif4, :coif8] || throw(ArgumentError("wt must be :db2, :db4, :db8, :db10, :haar, :coif2, :coif4, :coif8"))

    # wt === :db2 && (wt = wavelet(WT.db2))
    # wt === :db4 && (wt = wavelet(WT.db4))
    # wt === :db8 && (wt = wavelet(WT.db8))
    # wt === :db10 && (wt = wavelet(WT.db10))
    # wt === :haar && (wt = wavelet(WT.haar))
    # wt === :coif2 && (wt = wavelet(WT.coif2))
    # wt === :coif4 && (wt = wavelet(WT.coif4))
    # wt === :coif8 && (wt = wavelet(WT.coif8))

    return denoise(signal, wt)
end

"""
    s2_ispc(signal1, signal2)

Calculate ISPC (Inter-Site-Phase Clustering) between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`

# Returns

Named tuple containing:
- `ispc::Float64`: ISPC value
- `ispc_angle::Float64`: ISPC angle
- `signal_diff::Vector{Float64}`: signal difference (signal2 - signal1)
- `phase_diff::Vector{Float64}`: phase difference (signal2 - signal1)
- `s1_phase::Vector{Float64}`: signal 1 phase
- `s2_phase::Vector{Float64}`: signal 2 phase
"""
function s2_ispc(signal1::AbstractVector, signal2::AbstractVector)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))

    _, _, _, s1_phase = s_hspectrum(signal1)
    _, _, _, s2_phase = s_hspectrum(signal2)

    signal_diff = signal2 - signal1
    phase_diff = s2_phase - s1_phase

    ispc = abs(mean(exp.(1im .* phase_diff)))
    ispc_angle = angle(mean(exp.(1im .* phase_diff)))

    return (ispc=ispc, ispc_angle=ispc_angle, signal_diff=signal_diff, phase_diff=phase_diff, s1_phase=s1_phase, s2_phase=s2_phase)
end

"""
    s_itpc(signal; t)

Calculate ITPC (Inter-Trial-Phase Clustering) over epochs/trials at time `t`.

# Arguments

- `signal::AbstractArray`: one channel over epochs/trials
- `t::Int64`: time point (sample number) at which ITPC is calculated
- `w::Union{AbstractVector, Nothing}`: optional vector of epochs/trials weights for wITPC calculation

# Returns

Named tuple containing:
- `itpc::Float64`: ITPC value
- `itpcz::Float64`: Rayleigh's ITPC Z value
- `itpc_angle::Float64`: ITPC angle
- `itpc_phases::Vector{Float64}`: phases at time `t` averaged across trials/epochs
"""
function s_itpc(signal::AbstractArray; t::Int64, w::Union{AbstractVector, Nothing}=nothing)

    t < 1 && throw(ArgumentError("t must be ≥ 1."))
    t > size(signal, 2) && throw(ArgumentError("t must be ≤ $(size(signal, 2))."))
    size(signal, 1) == 1 || throw(ArgumentError("signal must have 1 channel."))
    epoch_n = size(signal, 3)

    w === nothing && (w = ones(epoch_n))
    # scale w if w contains negative values
    any(i -> i < 0, w) && (w .+= abs(minimum(w)))
    length(w) == epoch_n || throw(ArgumentError("Length of w should be equal to number of epochs ($epoch_n)."))
    
    s_phase = zeros(size(signal, 2), epoch_n)
    @inbounds @simd for epoch_idx in 1:epoch_n
        _, _, _, s_phase[:, epoch_idx] = @views s_hspectrum(signal[1, :, epoch_idx])
    end
 
    itpc_phases = @view s_phase[t, :]
    itpc = abs.(mean(exp.(1im .* itpc_phases .* w)))
    itpc_angle = angle.(mean(exp.(1im .* itpc_phases .* w)))
    itpcz = epoch_n * itpc^2

    return (itpc=itpc, itpcz=itpcz, itpc_angle=itpc_angle, itpc_phases=itpc_phases)
end

"""
    s2_pli(signal1, signal2)

Calculate PLI (Phase-Lag Index) between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`

# Returns

Named tuple containing:
- `pli::Float64`: PLI value
- `signal_diff::Vector{Float64}`: signal difference (signal2 - signal1)
- `phase_diff::Vector{Float64}`: phase difference (signal2 - signal1)
- `s1_phase::Vector{Float64}`: signal 1 phase
- `s2_phase::Vector{Float64}`: signal 2 phase
"""
function s2_pli(signal1::AbstractVector, signal2::AbstractVector)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))

    _, _, _, s1_phase = s_hspectrum(signal1)
    _, _, _, s2_phase = s_hspectrum(signal2)

    signal_diff = signal2 - signal1
    phase_diff = s2_phase - s1_phase

    pli = abs(mean(sign.(imag.(exp.(1im .* phase_diff)))))

    return (pli=pli, signal_diff=signal_diff, phase_diff=phase_diff, s1_phase=s1_phase, s2_phase=s2_phase)
end

"""
    s2_ged(signal1, signal2)

Perform generalized eigendecomposition.

# Arguments

- `signal1::AbstractArray`: signal to be analyzed
- `signal2::AbstractArray`: original signal

# Returns

Named tuple containing:
- `sged::Matrix{Float64}`
- `ress::Vector{Float64}`
- `ress_normalized::Vector{Float64}`: RESS normalized to -1..1
"""
function s2_ged(signal1::AbstractArray, signal2::AbstractArray)

    size(signal1) == size(signal2) || throw(ArgumentError("signal1 and signal2 must have the same size."))

    s1cov = cov(signal1')
    s2cov = cov(signal2')
    eig_val, eig_vec = eigen(s1cov, s2cov)
    eig_val_idx = sortperm(eig_val, rev=true)
    eig_val = eig_val[eig_val_idx]
    eig_vec = m_sort(eig_vec, eig_val_idx, dims=2)
    sged = signal2 .* eig_vec[:, 1]
    ress = pinv(eig_vec[:, 1]')
    ress_normalized = ress ./ maximum(abs.(ress))

    return (sged=sged, ress=ress, ress_normalized=ress_normalized)
end

"""
    s_frqinst(signal; fs)

Calculate instantaneous frequency.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`

# Returns

- `frqinst::Vector{Float64}`
"""
function s_frqinst(signal::AbstractVector; fs::Int64)
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    _, _, _, h_phases = s_hspectrum(signal)
    return 256 * s_derivative(h_phases) / (2*pi)
end

"""
    s_hspectrum(signal; pad=0)

Calculate amplitudes, powers and phases using Hilbert transform.

# Arguments

- `signal::AbstractArray`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `norm::Bool=true`: normalize do dB

# Returns

Named tuple containing:
- `h::Vector(ComplexF64}`: Hilbert components
- `h_amp::Vector{Float64}`
- `h_pow::Vector{Float64}`
- `h_pha::Vector{Float64}`
"""
function s_hspectrum(signal::AbstractArray; pad::Int64=0, norm::Bool=true)

    h = hilbert(pad0(signal, pad))

    # amplitudes
    h_amp = @. abs(h)
    # power
    h_pow = h_amp.^2
    norm == true && (h_pow = pow2db.(h_pow))
    # phases
    h_pha = angle.(h)

    return (h=h, h_amp=h_amp, h_pow=h_pow, h_pha=h_pha)
end

"""
    t2f(t)

Convert cycle length in ms `t` to frequency.

# Arguments

- `t::Real`: cycle length in ms

# Returns

- `f::Float64`: frequency in Hz
"""
function t2f(t::Real)
    t <= 0 && throw(ArgumentError("t must be > 0."))
    return round(1000 / t, digits=2)
end

"""
    f2t(f)

Convert frequency `f` to cycle length in ms.

# Arguments

- `f::Real`: frequency in Hz

# Returns

- `f::Float64`: cycle length in ms
"""
function f2t(f::Real)
    f <= 0 && throw(ArgumentError("f must be > 0."))
    return round(1000 / f, digits=2)
end

"""
    s_wspectrogram(signal; pad, norm, frq_lim, frq_n, frq, fs, ncyc, demean)

Calculate spectrogram using wavelet convolution.

# Arguments

- `signal::AbstractVector`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `frq_n::Int64`: number of frequencies
- `frq::Symbol=:log`: linear (:lin) or logarithmic (:log) frequencies
- `fs::Int64`: sampling rate
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number o cycles is used per frequency: ncyc = logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n) for frq === :log or ncyc = linspace(ncyc[1], ncyc[2], frq_n) for frq === :lin
- `demean::Bool=true`: demean signal prior to analysis

# Returns

Named tuple containing:
- `w_conv::Matrix(ComplexF64}`: convoluted signal
- `w_powers::Matrix{Float64}`
- `w_phases::Matrix{Float64}`
- `frq_list::Vector{Float64}`
"""
function s_wspectrogram(signal::AbstractVector; pad::Int64=0, norm::Bool=true, frq_lim::Tuple{Real, Real}, frq_n::Int64, frq::Symbol=:lin, fs::Int64, ncyc::Union{Int64, Tuple{Int64, Int64}}=6, demean::Bool=true)

    _check_var(frq, [:log, :lin], "frq")

    pad > 0 && (signal = pad0(signal, pad))
    if typeof(ncyc) == Int64
        ncyc < 1 && throw(ArgumentError("ncyc must be ≥ 1."))
    else
        ncyc[1] < 1 && throw(ArgumentError("ncyc[1] must be ≥ 1."))
        ncyc[2] < 1 && throw(ArgumentError("ncyc[2] must be ≥ 1."))
    end

    # get frequency range
    fs < 1 && throw(ArgumentError("fs must be > 1."))
    frq_lim = tuple_order(frq_lim)
    frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
    frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $(fs / 2)."))
    frq_n < 2 && throw(ArgumentError("frq_n must be ≥ 2."))
    frq_lim[1] == 0 && (frq_lim = (0.1, frq_lim[2]))
    if frq === :log
        # frq_lim = (frq_lim[1], frq_lim[2])
        frq_list = round.(logspace(log10(frq_lim[1]), log10(frq_lim[2]), frq_n), digits=1)
    else
        frq_list = linspace(frq_lim[1], frq_lim[2], frq_n)
    end

    demean == true && (signal = s_demean(signal))
    w_conv = zeros(ComplexF64, length(frq_list), length(signal))
    w_powers = zeros(length(frq_list), length(signal))
    w_amp = zeros(length(frq_list), length(signal))
    w_phases = zeros(length(frq_list), length(signal))

    if typeof(ncyc) != Tuple{Int64, Int64}
        ncyc = repeat([ncyc], frq_n)
    else
        if frq === :log
            ncyc = round.(Int64, logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n))
        else
            ncyc = round.(Int64, linspace(ncyc[1], ncyc[2], frq_n))
        end
    end

    @inbounds @simd for frq_idx in 1:frq_n
        kernel = generate_morlet(fs, frq_list[frq_idx], 1, ncyc=ncyc[frq_idx], complex=true)
        w_conv[frq_idx, :] = s_fconv(signal, kernel=kernel, norm=false)
        # alternative: w_amp[frq_idx, :] = LinearAlgebra.norm.(real.(w_conv), imag.(w_conv), 2)
        w_powers[frq_idx, :] = @views @. abs(w_conv[frq_idx, :])^2
        w_phases[frq_idx, :] = @views @. angle(w_conv[frq_idx, :])
    end

    # remove reflected part of the signal
    # if reflect == true
    #     w_conv = w_conv[:, (length(signal) ÷ 3 + 1):(2 * length(signal) ÷ 3)]
    #     w_amp = w_amp[:, (length(signal) ÷ 3 + 1):(2 * length(signal) ÷ 3)]
    #     w_powers = w_powers[:, (length(signal) ÷ 3 + 1):(2 * length(signal) ÷ 3)]
    #     w_phases = w_phases[:, (length(signal) ÷ 3 + 1):(2 * length(signal) ÷ 3)]
    # end

    norm == true && (w_powers = pow2db.(w_powers))

    return (w_conv=w_conv, w_powers=w_powers, w_phases=w_phases, frq_list=frq_list)
end

"""
   s_fftdenoise(signal; pad, threshold) 

Perform FFT denoising.

# Arguments

- `signal::AbstractVector`
- `pad::Int64=0`: number of zeros to add
- `threshold::Real=0`: PSD threshold for keeping frequency components; if 0, use mean signal power value

# Returns

Named tuple containing:
- `s_denoised::Vector{Float64}`
- `frq_idx::BitVector`: index of components zeroed
"""
function s_fftdenoise(signal::AbstractVector; pad::Int64=0, threshold::Real=0)

    s_fft = fft0(signal, pad)
    s_pow = (real.(s_fft .* conj.(s_fft))) ./ length(signal)
    
    threshold == 0 && (threshold = mean(s_pow))
    
    # zero frequencies with power above threshold
    frq_idx = s_pow .> threshold
    s_fft[frq_idx] .= Complex(0, 0)

    return (s_denoised=ifft0(s_fft, pad), frq_idx=frq_idx)
end

"""
    s_gfilter(signal, fs, f, gw)

Filter using Gaussian in the frequency domain.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `pad::Int64=0`: number of zeros to add
- `f::Real`: filter frequency
- `gw::Real=5`: Gaussian width in Hz

# Returns

Named tuple containing:
- `s_f::Vector{Float64}`
"""
function s_gfilter(signal::AbstractVector; fs::Int64, pad::Int64=0, f::Real, gw::Real=5)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    f <= 0 && throw(ArgumentError("f must be > 0."))
    gw <= 0 && throw(ArgumentError("gw must be > 0."))

    # create Gaussian in frequency domain
    gf = linspace(0, fs, length(signal))
    gs = (gw * (2 * pi - 1)) / (4 * pi)     # normalized width
    gf .-= f                                # shifted frequencies
    # g = @. exp(-0.5 * (gf / gs)^2)        # Gaussian
    g = @. exp((-gf^2 ) / 2 * gs^2)         # Gaussian
    g ./= abs(maximum(g))                   # gain-normalized

    # filter
    return 2 .* ifft0(fft0(signal, pad) .* g, pad)
    
end

"""
    s_ghspectrogram(signal; fs, norm, frq_lim, frq_n, frq, fs, demean)

Calculate spectrogram using Gaussian and Hilbert transform.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `frq_n::Int64`: number of frequencies
- `frq::Symbol=:log`: linear (:lin) or logarithmic (:log) frequencies
- `gw::Real=5`: Gaussian width in Hz
- `demean::Bool`=true: demean signal prior to analysis

# Returns

Named tuple containing:
- `s_pow::Matrix{Float64}`: powers
- `s_pow::Matrix{Float64}`: phases
- `frq_list::Vector{Float64}`: frequencies
"""
function s_ghspectrogram(signal::AbstractVector; fs::Int64, norm::Bool=true, frq_lim::Tuple{Real, Real}, frq_n::Int64, frq::Symbol=:lin, gw::Real=5, demean::Bool=true)

    _check_var(frq, [:log, :lin], "frq")

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    frq_lim = tuple_order(frq_lim)
    frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
    frq_lim[2] > fs ÷ 2 && throw(ArgumentError("Upper frequency bound must be ≤ $(fs ÷ 2)."))
    frq_n < 2 && throw(ArgumentError("frq_n frequency bound must be ≥ 2."))
    frq_lim[1] == 0 && (frq_lim = (0.1, frq_lim[2]))
    if frq === :log
        frq_lim = (frq_lim[1], frq_lim[2])
        s_frq = round.(logspace(log10(frq_lim[1]), log10(frq_lim[2]), frq_n), digits=1)
    else
        s_frq = linspace(frq_lim[1], frq_lim[2], frq_n)
    end

    demean == true && (signal = s_demean(signal))
    s_pow = zeros(length(s_frq), length(signal))
    s_ph = zeros(length(s_frq), length(signal))
    @inbounds @simd for frq_idx in eachindex(s_frq)
        s = s_gfilter(signal, fs=fs, f=s_frq[frq_idx], gw=gw)
        s_pow[frq_idx, :] = abs.(hilbert(s)).^2
        s_ph[frq_idx, :] = angle.(hilbert(s))
    end
    norm == true && (s_pow = pow2db.(s_pow))

    return (s_pow=s_pow, s_ph=s_ph, s_frq=s_frq)
end

"""
    s_tkeo(signal)

Calculate Teager-Kaiser energy-tracking operator: y(t) = x(t)^2 - x(t-1) × x(t+1)

# Arguments

- `signal::AbstractVector`

# Returns

- `s_new::Vector{Float64}`
"""
function s_tkeo(signal::AbstractVector)
    tkeo = zeros(length(signal))
    tkeo[1] = signal[1]
    tkeo[end] = signal[end]
    @inbounds @simd for idx in 2:(length(signal) - 1)
        tkeo[idx] = signal[idx]^2 - (signal[idx - 1] * signal[idx + 1])
    end

    return tkeo
end

"""
    s_mwpsd(signal; pad, norm, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `signal::AbstractVector`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `frq_n::Int64=0`: number of frequencies
- `frq::Symbol=:log`: linear (:lin) or logarithmic (:log) frequencies
- `fs::Int64`: sampling rate
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number o cycles is used per frequency: ncyc = logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n) for frq === :log or ncyc = linspace(ncyc[1], ncyc[2], frq_n) for frq === :lin

# Returns

Named tuple containing:
- `w_powers::Matrix{Float64}`
- `frq_list::Vector{Float64}`
"""
function s_mwpsd(signal::AbstractVector; pad::Int64=0, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, 0), frq_n::Int64=0, frq::Symbol=:lin, fs::Int64, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    _check_var(frq, [:log, :lin], "frq")
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    pad < 0 && throw(ArgumentError("pad must be ≥ 0."))
    frq_lim == (0, 0) && (frq_lim = (0, fs / 2))
    frq_lim = tuple_order(frq_lim)
    frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
    frq_lim[2] > fs ÷ 2 && throw(ArgumentError("Upper frequency bound must be ≤ $(fs ÷ 2)."))
    frq_n == 0 && (frq_n = length(frq_lim[1]:frq_lim[2]))
    frq_n < 2 && throw(ArgumentError("frq_n must be ≥ 2."))
    frq_lim[1] == 0 && (frq_lim = (0.1, frq_lim[2]))
    if frq === :log
        frq_lim = (frq_lim[1], frq_lim[2])
        frq_list = round.(logspace(log10(frq_lim[1]), log10(frq_lim[2]), frq_n), digits=1)
    else
        frq_list = linspace(frq_lim[1], frq_lim[2], frq_n)
    end

    if typeof(ncyc) != Tuple{Int64, Int64}
        ncyc = repeat([ncyc], frq_n)
    else
        if frq === :log
            ncyc = round.(Int64, logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n))
        else
            ncyc = round.(Int64, linspace(ncyc[1], ncyc[2], frq_n))
        end
    end

    channel_n = size(signal, 1)
    w_powers = zeros(channel_n, )

    pad > 0 && (signal = pad0(signal, pad))
    @inbounds @simd for frq_idx in 1:frq_n
        kernel = generate_morlet(fs, frq_list[frq_idx], 1, ncyc=ncyc[frq_idx], complex=true)
        w_conv = s_fconv(signal, kernel=kernel, norm=true)
        w_powers[frq_idx] = mean(@. abs(w_conv)^2)
    end

    w_powers = w_powers[1:length(frq_list)]
    norm == true && (w_powers = pow2db.(w_powers))

    return (w_powers=w_powers, frq_list=frq_list)
end


"""
    s_mwpsd(signal; pad, norm, frq_lim, frq_n, frq, fs, ncyc)

Calculate power spectrum using Morlet wavelet convolution.

# Arguments

- `signal::Array{Float64, 2}`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}=(0, 0)`: frequency bounds for the spectrogram
- `frq_n::Int64=10`: number of frequencies
- `frq::Symbol=:log`: linear (:lin) or logarithmic (:log) frequencies
- `fs::Int64`: sampling rate
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet, for tuple a variable number o cycles is used per frequency: ncyc = logspace(log10(ncyc[1]), log10(ncyc[2]), frq_n) for frq === :log or ncyc = linspace(ncyc[1], ncyc[2], frq_n) for frq === :lin

# Returns

Named tuple containing:
- `w_powers::Matrix{Float64}`
- `frq_list::Vector{Float64}`
"""
function s_mwpsd(signal::Matrix{Float64}; pad::Int64=0, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, 0), frq_n::Int64=10, frq::Symbol=:lin, fs::Int64, ncyc::Union{Int64, Tuple{Int64, Int64}}=6)

    channel_n = size(signal, 1)
    w_powers, frq_list = s_mwpsd(signal[1, :], pad=pad, norm=norm, frq_lim=frq_lim, frq_n=frq_n, frq=frq, fs=fs, ncyc=ncyc)
    w_powers = zeros(channel_n, length(frq_list))
    frq_list = zeros(length(frq_list))

    Threads.@threads for channel_idx in 1:channel_n
        @inbounds w_powers[channel_idx, :], frq_list = @views s_mwpsd(signal[channel_idx, :], pad=pad, norm=false, frq_lim=frq_lim, frq_n=frq_n, frq=frq, fs=fs, ncyc=ncyc)
    end

    norm == true && (w_powers = pow2db.(w_powers))

    return (w_powers=w_powers, frq_list=frq_list)
end

"""
    a2_cmp(a1, a2; p, perm_n)

Compare two 3-dimensional arrays `a1` and `a2` (e.g. two spectrograms), using permutation based statistic.

# Arguments

- `a1::Array{<:Real, 3}`: first array
- `a2::Array{<:Real, 3}`: second array
- `p::Float64=0.05`: p-value
- `perm_n::Int64=1000`: number of permutations

# Returns

Named tuple containing:
- `zmap::Array{Float64, 3}`: array of Z-values
- `zmap_b::Array{Float64, 3}`: binarized mask of statistically significant positions
"""
function a2_cmp(a1::Array{<:Real, 3}, a2::Array{<:Real, 3}; p::Float64=0.05, perm_n::Int64=1000)

    size(a1) == size(a2) || throw(ArgumentError("Both arrays must have the same size"))
    perm_n <= 0 && throw(ArgumentError("perm_n must be > 0."))
    p < 0 && throw(ArgumentError("p must be ≥ 0."))
    p > 1 && throw(ArgumentError("p must be ≤ 1."))

    spec_diff = dropdims(mean(a2, dims=3) .- mean(a1, dims=3), dims=3)
    zval = abs(norminvcdf(p))
    perm_n = 1000
    spec_all = cat(a1, a2, dims=3)
    perm_maps = zeros(size(a1, 1), size(a1, 2), perm_n)
    epoch_n = size(spec_all, 3)
    @inbounds @simd for perm_idx in 1:perm_n
        rand_idx = sample(1:epoch_n, epoch_n, replace=false)
        rand_spec = @view spec_all[:, :, rand_idx]
        perm_maps[:, :, perm_idx] = @views dropdims(mean(rand_spec[:, :, (epoch_n ÷ 2 + 1):end], dims=3) .- mean(rand_spec[:, :, 1:(epoch_n ÷ 2)], dims=3), dims=3)
    end
    mean_h0 = dropdims(mean(perm_maps, dims=3), dims=3)
    std_h0 = dropdims(std(perm_maps, dims=3), dims=3)

    # threshold real data
    zmap = @. (spec_diff - mean_h0) / std_h0

    # threshold at p-value
    zmap_b = deepcopy(zmap)
    @. zmap_b[abs(zmap) < zval] = 0
    @. zmap_b[zmap_b != 0] = 1
    zmap_b = Bool.(zmap_b)
    zmap_b = map(x -> !x, zmap_b)

    return (zmap=zmap, zmap_b=zmap_b)
end

"""
    s_fcoherence(signal; fs, frq_lim)

Calculate coherence (mean over all frequencies) and MSC (magnitude-squared coherence) between channels.

# Arguments

- `signal::AbstractArray`
- `fs::Int64`: sampling rate
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: return coherence only for the given frequency range

# Returns

Named tuple containing:
- `c::Array{Float64, 3}`: coherence
- `msc::Array{Float64, 3}`: MSC
- `f::Vector{Float64}`: frequencies
"""
function s_fcoherence(signal::AbstractArray; fs::Int64, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    c = mt_coherence(signal, fs=fs)
    f = Vector(c.freq)
    c = c.coherence
    if frq_lim !== nothing
        frq_lim = tuple_order(frq_lim)
        frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
        frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $fs."))
        idx1 = vsearch(frq_lim[1], f)
        idx2 = vsearch(frq_lim[2], f)
        c = c[:, :, idx1:idx2]
        f = f[idx1:idx2]
    end

    return (c=c, msc=c.^2, f=f)
end

"""
    s2_fcoherence(signal1, signal2; fs, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

Calculate coherence (mean over all frequencies) and MSC (magnitude-squared coherence) between channels of `signal1` and `signal2`.

# Arguments

- `signal1::AbstractArray`
- `signal2::AbstractArray`
- `fs::Int64`
- `frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing`: return coherence only for the given frequency range

# Returns

- `c::Array{Float64, 3}`: coherence
- `msc::Array{Float64, 3}`: MSC
- `f::Vector{Float64}`: frequencies
"""
function s2_fcoherence(signal1::AbstractArray, signal2::AbstractArray; fs::Int64, frq_lim::Union{Tuple{Real, Real}, Nothing}=nothing)

    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))

    signal = hcat(signal1, signal2)'
    c = mt_coherence(signal, fs=fs)
    f = Vector(c.freq)
    c = c.coherence
    if frq_lim !== nothing
        frq_lim = tuple_order(frq_lim)
        frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
        frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $fs."))
        idx1 = vsearch(frq_lim[1], f)
        idx2 = vsearch(frq_lim[2], f)
        c = c[:, :, idx1:idx2]
        f = f[idx1:idx2]
    end
    c = c[1, 2, :]
    msc = @. abs(c)^2
    
    return (c=c, msc=msc, f=f)
end

"""
    a2_l1(a1, a2)

Compare two arrays (e.g. two spectrograms), using L1 (Manhattan) distance.

# Arguments

- `a1::AbstractArray`: first array
- `a2::AbstractArray`: second array

# Returns

- `l1::Float64`
"""
function a2_l1(a1::AbstractArray, a2::AbstractArray)
    size(a1) == size(a2) || throw(ArgumentError("a1 and a2 mast have the same size."))
    return sum(abs.(a1 .- a2))
end

"""
    a2_l2(a1, a2)

Compare two arrays (e.g. two spectrograms), using L2 (Euclidean) distance.

# Arguments

- `a1::AbstractArray`: first array
- `a2::AbstractArray`: second array

# Returns

- `l2::Float64`
"""
function a2_l2(a1::AbstractArray, a2::AbstractArray)
    size(a1) == size(a2) || throw(ArgumentError("a1 and a2 mast have the same size."))
    # return sqrt(sum((a1 .- a2).^2))
    return euclidean(a1, a2)
end

"""
    s_cums(signal)

Calculate cumulative sum.

# Arguments

- `signal::AbstractVector`

# Returns

- `signal_cs::Vector{Float64}`
"""
function s_cums(signal::AbstractVector)
    return cumsum(signal)
end

"""
    s_cums(signal)

Calculate cumulative sum.

# Arguments

- `signal::Array{<:Real, 3}`

# Returns

- `signal_cs::Array{Float64, 3}`
"""
function s_cums(signal::Array{<:Real, 3})
    
    channel_n, _, epoch_n = size(signal)
    signal_cs = similar(signal)

    @inbounds @simd for epoch_idx in 1:epoch_n
        Threads.@threads for channel_idx in 1:channel_n
            signal_cs[channel_idx, :, epoch_idx] = @views s_cums(signal[channel_idx, :, epoch_idx])
        end
    end

    return signal_cs
end

"""
    s_gfp(signal)

Calculate GFP (Global Field Power).

# Arguments

- `signal::AbstractVector`

# Returns

- `gfp::Float64`
"""
function s_gfp(signal::AbstractVector)
    return sum(signal.^2) / length(signal)
end

"""
    s_gfp_norm(signal)

Calculate signal normalized for GFP (Global Field Power).

# Arguments

- `signal::AbstractVector`

# Returns

- `gfp_norm::Float64`
"""
function s_gfp_norm(signal::AbstractVector)
    return signal ./ s_gfp(signal)
end

"""
    s2_diss(signal1, signal2)

Calculate DISS (global dissimilarity) and spatial correlation between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`

# Returns

Named tuple containing:
- `diss::Float64`: global dissimilarity
- `c::Float64`: spatial correlation
"""
function s2_diss(signal1::AbstractVector, signal2::AbstractVector)
    
    length(signal1) == length(signal2) || throw(ArgumentError("Both signals must have the same length."))
    gfp_norm1 = s_gfp_norm(signal1)
    gfp_norm2 = s_gfp_norm(signal2)
    diss = sqrt(sum((gfp_norm1 .- gfp_norm2).^2) / length(signal1))
    c = 0.5 * (2 - diss^2)

    return (diss=diss, c=c)
end

"""
    generate_morlet_fwhm(fs, f, t; h)

Generate Morlet wavelet using Mike X Cohen formula.

# Arguments

- `fs::Int64`: sampling rate
- `f::Real`: frequency
- `t::Real=1`: length = -t:1/fs:t
- `h::Float64=0.25`: full width at half-maximum in seconds (FWHM)

# Returns

- `morlet::Vector{ComplexF64}`

# Source

Cohen MX. A better way to define and describe Morlet wavelets for time-frequency analysis. NeuroImage. 2019 Oct;199:81–6. 
"""
function generate_morlet_fwhm(fs::Int64, f::Real, t::Real=1; h::Float64=0.25)
    t = -t:1/fs:t
    return @. exp(2 * 1im * π * f * t) * exp((-4 * log(2) * t^2) / (h^2))
end

"""
    f_nearest(m, pos)

Find nearest position tuple `pos` in matrix of positions `m`.

# Arguments

- `m::Matrix{Tuple{Float64, Float64}}`
- `p::Tuple{Float64, Float64}`

# Returns

- `pos::Tuple{Int64, Int64}`: row and column in m
"""
function f_nearest(m::Matrix{Tuple{Float64, Float64}}, p::Tuple{Float64, Float64})
    d = zeros(size(m))
    @inbounds @simd for idx1 in 1:size(m, 1)
        for idx2 in 1:size(m, 2)
            d[idx1, idx2] = euclidean(m[idx1, idx2], p)
        end
    end
    return (findmin(d)[2][1], findmin(d)[2][2])
end

"""
    s_band_mpower(signal; fs, f)

Calculate mean and maximum band power and its frequency.

# Arguments

- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `f::Tuple{Real, Real}`: lower and upper frequency bounds

# Returns

Named tuple containing:
- `mbp::Float64`: mean band power [dB]
- `maxfrq::Float64`: frequency of maximum band power [Hz]
- `maxbp::Float64`: power at maximum band frequency [dB]
"""
function s_band_mpower(signal::AbstractVector; fs::Int64, f::Tuple{Real, Real}, mt::Bool=false)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    f = tuple_order(f)
    f[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0.")) 
    f[2] > fs / 2 && throw(ArgumentError("Lower frequency bound must be ≤ $(fs / 2).")) 

    if mt == true
        psd = mt_pgram(signal, fs=fs)
    else
        psd = welch_pgram(signal, 4*fs, fs=fs)
    end

    psd_freq = Vector(psd.freq)
    f1_idx = vsearch(f[1], psd_freq)
    f2_idx = vsearch(f[2], psd_freq)
    mbp = mean(psd.power[f1_idx:f2_idx])
    maxfrq = psd_freq[f1_idx:f2_idx][findmax(psd.power[f1_idx:f2_idx])[2]]
    maxbp = psd.power[vsearch(maxfrq, psd_freq)]

    return (mbp=mbp, maxfrq=maxfrq, maxbp=maxbp)
end

"""
    s_rel_psd(signal; fs, norm, mt, f)

Calculate relative power spectrum density.

# Arguments
- `signal::AbstractVector`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `mt::Bool=false`: if true use multi-tapered periodogram
- `f::Union(Tuple{Real, Real}, Nothing)=nothing`: calculate power relative to frequency range or total power

# Returns

Named tuple containing:
- `psd_pow::Vector{Float64}`
- `psd_frq::Vector{Float64}`
"""
function s_rel_psd(signal::AbstractVector; fs::Int64, norm::Bool=false, mt::Bool=false, f::Union{Tuple{Real, Real}, Nothing}=nothing)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    if f !== nothing
        f = tuple_order(f)
        f[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0.")) 
        f[2] > fs / 2 && throw(ArgumentError("Lower frequency bound must be ≤ $(fs / 2).")) 
    end
    ref_pow = f === nothing ? s_total_power(signal, fs=fs, mt=mt) : s_band_power(signal, fs=fs, mt=mt, f=f)
    if mt == true
        psd = mt_pgram(signal, fs=fs)
    else
        psd = welch_pgram(signal, 4*fs, fs=fs)
    end

    psd_pow = power(psd)
    psd_frq = Vector(freq(psd))
    psd_pow[1] = psd_pow[2]
    psd_pow ./= ref_pow

    norm == true && (psd_pow = pow2db.(psd_pow))

    return (psd_pow=psd_pow, psd_frq=psd_frq)
end

"""
    s_rel_psd(signal; fs, norm, mt, f)

Calculate relative power spectrum density.

# Arguments
- `signal::Matrix{Float64}`
- `fs::Int64`: sampling rate
- `norm::Bool=false`: normalize do dB
- `mt::Bool=false`: if true use multi-tapered periodogram
- `f::Union(Tuple{Real, Real}, Nothing)=nothing`: calculate power relative to frequency range or total power

# Returns

Named tuple containing:
- `psd_pow::Vector{Float64}`
- `psd_frq::Vector{Float64}`
"""
function s_rel_psd(signal::Matrix{Float64}; fs::Int64, norm::Bool=false, mt::Bool=false, f::Union{Tuple{Real, Real}, Nothing}=nothing)

    channel_n = size(signal, 1)
    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    f = tuple_order(f)
    f[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0.")) 
    f[2] > fs / 2 && throw(ArgumentError("Lower frequency bound must be ≤ $(fs / 2).")) 

    if mt == true
        psd_tmp = mt_pgram(signal[1, :], fs=fs)
    else
        psd_tmp = welch_pgram(signal[1, :], 4*fs, fs=fs)
    end
    psd_frq = Vector(freq(psd_tmp))
    psd_pow = zeros(channel_n, length(Vector(freq(psd_tmp))))

    Threads.@threads for channel_idx in 1:channel_n
        ref_pow = f === nothing ? s_total_power(signal[channel_idx, :], fs=fs, mt=mt) : s_band_power(signal[channel_idx, :], fs=fs, mt=mt, f=f)
        if mt == true
            psd = mt_pgram(signal[channel_idx, :], fs=fs)
        else
            psd = welch_pgram(signal[channel_idx, :], 4*fs, fs=fs)
        end
        psd_pow[channel_idx, :] = power(psd)
        psd_pow[channel_idx, :] ./= ref_pow
        psd_pow[channel_idx, 1] = psd_pow[channel_idx, 2]
    end

    norm == true && (psd_pow = pow2db.(psd_pow))

    return (psd_pow=psd_pow, psd_frq=psd_frq)
end

"""
    s_wbp(signal; pad, frq, fs, ncyc, demean)

Perform wavelet bandpass filtering.

# Arguments

- `signal::AbstractVector`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `frq::Real`: filter frequency
- `fs::Int64`: sampling rate
- `ncyc::Int64=6`: number of cycles for Morlet wavelet
- `demean::Bool=true`: demean signal prior to analysis

# Returns

- `signal_new::Vector{Float64}`
"""
function s_wbp(signal::AbstractVector; pad::Int64=0, frq::Real, fs::Int64, ncyc::Int64=6, demean::Bool=true)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    frq <= 0 && throw(ArgumentError("frq must be > 0."))
    ncyc <= 0 && throw(ArgumentError("ncyc must be > 0."))
    pad < 0 && throw(ArgumentError("pad must be ≥ 0."))
    frq > fs / 2 && throw(ArgumentError("frq must be ≤ $(fs / 2)."))

    pad > 0 && (signal = pad0(signal, pad))

    demean == true && (signal = s_demean(signal))

    kernel = generate_morlet(fs, frq, 1, ncyc=ncyc, complex=true)

    return real.(s_fconv(signal, kernel=kernel, norm=true))
end

"""
    s_normalize_gauss(signal, dims)

Normalize to Gaussian.

# Arguments

- `signal::AbstractArray`
- `dims::Int64=1`: dimension for cumsum()

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_gauss(signal::AbstractArray, dims::Int64=1)
    dims in 1:ndims(signal) || throw(ArgumentError("dims must be in: 1:$(ndims(signal)).")) 
    l = length(signal) + 1
    return atanh.((tiedrank(cumsum(signal, dims=dims)) ./ l .- 0.5) .* 2)
end

"""
    s_cbp(signal; pad, frq, fs, demean)

Perform convolution bandpass filtering.

# Arguments

- `signal::AbstractVector`
- `pad::Int64`: pad the `signal` with `pad` zeros
- `frq::Real`: filter frequency
- `fs::Int64`: sampling rate
- `demean::Bool=true`: demean signal prior to analysis

# Returns

- `signal_new::Vector{Float64}`
"""
function s_cbp(signal::AbstractVector; pad::Int64=0, frq::Real, fs::Int64, demean::Bool=true)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    frq <= 0 && throw(ArgumentError("frq must be > 0."))
    frq > fs / 2 && throw(ArgumentError("frq must be ≤ $(fs / 2)."))

    pad > 0 && (signal = pad0(signal, pad))

    demean == true && (signal = s_demean(signal))

    kernel = generate_sine(frq, -1:1/fs:1)

    return s_tconv(signal, kernel=kernel)
end

"""
    s_specseg(sp, sf, st; t, f)

Return spectrogram segment.

# Arguments

- `sp::Matrix{Float64}`: spectrogram powers
- `st::Vector{Float64}`: spectrogram time
- `sf::Vector{Float64}`: spectrogram frequencies
- `t::Tuple{Real, Real}`: time bounds
- `f::Tuple{Real, Real}`: frequency bounds

# Returns

Named tuple containing:
- `seg_pow::Matrix{Float64}`: powers
- `seg_shape::Shape{Real, Int64}`: shape for plotting
- `t_idx::Tuple{Real, Real}`: time indices
- `f_idx::Tuple{Real, Real}`: frequency indices
"""
function s_specseg(sp::Matrix{Float64}, st::Vector{Float64}, sf::Vector{Float64}; t::Tuple{Real, Real}, f::Tuple{Real, Real})

    t = tuple_order(t)
    f = tuple_order(f)

    t[1] < st[1] && throw(ArgumentError("t[1] must be ≥ $(st[1])."))
    t[2] > st[end] && throw(ArgumentError("t[2] must be ≤ $(st[end])."))
    f[1] < sf[1] && throw(ArgumentError("f[1] must be ≥ $(sf[1])."))
    f[2] > sf[end] && throw(ArgumentError("f[2] must be ≤ $(sf[end])."))

    f_idx1 = vsearch(f[1], sf)
    f_idx2 = vsearch(f[2], sf)
    t_idx1 = vsearch(t[1], st)
    t_idx2 = vsearch(t[2], st)
    seg_pow = sp[f_idx1:f_idx2, t_idx1:t_idx2]
    seg_shape = Shape([(st[t_idx1], sf[f_idx1]), (st[t_idx2], sf[f_idx1]), (st[t_idx2], sf[f_idx2]), (st[t_idx1], sf[f_idx2])])

    return (seg_pow=seg_pow, seg_shape=seg_shape, t_idx=(t_idx1,t_idx2), f_idx=(f_idx1,f_idx2))
end


"""
    s_specseg(sp, sf, st; t, f)

Return spectrogram segment.

# Arguments

- `sp::AbstractArray`: spectrogram powers
- `st::AbstractVector`: spectrogram time
- `sf::AbstractVector`: spectrogram frequencies
- `t::Tuple{Real, Real}`: time bounds
- `f::Tuple{Real, Real}`: frequency bounds

# Returns

Named tuple containing:
- `seg_pow::Array{Float64, 3}`: segment of powers
- `seg_shape::Shape{Real, Int64}`: segment coordinates (shape for plotting)
- `t_idx::Tuple{Real, Real}`: time indices
- `f_idx::Tuple{Real, Real}`: frequency indices
"""
function s_specseg(sp::AbstractArray, st::AbstractVector, sf::AbstractVector; channel::Int64, t::Tuple{Real, Real}, f::Tuple{Real, Real})

    t = tuple_order(t)
    f = tuple_order(f)

    channel < 1 && throw(ArgumentError("channel must be ≥ 1."))
    channel > size(sp, 3) && throw(ArgumentError("channel must be ≤ $(size(sp, 3))."))

    t[1] < st[1] && throw(ArgumentError("t[1] must be ≥ $(st[1])."))
    t[2] > st[end] && throw(ArgumentError("t[2] must be ≤ $(st[end])."))
    f[1] < sf[1] && throw(ArgumentError("f[1] must be ≥ $(sf[1])."))
    f[2] > sf[end] && throw(ArgumentError("f[2] must be ≤ $(sf[end])."))

    f_idx1 = vsearch(f[1], sf)
    f_idx2 = vsearch(f[2], sf)
    t_idx1 = vsearch(t[1], st)
    t_idx2 = vsearch(t[2], st)
    seg_pow = sp[f_idx1:f_idx2, t_idx1:t_idx2, channel, :]
    seg_shape = Shape([(st[t_idx1], sf[f_idx1]), (st[t_idx2], sf[f_idx1]), (st[t_idx2], sf[f_idx2]), (st[t_idx1], sf[f_idx2])])

    return (seg_pow=seg_pow, seg_shape=seg_shape, t_idx=(t_idx1,t_idx2), f_idx=(f_idx1,f_idx2))
end

"""
    s_denoise_wien(signal)

Perform Wiener deconvolution denoising.

# Arguments

- `signal::AbstractArray`

# Returns

- `signal_new::Vector{Float64}`
"""
function s_denoise_wien(signal::AbstractArray)

    channel_n, _, epoch_n = size(signal)
    signal_new = similar(signal)

    @inbounds @simd for epoch_idx in 1:epoch_n
        s_m = @views mean(signal[:, :, epoch_idx], dims=1)'[:, 1]
        m = mean(s_m)
        noise = rand(Float64, size(s_m)) .* m
        Threads.@threads for channel_idx in 1:channel_n
            signal_new[channel_idx, :, epoch_idx] = @views wiener(signal[channel_idx, :, epoch_idx], s_m, noise)
        end
    end

    return signal_new
end

"""
    s2_cps(signal1, signal2; fs, norm)

Calculate cross power spectrum between `signal1` and `signal2`.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`
- `fs::Int64`: sampling rate
- `norm::Bool=true`: normalize do dB

# Returns

Named tuple containing:
- `cps_pw::Vector{Float64}`: cross power spectrum power
- `cps_ph::Vector{Float64}`: cross power spectrum phase (in radians)
- `cps_fq::Vector{Float64}`: cross power spectrum frequencies
"""
function s2_cps(signal1::AbstractVector, signal2::AbstractVector; fs::Int64, norm::Bool=true)

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    s = hcat(signal1, signal2)'
    p = mt_cross_power_spectra(s, fs=fs)
    cps_pw = real.(p.power)[1, 2, :]
    cps_ph = angle.(imag.(p.power))[1, 2, :]
    cps_fq = Vector(p.freq)

    return (cps_pw=cps_pw, cps_ph=cps_ph, cps_fq=cps_fq)
end

"""
    s_phdiff(signal1, signal2; pad, h)

Calculate phase difference between signals.

# Arguments

- `signal1::AbstractVector`
- `signal2::AbstractVector`
- `pad::Int64=0`: number of zeros to add
- `h::Bool=false`: use FFT or Hilbert transformation (if h=true)

# Returns

Named tuple containing:
- `ph_diff::Vector{Float64}`: phase differences in radians
"""
function s2_phdiff(signal1::AbstractVector, signal2::AbstractVector; pad::Int64=0, h::Bool=false)

    if h
        _, _, _, ph1 = s_hspectrum(signal1, pad=pad)
        _, _, _, ph2 = s_hspectrum(signal2, pad=pad)
    else
        _, _, _, ph1 = s_spectrum(signal1, pad=pad)
        _, _, _, ph2 = s_spectrum(signal2, pad=pad)
    end

    return round.(ph1 - ph2, digits=2)
end

"""
    s_normalize_log10(signal)

Normalize using log10-transformation.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_log10(signal::AbstractArray)
    m = 1 + abs(minimum(signal))
    return @. log10(signal + m)
end

"""
    s_normalize_neglog(signal)

Normalize to using -log-transformation.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_neglog(signal::AbstractArray)
    return @. -log(signal)
end

"""
    s_normalize_neglog10(signal)

Normalize using -log10-transformation.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_neglog10(signal::AbstractArray)
    return @. -log10(signal)
end

"""
    s_normalize_neg(signal)

Normalize in [0, -∞].

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_neg(signal::AbstractArray)
    m = maximum(signal)
    return @. signal - m
end

"""
    s_normalize_pos(signal)

Normalize in [0, +∞].

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_pos(signal::AbstractArray)
    m = abs(minimum(signal))
    return @. signal + m
end

"""
    s_normalize_perc(signal)

Normalize in percentages.

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_perc(signal::AbstractArray)
    m1 = minimum(signal)
    m2 = maximum(signal)
    m = m2 - m1
    return (signal .- m1) ./ m
end

"""
    s_normalize(signal, n; method)

Normalize.

# Arguments

- `signal::AbstractArray`
- `n::Real`
- `method::Symbol`: :zscore, :minmax, :log, :log10, :neglog, :neglog10, :neg, :pos, :perc, :gauss, :invroot, :n, :none

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize(signal::AbstractArray, n::Real=1.0; method::Symbol)

    _check_var(method, [:zscore, :minmax, :log, :log10, :neglog, :neglog10, :neg, :pos, :perc, :gauss, :invroot, :n, :none], "method")

    if method === :zscore
        return s_normalize_zscore(signal)
    elseif method === :minmax
        return s_normalize_minmax(signal)
    elseif method === :log
        return s_normalize_log(signal)
    elseif method === :log10
        return s_normalize_log10(signal)
    elseif method === :neglog
        return s_normalize_neglog(signal)
    elseif method === :neglog10
        return s_normalize_neglog10(signal)
    elseif method === :neg
        return s_normalize_neg(signal)
    elseif method === :pos
        return s_normalize_pos(signal)
    elseif method === :perc
        return s_normalize_perc(signal)
    elseif method === :gauss
        return s_normalize_gauss(signal)
    elseif method === :invroot
        return s_normalize_invroot(signal)
    elseif method === :n
        return s_normalize_n(signal, n)
    elseif method === :none
        return signal
    end
end

"""
    s_phases(signal; pad)

Calculate phases.

# Arguments

- `signal::AbstractArray`
- `pad::Int64=0`: number of zeros to add

# Returns

- `phases::Vector{Float64}`
"""
function s_phases(signal::AbstractArray, pad::Int64=0)
    return angle.(pad0(signal, pad))
end

"""
    s_cwtspectrogram(signal; wt, pad, norm, frq_lim, fs, demean)

Calculate spectrogram using continuous wavelet transformation (CWT).

# Arguments

- `signal::AbstractVector`
- `wt<:CWT`: continuous wavelet, e.g. `wt = wavelet(Morlet(π), β=2)`, see ContinuousWavelets.jl documentation for the list of available wavelets
- `fs::Int64`: sampling rate
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `demean::Bool`=true: demean signal prior to analysis

# Returns

Named tuple containing:
- `h_powers::Matrix{Float64}`
- `frq_list::Vector{Float64}`
"""
function s_cwtspectrogram(signal::AbstractVector; wt::T, fs::Int64, norm::Bool=true, frq_lim::Tuple{Real, Real}, demean::Bool=true) where {T <: CWT}

    fs < 1 && throw(ArgumentError("fs must be ≥ 1."))
    frq_lim = tuple_order(frq_lim)
    frq_lim[1] < 0 && throw(ArgumentError("Lower frequency bound must be ≥ 0."))
    frq_lim[2] > fs / 2 && throw(ArgumentError("Upper frequency bound must be ≤ $(fs / 2)."))

    demean == true && (signal = s_demean(signal))

    h_powers = abs.(ContinuousWavelets.cwt(signal, wt)')
    frq_list = ContinuousWavelets.getMeanFreq(ContinuousWavelets.computeWavelets(length(signal), wt)[1])
    frq_list[1] = 0
    frq_list[1] < frq_lim[1] && throw(ArgumentError("Lower frequency bound must be ≥ $(frq_list[1])."))
    frq_list[end] < frq_lim[2] && throw(ArgumentError("Upper frequency bound must be ≤ $(frq_list[end])."))
    frq_list = frq_list[vsearch(frq_lim[1], frq_list):vsearch(frq_lim[2], frq_list)]
    h_powers = h_powers[vsearch(frq_lim[1], frq_list):vsearch(frq_lim[2], frq_list), :]

    norm == true && (h_powers = pow2db.(h_powers))

    return (h_powers=h_powers, frq_list=frq_list)
end

"""
    s_dwt(signal; wt, type, l)

Perform discrete wavelet transformation (DWT).

# Arguments

- `signal::AbstractVector`
- `wt<:DiscreteWavelet`: discrete wavelet, e.g. `wt = wavelet(WT.haar)`, see Wavelets.jl documentation for the list of available wavelets
- `type::Symbol`: transformation type: Stationary Wavelet Transforms (`:sdwt`) or Autocorrelation Wavelet Transforms (`:acdwt`)
- `l::Int64=0`: number of levels, default maximum number of levels available or total transformation

# Returns

- `dwt_c::Array{Float64, 2}`: DWT coefficients cAl, cD1, ..., cDl (by rows)
"""
function s_dwt(signal::AbstractVector; wt::T, type::Symbol, l::Int64=0) where {T <: DiscreteWavelet}
    _check_var(type, [:sdwt, :acdwt], "type")

    l < 0 && throw(ArgumentError("l must be > 0."))
    l > maxtransformlevels(signal) && throw(ArgumentError("l must be ≤ $(maxtransformlevels(signal))."))

    if l == 0
        l = maxtransformlevels(signal)
        _info("Calculating DWT using maximum level: $l.")
    end

    if type === :sdwt
        dwt_coefs = sdwt(signal, wt, l)
    elseif type === :acdwt
        dwt_coefs = acdwt(signal, wt, l)
    end

    dwt_c = zeros(size(dwt_coefs, 2), size(dwt_coefs, 1))
    dwt_c[1, :] = @view dwt_coefs[:, 1]
    @inbounds @simd for idx in 2:(l + 1)
        dwt_c[idx, :] = @views dwt_coefs[:, (end - idx + 2)]
    end

    return dwt_c
end

"""
    s_idwt(dwt_coefs; wt, type)

Perform inverse discrete wavelet transformation (iDWT) of the `dwt_coefs`.

# Arguments

- `dwt_coefs::AbstractArray`: DWT coefficients cAl, cD1, ..., cDl (by rows)
- `wt<:DiscreteWavelet`: discrete wavelet, e.g. `wt = wavelet(WT.haar)`, see Wavelets.jl documentation for the list of available wavelets
- `type::Symbol`: transformation type: Stationary Wavelet Transforms (:sdwt) or Autocorrelation Wavelet Transforms (:acdwt)

# Returns

- `signal::Vector{Float64}`: reconstructed signal
"""
function s_idwt(dwt_coefs::AbstractArray; wt::T, type::Symbol) where {T <: DiscreteWavelet}
    
    _check_var(type, [:sdwt, :acdwt], "type")

    # reconstruct array of DWT coefficients as returned by Wavelets.jl functions
    dwt_c = zeros(size(dwt_coefs, 2), size(dwt_coefs, 1))
    dwt_c[:, 1] = @view dwt_coefs[1, :]
    @inbounds @simd for idx in 2:size(dwt_coefs, 1)
        dwt_c[:, idx] = @views dwt_coefs[(end - idx + 2), :]
    end

    if type === :sdwt
        return isdwt(dwt_c, wt)
    elseif type === :acdwt
        return iacdwt(dwt_c, wt)
    end
end

"""
    s_normalize_invroot(signal)

Normalize in inverse root (1/sqrt(x)).

# Arguments

- `signal::AbstractArray`

# Returns

- `s_normalized::Vector{Float64}`
"""
function s_normalize_invroot(signal::AbstractArray)
    # make signal > 0
    return 1 ./ (sqrt.(signal .+ abs(minimum(signal)) .+ eps()))
end

"""
    s_cwt(signal; wt, type, l)

Perform continuous wavelet transformation (CWT).

# Arguments

- `signal::AbstractVector`
- `wt<:CWT`: continuous wavelet, e.g. `wt = wavelet(Morlet(π), β=2)`, see ContinuousWavelets.jl documentation for the list of available wavelets

# Returns

- `cwt_c::Array{Float64, 2}`: CWT coefficients (by rows)
"""
function s_cwt(signal::AbstractVector; wt::T) where {T <: CWT}
    cwt_coefs = abs.(ContinuousWavelets.cwt(signal, wt))
    cwt_c = zeros(size(cwt_coefs, 2), size(cwt_coefs, 1))
    for idx in 1:size(cwt_coefs, 2)
        cwt_c[idx, :] = @views cwt_coefs[:, idx]
    end
    return cwt_c
end

"""
    s_icwt(dwt_coefs; wt, type)

Perform inverse continuous wavelet transformation (iCWT) of the `dwt_coefs`.

# Arguments

- `cwt_coefs::AbstractArray`: CWT coefficients (by rows)
- `wt<:CWT`: continuous wavelet, e.g. `wt = wavelet(Morlet(π), β=2)`, see ContinuousWavelets.jl documentation for the list of available wavelets
- `type::Symbol=df`: inverse style type:
    - `:nd`: NaiveDelta
    - `:pd`: PenroseDelta
    - `:df`: DualFrames

# Returns

- `signal::Vector{Float64}`: reconstructed signal
"""
function s_icwt(cwt_coefs::AbstractArray; wt::T, type::Symbol) where {T <: CWT}

    _check_var(type, [:nd, :pd, :df], "type")

    # reconstruct array of CWT coefficients as returned by ContinuousWavelets.jl functions
    cwt_c = zeros(size(cwt_coefs, 2), size(cwt_coefs, 1))
    for idx in 1:size(cwt_coefs, 2)
        cwt_c[idx, :] = @views cwt_coefs[:, idx]
    end
    type === :nd && return ContinuousWavelets.icwt(cwt_c, wt, NaiveDelta())
    type === :pd && return ContinuousWavelets.icwt(cwt_c, wt, PenroseDelta())
    type === :df && return ContinuousWavelets.icwt(cwt_c, wt, DualFrames())
end

"""
    t2s(t, fs)

Convert time to sample number.

# Arguments

- `t::Real`: time in s
- `fs::Int64`: sampling rate

# Returns

- `s::Int64`: sample number
"""
function t2s(t::Real, fs::Int64)
    t < 0 && throw(ArgumentError("t must be ≥ 0."))
    if t == 0
        return 1
    else
        return round(Int64, t * fs)
    end
end

"""
    s2t(s, fs)

Convert sample number to time.

# Arguments

- `t::Int64`: sample number
- `fs::Int64`: sampling rate

# Returns

- `t::Float64`: time in s
"""
function s2t(s::Int64, fs::Int64)
    s < 0 && throw(ArgumentError("s must be > 0."))
    return s / fs
end

"""
    generate_noise(n, amp; type)

Generate noise.

# Arguments

- `n::Int64`: length (in samples)
- `amp::Real=1.0`: amplitude, signal will be [-amp..+amp]
- `type::Symbol=:whiten`: noise type: `:whiten` (normal distributed), `:whiteu` (uniformly distributed), `:pink`

# Returns

- `noise::Float64`
"""
function generate_noise(n::Int64, amp::Real=1.0; type::Symbol=:whiten)
    _check_var(type, [:whiten, :whiteu, :pink], "type")
    if type === :whiten
        noise = randn(n)
    elseif type === :whiteu
        noise = rand(n)
    elseif type === :pink
        noise = real(ifft(fft(randn(n)) .* linspace(-1, 1, length(fft(randn(n)))).^2)) .* 2
    end
    noise = s_normalize_minmax(noise)
    noise .*= amp
    return noise
end
