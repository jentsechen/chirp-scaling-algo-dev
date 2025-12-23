function gen_golden_for_cpp_imp(mode, golden_folder_path)
    arguments
        mode GoldenGenMode = GoldenGenMode.ImgPar
        golden_folder_path string = "../csa-sar-imaging/TestChirpScalingAlgo/golden/"
    end

    sig_par = SigPar('wavelength_m', 0.4, 'pulse_width_sec', 10e-6, 'pulse_rep_freq_hz', 1e3, ...
                    'bandwidth_hz', 50e6, 'sampling_freq_hz', 64e6);
    imaging_par = ImagingPar('sig_par', sig_par, 'closest_slant_range_m', 4e3);
    chirp_scaling_algo = ChirpScalingAlgo("imaging_par", imaging_par);

    if mode == GoldenGenMode.ImgPar
        writematrix(imaging_par.range_time_axis_sec, 'range_time_axis_sec.csv');
        writematrix(imaging_par.range_freq_axis_hz, 'range_freq_axis_hz.csv');
        writematrix(imaging_par.azimuth_time_axis_sec, 'azimuth_time_axis_sec.csv');
        writematrix(imaging_par.azimuth_freq_axis_hz, 'azimuth_freq_axis_hz.csv');
    end
    
    if mode == GoldenGenMode.CsaPar
        migr_par = chirp_scaling_algo.migr_par;
        save(golden_folder_path + "migr_par.mat", "migr_par");
        modified_range_fm_rate_hz_s = chirp_scaling_algo.modified_range_fm_rate_hz_s;
        save(golden_folder_path + "modified_range_fm_rate_hz_s.mat", "modified_range_fm_rate_hz_s");
        chirp_scaling = chirp_scaling_algo.chirp_scaling;
        save(golden_folder_path + "chirp_scaling.mat", "chirp_scaling");
        range_comp_filt = chirp_scaling_algo.range_comp_filt;
        save(golden_folder_path + "range_comp_filt.mat", "range_comp_filt");
        azimuth_comp_filt = chirp_scaling_algo.azimuth_comp_filt;
        save(golden_folder_path + "azimuth_comp_filt.mat", "azimuth_comp_filt");
        second_comp_filt = chirp_scaling_algo.second_comp_filt;
        save(golden_folder_path + "second_comp_filt.mat", "second_comp_filt");
        third_comp_filt = chirp_scaling_algo.third_comp_filt;
        save(golden_folder_path + "third_comp_filt.mat", "third_comp_filt");
    end

    if mode == GoldenGenMode.CsaApp
        point_target_echo_signal = imaging_par.point_target_echo_signal();
        azimuth_fft_out = chirp_scaling_algo.apply_azimuth_fft(point_target_echo_signal);
        chirp_scaling_out = chirp_scaling_algo.apply_chirp_scaling(azimuth_fft_out);
        range_fft_out = chirp_scaling_algo.apply_range_fft(chirp_scaling_out);
        second_phase_func_out = chirp_scaling_algo.apply_second_phase_func(range_fft_out);
        range_ifft_out = chirp_scaling_algo.apply_range_ifft(second_phase_func_out);
        third_phase_func_out = chirp_scaling_algo.apply_third_phase_func(range_ifft_out);
        csa_out = chirp_scaling_algo.apply_azimuth_ifft(third_phase_func_out);
        save(golden_folder_path + "azimuth_fft_out.mat", "azimuth_fft_out");
        save(golden_folder_path + "chirp_scaling_out.mat", "chirp_scaling_out");
        save(golden_folder_path + "range_fft_out.mat", "range_fft_out");
        save(golden_folder_path + "second_phase_func_out.mat", "second_phase_func_out");
        save(golden_folder_path + "range_ifft_out.mat", "range_ifft_out");
        save(golden_folder_path + "third_phase_func_out.mat", "third_phase_func_out");
        save(golden_folder_path + "csa_out.mat", "csa_out");
    end

    disp("DONE")
end