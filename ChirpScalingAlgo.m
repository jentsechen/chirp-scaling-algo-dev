classdef ChirpScalingAlgo
    properties
        imaging_par ImagingPar
    end
    methods
        function obj = ChirpScalingAlgo(imaging_par)
            obj.imaging_par = imaging_par;
        end
        function azimuth_fft_out = azimuth_fft(~, raw_data)
            azimuth_fft_out = fft(raw_data, [], 1);
        end
        function range_fft_out = range_fft(~, chirp_scaling_out)
            range_fft_out = fft(chirp_scaling_out, [], 2);
        end
    end
end