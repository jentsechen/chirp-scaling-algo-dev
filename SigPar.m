classdef SigPar
    properties (Constant)
        light_speed_m_s = 3e8
    end
    properties
        wavelength_m
        carrier_freq
        pulse_width_sec
        pulse_rep_freq_hz
        bandwidth_hz
        sampling_freq_hz
        chirp_rate_hz_s
    end
    methods
        function obj = SigPar(varargin)
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
            obj.carrier_freq = SigPar.light_speed_m_s / obj.wavelength_m;
            obj.chirp_rate_hz_s = obj.bandwidth_hz / obj.pulse_width_sec;
        end
    end
end