using Wavelets
using ContinuousWavelets

#=
using BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.samples = 1
b = @benchmarkable eeg_import_edf("test/eeg-test-edf.edf") evals=20
run(b)

=#

@info "Reporting system data"
println("# System info")
println()
if Sys.isunix() || Sys.isapple()
    print("OS: $(read(`uname -a`, String))")
elseif Sys.iswindows()
    print("OS: Windows $(Sys.windows_version())")
end
println("CPU: $(Sys.cpu_info()[1].model) $(length(Sys.cpu_info()) ÷ 2) cores ($(round(Sys.cpu_info()[1].speed / 1024, digits=2)) GHz)")
println("RAM: $(round((Int64(Sys.free_memory())) / 1024^3, digits=1)) GB free / $(round((Int64(Sys.total_memory())) / 1024^3, digits=1)) GB")
println()
@info "Loading NeuroAnalyzer.jl"
println("# Loading NeuroAnalyzer.jl")
println()
# @time_imports using NeuroAnalyzer
@time using NeuroAnalyzer
println()
println("# NeuroAnalyzer info")
println()
na_info()

@info "Benchmarking: eeg_io.jl"
println()
println("# IO")
println()

print(rpad("Import EDF", 36))
eeg = eeg_import_edf("test/eeg-test-edf.edf");
@time eeg_import_edf("test/eeg-test-edf.edf");
print(rpad("Import EDF+", 36))
eeg_import_edf("test/eeg-test-edfplus.edf");
@time eeg_import_edf("test/eeg-test-edfplus.edf");
print(rpad("Import BDF+", 36))
eeg_import_bdf("test/eeg-test-bdf.bdf");
@time eeg_import_bdf("test/eeg-test-bdf.bdf");
print(rpad("Import Digitrack", 36))
eeg_import_digitrack("test/eeg-test-digitrack.txt");
@time eeg_import_digitrack("test/eeg-test-digitrack.txt");
print(rpad("Import BrainVision", 36))
eeg_import_bv("test/eeg-test-bv.vhdr")
@time eeg_import_bv("test/eeg-test-bv.vhdr")
print(rpad("Save HDF5", 36))
tmp = tempname()
eeg_save(eeg, file_name=tmp);
tmp = tempname()
@time eeg_save(eeg, file_name=tmp);
print(rpad("Load HDF5", 36))
eeg_load(tmp);
@time eeg_load(tmp);

eeg = eeg_import_edf("test/eeg-test-edf.edf");
eeg_delete_channel!(eeg, channel=20:24)
e10 = eeg_epoch(eeg, epoch_len=2560)
eeg_load_electrodes!(e10, file_name="locs/standard-10-20-cap19-elmiko.ced")

@info "Benchmarking: eeg_edit.jl"
println()
println("# EDIT")
println()

e10_tmp = deepcopy(e10)
print(rpad("Delete channel", 36))
eeg_delete_channel(e10_tmp, channel=1);
@time eeg_delete_channel(e10_tmp, channel=1);
e10_tmp = deepcopy(e10)
print(rpad("Keep channel", 36))
eeg_keep_channel(e10_tmp, channel=1);
@time eeg_keep_channel(e10_tmp, channel=1);
e10_tmp = deepcopy(e10)
print(rpad("Delete epoch", 36))
eeg_delete_epoch(e10_tmp, epoch=1);
@time eeg_delete_epoch(e10_tmp, epoch=1);
e10_tmp = deepcopy(e10)
print(rpad("Keep epoch", 36))
eeg_keep_epoch(e10_tmp, epoch=1);
@time eeg_keep_epoch(e10_tmp, epoch=1);
print(rpad("Virtual channel", 36))
eeg_vch(e10, f="fp1 + fp2");
@time eeg_vch(e10, f="fp1 + fp2");

@info "Benchmarking: eeg_process.jl"
println()
println("# PROCESS")
println()

