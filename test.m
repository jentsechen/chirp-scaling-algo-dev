% clear;
sig_par = SigPar('wavelength_m', 0.4, 'pulse_width_sec', 10e-6, 'pulse_rep_freq_hz', 1e3, ...
                 'bandwidth_hz', 50e6, 'sampling_freq_hz', 64e6);
imaging_par = ImagingPar('sig_par', sig_par, 'closest_slant_range_m', 4e3);
% point_target_echo_signal = imaging_par.point_target_echo_signal;
% imaging_par.plot_point_target_echo_signal(point_target_echo_signal, TimeUnitMode.Sample)
% save('point_target_echo_signal.mat', 'point_target_echo_signal');
% point_target_echo_signal = load('point_target_echo_signal.mat').point_target_echo_signal;
% point_target_echo_signal = load('point_target_echo_signal_long.mat').point_target_echo_signal;
% imaging_par.plot_point_target_echo_signal(point_target_echo_signal, AxisMode.TimeSample, AxisMode.TimeSample);

chirp_scaling_algo = ChirpScalingAlgo("imaging_par", imaging_par);
azimuth_fft_out = chirp_scaling_algo.apply_azimuth_fft(point_target_echo_signal);
chirp_scaling_out = chirp_scaling_algo.apply_chirp_scaling(azimuth_fft_out);
range_fft_out = chirp_scaling_algo.apply_range_fft(chirp_scaling_out);
sec_phase_func_out = chirp_scaling_algo.apply_sec_phase_func(range_fft_out);
range_ifft_out = chirp_scaling_algo.apply_range_ifft(sec_phase_func_out);
third_phase_func_out = chirp_scaling_algo.apply_third_phase_func(range_ifft_out);
azimuth_ifft_out = chirp_scaling_algo.apply_azimuth_ifft(third_phase_func_out);

imaging_par.plot_point_target_echo_signal(azimuth_fft_out, AxisMode.TimeSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(chirp_scaling_out, AxisMode.TimeSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(range_fft_out, AxisMode.FreqSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(sec_phase_func_out, AxisMode.FreqSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(range_ifft_out, AxisMode.TimeSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(third_phase_func_out, AxisMode.TimeSample, AxisMode.FreqSample);
imaging_par.plot_point_target_echo_signal(azimuth_ifft_out, AxisMode.TimeSample, AxisMode.TimeSample);

figure;
imagesc(10*log10(azimuth_ifft_out .* conj(azimuth_ifft_out)));
xlabel("range (sample)"); ylabel("azimuth (sample)");
title("magnitude (dB)"); colorbar; axis xy;

% mc_imaging_par = metaclass(imaging_par);
% for i = 1:length(mc_imaging_par.Properties)
%     disp(mc_imaging_par.Properties{i}.Name);
% end
% for i = 1:length(mc_imaging_par.Methods)
%     disp(mc_imaging_par.Methods{i}.Name);
% end

% load('point_target_echo_signal.mat');
% imaging_par.plot_point_target_echo_signal(point_target_echo_signal, TimeUnitMode.Sample);
% imaging_par.plot_point_target_echo_signal(point_target_echo_signal, TimeUnitMode.Second);

