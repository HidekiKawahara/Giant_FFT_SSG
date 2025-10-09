%% Single-Channel Signal Safeguarding Acoustic Test Script (oneShotSGforMonoInput.m)
%
% This script is a single-channel version of the acoustic test for the
% "Signal Safeguarding" audio processing idea. It performs the following steps:
%   1. Loads a reference audio signal (.wav file).
%   2. Prompts for processing parameters and the I/O device.
%   3. Applies the signal safeguarding algorithm to the reference signal.
%   4. Plays and records both the original and safeguarded signals using a
%      single-channel (mono) audio input.
%   5. Calculates the system impulse response (IR) for both cases.
%   6. Interactively refines the measured frequency response.
%   7. Automatically optimizes the retrospective safeguarding threshold.
%   8. Saves all analysis plots and final impulse responses to a unique directory.
%
% Required helper functions:
%   - signalSafeguardwithGiantFFTSRC.m
%   - basicPlayRecLoopMono.m
% Copyright 2025 Hideki Kawahara
% Author: Hideki Kawahara
% Version: 2.0 (Final) - Refined structure, comments, and added optimization.
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
% Initialize the audio player/recorder object.
try
    playerRecorder = audioPlayerRecorder("SampleRate", fs, "BitDepth", ...
        "24-bit integer");
catch ME
    disp(['Error initializing audio player/recorder: ', ME.message]);
    disp('Please ensure a valid audio device is connected and configured.');
    return;
end
% Get and display a list of available audio devices
availableDevices = getAudioDevices(playerRecorder);
disp('Available Audio Devices:');
disp(availableDevices);

% --- Create a unique directory for saving results ---
% Using a timestamp ensures that results from different runs are not overwritten.
timestamp = datetime('now', 'format', 'yyyyMMdd_HHmmss');
resultsDir = "oneShotSG_Test_" + string(timestamp);
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
ioResultsSG = basicPlayRecLoopMono(fs, safeguardedSignal, selectedDeviceName);
disp('I/O for safeguarded signal complete.');

% --- Play and record the ORIGINAL (RAW) signal ---
disp('Performing I/O loop for the ORIGINAL signal...');
ioResultsRaw = basicPlayRecLoopMono(fs, originalSignal, selectedDeviceName);
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
disp('Calculating impulse responses...');
% IR for the safeguarded signal playback
impulseResponseSG = ifft(fft(recordedSignalSG) ./ fft(playbackSignalSG));
% IR for the raw signal playback, referenced to the safeguarded signal's
% spectrum. This is for the "Retro-Safeguard" comparison.
impulseResponseRetroSG = ifft(fft(recordedSignalRaw) ./ fft(playbackSignalSG));
disp('Impulse response calculation complete.');

%% 7. Initial Time-Domain Analysis and Plotting
% --- Plot Impulse Response from Safeguarded Signal ---
figure('Name', 'Impulse Response (Safeguarded)');
timeVector = (0:numSamples-1)' / fs;
plot(timeVector(1:fs), 20*log10(abs(impulseResponseSG(1:fs, :))), "LineWidth", 2);
grid on;
title('Initial Impulse Response from Safeguarded Signal Playback');
xlabel('Time (s)');
ylabel('Level (dB)');
axis([0 1 -100 0]);
set(gca, "FontSize", 13, "LineWidth", 2);
print(fullfile(resultsDir, 'initial_impulse_response_SG.png'), '-dpng', '-r200');

% --- Plot Comparison of Initial Impulse Responses ---
figure('Name', 'Initial Impulse Response Comparison');
plot(timeVector(1:fs), 20*log10(abs(impulseResponseRetroSG(1:fs,:))), "LineWidth", 2);
hold on;
plot(timeVector(1:fs), 20*log10(abs(impulseResponseSG(1:fs,:))), "LineWidth", 2);
hold off;
grid on;
title('Initial Impulse Response Comparison');
xlabel('Time (s)');
ylabel('Level (dB)');
axis([0 1 -100 0]);
legend("Retro-SG", "SG");
set(gca, "FontSize", 13, "LineWidth", 2);
print(fullfile(resultsDir, 'initial_impulse_response_comparison.png'), '-dpng', '-r200');