print(rpad("A referencing", 36))
edf_am = eeg_import_edf("test/eeg-test-edf.edf")
eeg_delete_channel!(edf_am, channel=[22, 23, 24])
e10_am = eeg_epoch(edf_am, epoch_len=2560)
eeg_reference_a(e10_am)
@time eeg_reference_a(e10_am);
print(rpad("M referencing", 36))
eeg_edit_channel!(e10_am, channel=17, field=:labels, value="M1")
eeg_edit_channel!(e10_am, channel=18, field=:labels, value="M2")
eeg_reference_m(e10_am)
@time eeg_reference_m(e10_am);
print(rpad("CAR referencing", 36))
eeg_reference_car(e10);
@time eeg_reference_car(e10);
print(rpad("Channel referencing", 36))
eeg_reference_ch(e10, channel=1);
@time eeg_reference_ch(e10, channel=1);
print(rpad("Filter: LP", 36))
eeg_filter(e10, fprototype=:butterworth, ftype=:lp, cutoff=45.0, order=8);
@time eeg_filter(e10, fprototype=:butterworth, ftype=:lp, cutoff=45.0, order=8);
print(rpad("Filter: HP", 36))
eeg_filter(e10, fprototype=:butterworth, ftype=:hp, cutoff=0.1, order=8);
@time eeg_filter(e10, fprototype=:butterworth, ftype=:hp, cutoff=0.1, order=8);
print(rpad("Filter: IIR notch", 36))
eeg_filter(e10, fprototype=:iirnotch, cutoff=50, bw=2);
@time eeg_filter(e10, fprototype=:iirnotch, cutoff=50, bw=2);
print(rpad("Filter: Remez", 36))
eeg_filter(e10, fprototype=:remez, ftype=:lp, order=128, cutoff=20, bw=0.5);
@time eeg_filter(e10, fprototype=:remez, ftype=:lp, order=128, cutoff=20, bw=0.5);
print(rpad("Filter: FIR", 36))
eeg_filter(e10, fprototype=:fir, ftype=:hp, cutoff=0.1, order=8, window=generate_window(:hann, 128));
@time eeg_filter(e10, fprototype=:fir, ftype=:hp, cutoff=0.1, order=8, window=generate_window(:hann, 128));
print(rpad("Filter: polynomial (8)", 36))
eeg_filter(e10, fprototype=:poly, order=8);
@time eeg_filter(e10, fprototype=:poly, order=8);
print(rpad("Filter: moving average", 36))
eeg_filter(e10, fprototype=:mavg);
@time eeg_filter(e10, fprototype=:mavg);
print(rpad("Interpolate: PL", 36))
eeg_plinterpolate_channel(e10, channel=1, epoch=1);
@time eeg_plinterpolate_channel(e10, channel=1, epoch=1);
print(rpad("Interpolate: LR", 36))
eeg_lrinterpolate_channel(e10, channel=1, epoch=1);
@time eeg_lrinterpolate_channel(e10, channel=1, epoch=1);
print(rpad("Surface Laplacian", 36))
eeg_slaplacian(e10);
@time eeg_slaplacian(e10);

@info "Benchmarking: eeg_analyze.jl"
println()
println("# ANALYZE")
println()

