classdef PerfMetricAnalysis
    properties
        data_anal
        sig_par SigPar
        azi_peak_loc
        rng_peak_loc
        azi_n_smp_anal = 100
        rng_n_smp_anal = 50
        interp_factor = 20
    end
    methods
        function obj = PerfMetricAnalysis(varargin)
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
        end
        function plot_data_to_be_anal(obj)
            figure;
            imagesc(10*log10(obj.data_anal .* conj(obj.data_anal)));
            xlabel("range (sample)"); ylabel("azimuth (sample)");
            title("magnitude (dB)"); colorbar; axis xy;
        end
        function interp_out = interp(obj, slice, n_smp_anal)
            slice_fft_out = fftshift(fft(slice));
            slice_fft_out_zp = [zeros(1, n_smp_anal*(obj.interp_factor/2-0.5)), ...
                                slice_fft_out, ...
                                zeros(1, n_smp_anal*(obj.interp_factor/2-0.5))];
            interp_out = ifft(slice_fft_out_zp);
        end
        function interp_out = rng_interp(obj)
            slice = obj.data_anal(obj.azi_peak_loc, ...
                    (obj.rng_peak_loc-obj.rng_n_smp_anal/2):(obj.rng_peak_loc-1+obj.rng_n_smp_anal/2));
            interp_out = obj.interp(slice, obj.rng_n_smp_anal);
        end
        function interp_out = azi_interp(obj)
            slice = obj.data_anal( ...
                    (obj.azi_peak_loc-obj.azi_n_smp_anal/2):(obj.azi_peak_loc-1+obj.azi_n_smp_anal/2), ...
                    obj.rng_peak_loc).';
            interp_out = obj.interp(slice, obj.azi_n_smp_anal);
        end
        function plot_interp_out(~, interp_out)
            figure;
            plot(10*log10(interp_out .* conj(interp_out)))
            ylabel("magnitude (dB)");
        end
        function calc_pslr(~, sig)
            [pks, ~] = findpeaks(abs(sig));
            [peaks_sorted, ~] = sort(pks, 'descend');
            mainlobe_peak = peaks_sorted(1);
            sidelobe_peak = peaks_sorted(2);
            pslr_db = 20*log10(mainlobe_peak / sidelobe_peak);
            fprintf('PSLR = %.2f dB\n', pslr_db)
        end
        function calc_irw(obj, sig)
            mag = abs(sig) / max(abs(sig));
            [~, peak_idx] = max(mag);
            th = 10^(-3/20);
            left_idx = find(mag(1:peak_idx) <= th, 1, 'last');
            right_idx = peak_idx - 1 + find(mag(peak_idx:end) <= th, 1, 'first');
            irw_smp = right_idx - left_idx;
            irw_m = irw_smp / (obj.sig_par.sampling_freq_hz * obj.interp_factor) ...
                    * obj.sig_par.light_speed_m_s;
            fprintf('IRW = %.2f m\n', irw_m)
        end
    end
end