%% 8. Initial Frequency-Domain Analysis
disp('Analyzing frequency responses...');
% --- Define windowing parameters for IR analysis ---
IR_PRE_DELAY_S = 0.05;       % Time before the main peak to start the window (seconds)
IR_WINDOW_DURATION_S = input("Input plausible length of the impulse response (seconds): ");

% --- Find the main peak of the direct-path sound ---
[~, peakIndex] = max(abs(impulseResponseSG));

% --- Define sample indices for the LTI and noise parts ---
ltiStartSample = peakIndex - round(IR_PRE_DELAY_S * fs);
irWindowLengthSamples = round(IR_WINDOW_DURATION_S * fs);
ltiSampleIndices = ltiStartSample + (0:irWindowLengthSamples-1);
% For the "noise" part, take a window from the middle of the IR
noiseSampleIndices = round(numSamples/2) + (0:irWindowLengthSamples-1);

% --- Calculate spectra for different parts of the IRs ---
frequencyVector = (0:numSamples-1)' / numSamples * fs;
% Spectra for the SAFEGUARDED measurement
ltiSpectrumComplexSG = fft(impulseResponseSG(ltiSampleIndices), numSamples);
noiseSpectrumComplexSG = fft(impulseResponseSG(noiseSampleIndices), numSamples);
% Spectra for the RETRO-SAFEGUARDED measurement
ltiSpectrumComplexRetroSG = fft(impulseResponseRetroSG(ltiSampleIndices), numSamples);
noiseSpectrumComplexRetroSG = fft(impulseResponseRetroSG(noiseSampleIndices), numSamples);
% Convert spectra to decibels for plotting
ltiSpectrumDbSG = 20*log10(abs(ltiSpectrumComplexSG));
noiseSpectrumDbSG = 20*log10(abs(noiseSpectrumComplexSG));
ltiSpectrumDbRetroSG = 20*log10(abs(ltiSpectrumComplexRetroSG));
noiseSpectrumDbRetroSG = 20*log10(abs(noiseSpectrumComplexRetroSG));

