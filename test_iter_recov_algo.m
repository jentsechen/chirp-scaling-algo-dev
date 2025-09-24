% load("point_target_echo_signal.mat");
sig_par = SigPar('wavelength_m', 0.4, 'pulse_width_sec', 10e-6, 'pulse_rep_freq_hz', 1e3, ...
                 'bandwidth_hz', 50e6, 'sampling_freq_hz', 64e6);
imaging_par = ImagingPar('sig_par', sig_par, 'closest_slant_range_m', 4e3);
chirp_scaling_algo = ChirpScalingAlgo("imaging_par", imaging_par);

% iteration 1
disp("iteration 1:")
s = size(point_target_echo_signal);
H_0 = zeros(s(1), s(2));
DH_0 = chirp_scaling_algo.apply_csa(point_target_echo_signal - ...
            chirp_scaling_algo.apply_inv_csa(H_0));
% H_1 = H_0 + DH_0;
disp("start thresholding")
H_1 = thresholding(H_0 + DH_0);

perf_metric_anal = PerfMetricAnalysis('data_anal', H_1, ...
                    'azi_peak_loc', s(1)/2+1, 'rng_peak_loc', s(2)/2+1, 'imaging_par', imaging_par);

rng_interp_out = perf_metric_anal.rng_interp();
% perf_metric_anal.plot_interp_out(rng_interp_out);
disp('range direction:');
perf_metric_anal.calc_pslr(rng_interp_out);
perf_metric_anal.calc_irw(rng_interp_out, true);

azi_interp_out = perf_metric_anal.azi_interp();
% perf_metric_anal.plot_interp_out(azi_interp_out);
disp('azimuth direction:');
perf_metric_anal.calc_pslr(azi_interp_out);
perf_metric_anal.calc_irw(azi_interp_out, false);

disp("")
disp("iteration 2:")
DH_1 = chirp_scaling_algo.apply_csa(point_target_echo_signal - ...
            chirp_scaling_algo.apply_inv_csa(H_1));
% H_2 = (H_1 + DH_1);
disp("start thresholding")
H_2 = thresholding(H_1 + DH_1);

perf_metric_anal = PerfMetricAnalysis('data_anal', H_2, ...
                    'azi_peak_loc', s(1)/2+1, 'rng_peak_loc', s(2)/2+1, 'imaging_par', imaging_par);

rng_interp_out = perf_metric_anal.rng_interp();
% perf_metric_anal.plot_interp_out(rng_interp_out);
disp('range direction:');
perf_metric_anal.calc_pslr(rng_interp_out);
perf_metric_anal.calc_irw(rng_interp_out, true);

azi_interp_out = perf_metric_anal.azi_interp();
disp('azimuth direction:');
perf_metric_anal.calc_pslr(azi_interp_out);
perf_metric_anal.calc_irw(azi_interp_out, false);

function output = thresholding(input)
    T = 10^2;
    real_part = (abs(real(input)) > T) .* sign(real(input)) .* (abs(real(input)) - T);
    imag_part = (abs(imag(input)) > T) .* sign(imag(input)) .* (abs(imag(input)) - T);
    output = real_part + 1i * imag_part;
end