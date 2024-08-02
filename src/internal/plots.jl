_xlims(t::Union{AbstractVector, AbstractRange}) = floor(t[1], digits=2), ceil(t[end], digits=2)
function _ylims(s::AbstractVector)
    if maximum(abs.(s)) > 100
        n = 2
    elseif maximum(abs.(s)) >= 0
        n = 1
    elseif maximum(abs.(s)) < 0
        n = 0
    end
    max = round(maximum(s) * 1.5, digits=-n)
    min = round(minimum(s) * 1.5, digits=-n)
    if abs(max) > abs(min)
        return (-abs(max), abs(max))
    else
        return (-abs(min), abs(min))
    end
end

function _ticks(t::Union{AbstractVector, AbstractRange})
    if length(t) >= 3
        if t[2] - t[1] == t[3] - t[2]
            tc = round.(linspace(t[1], t[end], 11))
        else
            tc = floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 10):ceil(t[end], digits=2)
        end
    end
    tc[end] = t[end]
    return tc
end

function _ticks(t::Tuple{Real, Real})
    if typeof(t[1]) <: Int && typeof(t[2]) <: Int
        if length(t[1]:t[2]) <= 30
            return collect(t[1]:t[2])
        elseif length(t[1]:t[2]) <= 100
            return collect(t[1]:5:t[2])
        elseif length(t[1]:t[2]) <= 1000
            return collect(t[1]:10:t[2])
        end
    else
        if length(collect(t[1]:t[2])) > (1 / (collect(t[1]:t[2])[2] - collect(t[1]:t[2])[1]))
            return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 10):ceil(t[end], digits=2)
        else
            return floor(t[1], digits=2):((ceil(t[end]) - floor(t[1])) / 20):ceil(t[end], digits=2)
        end
        return floor(t[1], digits=2):((ceil(t[2]) - floor(t[1])) / 10):ceil(t[2], digits=2)
    end
end

_erpticks(t::Union{AbstractVector, AbstractRange}) = vcat(collect(range(floor(t[1], digits=2), 0, 3)), collect(range(0, ceil(t[end], digits=2), 9))[2:end])

_erpticks(t::Tuple{Real, Real}) = vcat(collect(range(floor(t[1], digits=2), 0, 3)), collect(range(0, ceil(t[2], digits=2), 9))[2:end])

function _set_defaults(xl::String, yl::String, tt::String, x::String, y::String, t::String)
    yl == "default" && (yl = y)
    xl == "default" && (xl = x)
    tt == "default" && (tt = t)
    return xl, yl, tt
end
