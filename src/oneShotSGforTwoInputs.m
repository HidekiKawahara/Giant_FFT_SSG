%% Signal Safeguarding Acoustic Test Script
%
% This script is designed to test the "Signal Safeguarding" audio processing
% idea. It performs the following steps:
%   1. Loads a reference audio signal (.wav file).
%   2. Prompts the user for processing parameters (threshold, frequency).
%   3. Applies the signal safeguarding algorithm to the reference signal.
%   4. Plays and records both the original and safeguarded signals through a
%      selected audio interface to measure the acoustic transfer function.
%   5. Calculates the impulse response (IR) of the system for both cases
%      via deconvolution in the frequency domain.
%   6. Analyzes and compares the time-domain and frequency-domain
%      characteristics of the resulting IRs.
%   7. Saves all analysis plots to a unique, timestamped directory.
%
% Required helper functions:
%   - signalSafeguardwithGiantFFTSRC.m
%   - basicPlayRecLoop.m
% Copyright 2025 Hideki Kawahara
% Author: Hideki Kawahara
% Version: 1.3 - Integrated retrospective analysis and refactored tapering
%                logic into a local function for clarity and bug fixing.
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

%% 1. Setup Environment
% Clears the workspace, command window, and closes all figures to ensure a
% clean run.
clear;
clc;
close all;

%% 2. Initialization and File Selection
% --- User selects the reference audio file ---
[fileName, filePath] = uigetfile('*.wav', 'Select Reference WAV File');
% Check if the user cancelled the file selection
if isequal(fileName, 0)
    disp('User cancelled file selection. Script terminated.');
    return;
end
audioFileFullPath = fullfile(filePath, fileName);
[originalSignal, fs] = audioread(audioFileFullPath);
disp(['Loaded reference file: ', fileName]);

% --- Setup Audio I/O Device ---
% Initialize the audio player/recorder object. This requires a two-channel
% input device for comparing the measurement mic (Ch1) and reference mic (Ch2).
try
    playerRecorder = audioPlayerRecorder("SampleRate", fs, "BitDepth", ...
        "24-bit integer","RecorderChannelMapping",[1 2]);
catch ME
    disp(['Error initializing audio player/recorder: ', ME.message]);
    disp('This tool requires a two-channel audio input.');
    disp('Please connect a device with at least two channels and try again.');
    disp('  - Channel 1: Measurement target (e.g., recording mic).');
    disp('  - Channel 2: Reference signal (e.g., proximity mic).');
    return;
end
% Get and display a list of available audio devices
availableDevices = getAudioDevices(playerRecorder);
disp('Available Audio Devices:');
disp(availableDevices);

% --- Create a unique directory for saving results ---
% Using a timestamp ensures that results from different runs are not overwritten.
timestamp = datetime('now', 'format', 'yyyyMMdd_HHmmss');
resultsDir = "SignalSafeguard_Test_" + string(timestamp);
mkdir(resultsDir);
disp(['Results will be saved in: ./' resultsDir]);

%% 3. User Input for Processing Parameters
% --- Get safeguarding parameters from the user ---
thresholdDb = input("Enter the safeguarding threshold level (dB): ");
highFreqLimitHz = input("Enter the high frequency limit for safeguarding (Hz): ");

% --- Get audio device selection from the user ---
% This ID corresponds to the list displayed above.
deviceID = input("Select the audio device ID for playback and recording: ");
% Basic validation
if deviceID > length(availableDevices) || deviceID < 1
    error('Invalid device ID selected. Please run the script again.');
end
selectedDeviceName = availableDevices{deviceID};
disp(['Selected device: ' selectedDeviceName]);

%% 4. Apply Signal Safeguarding Algorithm
disp('Applying signal safeguarding...');
displayOn = true;
[safeguardedSignal, safeguardParams] = ...
    signalSafeguardwithGiantFFTSRC(originalSignal, fs, fs, thresholdDb, highFreqLimitHz, displayOn);
disp('Signal safeguarding complete.');

%% 5. Perform Acoustic I/O Measurements
% --- Play and record the SAFGUARDED signal ---
disp('Performing I/O loop for the SAFEGUARDED signal...');
ioResultsSG = basicPlayRecLoop(fs, safeguardedSignal, selectedDeviceName);
disp('I/O for safeguarded signal complete.');

