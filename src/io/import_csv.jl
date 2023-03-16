export import_csv

"""
    import_csv(file_name; detect_type)

Load CSV file (e.g. exported from EEGLAB) and return `NeuroAnalyzer.NEURO` object.

# Arguments

- `file_name::String`: name of the file to load
- `detect_type::Bool=true`: detect channel type based on its label

# Returns

- `::NeuroAnalyzer.NEURO`

# Notes

CSV first row or first column must contain channel names.
Shape of data array will be detected automatically. Sampling rate will be detected.
If file is gzip-ed, it will be uncompressed automatically while reading.
"""
function import_csv(file_name::String; detect_type::Bool=true)

    isfile(file_name) || throw(ArgumentError("File $file_name cannot be loaded."))

    file_type = "CSV"

    df = CSV.read(file_name, DataFrame)

    if typeof(df[:, 1]) == Vector{Float64}
        # time by channels
        time_pts = df[:, 1]
        data = Array(df[:, 2:end])'
        ch_n = ncol(df) - 1
        clabels = String.(names(df)[2:end])
    else
        # channels by time
        time_pts = parse.(Float64, names(df)[2:end])
        data = Array(df[:, 2:end])
        ch_n = nrow(df)
        clabels = String.(df[:, 1])
    end
    data = reshape(data, size(data, 1), size(data, 2), 1)

    clabels = _clean_labels(clabels)
    if detect_type == true
        channel_type = _set_channel_types(clabels)
    else
        channel_type = repeat(["???"], ch_n)
    end
    channel_order = _sort_channels(copy(channel_type))

    markers = DataFrame(:id=>String[], :start=>Int64[], :length=>Int64[], :description=>String[], :channel=>Int64[])
    sampling_rate = round(Int64, 1 / time_pts[2] * 1000)
    gain = ones(ch_n)
    markers = DataFrame(:id=>String[], :start=>Int64[], :length=>Int64[], :description=>String[], :channel=>Int64[])

    time_pts = collect(0:(1 / sampling_rate):((size(data, 2) * size(data, 3)) / sampling_rate))
    time_pts = round.(linspace(time_pts[1], time_pts[end], size(data, 2) * size(data, 3)), digits=4)
    epoch_time = round.(linspace(time_pts[1], time_pts[end], size(data, 2)), digits=4)
    
    file_size_mb = round(filesize(file_name) / 1024^2, digits=2)

    data_type = "eeg"

    s = _create_subject(id="",
                        first_name="",
                        middle_name="",
                        last_name="",
                        handedness="",
                        weight=-1,
                        height=-1)

    r = _create_recording_eeg(data_type=data_type,
                              file_name=file_name,
                              file_size_mb=file_size_mb,
                              file_type=file_type,
                              recording="",
                              recording_date="",
                              recording_time="",
                              recording_notes="",
                              channel_type=channel_type,
                              reference="",
                              clabels=clabels,
                              transducers=repeat([""], ch_n),
                              units=repeat([""], ch_n),
                              prefiltering=repeat([""], ch_n),
                              sampling_rate=sampling_rate,
                              gain=gain)

    e = _create_experiment(experiment_name="",
                           experiment_notes="",
                           experiment_design="")

    hdr = _create_header(s,
                         r,
                         e)

    components = Dict()

    history = String[]

    locs = DataFrame(:channel=>Int64,
                     :labels=>String[],
                     :loc_theta=>Float64[],
                     :loc_radius=>Float64[],
                     :loc_x=>Float64[],
                     :loc_y=>Float64[],
                     :loc_z=>Float64[],
                     :loc_radius_sph=>Float64[],
                     :loc_theta_sph=>Float64[],
                     :loc_phi_sph=>Float64[])

    return NeuroAnalyzer.NEURO(hdr, time_pts, epoch_time, data[channel_order, :, :], components, markers, locs, history)
    
end
