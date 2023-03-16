function _clean_labels(clabels::Vector{String})
    clabels = replace.(clabels, "EEG " => "")
    clabels = replace.(clabels, "eeg " => "")
    clabels = replace.(clabels, "EOG EOG" => "EOG")
    clabels = replace.(clabels, "eog eog" => "EOG")
    clabels = replace.(clabels, "ECG EKG" => "ECG")
    clabels = replace.(clabels, "ecg ekg" => "ECG")
    clabels = replace.(clabels, "BDF " => "")
    clabels = replace.(clabels, "bdf " => "")
    return clabels
end

function _gen_clabels(obj::NeuroAnalyzer.NEURO, c::Symbol)
    c = _get_component(obj, c)
    clabels = Vector{String}()
    for idx in 1:size(c, 1)
        push!(clabels, lpad(string(idx), length(string(size(c, 1))), "0"))
    end
    return clabels
end

function _gen_clabels(c::Union{AbstractVector, AbstractArray})
    clabels = Vector{String}()
    if ndims(c) == 1
        push!(clabels, "1")
    else
        for idx in 1:size(c, 1)
            push!(clabels, lpad(string(idx), length(string(size(c, 1))), "0"))
        end
    end
    return clabels
end
