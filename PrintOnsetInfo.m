function PrintOnsetInfo(filename, ONSET)
%% FUNCTION: PRINT ONSET INFO TO TAB DELIMITED TEXT FILE
%
%  Benjamin H. Zobel - 01-20-2018
%  Neurocognition and Perception Laboratory
%  Department of Psychological and Brain Sciences
%  University of Massachusetts Amherst
%
%% PrintOnsetInfo.m is a function that takes the output structre from the onset finder (AcousticOnsetsNormAmp.m)
%  and prints the relevant fields to columns in a tab delimited text file
%
%DEPENDANTS (OTHER FUNCTIONS THAT DEPEND ON THIS FUNCTION):
%1. PrintOnsetInfor was written specifically for printing the output
%   structure created by AcousticOnsetsNormAmp.m to a tab delimited text
%   file
%
%
%DESCRIPTION OF INPUTS:
%filename: The name of the text file that you want to this function to print.
%          NOTE: If filename does not include a path, then the file will be printed 
%          to the location of this script.  his function only analyzes Channel 1 of the waveform regardless of the number of channels contained in the input matrix.  
%
%ONSET: The output structure that is created by AcousticOnsetsNormAmp.m
%
%
%INFORMATION PRINTED TO TEXT FILE (i.e., columns of text file)
%OnsetTimeMS
%NoiseRMS_DBFS
%AttackRMS_DBFS
%SustainRMS_DBFS
%OnsetRMS_DBFS
%Noise_F0
%Attack_F0
%Sustain_F0
%Onset_F0
%
%
%IMPORTANT NOTE: 
%Numbers are written to the 7th decimal place (trailing zeroes are not printed)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OPEN TEXT FILE FOR PRINTING

%if you want to save text file in a location other than the location of this script
%add a path to the filename.
fileID = fopen(filename, 'w');

%% PRINT COLUMN HEADERS OF TEXT FILE 

fprintf(fileID, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                  'OnsetTime_MS',...
                  'Noise_RMS_NormAmp',...
                  'Attack_RMS_NormAmp',...
                  'Sustain_RMS_NormAmp',...
                  'Onset_RMS_NormAmp',...
                  'Noise_RMS_DBFS',...
                  'Attack_RMS_DBFS',...
                  'Sustain_RMS_DBFS',...
                  'Onset_RMS_DBFS',...
                  'Noise_F0',...
                  'Attack_F0',...
                  'Sustain_F0',...
                  'Onset_F0');

%% PRINT INFORMATION

%Find the length of the field array
arrLength = length(ONSET.OnsetTime_MS);

for i = 1:arrLength
    fprintf(fileID, '%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\t%.7g\n',... 
                    ONSET.OnsetTime_MS(i),...
                    ONSET.Noise_RMS_NormAmp(i),...
                    ONSET.Attack_RMS_NormAmp(i),...
                    ONSET.Sustain_RMS_NormAmp(i),...
                    ONSET.Onset_RMS_NormAmp(i),...   
                    ONSET.Noise_RMS_DBFS(i),...
                    ONSET.Attack_RMS_DBFS(i),...
                    ONSET.Sustain_RMS_DBFS(i),...
                    ONSET.Onset_RMS_DBFS(i),...
                    ONSET.Noise_F0(i),...
                    ONSET.Attack_F0(i),...
                    ONSET.Sustain_F0(i),...
                    ONSET.Onset_F0(i));
end

%% CLOSE THE TEXT FILE
fclose(fileID);




