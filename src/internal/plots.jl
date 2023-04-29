function _xlims(t::Union{Vector{<:Real}, AbstractRange})
    return floor(t[1], digits=2), ceil(t[end], digits=2)
end

function _ticks(t::Union{Vector{<:Real}, AbstractRange})
    if length(t) > 1 / (t[2] - t[1])
        return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 10):ceil(t[end], digits=2)
    else
        return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 20):ceil(t[end], digits=2)
    end
end

function _ticks(t::Tuple{Real, Real})
    if length(collect(t[1]:t[2])) > (1 / (collect(t[1]:t[2])[2] - collect(t[1]:t[2])[1]))
        return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 10):ceil(t[end], digits=2)
    else
        return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 20):ceil(t[end], digits=2)
    end

    return floor(t[1], digits=2):((ceil(t[2]) - floor(t[1])) / 10):ceil(t[2], digits=2)
end

_erpticks(t::Union{Vector{<:Real}, AbstractRange}) = vcat(collect(range(floor(t[1], digits=2), 0, 3)), collect(range(0, ceil(t[end], digits=2), 9))[2:end])

_erpticks(t::Tuple{Real, Real}) = vcat(collect(range(floor(t[1], digits=2), 0, 3)), collect(range(0, ceil(t[2], digits=2), 9))[2:end])

function _set_defaults(xl::String, yl::String, tt::String, x::String, y::String, t::String)
    yl == "default" && (yl = y)
    xl == "default" && (xl = x)
    tt == "default" && (tt = t)
    return xl, yl, tt
end
