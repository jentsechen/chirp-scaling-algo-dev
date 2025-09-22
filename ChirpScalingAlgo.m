classdef ChirpScalingAlgo
    properties
        imaging_par ImagingPar
        migr_par % D(f_\eta, V_r)
        modified_range_fm_rate_hz_s % K_m
        chirp_scaling
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
        end
        function azimuth_fft_out = apply_azimuth_fft(~, raw_data)
            azimuth_fft_out = fft(raw_data, [], 1);
        end
        function azimuth_ifft_out = apply_azimuth_ifft(~, third_phase_func_out)
            azimuth_ifft_out = ifft(third_phase_func_out, [], 1);
        end
        function range_fft_out = apply_range_fft(~, chirp_scaling_out)
            range_fft_out = fft(chirp_scaling_out, [], 2);
        end
        function range_ifft_out = apply_range_ifft(~, sec_phase_func_out)
            range_ifft_out = ifft(sec_phase_func_out, [], 2);
        end
        function chirp_scaling_out = apply_chirp_scaling(obj, azimuth_fft_out)
            chirp_scaling_out = azimuth_fft_out .* obj.chirp_scaling;
        end
        function sec_phase_func_out = apply_sec_phase_func(obj, range_fft_out)
            sec_phase_func_out = range_fft_out .* obj.gen_second_phase_func();
        end
        function third_phase_func_out = apply_third_phase_func(obj, range_fft_out)
            third_phase_func_out = range_fft_out .* obj.gen_third_phase_func();
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
        function second_phase_func = gen_second_phase_func(obj)
            col_len = length(obj.imaging_par.azimuth_freq_axis_hz);
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            rc_exp_col_term = obj.migr_par ./ obj.modified_range_fm_rate_hz_s;
            rc_exp_row_term = obj.imaging_par.range_freq_axis_hz.^2;
            rc_exp_mat = repmat(rc_exp_col_term, 1, row_len) .* repmat(rc_exp_row_term, col_len, 1);
            rc = exp(1j * pi * rc_exp_mat);
            second_comp_exp_col_term = 1 ./ obj.migr_par - 1;
            second_comp_exp_row_term = obj.imaging_par.range_freq_axis_hz;
            second_comp_exp_mat = repmat(second_comp_exp_col_term, 1, row_len) .* ...
                                      repmat(second_comp_exp_row_term, col_len, 1);
            second_comp = exp(1j * 4 * pi * obj.imaging_par.closest_slant_range_m / ...
                            obj.imaging_par.sig_par.light_speed_m_s * second_comp_exp_mat);
            second_phase_func = rc .* second_comp;
            second_phase_func = fftshift(second_phase_func);
            % second_phase_func = fftshift(rc);
        end
        function third_phase_func = gen_third_phase_func(obj)
            row_len = length(obj.imaging_par.range_freq_axis_hz);
            azimuth_comp_phase_col_term = obj.imaging_par.closest_slant_range_m / ...
                                obj.imaging_par.sig_par.wavelength_m * obj.migr_par;
            azimuth_comp_exp = repmat(azimuth_comp_phase_col_term, 1, row_len);
            third_comp_phase_col_term = (obj.imaging_par.closest_slant_range_m / ...
                                        obj.imaging_par.sig_par.light_speed_m_s)^2 * ...
                                        obj.modified_range_fm_rate_hz_s ./ ...
                                        obj.migr_par .* (1 ./ obj.migr_par - 1);
            third_comp_exp = repmat(third_comp_phase_col_term, 1, row_len);
            % third_phase_func = exp(1j * 4 * pi * azimuth_comp_exp) .* ...
            %                    exp(-1j * 4 * pi * third_comp_exp);
            third_phase_func = exp(1j * 4 * pi * azimuth_comp_exp);
            third_phase_func = fftshift(third_phase_func, 1);
        end
    end
end