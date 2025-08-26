clear;
sig_par = SigPar('wavelength_m', 0.4, 'pulse_width_sec', 10e-6, 'pulse_rep_freq_hz', 1e3, ...
                 'bandwidth_hz', 50e6, 'sampling_freq_hz', 64e6);
imaging_par = ImagingPar('sig_par', sig_par, 'closest_slant_range_m', 4e3);
% point_target_echo_signal = imaging_par.point_target_echo_signal;
% save('point_target_echo_signal.mat', 'point_target_echo_signal');

% mc_imaging_par = metaclass(imaging_par);
% for i = 1:length(mc_imaging_par.Properties)
%     disp(mc_imaging_par.Properties{i}.Name);
% end
% for i = 1:length(mc_imaging_par.Methods)
%     disp(mc_imaging_par.Methods{i}.Name);
% end

load('point_target_echo_signal.mat');
% imaging_par.plot_point_target_echo_signal(point_target_echo_signal, TimeUnitMode.Sample);
imaging_par.plot_point_target_echo_signal(point_target_echo_signal, TimeUnitMode.Second);

