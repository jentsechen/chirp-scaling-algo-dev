clear;
sig_par = SigPar('wavelength_m', 0.4, 'pulse_width_sec', 10e-6, 'pulse_rep_freq_hz', 1e3, ...
                 'bandwidth_hz', 50e6, 'sampling_freq_hz', 64e6);
imaging_par = ImagingPar('sig_par', sig_par, 'closest_slant_range_m', 4e3);
load('azimuth_ifft_out.mat')
s = size(azimuth_ifft_out);
perf_metric_anal = PerfMetricAnalysis('data_anal', azimuth_ifft_out, ...
                    'azi_peak_loc', s(1)/2+1, 'rng_peak_loc', s(2)/2+1, 'imaging_par', imaging_par);
% perf_metric_anal.plot_data_to_be_anal();

rng_interp_out = perf_metric_anal.rng_interp();
% perf_metric_anal.plot_interp_out(rng_interp_out)
disp('range direction:');
perf_metric_anal.calc_pslr(rng_interp_out);
perf_metric_anal.calc_irw(rng_interp_out, true);

azi_interp_out = perf_metric_anal.azi_interp();
% perf_metric_anal.plot_interp_out(azi_interp_out)
disp('azimuth direction:');
perf_metric_anal.calc_pslr(azi_interp_out);
perf_metric_anal.calc_irw(azi_interp_out, false);

