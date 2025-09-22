
s = size(azimuth_ifft_out);
perf_metric_anal = PerfMetricAnalysis('data_anal', azimuth_ifft_out, ...
                    'azi_peak_loc', s(1)/2+1, 'rng_peak_loc', s(2)/2+1, 'sig_par', sig_par);
% perf_metric_anal.plot_data_to_be_anal();

rng_interp_out = perf_metric_anal.rng_interp();
% perf_metric_anal.plot_interp_out(rng_interp_out)
disp('range direction:');
perf_metric_anal.calc_pslr(rng_interp_out);
perf_metric_anal.calc_irw(rng_interp_out);

azi_interp_out = perf_metric_anal.azi_interp();
% perf_metric_anal.plot_interp_out(azi_interp_out)
disp('azimuth direction:');
perf_metric_anal.calc_pslr(azi_interp_out);
perf_metric_anal.calc_irw(azi_interp_out);