% --- Play and record the ORIGINAL (RAW) signal ---
disp('Performing I/O loop for the ORIGINAL signal...');
ioResultsRaw = basicPlayRecLoop(fs, originalSignal, selectedDeviceName);
disp('I/O for original signal complete.');

%% 6. Post-Processing and Data Archiving
% --- Save the raw acquired data for offline analysis ---
audiowrite(fullfile(resultsDir, 'acquiredUsingSG.wav'), ...
    ioResultsSG.acquiredSignal, fs, "BitsPerSample", 24);
audiowrite(fullfile(resultsDir, 'acquiredUsingRaw.wav'), ...
    ioResultsRaw.acquiredSignal, fs, "BitsPerSample", 24);
disp('Raw test recordings saved.');

% --- Ensure consistent signal lengths for analysis ---
% Trim recorded signals to match the length of the original reference.
numSamples = length(originalSignal);
playbackSignalSG   = ioResultsSG.outputSignal(1:numSamples, :); % This is the signal SENT to the speaker
recordedSignalSG   = ioResultsSG.acquiredSignal(1:numSamples, :); % This is the signal RECEIVED from the mic
recordedSignalRaw  = ioResultsRaw.acquiredSignal(1:numSamples, :);

% --- Calculate Impulse Responses via Deconvolution ---
% The impulse response is calculated by dividing the FFT of the recorded
% signal by the FFT of the played signal.
disp('Calculating impulse responses...');
% IR for the safeguarded signal playback
impulseResponseSG = ifft(fft(recordedSignalSG) ./ fft(playbackSignalSG));
% IR for the raw signal playback, but referenced to the safeguarded signal's
% spectrum. This is for the "Retro-Safeguard" comparison.
impulseResponseRetroSG = ifft(fft(recordedSignalRaw) ./ fft(playbackSignalSG));

%% 7. Time-Domain Analysis and Plotting
% --- Plot Impulse Response from Safeguarded Signal ---
figure('Name', 'Impulse Response (Safeguarded)');
timeVector = (0:fs-1) / fs; % Create a 1-second time vector
plot(timeVector, 20*log10(abs(impulseResponseSG(1:fs, :))), "LineWidth", 2);
grid on;
title('Impulse Response from Safeguarded Signal Playback');
xlabel('Time (s)');
ylabel('Level (dB)');
axis([0 1 -100 0]);
set(gca, "FontSize", 13, "LineWidth", 2);
legend("Target mic", "Close mic");
print(fullfile(resultsDir, 'impulse_response_SG.png'), '-dpng', '-r200');

% --- Plot Comparison of Impulse Responses ---
figure('Name', 'Impulse Response Comparison');
plot(timeVector, 20*log10(abs(impulseResponseRetroSG(1:fs,:))), "LineWidth", 2);
hold on;
plot(timeVector, 20*log10(abs(impulseResponseSG(1:fs,:))), "LineWidth", 2);
hold off;
grid on;
title('Impulse Response Comparison');
xlabel('Time (s)');
ylabel('Level (dB)');
axis([0 1 -100 0]);
legend("Retro-SG Ch-1", "Retro-SG Ch-2","SG Ch-1", "SG Ch-2");
set(gca, "FontSize", 13, "LineWidth", 2);
print(fullfile(resultsDir, 'impulse_response_comparison.png'), '-dpng', '-r200');

%% 8. Frequency-Domain Analysis
disp('Analyzing frequency responses...');
% --- Define windowing parameters for IR analysis ---
% Isolate the direct-path sound (LTI part) and a later part (noise).
IR_PRE_DELAY_S = 0.05;       % Time before the main peak to start the window (seconds)
IR_WINDOW_DURATION_S = input("Input plausible length of the impulse response (seconds): ");

% --- Find the main peak of the direct-path sound of close mic.---
[~, peakIndex] = max(abs(impulseResponseSG(:,2)));

