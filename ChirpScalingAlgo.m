classdef ChirpScalingAlgo
    properties
        imaging_par ImagingPar
        migr_par % D(f_\eta, V_r)
        modified_range_fm_rate_hz_s % K_m
        chirp_scaling
        range_comp_filt
        azimuth_comp_filt
        second_comp_filt
        third_comp_filt
    end
    methods
        function obj = ChirpScalingAlgo(varargin)
            if mod(nargin, 2) ~= 0
                error('SigPar:InvalidInput', 'Name-value pairs required.');
            end
            for i = 1:2:nargin
                name = varargin{i};
                value = varargin{i+1};
                if isprop(obj, name)
                    obj.(name) = value;
                else
                    error('SigPar:InvalidProperty', 'Unknown property "%s".', name);
                end
            end
            obj.migr_par = obj.gen_migr_par();
            obj.modified_range_fm_rate_hz_s = obj.modify_range_fm_rate_hz_s();
            obj.chirp_scaling = obj.gen_chirp_scaling();
            obj.range_comp_filt = obj.gen_range_comp_filt();
            obj.azimuth_comp_filt = obj.gen_azimuth_comp_filt();
            obj.second_comp_filt = obj.gen_second_comp_filt();
            obj.third_comp_filt = obj.gen_third_comp_filt();
        end
        function output = apply_azimuth_fft(~, input)
            output = fft(input, [], 1);
        end
        function azimuth_ifft_out = apply_azimuth_ifft(~, input)
            azimuth_ifft_out = ifft(input, [], 1);
        end
        function output = apply_range_fft(~, input)
            output = fft(input, [], 2);
        end
        function output = apply_range_ifft(~, input)
            output = ifft(input, [], 2);
        end
        function output = apply_chirp_scaling(obj, input)
            output = input .* obj.chirp_scaling;
        end
        function output = apply_chirp_scaling_conj(obj, input)
            output = input .* conj(obj.chirp_scaling);
        end
        function output = apply_second_phase_func(obj, input)
            output = input .* obj.range_comp_filt .* obj.second_comp_filt;
        end
        function output = apply_second_phase_func_conj(obj, input)
            output = input .* conj(obj.range_comp_filt) .* conj(obj.second_comp_filt);
        end
        function output = apply_third_phase_func(obj, input)
            output = input .* obj.azimuth_comp_filt;
        end
        function output = apply_third_phase_func_conj(obj, input)
            output = input .* conj(obj.azimuth_comp_filt);
        end
        function output = apply_csa(obj, input)
            azimuth_fft_out = obj.apply_azimuth_fft(input);
            chirp_scaling_out = obj.apply_chirp_scaling(azimuth_fft_out);
            range_fft_out = obj.apply_range_fft(chirp_scaling_out);
            second_phase_func_out = obj.apply_second_phase_func(range_fft_out);
            range_ifft_out = obj.apply_range_ifft(second_phase_func_out);
            third_phase_func_out = obj.apply_third_phase_func(range_ifft_out);
            output = obj.apply_azimuth_ifft(third_phase_func_out);
        end
        function output = apply_inv_csa(obj, input)
            azimuth_fft_out = obj.apply_azimuth_fft(input);
            third_phase_func_conj_out = obj.apply_third_phase_func_conj(azimuth_fft_out);
            range_fft_out = obj.apply_range_fft(third_phase_func_conj_out);
            second_phase_func_conj_out = obj.apply_second_phase_func_conj(range_fft_out);
            range_ifft_out = obj.apply_range_ifft(second_phase_func_conj_out);
            chirp_scaling_conj_out = obj.apply_chirp_scaling_conj(range_ifft_out);
            output = obj.apply_azimuth_ifft(chirp_scaling_conj_out);
        end
    end
    methods (Access = private)
        function migr_par = gen_migr_par(obj)
            num = obj.imaging_par.sig_par.light_speed_m_s * obj.imaging_par.azimuth_freq_axis_hz;
            den = 2 * obj.imaging_par.sensor_speed_m_s * obj.imaging_par.sig_par.carrier_freq_hz;
            migr_par = sqrt(1-(num/den).^2)';
        end
        function modified_range_fm_rate_hz_s = modify_range_fm_rate_hz_s(obj)
            num = (obj.imaging_par.sig_par.light_speed_m_s * ...
                  obj.imaging_par.closest_slant_range_m * ...
                  obj.imaging_par.azimuth_freq_axis_hz.^2)';
            den = 2 * obj.imaging_par.sensor_speed_m_s^2 ...
                  * obj.imaging_par.sig_par.carrier_freq_hz^3 ...
                  * obj.migr_par.^3;
            modified_range_fm_rate_hz_s = obj.imaging_par.sig_par.range_fm_rate_hz_s ./ ...
                (1 - obj.imaging_par.sig_par.range_fm_rate_hz_s * num ./ den);
        end
        function chirp_scaling = gen_chirp_scaling(obj)
            first_order_col_term = obj.modified_range_fm_rate_hz_s .* (1 ./ obj.migr_par - 1);
            second_order_row_term = obj.imaging_par.range_time_axis_sec;
            second_order_col_term = 2 * obj.imaging_par.closest_slant_range_m ./ ...
                   (obj.imaging_par.sig_par.light_speed_m_s * obj.migr_par);
            col_len = length(obj.imaging_par.azimuth_freq_axis_hz);
            row_len = length(obj.imaging_par.range_time_axis_sec);
            first_order_mat = repmat(first_order_col_term, 1, row_len);
            second_order_mat = (repmat(second_order_row_term, col_len, 1) - ...
                               repmat(second_order_col_term, 1, row_len)).^2 ;
            chirp_scaling = exp(1j * pi * first_order_mat .* second_order_mat);
            chirp_scaling = fftshift(chirp_scaling, 1);
        end
        function range_comp_filt = gen_range_comp_filt(obj)
            col_len = length(obj.imaging_par.azimuth_freq_axis_hz);
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            range_comp_exp_col_term = obj.migr_par ./ obj.modified_range_fm_rate_hz_s;
            range_comp_exp_row_term = obj.imaging_par.range_freq_axis_hz.^2;
            range_comp_exp_mat = repmat(range_comp_exp_col_term, 1, row_len) .* repmat(range_comp_exp_row_term, col_len, 1);
            range_comp = exp(1j * pi * range_comp_exp_mat);
            range_comp_filt = fftshift(range_comp);
        end
        function second_comp_filt = gen_second_comp_filt(obj)
            col_len = length(obj.imaging_par.azimuth_freq_axis_hz);
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            second_comp_exp_col_term = 1 ./ obj.migr_par - 1;
            second_comp_exp_row_term = obj.imaging_par.range_freq_axis_hz;
            second_comp_exp_mat = repmat(second_comp_exp_col_term, 1, row_len) .* ...
                                      repmat(second_comp_exp_row_term, col_len, 1);
            second_comp = exp(1j * 4 * pi * obj.imaging_par.closest_slant_range_m / ...
                            obj.imaging_par.sig_par.light_speed_m_s * second_comp_exp_mat);
            second_comp_filt = fftshift(second_comp);
        end
        function azimuth_comp_filt = gen_azimuth_comp_filt(obj)
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            azimuth_comp_phase_col_term = obj.imaging_par.closest_slant_range_m / ...
                                obj.imaging_par.sig_par.wavelength_m * obj.migr_par;
            azimuth_comp_exp = repmat(azimuth_comp_phase_col_term, 1, row_len);
            azimuth_comp = exp(1j * 4 * pi * azimuth_comp_exp);
            azimuth_comp_filt = fftshift(azimuth_comp, 1);
        end
        function third_comp_filt = gen_third_comp_filt(obj)
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            third_comp_phase_col_term = (obj.imaging_par.closest_slant_range_m / ...
                                        obj.imaging_par.sig_par.light_speed_m_s)^2 * ...
                                        obj.modified_range_fm_rate_hz_s ./ ...
                                        obj.migr_par .* (1 ./ obj.migr_par - 1);
            third_comp_exp = repmat(third_comp_phase_col_term, 1, row_len);
            third_comp = exp(-1j * 4 * pi * third_comp_exp);
            third_comp_filt = fftshift(third_comp, 1);
        end
    end
end