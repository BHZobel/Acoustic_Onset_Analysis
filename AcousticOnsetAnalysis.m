function OnsetInfo = AcousticOnsetAnalysis(wav,samplerate,noiseWindow,attackWindow,sustainWindow,maxNoise,SNdiff,ISI,filename)                 
%% FUNCTION: FIND ACOUSTIC ONSETS IN AN AUDIO FILE 
% 
%  Benjamin H. Zobel - 01-20-2018
%  Neurocognition and Perception Laboratory
%  Department of Psychological and Brain Sciences
%  University of Massachusetts Amherst
%
%% AcousticOnsetAnalysis.m is a Matlab function for finding acoustic onsets in an audio file or group of audio files
%  (select one or multiple audio files when prompted)
%
%This function takes a wavform array and does the following:
%1. Returns a structure array. Each field in the structure array contains information about the onsets detected in the waveform, including onset times. 
%   The information in the structure array is listed below in DESCRIPTION OF OUTPUTS.  
%2. Prints a tab-delimited text file containing all of the important information about the onsets that was gathered in the fields of the structure array.  
%
%
%DEPENDENCIES (OTHER FUNCTIONS THAT THIS FUNCTION REQUIRES):
%1. amp2dBV function for converting normalized amplitude to decibels (volts/current). The result will give you dB relative to full scale (i.e., dBFS)
%2. PrintOnsetInfo function for printing the fields of the structure array, containing info about the onsets, to a tab-delimited text file
%3. YinBest function for estimating the fundamental frequency of a waveform.  This function was adapted from the yin function contained in the yin package (see #4)
%4. All functions contained in the yin package that can be downloaded from http://audition.ens.fr/adc/sw/yin.zip
%   yin is a popular F0 estimation algorithm developed by Alain de Cheveigne
%   The paper on yin, published in JASA (2002), can be downloaded here: audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf
%   NOTE: After downloading the yin package from the url provided above, unzip and add a path to the yin folder and all of its contents.        
%
%
%DESCRIPTION OF INPUTS:
%wav: Input waveform. This function only analyzes Channel 1 of the waveform regardless of the number of channels contained in the input matrix.  
%
%samplerate: Sample rate (in Hertz) of the input waveform
%
%noiseWindow: The size of the window (in milliseconds) preceding the onset over which an rms amplitude calculation will be made.
%             The rms calculated over this window provides the noise value in the calculated SN ratio. Consider this the length of quiet that 
%             you would like to have leading up to each onset.
%
%attackWindow: The size of the window (in milliseconds) following the onset over which an rms amplitude calculation will be made.
%              This window should be smaller than or equal to the sustainWindow.
%              If you set this value equal to the sustainWindow, then you are essentially using one only one window for analysis of ramps. 
%              The rms calculated over this window minus the rms calculated over the noiseWindow provides a SN ratio of the onset. 
%              Use a relatively small attackwindow to capture the initial ramp up of the onset. If you set this window small, you will capture onsets 
%              with higher slopes, and your onset times will also fall closer to the ramp up (i.e., onset times will generally be later, 
%              occuring closer to or higher up on the ramp).
%
%sustainWindow: The size of the window (in milliseconds) following the onset over which an rms amplitude calculation will be made.
%               This window should be larger than or equal to the attackWindow.
%               If you set this value equal to the attackWindow, then you are essentially using only one window for analysis of ramps. 
%               The rms calculated over this window minus the rms calculated over the noiseWindow provides a SN ratio of the onset.
%               Use a relatively longer window to detect more sustained onsets, avoiding unwanted transient onsets that might be captured in the attack window.
%
%maxNoise: The maximum value (in normalized amplitude) allowed for the rms calculated in the noiseWindow for an onset to be considered. In other words, the 
%          rms calculated across the noiseWindow must be less than or equal to maxNoise. In normalized amplitude, an absolute value of 1 is the maximum amplitude permitted, 
%          with all other values expressed in fractions. 
%          
%SNdiff: The minimum difference between signal and noise (signal - noise) allowed for an onset to be considered. Separate calculations of SNdiff for attack and sustain.
%        That is, SNdiff is calculated by subtracting the rms across the noiseWindow from the rms across the attackWindow, and the rms across the noiseWindow from the 
%        rms across the sustainWindow must both be larger than SNRatio.  
%       
%ISI: The minimum amount of time (in milliseconds) allowed between any two onsets. If two onsets are separated by a time that is less than ISI, the onset
%     with the larger average signal-to-noise ratio (i.e., average of the attackWindow/noiseWindow SNR and sustainWindow/noiseWindow SNR) will be chosen, and 
%     the other onset will be ignored. 
%
%filename: The name that you want to give to the tab-delimited text file that is output containing all of the important information about the onsets gathered in the fields of the structure array. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DESCRIPTION OF OUTPUTS 
%Output is a structure array containing the fields listed below 
%    (NOTE: all of the fields are printed to the text file except for .OnsetTime_SMP and .SN)
%
%Fields:
%.OnsetTime_SMP - onset time in samples (not printed to text file)
%.OnsetTime_MS - onset time in milliseconds
%.Noise_RMS_NormAmp - normalized rms amplitude over noise window
%.Attack_RMS_NormAmp - normalized rms amplitude over attack window
%.Sustain_RMS_NormAmp - normalized rms amplitude over sustain window
%.Onset_RMS_NormAmp - normalized rms amplitude over entire onset window (attack window + sustain window)
%.SN - unweighted average of RMS amplitudes calculated for attack window and sustain window (i.e, average of .Attack_RMS_NormAmp and .Sustain_RMS_NormAmp). Used for deciding onset when there is an ISI conflict (not printed to text file).
%.Noise_RMS_DBFS - rms amplitude in dBFS over noise window
%.Attack_RMS_DBFS - rms amplitude in dBFS over attack window
%.Sustain_RMS_DBFS - rms amplitude in dBFS over sustain window
%.Onset_RMS_DBFS - rms amplitude in dBFS over entire onset window (attack window + sustain window)
%.Noise_F0 - fundamental frequency over noise window (will return NaN if window is too short for an estimate to be made)
%.Attack_F0 - fundamental frequency over attack window (will return NaN if window is too short for an estimate to be made)
%.Sustain_F0 - fundamental frequency over sustain window (will return NaN if window is too short for an estimate to be made)(will return NaN if window is too short for an estimate to be made)
%.Onset_F0 - fundamental frequency over entire onset window, defined as attack + sustain window (will return NaN if window is too short for an estimate to be made)
%
%Notes about F0 estimate: 
%1. Minimum fundamental frequency searched for is set to 75 Hz in YinBest function.  Won't search below this frequency.
%   This is the standard minF0 for estimating F0 in speech.
%2. Good F0 estimation typicalliy requires enough signal to cover twice the largest expected period (Cheveigne & Kawahara, 2002). 
%   Therefore, if your window is too short, F0 estimate may fail, and the YinBest function will return NaN in the F0 field of the structure array.
%      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%HOW THE ALGORITHM WORKS:
%At each sample in the waveform, the rms across the noiseWindow (including the current sample) is first calculated. If this value is less than or equal to maxNoise, 
%then the rms across the attackWindow (including the current sample) is calculated. If attackWindow - noiseWindow is greater than or equal to SNdiff, then 
%the rms across the sustainWindow is calculated. If sustainWindow - noiseWindow is greater than or equal to SNdiff, then 
%the script checks whether the current time point minus the time point of the previously detected onset is greater than or equal to ISI. If it is, then the current 
%time point is recorded as an onset.  However, if there is an ISI conflict, then the unweighted average of the RMS amplitudes calculatd for attackWindow and sustainWindow is 
%calculated for the current time point and the previously detected onset. If this average rms is larger for the current onset, then the previously detected onset
%is discarded and the current onset is recorded.  Otherwise, the current onset is ignored, and the algorithm moves on to the next sample.  Note that the comparison
%of average attack/sustain rms is unweighted.  This means that it naturally places somewhat more weight on the ramping up of the onset over the attackWindow (i.e., the slope and amplitude 
%of the initial onset ramp) compared to the sustain of the onset over the sustainWindow.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Suggested params to get started (note that these are the defaults if no params are entered):
% noiseWindow = 100;
% attackWindow = 15;
% sustainWindow = 75;
% maxNoise = 0.02;
% SNdiff = 0.03; 
% ISI = 500; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 1 %Set defaults for runtime usage
    [wavfns, wavpath] = uigetfile('/Volumes/GL_Storage/GL_Experiments/LiveNoise/Processed_AudioData/RandIDed/Lintee/*.wav', 'Pick an audio file within which to detect acoustic onsets', 'MultiSelect', 'on');
    noiseWindow = 100;
    attackWindow = 15;
    sustainWindow = 75;
    maxNoise = 0.02;
    SNdiff = 0.03; 
    ISI = 500; 
end
if ~iscell(wavfns)
    wavfns = {wavfns};
end

for part = 1:length(wavfns)
     
    clearvars -except wavfns wavpath noiseWindow attackWindow sustainWindow maxNoise SNdiff ISI part
    
    wavfn = wavfns{part};
 
    %% DISPLAY INITIALIZATION
    disp('Loading audio file...');
    [wav, samplerate] = audioread([wavpath wavfn]);
    
    display('Analyzing waveform for onsets...')
    
    %% REDUCE WAV ARRAY TO ONE CHANNEL
    
    wav = wav(:,1); %Regardless of whether this is a mono file or a stereo file, you will only
                    %be working with channel 1 of the wav array.  
                    
    %% CONVERT WINDOW AND ISI TIMES FROM MS TO SAMPLES

    %Milliseconds are rounded to the nearest sample
    sampNoiseWindow = round((noiseWindow/1000) * samplerate);
    sampAttackWindow = round((attackWindow/1000) * samplerate);
    sampSustainWindow = round((sustainWindow/1000) * samplerate);
    sampISI = round((ISI/1000) * samplerate);

     %% IDENTIFY START AND END TIME OVER WHICH WAV FILE WILL BE ANALYZED AND ONSETS DETECTED
    sampStartTime = sampNoiseWindow + 1; %Array starts at index 1, so you need to add 1 here. So that when you look back on the first  
                                         %loop of the time series, thcell in the time series, you will not call for index 0, which will be out of bounds
                                         %you want to look back to index 1.
                                         
    sampEndTime = length(wav) - (sampAttackWindow + sampSustainWindow);                                   
    %sampEndTime = round((34415/1000) * samplerate);
    %% CREATE THERMOMETER FOR DISPLAYING PROGRESS TO COMMAND WINDOW

    analyzeLength = sampEndTime - sampStartTime;
    Thermometer(1) = round(.10 * analyzeLength) + sampStartTime; %sample in wav array marking 10% of wav file length
    Thermometer(2) = round(.20 * analyzeLength) + sampStartTime; %sample in wav array marking 20% of wav file length
    Thermometer(3) = round(.30 * analyzeLength) + sampStartTime; %sample in wav array marking 30% of wav file length
    Thermometer(4) = round(.40 * analyzeLength) + sampStartTime; %sample in wav array marking 40% of wav file length
    Thermometer(5) = round(.50 * analyzeLength) + sampStartTime; %sample in wav array marking 50% of wav file length
    Thermometer(6) = round(.60 * analyzeLength) + sampStartTime; %sample in wav array marking 60% of wav file length
    Thermometer(7) = round(.70 * analyzeLength) + sampStartTime; %sample in wav array marking 70% of wav file length
    Thermometer(8) = round(.80 * analyzeLength) + sampStartTime; %sample in wav array marking 80% of wav file length
    Thermometer(9) = round(.90 * analyzeLength) + sampStartTime; %sample in wav array marking 90% of wav file length
    Thermometer(10) = sampEndTime; %sample in wav array marking 100% of wav file length
    thermText = '% of waveform analyzed for onsets...';

    %% STEP ACROSS WAVEFORM AND DETECT AND RECORD ONSETS
    
    uBound = 0; %used to index the SampOnsetTimes and SNOnsets arrays, which store the onsets that are detected        
    for i = sampStartTime:sampEndTime
        onsetTrip = 0; %this will turn to 1 if a legitimate onset is identified on this loop of the for loop
        aveNoise = rms(wav(i - sampNoiseWindow:i)); %get rms of noise in preceding noise window (calculation includes current sample)       
       
        if aveNoise <= maxNoise %fits criterion for noise floor, so now check on attack criterion
            %See if attack satisfies the criterion
            attackSignal = rms(wav(i:i + sampAttackWindow)); %get rms of sound in attack window (calculation includes current sample)
            
            if attackSignal - aveNoise >= SNdiff %fits criterion for attack SNdiff, so now check on sustain criterion
                sustainSignal = rms(wav(i + sampAttackWindow:i + sampAttackWindow + sampSustainWindow)); %get rms of sound in sustain window 
                                                                                                         %(calculation includes last sample of attack window)
                if sustainSignal - aveNoise >= SNdiff %fits criterion for sustain SNdiff, now consider as a candidate and check ISI
                    %You have identified a potential onset        
                     SN = mean([attackSignal, sustainSignal]); %Note: the SN stored in SN array and compared against potential ISI conflicts is the 
                                                                      %average of the rms amplitudes over attack and sustain windows.
                    if uBound == 0 %this is the first onset that has been detected
                       %Enter this onset into the onset arrays
                        onsetTrip = 1; %legitmate onset identified
                        uBound = uBound + 1; %increment the onset array cell 
                  
                    elseif i - ONSET.OnsetTime_SMP(uBound) >= (sampAttackWindow + sampSustainWindow) %if candidate is outside the range of the previous onset found, make sure this onset doesn't conflict with ISI
                                                                                                     %i.e., check previous onset based on the minimum ISI you specified
                        if i - ONSET.OnsetTime_SMP(uBound) < sampISI %if there is, indeed, an ISI conflict with the previous detected onset
                            %This onset and previous one conflict in ISI
                            %Choose the onset with the greater SN. 
                            %SN is calculated as the avarage of the rms amplitudes over the attack and sustain windows: mean([attackSignal, sustainSignal])
                            %So you are keeping the onset that has the greater average of rms amplitudes over attack and sustain windows
                            if ONSET.SN(uBound) < SN %if previous onset SN is less than the current SN
                                onsetTrip = 1; %legitmate onset identified
                                %NOTE: DO NOT INCREMENT ARRAY (i.e., do not add 1 to uBound)
                                %by not incrementing here, you will replace previous onset with current onset
                                %note: if previous onset is greater than or equal to
                                %current onset, then current onset with be ignored and
                                %won't be entered into the onset arrays
                            end
                            
                        else %there is no ISI conflict with previous onset
                            onsetTrip = 1; %legitmate onset identified
                            uBound = uBound + 1; %increment onset array cell
                        end
                    end     
                end
            end
        end
%%      IF LEGITIMATE ONSET WAS FOUND, ENTER INFORMATION
        if onsetTrip == 1 %a legitimate onset has been found, enter it into the arrays      
            %Segment the wavform for F0 analysis
            noiseWav = wav(i - sampNoiseWindow:i); %noise segment
            attackWav = wav(i:i + sampAttackWindow); %attack segment
            sustainWav = wav(i + sampAttackWindow:i + sampAttackWindow + sampSustainWindow); %sustain segment
            onsetWav = wav(i:i + sampAttackWindow + sampSustainWindow); %onset segment (attack + sustain)
            
            ONSET.OnsetTime_SMP(uBound, :) = i; %Onset time in samples
            ONSET.OnsetTime_MS(uBound, :) = round((1000/samplerate) * ONSET.OnsetTime_SMP(uBound)); %Onset time in milliseconds.  Calculation converts onset in samples, to milliseconds
            
            ONSET.Noise_RMS_NormAmp(uBound, :) = aveNoise; %normalized RMS amplitude over the noise window
            ONSET.Attack_RMS_NormAmp(uBound, :) = attackSignal; %normalized RMS amplitude over the attack window
            ONSET.Sustain_RMS_NormAmp(uBound, :) = sustainSignal; %normalized RMS amplitude over the sustain window
            ONSET.Onset_RMS_NormAmp(uBound, :) = rms(onsetWav); 
            ONSET.SN(uBound, :) = SN; %Average of attack window and sustain window normalized RMS amplitudes (i.e, average of ONSET.AttackRMS and ONSET.SustainRMS)
                                   %SN is used for determining the winning onset when there's an ISI conflict.
                                   %This is used in the script and is necessary to have here
                                   %But it's probably not needed for anything in terms of analysis.  You can always
                                   %write code at the end of the script to remove it from the structure before the 
                                   %final output.  I have commented code that does that at th end of this script 
                                   %in case you want to do that eventually if you see no need to have this info in the 
                                   %final output.  
                                   
            ONSET.Noise_RMS_DBFS(uBound, :) = amp2dBV(ONSET.Noise_RMS_NormAmp(uBound));  %normalized RMS amplitude over the noise window
            ONSET.Attack_RMS_DBFS(uBound, :) = amp2dBV(ONSET.Attack_RMS_NormAmp(uBound)); %normalized RMS amplitude over the noise window
            ONSET.Sustain_RMS_DBFS(uBound, :) = amp2dBV(ONSET.Sustain_RMS_NormAmp(uBound)); %normalized RMS amplitude over the noise window
            ONSET.Onset_RMS_DBFS(uBound, :) = amp2dBV(ONSET.Onset_RMS_NormAmp(uBound)); %normalized RMS amplitude over the noise window
            
            
            ONSET.Noise_F0(uBound, :) = YinBest(noiseWav, samplerate); %F0 over the noise window
            ONSET.Attack_F0(uBound, :) = YinBest(attackWav, samplerate); %F0 over the attack window (if attack window is too short, an F0 cannot be calculated and will return Null)
            ONSET.Sustain_F0(uBound, :) = YinBest(sustainWav, samplerate); %F0 over the sustain window
            ONSET.Onset_F0(uBound, :) = YinBest(onsetWav, samplerate); %F0 over the entire onset (i.e., Attack + Sustain window)
        end
            
%%      Increment thermometer        
        %Thermometer sends progress update to the command window
        switch i
            case Thermometer(1)
                display(strcat('10', thermText)) %10% of waveform analyzed
            case Thermometer(2)
                display(strcat('20', thermText)) %20% of waveform analyzed
            case Thermometer(3)
                display(strcat('30', thermText)) %30% of waveform analyzed
            case Thermometer(4)
                display(strcat('40', thermText)) %40% of waveform analyzed
            case Thermometer(5)
                display(strcat('50', thermText)) %50% of waveform analyzed
            case Thermometer(6)
                display(strcat('60', thermText)) %60% of waveform analyzed
            case Thermometer(7)
                display(strcat('70', thermText)) %70% of waveform analyzed
            case Thermometer(8)
                display(strcat('80', thermText)) %80% of waveform analyzed
            case Thermometer(9)
                display(strcat('90', thermText)) %90% of waveform analyzed
            case Thermometer(10)
                display(strcat('100', thermText)) %100% of waveform analyzed
                display('done.')
        end 

    end
    
%% OUTPUT THE ONSET STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%In case you don't want to have SN as a field in the final output structure:
%field = 'SN';
%ONSET = rmfield(ONSET,field)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Another option: If you want to ouput onset time in seconds as a field in the structure 
%ONSET.OnsetTimeSEC = round((1/samplerate).*ONSET.OnsetTimeSMP 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OnsetInfo = ONSET;
outputpath = '/Volumes/GL_Storage/GL_Experiments/LiveNoise/Processed_AudioData/RandIDed/Lintee/LinteeOnsetsAttempts/Attempt1/'; %%Maggie added this on 10/12/17 to control where .txt files end up
if ~exist('filename', 'var')
%     [outfn, outpath] = uiputfile('*.txt', ['Where to save tab-delimited output for ' wavfn '?']);
%     filename = [outpath outfn];
    filename = [wavpath wavfns{part}(1:end-4) '.txt'];
    filename2 = [outputpath wavfns{part}(1:end-4) '.txt']; %Maggie added this on 10/12/17 to control where output .txt files end up
end
%% PRINT THE ONSET INFO
PrintOnsetInfo(filename, OnsetInfo);
PrintOnsetInfo(filename2, OnsetInfo);
end
disp('Script is done! You can clear the workspace or close MatLab!');
end
   