%% 9. Initial Frequency-Domain Plotting
% --- Plot Frequency Response of SAFEGUARDED Measurement ---
figure('Name', 'Initial Frequency Response (Safeguarded)');
plot(frequencyVector, ltiSpectrumDbSG, "LineWidth", 2);
hold on;
plot(frequencyVector, noiseSpectrumDbSG, "LineWidth", 2, 'LineStyle', '--');
xline(safeguardParams.fLow, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
xline(safeguardParams.fHigh, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
hold off;
grid on;
set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
axis([20 fs/2 [-70 10] + max(ltiSpectrumDbSG(:))]);
title(['Initial Frequency Response (Safeguarded) | Threshold: ' num2str(thresholdDb) ' dB']);
xlabel("Frequency (Hz)");
ylabel("Level (dB)");
legend("LTI System Response","Noise Floor", "Location", "northwest");
print(fullfile(resultsDir, 'initial_freq_response_SG.png'), '-dpng', '-r200')

% --- Plot Frequency Response of RETRO-SAFEGUARDED Measurement ---
figure('Name', 'Initial Frequency Response (Retro-Safeguarded)');
plot(frequencyVector, ltiSpectrumDbRetroSG, "LineWidth", 2);
hold on;
plot(frequencyVector, noiseSpectrumDbRetroSG, "LineWidth", 2, 'LineStyle', '--');
xline(safeguardParams.fLow, 'g', 'LineWidth', 2, 'Label', 'Low Freq Limit');
xline(safeguardParams.fHigh, 'g', 'LineWidth', 2, 'Label', 'High Freq Limit');
hold off;
grid on;
set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
axis([20 fs/2 [-70 10] + max(ltiSpectrumDbRetroSG(:))]);
title(['Initial Frequency Response (Retro-Safeguarded) | Threshold: ' num2str(thresholdDb) ' dB']);
xlabel("Frequency (Hz)");
ylabel("Level (dB)");
legend("LTI System Response","Noise Floor", "Location", "northwest");
print(fullfile(resultsDir, 'initial_freq_response_RetroSG.png'), '-dpng', '-r200');
disp('Initial analysis complete. Starting interactive refinement...');

%% 10. Interactive System Response Refinement
% This section allows for iterative shaping of the measured system response.
% The goal is to create a clean, band-limited impulse response by applying
% smooth tapers to the frequency response spectrum.

isResultOK = false; % Use a boolean flag for the loop condition
while ~isResultOK
    % --- Get frequency limits for shaping from the user ---
    disp('Enter frequency limits to refine the system response.');
    lowFreqLimitFix = input('Enter the desired LOW frequency limit (Hz): ');
    highFreqLimitFix = input('Enter the desired HIGH frequency limit (Hz): ');
    
    % --- Input validation ---
    if lowFreqLimitFix >= highFreqLimitFix
        warning('Low frequency limit must be less than high frequency limit. Please try again.');
        continue; % Skip to the next loop iteration
    end
    
    % --- Apply frequency tapering to both system responses using a local function ---
    [taperedSpectrumSG, originalSpectrumSG] = applyFrequencyTaper(ltiSpectrumComplexSG, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);
    [taperedSpectrumRetro, ~] = applyFrequencyTaper(ltiSpectrumComplexRetroSG, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);
    
    % --- Calculate the refined impulse responses ---
    refinedImpulseResponse = ifft(taperedSpectrumSG, 'symmetric');
    refinedImpulseResponseRetro = ifft(taperedSpectrumRetro, 'symmetric');
    
    % --- Plotting Results for Verification ---
    figure('Name', 'Refined System Response and Impulse Response');
    
    % Subplot 1: Frequency Response Comparison
    subplot(2, 1, 1);
    plot(frequencyVector, 20*log10(abs(originalSpectrumSG)), 'LineWidth', 1.5, 'Color', [0.7 0.7 0.7]);
    hold on;
    plot(frequencyVector, 20*log10(abs(taperedSpectrumRetro)), 'g', 'LineWidth', 2);
    plot(frequencyVector, 20*log10(abs(taperedSpectrumSG)), 'r', 'LineWidth', 2);
    grid on;
    xline(lowFreqLimitFix, 'k--', 'LineWidth', 1);
    xline(highFreqLimitFix, 'k--', 'LineWidth', 1);
    set(gca, 'XScale', 'log', "FontSize", 13, "LineWidth", 2);
    title(['Refined System Response | Freq Range: ' num2str(lowFreqLimitFix) ' - ' num2str(highFreqLimitFix) ' Hz']);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    legend('Original SG', 'Refined Retro', 'Refined SG', 'Location', 'southwest');
    axis([20 fs/2 [-80 20] + max(ltiSpectrumDbSG(:))]);
    
    % Subplot 2: Resulting Impulse Response (in dB)
    subplot(2, 1, 2);
    plot(timeVector, 20*log10(abs(refinedImpulseResponse)), 'r', "LineWidth", 2);
    hold on;
    plot(timeVector, 20*log10(abs(refinedImpulseResponseRetro)), 'g', "LineWidth", 2);
    grid on;
    title('Resulting Refined Impulse Response');
    set(gca, "FontSize", 13, "LineWidth", 2);
    xlabel('Time (s)');
    ylabel('Amplitude (dB)');
    legend('Refined SG', 'Refined Retro', 'Location', 'northeast');
    axis([0 min(5, numSamples/fs) -200 0]);
    
    % --- Save Plots and Data ---
    print(fullfile(resultsDir, 'refined_FreqResp_and_IR.png'), '-dpng', '-r200');
    disp('Refined response and impulse response plots saved.');
    
    % --- Check with user if the result is satisfactory ---
    userResponse = input('Are these results OK? (Y/N) [Y]: ', 's');
    if isempty(userResponse) || upper(userResponse) == 'Y'
        isResultOK = true;
        disp('Finalizing results from interactive session.');
        
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
        disp('NOTE: If script execution pauses here, use "Continue" (F5) or run the next cell.');
        break
    else
        disp('Repeating the refinement process...');
        close(gcf); % Close the current figure before the next iteration
    end
end

%% 11. Optimize Retrospective Safeguarding Parameters
% This section automates the search for the optimal safeguarding threshold
% for the retrospective method. It iterates through a range of thresholds,
% calculating the error between the resulting retro-IR and the reference SG-IR
% from the interactive section.

disp('Starting optimization of retrospective safeguarding parameters...');
% Define a time-domain window for comparing impulse responses, centered on the main peak.
selIdx = timeVector>IR_PRE_DELAY_S - 0.01 & timeVector < IR_WINDOW_DURATION_S;

displayOn = false; % Suppress plots during the loop
thresholdDbList = 0:-2:-40;
sgErrorLevel = zeros(length(thresholdDbList),1);

% --- Loop over all thresholds to find the best one ---
fprintf('Testing %d threshold levels...', length(thresholdDbList));
for jj = 1:length(thresholdDbList)
    % 1. Generate the safeguarded signal for the current threshold
    [safeguardedSignal, ~] = ...
        signalSafeguardwithGiantFFTSRC(originalSignal, fs, fs, ...
        thresholdDbList(jj), highFreqLimitHz, displayOn);
    
    % 2. Calculate the retrospective impulse response
    impulseResponseRetroSG_loop = ifft(fft(recordedSignalRaw) ./ fft(safeguardedSignal));
    
    % 3. Extract and taper the system response spectrum
    ltiSpectrumComplexRetroSG_loop = fft(impulseResponseRetroSG_loop(ltiSampleIndices), numSamples);
    [taperedSpectrumRetro_loop, ~] = applyFrequencyTaper(ltiSpectrumComplexRetroSG_loop, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);
    refinedImpulseResponseRetro_loop = ifft(taperedSpectrumRetro_loop, 'symmetric');
    
    % 4. Find the optimal scaling factor and calculate the minimum error.
    % This inner loop finds a small magnitude correction (e.g., +/-10%) for the
    % best fit, which makes the error comparison more robust against tiny gain differences.
    magList = 0.9:0.001:1.1;
    errLevel = zeros(length(magList),1);
    for ii = 1:length(magList)
        errLevel(ii) = std(refinedImpulseResponseRetro_loop(selIdx) * magList(ii) ...
            - refinedImpulseResponse(selIdx)) / std(refinedImpulseResponse(selIdx));
    end
    sgErrorLevel(jj) = 20 * log10(min(errLevel));
    fprintf('.');
end
fprintf('\nOptimization complete.\n');

% --- Plot the error curve from the optimization ---
figure('Name', 'Retrospective Threshold Optimization');
plot(thresholdDbList, sgErrorLevel, '-o', "LineWidth", 2);
grid on;
title('Optimization of Retrospective SG Threshold');
xlabel('Safeguarding Threshold (dB)');
ylabel('Relative Error (dB vs. Refined SG)');
set(gca, "FontSize", 13, "LineWidth", 2);
print(fullfile(resultsDir, 'retrospective_optimization_error.png'), '-dpng', '-r200');

% --- Recalculate and plot the final results using the BEST threshold ---
[~,bestIdx] = min(sgErrorLevel);
bestThresholdDb = thresholdDbList(bestIdx);
disp(['Optimal retrospective threshold found: ' num2str(bestThresholdDb) ' dB']);

[safeguardedSignal, safeguardParams] = ...
    signalSafeguardwithGiantFFTSRC(originalSignal, fs, fs, ...
    bestThresholdDb, highFreqLimitHz, displayOn);
impulseResponseRetroSG = ifft(fft(recordedSignalRaw) ./ fft(safeguardedSignal));
ltiSpectrumComplexRetroSG = fft(impulseResponseRetroSG(ltiSampleIndices), numSamples);
[taperedSpectrumRetro, ~] = applyFrequencyTaper(ltiSpectrumComplexRetroSG, lowFreqLimitFix, highFreqLimitFix, frequencyVector, fs);
refinedImpulseResponseRetro = ifft(taperedSpectrumRetro, 'symmetric');

% --- Create the final comparison plot ---
figure('Name', 'Best Retrospective Result');
% Subplot 1: Frequency Response Comparison
subplot(2, 1, 1);
semilogx(frequencyVector, 20*log10(abs(originalSpectrumSG)), 'LineWidth', 1.5, 'Color', [0.7 0.7 0.7]);
hold on;
semilogx(frequencyVector, 20*log10(abs(taperedSpectrumRetro)), 'g', 'LineWidth', 2);
semilogx(frequencyVector, 20*log10(abs(taperedSpectrumSG)), 'r', 'LineWidth', 2);
grid on;
xline(lowFreqLimitFix, 'k--', 'LineWidth', 1);
xline(highFreqLimitFix, 'k--', 'LineWidth', 1);
set(gca, "FontSize", 13, "LineWidth", 2);
title(['Best Retrospective Response (Threshold: ' num2str(bestThresholdDb) ' dB)']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
legend('Original SG', 'Best Retro', 'Refined SG', 'Location', 'southwest');
axis([20 fs/2 [-80 20] + max(ltiSpectrumDbSG(:))]);

% Subplot 2: Resulting Impulse Response (in dB)
subplot(2, 1, 2);
plot(timeVector, 20*log10(abs(refinedImpulseResponse)), 'r', "LineWidth", 2);
hold on;
plot(timeVector, 20*log10(abs(refinedImpulseResponseRetro)), 'g', "LineWidth", 2);
grid on;
title('Comparison of Best Resulting Impulse Responses');
set(gca, "FontSize", 13, "LineWidth", 2);
xlabel('Time (s)');
ylabel('Amplitude (dB)');
legend('Refined SG', 'Best Retro', 'Location', 'northeast');
axis([0 min(5, numSamples/fs) -200 0]);

% --- Save Final Plots and Data ---
print(fullfile(resultsDir, 'best_FreqResp_and_IR.png'), '-dpng', '-r200');
disp('Best response and impulse response plots saved.');

commentTextBestRetro = sprintf("Best Retro-SG IR from %s. Best Thr: %.1fdB. F-Range: %.1f-%.1f Hz.", ...
    fileName, bestThresholdDb, lowFreqLimitFix, highFreqLimitFix);
audiowrite(fullfile(resultsDir, 'bestImpulseResponseRetro.wav'), refinedImpulseResponseRetro, fs, ...
    "BitsPerSample", 24, "Comment", commentTextBestRetro);
disp('Best retrospective impulse response saved as WAV file.');

save(fullfile(resultsDir, 'best_SG_params.mat'),"safeguardParams");
disp('Best retrospective SG parameters saved.');
disp('--- Script Finished ---');

%% Local Functions
function [taperedSpectrum, originalSpectrum] = applyFrequencyTaper(inputSpectrum, lowCut, highCut, freqVec, fs)
    % This function applies a smooth cosine-based taper to a frequency spectrum
    % to band-limit it between lowCut and highCut frequencies.
    
    originalSpectrum = inputSpectrum; % Keep a copy for comparison
    taperedSpectrum = inputSpectrum;
    % Create a bilateral frequency vector (-fs/2 to fs/2) for easier indexing
    bilateralFreqVector = freqVec;
    bilateralFreqVector(bilateralFreqVector > fs/2) = bilateralFreqVector(bilateralFreqVector > fs/2) - fs;
    % --- Apply smooth low-frequency roll-off (high-pass) ---
    [~, lowIdxPos] = min(abs(freqVec - lowCut));
    [~, lowIdxNeg] = min(abs(bilateralFreqVector + lowCut));
    lowPassRegionPos = freqVec < lowCut;
    lowPassRegionNeg = bilateralFreqVector > -lowCut & bilateralFreqVector < 0;
    normFreqDistPos = abs(bilateralFreqVector(lowPassRegionPos)) / lowCut;
    normFreqDistNeg = abs(bilateralFreqVector(lowPassRegionNeg)) / lowCut;
    taperedSpectrum(lowPassRegionPos) = ((1 - cos(normFreqDistPos * pi)) / 2) * taperedSpectrum(lowIdxPos);
    taperedSpectrum(lowPassRegionNeg) = ((1 - cos(normFreqDistNeg * pi)) / 2) * taperedSpectrum(lowIdxNeg);
    % --- Apply smooth high-frequency roll-off (low-pass) ---
    [~, highIdxPos] = min(abs(bilateralFreqVector - highCut));
    [~, highIdxNeg] = min(abs(bilateralFreqVector + highCut));
    highPassRegionPos = bilateralFreqVector > highCut;
    highPassRegionNeg = bilateralFreqVector < -highCut;
    normFreqDistPos = (fs/2 - bilateralFreqVector(highPassRegionPos)) / (fs/2 - highCut);
    normFreqDistNeg = (-fs/2 - bilateralFreqVector(highPassRegionNeg)) / (fs/2 - highCut);
    taperedSpectrum(highPassRegionPos) = ((1 - cos(normFreqDistPos * pi)) / 2) * taperedSpectrum(highIdxPos);
    taperedSpectrum(highPassRegionNeg) = ((1 - cos(normFreqDistNeg * pi)) / 2) * taperedSpectrum(highIdxNeg);
end