% --- Define sample indices for the LTI and noise parts ---
ltiStartSample = peakIndex - round(IR_PRE_DELAY_S * fs);
irWindowLengthSamples = round(IR_WINDOW_DURATION_S * fs);
ltiSampleIndices = ltiStartSample + (0:irWindowLengthSamples-1);
% For the "noise" part, take a window from the middle of the IR
noiseSampleIndices = round(numSamples/2) + (0:irWindowLengthSamples-1);

% --- Calculate spectra for different parts of the IRs ---
% Take the FFT of the windowed sections of the impulse responses.
frequencyVector = (0:numSamples-1)' / numSamples * fs;
% Spectra for the SAFEGUARDED measurement
ltiSpectrumComplexSG = fft(impulseResponseSG(ltiSampleIndices, :), numSamples);
noiseSpectrumComplexSG = fft(impulseResponseSG(noiseSampleIndices, :), numSamples);
% Spectra for the RETRO-SAFEGUARDED measurement
ltiSpectrumComplexRetroSG = fft(impulseResponseRetroSG(ltiSampleIndices, :), numSamples);
noiseSpectrumComplexRetroSG = fft(impulseResponseRetroSG(noiseSampleIndices, :), numSamples);
% Convert spectra to decibels for plotting
ltiSpectrumDbSG = 20*log10(abs(ltiSpectrumComplexSG));
noiseSpectrumDbSG = 20*log10(abs(noiseSpectrumComplexSG));
ltiSpectrumDbRetroSG = 20*log10(abs(ltiSpectrumComplexRetroSG));
noiseSpectrumDbRetroSG = 20*log10(abs(noiseSpectrumComplexRetroSG));