print(rpad("Total power", 36))
eeg_total_power(e10);
@time eeg_total_power(e10);
print(rpad("Total power: mt", 36))
eeg_total_power(e10, mt=true);
@time eeg_total_power(e10, mt=true);
print(rpad("Band power", 36))
eeg_band_power(e10, f=(10, 20));
@time eeg_band_power(e10, f=(10, 20));
print(rpad("Band power: mt", 36))
eeg_band_power(e10, f=(10, 20), mt=true);
@time eeg_band_power(e10, f=(10, 20), mt=true);
print(rpad("Covariance matrix", 36))
eeg_cov(e10);
@time eeg_cov(e10);
print(rpad("Correlation matrix", 36))
eeg_cor(e10);
@time eeg_cor(e10);
print(rpad("Auto-covariance", 36))
eeg_acov(e10);
@time eeg_acov(e10);
print(rpad("Cross-covariance 1", 36))
eeg_xcov(e10, lag=10, demean=true);
@time eeg_xcov(e10, lag=10, demean=true);
print(rpad("Cross-covariance 2", 36))
eeg_xcov(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=2, lag=10, demean=true);
@time eeg_xcov(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=2, lag=10, demean=true);
print(rpad("PSD", 36))
eeg_psd(e10);
@time eeg_psd(e10);
print(rpad("PSD: mt", 36))
eeg_psd(e10, mt=true);
@time eeg_psd(e10, mt=true);
print(rpad("PSD: mw ", 36))
eeg_mwpsd(e10);
@time eeg_mwpsd(e10);
print(rpad("Stationarity: mean", 36))
eeg_stationarity(e10, method=:mean);
@time eeg_stationarity(e10, method=:mean);
print(rpad("Stationarity: var", 36))
eeg_stationarity(e10, method=:var);
@time eeg_stationarity(e10, method=:var);
print(rpad("Stationarity: cov", 36))
eeg_stationarity(e10, method=:cov);
@time eeg_stationarity(e10, method=:cov);
print(rpad("Stationarity: hilbert", 36))
eeg_stationarity(e10, method=:hilbert);
@time eeg_stationarity(e10, method=:hilbert);
print(rpad("Stationarity: adf", 36))
eeg_stationarity(e10, method=:adf);
@time eeg_stationarity(e10, method=:adf);
print(rpad("Mutual information 1", 36))
eeg_mi(e10);
@time eeg_mi(e10);
print(rpad("Mutual information 2", 36))
eeg_mi(e10, e10);
@time eeg_mi(e10, e10);
# print(rpad("Entropy", 36))
# eeg_entropy(e10);
# @time eeg_entropy(e10);
# print(rpad("Negentropy", 36))
# eeg_negentropy(e10);
# @time eeg_negentropy(e10);
print(rpad("Time coherence", 36))
eeg_tcoherence(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=2);
@time eeg_tcoherence(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=2);
print(rpad("Signal difference: absdiff", 36))
eeg_difference(e10, e10; method=:absdiff);
@time eeg_difference(e10, e10; method=:absdiff);
print(rpad("Signal difference: diff2int", 36))
eeg_difference(e10, e10; method=:diff2int);
@time eeg_difference(e10, e10; method=:diff2int);
print(rpad("Epoch stats", 36))
eeg_epoch_stats(e10);
@time eeg_epoch_stats(e10);
print(rpad("Spectrogram: standard", 36))
eeg_spectrogram(e10);
@time eeg_spectrogram(e10);
print(rpad("Spectrogram: mt", 36))
eeg_spectrogram(e10, method=:mt);
@time eeg_spectrogram(e10, method=:mt);
print(rpad("Spectrogram: stft", 36))
eeg_spectrogram(e10, method=:stft);
@time eeg_spectrogram(e10, method=:stft);
print(rpad("Spectrogram: mw", 36))
eeg_spectrogram(e10, method=:mw);
@time eeg_spectrogram(e10, method=:mw);
print(rpad("Spectrogram: cwt", 36))
eeg_spectrogram(e10, method=:cwt);
@time eeg_spectrogram(e10, method=:cwt);
print(rpad("Spectrum: FFT", 36))
eeg_spectrum(e10);
@time eeg_spectrum(e10);
print(rpad("Spectrum: Hilbert", 36))
eeg_spectrum(e10, h=true);
@time eeg_spectrum(e10, h=true);
print(rpad("Channel stats", 36))
eeg_channel_stats(e10);
@time eeg_channel_stats(e10);
print(rpad("SNR", 36))
eeg_snr(e10);
@time eeg_snr(e10);
print(rpad("Standardize", 36))
eeg_standardize(e10);
@time eeg_standardize(e10);
print(rpad("Frequency convolution", 36))
eeg_fconv(e10, kernel=generate_morlet(256, 1, 32, complex=true));
@time eeg_fconv(e10, kernel=generate_morlet(256, 1, 32, complex=true));
print(rpad("Time convolution", 36))
eeg_tconv(e10, kernel=generate_morlet(256, 1, 32, complex=true));
@time eeg_tconv(e10, kernel=generate_morlet(256, 1, 32, complex=true));
print(rpad("DFT", 36))
eeg_dft(e10);
@time eeg_dft(e10);
print(rpad("MSCI95: normal", 36))
eeg_msci95(e10);
@time eeg_msci95(e10);
print(rpad("MSCI95:boot", 36))
eeg_msci95(e10, method=:boot);
@time eeg_msci95(e10);
print(rpad("Mean", 36))
eeg_mean(e10, e10);
@time eeg_mean(e10, e10);
print(rpad("Subtract channels", 36))
eeg_chdiff(e10, e10); 
@time eeg_chdiff(e10, e10); 
print(rpad("Temporal envelope", 36))
eeg_tenv(e10);
@time eeg_tenv(e10);
print(rpad("Temporal envelope: mean", 36))
eeg_tenv_mean(e10, dims=1);
@time eeg_tenv_mean(e10, dims=1);
print(rpad("Temporal envelope: median", 36))
eeg_tenv_median(e10, dims=1);
@time eeg_tenv_median(e10, dims=1);
print(rpad("Power envelope", 36))
eeg_penv(e10);
@time eeg_penv(e10);
print(rpad("Power envelope: mean", 36))
eeg_penv_mean(e10, dims=1);
@time eeg_penv_mean(e10, dims=1);
print(rpad("Power envelope: median", 36))
eeg_penv_median(e10, dims=1);
@time eeg_penv_median(e10, dims=1);
print(rpad("Spectral envelope", 36))
eeg_senv(e10);
@time eeg_senv(e10);
print(rpad("Spectral envelope: mean", 36))
eeg_senv_mean(e10, dims=1);
@time eeg_senv_mean(e10, dims=1);
print(rpad("Spectral envelope: median", 36))
eeg_senv_median(e10, dims=1);
@time eeg_senv_median(e10, dims=1);
print(rpad("Hilbert amplitude envelope", 36))
eeg_henv(e10);
@time eeg_henv(e10);
print(rpad("Hilbert amplitude envelope: mean", 36))
eeg_henv_mean(e10, dims=1);
@time eeg_henv_mean(e10, dims=1);
print(rpad("Hilbert amplitude envelope: median", 36))
eeg_henv_median(e10, dims=1);
@time eeg_henv_median(e10, dims=1);
print(rpad("ISPC 1", 36))
eeg_ispc(e10);
@time eeg_ispc(e10);
print(rpad("ISPC 2", 36))
eeg_ispc(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
@time eeg_ispc(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
print(rpad("ITPC", 36))
eeg_itpc(e10, channel=1, t=256);
@time eeg_itpc(e10, channel=1, t=256);
print(rpad("ITPC spectrogram", 36))
eeg_itpc_s(e10, channel=1, frq_lim=(10, 20), frq_n=11);
@time eeg_itpc_s(e10, channel=1, frq_lim=(10, 20), frq_n=11);
print(rpad("PLI 1", 36))
eeg_pli(e10);
@time eeg_pli(e10);
print(rpad("PLI 2", 36))
eeg_pli(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
@time eeg_pli(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
print(rpad("AEC", 36))
eeg_aec(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
@time eeg_aec(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
print(rpad("GED", 36))
eeg_ged(e10, e10);
@time eeg_ged(e10, e10);
print(rpad("Instant frequency", 36))
eeg_frqinst(e10);
@time eeg_frqinst(e10);
print(rpad("TKEO", 36))
eeg_tkeo(e10);
@time eeg_tkeo(e10);
print(rpad("Frequency coherence", 36))
eeg_fcoherence(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
@time eeg_fcoherence(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
print(rpad("F-test 1", 36))
eeg_vartest(e10);
@time eeg_vartest(e10);
print(rpad("F-test 2", 36))
eeg_vartest(e10, e10);
@time eeg_vartest(e10, e10);
print(rpad("Band power", 36))
eeg_band_mpower(e10; f=(10, 20));
@time eeg_band_mpower(e10; f=(10, 20));
print(rpad("Relative PSD", 36))
eeg_rel_psd(e10; f=(10, 20));
@time eeg_rel_psd(e10; f=(10, 20));
print(rpad("Frequency band split", 36))
eeg_fbsplit(e10);
@time eeg_fbsplit(e10);
print(rpad("Channel difference", 36))
eeg_chdiff(e10, e10, channel1=1, channel2=2);
@time eeg_chdiff(e10, e10, channel1=1, channel2=2);
print(rpad("Cross power spectrum 1", 36))
eeg_cps(e10);
@time eeg_cps(e10);
print(rpad("Cross power spectrum 2", 36))
eeg_cps(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
@time eeg_cps(e10, e10, channel1=1, channel2=2, epoch1=1, epoch2=1);
print(rpad("Amplitude difference", 36))
eeg_ampdiff(e10);
@time eeg_ampdiff(e10);
print(rpad("DWT", 36))
eeg_dwt(e10, wt=wavelet(WT.haar), type=:sdwt);
@time eeg_dwt(e10, wt=wavelet(WT.haar), type=:sdwt);
print(rpad("CWT", 36))
eeg_cwt(e10, wt=wavelet(Morlet(π), β=2));
@time eeg_cwt(e10, wt=wavelet(Morlet(π), β=2));
print(rpad("PSD slope", 36))
eeg_psdslope(e10);
@time eeg_psdslope(e10);
print(rpad("eeg_apply()", 36))
eeg_apply(e10, f="mean(eeg, dims=1)", channel=1:4);
@time eeg_apply(e10, f="mean(eeg, dims=1)", channel=1:4);
print(rpad("Normalize", 36))
eeg_normalize(e10, method=:zscore);
@time eeg_normalize(e10, method=:zscore);
print(rpad("Demean", 36))
eeg_demean(e10);
@time eeg_demean(e10);
print(rpad("Taper", 36))
eeg_taper(e10, taper=generate_window(:hann, eeg_epoch_len(e10)));
@time eeg_taper(e10, taper=generate_window(:hann, eeg_epoch_len(e10)));
print(rpad("Derivative", 36))
eeg_derivative(e10);
@time eeg_derivative(e10);
print(rpad("Detrend", 36))
eeg_detrend(e10, type=:constant);
@time eeg_detrend(e10, type=:constant);
print(rpad("Wiener denoising", 36))
eeg_denoise_wien(e10);
@time eeg_denoise_wien(e10);
print(rpad("Generate PCA", 36))
eeg_pca(e10, n=4);
@time eeg_pca(e10, n=4);
print(rpad("Generate ICA", 36))
eeg_ica(e10, n=15, tol=1.0);
@time eeg_ica(e10, n=15, tol=1.0);
i, i_mw = eeg_ica(e10, n=15, tol=1.0)
e10_ica = eeg_add_component(e10, c=:ica, v=i);
eeg_add_component!(e10_ica, c=:ica_mw, v=i_mw);
print(rpad("Remove ICA", 36))
eeg_ica_reconstruct(e10_ica, ic=1);
@time eeg_ica_reconstruct(e10_ica, ic=1);
print(rpad("Split using DWT", 36))
eeg_bands_dwt(e10, channel=1, wt=wavelet(WT.db2), type=:sdwt, n=5);
@time eeg_bands_dwt(e10, channel=1, wt=wavelet(WT.db2), type=:sdwt, n=5);