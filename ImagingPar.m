classdef ImagingPar
    properties
        sig_par SigPar
        closest_slant_range_m
        sensor_speed_m_s = 120
        azimuth_aperture_len_m = 1.2
        beamwidth_rad
        synthetic_aperture_len_m
        synthetic_aperture_time_sec
        range_time_stamp_sec
        azimuth_time_stamp_sec
    end
    methods
        function obj = ImagingPar(varargin)
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
            obj.beamwidth_rad = obj.sig_par.wavelength_m / obj.azimuth_aperture_len_m;
            obj.synthetic_aperture_len_m = obj.beamwidth_rad * obj.closest_slant_range_m;
            obj.synthetic_aperture_time_sec = obj.synthetic_aperture_len_m / obj.sensor_speed_m_s;
            obj.range_time_stamp_sec = obj.gen_range_time_stamp_sec;
            obj.azimuth_time_stamp_sec = obj.gen_azimuth_time_stamp_sec;
        end
        function point_target_echo_signal = point_target_echo_signal(obj)
            point_target_echo_signal = zeros(length(obj.azimuth_time_stamp_sec), length(obj.range_time_stamp_sec));
            for i = 1:length(obj.azimuth_time_stamp_sec)
                slant_range_m = obj.slant_range_m(obj.azimuth_time_stamp_sec(i));
                round_trip_time_sec = obj.round_trip_time_sec(slant_range_m);
                echo_signal = obj.range_window(round_trip_time_sec) .* ...
                              exp(1j*pi*obj.sig_par.chirp_rate_hz_s*(obj.range_time_stamp_sec-round_trip_time_sec).^2) .* ...
                              exp(-1j*4*pi*slant_range_m/obj.sig_par.wavelength_m);
                point_target_echo_signal(i, :) = echo_signal;
            end
        end
        function plot_point_target_echo_signal(obj, point_target_echo_signal, x_axis_mode, y_axis_mode)
            if x_axis_mode == AxisMode.TimeSecond
                x_axis = obj.range_time_stamp_sec * 1e6;
            end
            if y_axis_mode == AxisMode.TimeSecond
                y_axis = obj.range_time_stamp_sec * 1e6;
            end
            figure;
            data_funcs = {@real, @imag, @abs, @angle};
            titles = {'real part', 'imaginary part', 'magnitude', 'phase (rad)'};
            for i = 1:4
                subplot(2,2,i);
                if x_axis_mode == AxisMode.TimeSecond && y_axis_mode == AxisMode.TimeSecond
                    imagesc(x_axis, y_axis, data_funcs{i}(point_target_echo_signal));
                elseif x_axis_mode == AxisMode.TimeSecond
                    imagesc(x_axis, data_funcs{i}(point_target_echo_signal));
                elseif y_axis_mode == AxisMode.TimeSecond
                    imagesc(y_axis, data_funcs{i}(point_target_echo_signal));
                else
                    imagesc(data_funcs{i}(point_target_echo_signal));
                end
                xlabel(obj.gen_xlabel(x_axis_mode)); ylabel(obj.gen_ylabel(y_axis_mode));
                title(titles{i}); colorbar; axis xy;
            end
        end
    end
    methods (Access = private)
        function range_time_stamp_sec = gen_range_time_stamp_sec(obj)
            range_time_stamp_sec_len = floor(2 * obj.sig_par.pulse_width_sec * obj.sig_par.sampling_freq_hz / 2) * 2;
            range_time_stamp_sec = (-range_time_stamp_sec_len/2 : range_time_stamp_sec_len/2-1) / obj.sig_par.sampling_freq_hz ...
                                + 2 * obj.closest_slant_range_m / obj.sig_par.light_speed_m_s;
        end
        function azimuth_time_stamp_sec = gen_azimuth_time_stamp_sec(obj)
            azimuth_time_stamp_sec_len = floor(obj.synthetic_aperture_time_sec * obj.sig_par.pulse_rep_freq_hz / 2) * 2;
            azimuth_time_stamp_sec = (-azimuth_time_stamp_sec_len/2 : azimuth_time_stamp_sec_len/2-1)' / obj.sig_par.pulse_rep_freq_hz;
        end
        function slant_range_m = slant_range_m(obj, azimuth_time_sec)
            slant_range_m = sqrt(obj.closest_slant_range_m^2 + (obj.sensor_speed_m_s*azimuth_time_sec)^2);
        end
        function round_trip_time_sec = round_trip_time_sec(obj, slant_range_m)
            round_trip_time_sec = 2 * slant_range_m / obj.sig_par.light_speed_m_s;
        end
        function range_window = range_window(obj, round_trip_time_sec)
            range_window = ((obj.range_time_stamp_sec-round_trip_time_sec)>-obj.sig_par.pulse_width_sec/2) & ...
                           ((obj.range_time_stamp_sec-round_trip_time_sec)<obj.sig_par.pulse_width_sec/2);
        end
        function xlabel_str = gen_xlabel(~, x_axis_mode)
            if x_axis_mode == AxisMode.TimeSecond
                xlabel_str  = 'range time (\mus)';
            elseif x_axis_mode == AxisMode.TimeSample
                xlabel_str  = 'range time (sample)';
            elseif x_axis_mode == AxisMode.FreqSample
                xlabel_str  = 'range freq. (sample)';
            else
                error('Unsupported x-axis mode.');
            end
        end
        function ylabel_str  = gen_ylabel(~, y_axis_mode)
            if y_axis_mode == AxisMode.TimeSecond
                ylabel_str  = 'azimuth time (\mus)';
            elseif y_axis_mode == AxisMode.TimeSample
                ylabel_str  = 'azimuth time (sample)';
            elseif y_axis_mode == AxisMode.FreqSample
                ylabel_str  = 'azimuth freq. (sample)';
            else
                error('Unsupported y-axis mode.');
            end
        end
    end
end