%% 9. Frequency-Domain Plotting
% --- Define frequency limits from the safeguarding algorithm output ---
lowFreqLimit = safeguardParams.fLow;
highFreqLimit = safeguardParams.fHigh;
% --- Plot Frequency Response of SAFEGUARDED Measurement ---
figure('Name', 'Frequency Response (Safeguarded)');
plot(frequencyVector, ltiSpectrumDbSG, "LineWidth", 2);
hold on;
plot(frequencyVector, noiseSpectrumDbSG, "LineWidth", 2, 'LineStyle', '--');
xline(lowFreqLimit, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
xline(highFreqLimit, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
hold off;
grid on;
set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
axis([20 fs/2 [-70 10] + max(ltiSpectrumDbSG(:))]);
title(['Frequency Response (Safeguarded) | Threshold: ' num2str(thresholdDb) ' dB']);
xlabel("Frequency (Hz)");
ylabel("Level (dB)");
legend("Ch1 LTI","Ch2 LTI","Ch1 noise","Ch2 noise", "Location", "northwest");
print(fullfile(resultsDir, 'freq_response_SG.png'), '-dpng', '-r200');

% --- Plot Frequency Response of RETRO-SAFEGUARDED Measurement ---
figure('Name', 'Frequency Response (Retro-Safeguarded)');
plot(frequencyVector, ltiSpectrumDbRetroSG, "LineWidth", 2);
hold on;
plot(frequencyVector, noiseSpectrumDbRetroSG, "LineWidth", 2, 'LineStyle', '--');
xline(lowFreqLimit, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
xline(highFreqLimit, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
hold off;
grid on;
set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
axis([20 fs/2 [-70 10] + max(ltiSpectrumDbRetroSG(:))]);
title(['Frequency Response (Retro-Safeguarded) | Threshold: ' num2str(thresholdDb) ' dB']);
xlabel("Frequency (Hz)");
ylabel("Level (dB)");
legend("Ch1 LTI","Ch2 LTI","Ch1 noise","Ch2 noise", "Location", "northwest");
print(fullfile(resultsDir, 'freq_response_RetroSG.png'), '-dpng', '-r200');

% --- Plot Gain Comparison ---
figure('Name', 'LTI Gain Comparison');
% Normalize the gain difference for a fair comparison
gainMask = (frequencyVector > lowFreqLimit & frequencyVector < highFreqLimit);
maxGainDiff = max(ltiSpectrumDbRetroSG(gainMask,1) - ltiSpectrumDbRetroSG(gainMask,2));
% Plot the normalized gain difference between channels
plot(frequencyVector, ltiSpectrumDbRetroSG(:,1) - ltiSpectrumDbRetroSG(:,2) - maxGainDiff, "LineWidth", 2);
hold on;
plot(frequencyVector, ltiSpectrumDbSG(:,1) - ltiSpectrumDbSG(:,2) - maxGainDiff, "LineWidth", 2);
xline(lowFreqLimit, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
xline(highFreqLimit, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
hold off;
grid on;
set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
axis([20 fs/2 -60 20]);
title('LTI Gain Difference Comparison (Ch1 - Ch2)');
xlabel("Frequency (Hz)");
ylabel("Normalized Gain Difference (dB)");
legend("Retro-SG", "SG", "Location", "northwest");
print(fullfile(resultsDir, 'gain_comparison_RetroSG.png'), '-dpng', '-r200');
disp('Analysis complete. All plots saved.');

%% 10. Interactive Transfer Function Refinement
% This section allows for iterative shaping of the transfer function derived
% from both measurements. The goal is to create a clean, band-limited impulse
% response by applying smooth tapers in the frequency domain.

isResultOK = false; % Use a boolean flag for the loop condition
while ~isResultOK
    % --- Get frequency limits for shaping from the user ---
    disp('Enter frequency limits to refine the transfer function.');
    lowFreqLimitFix = input('Enter the desired LOW frequency limit (Hz): ');
    highFreqLimitFix = input('Enter the desired HIGH frequency limit (Hz): ');
    
    % --- Input validation ---
    if lowFreqLimitFix >= highFreqLimitFix
        warning('Low frequency limit must be less than high frequency limit. Please try again.');
        continue; % Skip to the next loop iteration
    end

    % --- Calculate initial transfer functions ---
    transferFunction = ltiSpectrumComplexSG(:, 1) ./ ltiSpectrumComplexSG(:, 2);
    transferFunctionRetro = ltiSpectrumComplexRetroSG(:, 1) ./ ltiSpectrumComplexRetroSG(:, 2);

    % --- Apply frequency tapering to both TFs using a local function ---
    [taperedTF, originalTF] = applyFrequencyTaper(transferFunction, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);
    [taperedTFRetro, originalTFRetro] = applyFrequencyTaper(transferFunctionRetro, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);

    % --- Calculate the refined impulse responses ---
    refinedImpulseResponse = ifft(taperedTF, 'symmetric');
    refinedImpulseResponseRetro = ifft(taperedTFRetro, 'symmetric');
    timeVectorCentered = ((1:numSamples) - numSamples/2 - 1)' / fs;

    % --- Plotting Results for Verification ---
    figure('Name', 'Refined Transfer Function and Impulse Response');
    
    % Subplot 1: Transfer Function Comparison
    subplot(2, 1, 1);
    semilogx(frequencyVector, 20*log10(abs(originalTF)), 'b', 'LineWidth', 2); 
    hold on;
    semilogx(frequencyVector, 20*log10(abs(taperedTF)), 'r', 'LineWidth', 2);
    semilogx(frequencyVector, 20*log10(abs(taperedTFRetro)), 'g', 'LineWidth', 2);
    grid on;
    set(gca, "FontSize", 13, "LineWidth", 2);
    title(['Refined Transfer Function | Freq Range: ' num2str(lowFreqLimitFix) ' - ' num2str(highFreqLimitFix) ' Hz']);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    xline(lowFreqLimitFix, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
    xline(highFreqLimitFix, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
    legend('Original SG TF', 'Refined SG', 'Refined Retro', 'Location', 'southwest');
    axis([20 fs/2 -60 20]);

    % Subplot 2: Resulting Impulse Response
    subplot(2, 1, 2);
    plot(timeVectorCentered, 20*log10(abs(fftshift(refinedImpulseResponse))), 'r', "LineWidth", 2);
    hold on;
    plot(timeVectorCentered, 20*log10(abs(fftshift(refinedImpulseResponseRetro))), 'g', "LineWidth", 2);
    grid on;
    title('Resulting Refined Impulse Response');
    set(gca, "FontSize", 13, "LineWidth", 2);
    xlabel('Time (s)');
    ylabel('Amplitude (dB)');
    legend('Refined SG', 'Refined Retro', 'Location', 'northeast');
    axis([-0.01 0.5 -200 9\0]);
    
    % --- Save Plots and Data ---
    print(fullfile(resultsDir, 'refined_TF_and_IR.png'), '-dpng', '-r200');
    disp('Refined transfer function and impulse response plots saved.');
    
    % --- Check with user if the result is satisfactory ---
    userResponse = input('Are these results OK? (Y/N) [Y]: ', 's');
    if isempty(userResponse) || upper(userResponse) == 'Y'
        isResultOK = true;
        disp('Finalizing results.');
        
        % Save the final refined impulse responses as WAV files
        commentTextSG = sprintf("Refined SG IR from %s. F-Range: %.1f-%.1f Hz.", ...
                              fileName, lowFreqLimitFix, highFreqLimitFix);
        audiowrite(fullfile(resultsDir, 'refinedImpulseResponse.wav'), refinedImpulseResponse, fs, ...
            "BitsPerSample", 24, "Comment", commentTextSG);

        commentTextRetro = sprintf("Refined Retro-SG IR from %s. F-Range: %.1f-%.1f Hz.", ...
                              fileName, lowFreqLimitFix, highFreqLimitFix);
        audiowrite(fullfile(resultsDir, 'refinedImpulseResponseRetro.wav'), refinedImpulseResponseRetro, fs, ...
            "BitsPerSample", 24, "Comment", commentTextRetro);
        
        disp('Final refined impulse responses saved as WAV files.');
    else
        disp('Repeating the refinement process...');
        close(gcf); % Close the current figure before the next iteration
    end
end

%% Local Functions
function [taperedTF, originalTF] = applyFrequencyTaper(transferFunction, lowLimit, highLimit, freqVec, fs)
    % This function applies a smooth cosine-based taper to a transfer function
    % to band-limit it between lowLimit and highLimit frequencies.
    
    originalTF = transferFunction; % Keep a copy for comparison
    taperedTF = transferFunction;

    % Create a bilateral frequency vector (-fs/2 to fs/2) for easier indexing
    bilateralFreqVector = freqVec;
    bilateralFreqVector(bilateralFreqVector > fs/2) = bilateralFreqVector(bilateralFreqVector > fs/2) - fs;

    % --- Apply smooth low-frequency roll-off (high-pass) ---
    [~, lowIdxPos] = min(abs(freqVec - lowLimit));
    [~, lowIdxNeg] = min(abs(bilateralFreqVector + lowLimit));
    lowPassRegionPos = freqVec < lowLimit;
    lowPassRegionNeg = bilateralFreqVector > -lowLimit & bilateralFreqVector < 0;
    normFreqDistPos = abs(bilateralFreqVector(lowPassRegionPos)) / lowLimit;
    normFreqDistNeg = abs(bilateralFreqVector(lowPassRegionNeg)) / lowLimit;
    taperedTF(lowPassRegionPos) = ((1 - cos(normFreqDistPos * pi)) / 2) * taperedTF(lowIdxPos);
    taperedTF(lowPassRegionNeg) = ((1 - cos(normFreqDistNeg * pi)) / 2) * taperedTF(lowIdxNeg);

    % --- Apply smooth high-frequency roll-off (low-pass) ---
    [~, highIdxPos] = min(abs(bilateralFreqVector - highLimit));
    [~, highIdxNeg] = min(abs(bilateralFreqVector + highLimit));
    highPassRegionPos = bilateralFreqVector > highLimit;
    highPassRegionNeg = bilateralFreqVector < -highLimit;
    normFreqDistPos = (fs/2 - bilateralFreqVector(highPassRegionPos)) / (fs/2 - highLimit);
    normFreqDistNeg = (-fs/2 - bilateralFreqVector(highPassRegionNeg)) / (fs/2 - highLimit);
    taperedTF(highPassRegionPos) = ((1 - cos(normFreqDistPos * pi)) / 2) * taperedTF(highIdxPos);
    taperedTF(highPassRegionNeg) = ((1 - cos(normFreqDistNeg * pi)) / 2) * taperedTF(highIdxNeg);
end

