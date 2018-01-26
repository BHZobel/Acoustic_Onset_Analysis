function valueDB = amp2dBV(amplitude, maxValue)
%% FUNCTION: CONVERT AMPLITUDE TO DECIBELS
% 
%  Benjamin H. Zobel - 01-20-2018
%
%% amp2dBV is a function that takes an amplitude value and converts it to decibels voltage/current
%
%DESCRIPTION OF INPUTS
%1. amplitude - This is the amplitude value  you wish to convert to dB. amplitude can be a scalar or array. 
%               (i.e., this is the numerator of your dB ratio)
%        
%2. maxValue - A decible is a comparison (i.e., a ratio). This is the value that you wish to compare
%               your amplitude to for a dB measurement. As such, the output of this function tells you how 
%               many dB (voltage/current) diufferent your amplitude is
%               compared to your maxValue. maxValue can be a scaler or array
%               NOTE: if you do not provide a maxValue, then it defaults to a value of 1.  Assuming your amplitude is 
%                     in units of normalized amplitude (i.e., amplitude normalized to fall at or between -1 and 1; default when you read wav files in matlab), 
%                     then the output will tell you how many dB softer your amplitude is from the maximum allowable amplitude before clipping occurs. 
%                     As such, the output will be in decibels full-scale (i.e., dBFS)
%                     If you are using 16-bit values rather than normalized amplitude, then maxValue should be set to 32767.
        
    if ~exist('maxValue', 'var') %check if maxValue has been entered
        %normalization parameter does not exist, so default to 1
        maxValue = 1;
    end
    
    %calculate the dB voltage/current
    valueDB = 20.*log10(abs(amplitude)./maxValue);
    
%%  NOTE:   
    %if you want to calculate dB power instead, use this formula:
    %valueDB = 10.*log10(abs(wav)./maxValue); 
