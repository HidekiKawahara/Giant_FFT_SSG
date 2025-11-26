function output = constantQgaussBPFweight(frequencyAxis, bandWidthInOctave, stepInOctave)
% constantQgaussBPFweight  Gaussian bandpass weights on a log-frequency axis
%
% This implementation is NOT a standard constant-Q design; it follows the
% giant-FFT / SRC inspired approach from the provided code.
%
% Inputs:
%   frequencyAxis     - vector of analysis frequencies (Hz), ascending
%   bandWidthInOctave - bandwidth expressed in octaves (scalar)
%   stepInOctave      - channel spacing in octaves (scalar)
%
% Output (struct):
%   nChannel            - number of filter channels
%   filterWeight        - matrix (nChannel x nFreq) of normalized weights
%   filterWeight        - matrix (nChannel x nFreq) of raw weights
%   quadfilterWeight    - weights for fitering using quadrature response
%   fcSet               - vector of center frequencies (Hz) for channels
%   bandWidthInOctave   - same as input
%   stepInOctave        - same as input
%   elapsedTime         - runtime in seconds

% Start timer
startTimer = tic();

% Basic input validation
narginchk(3,3);
validateattributes(frequencyAxis, {'numeric'}, {'vector','real','nonnegative','nonempty'});
validateattributes(stepInOctave, {'numeric'}, {'scalar','real','positive'});
validateattributes(bandWidthInOctave, {'numeric'}, {'scalar','real','positive'});

% Ensure column vector for frequency axis
frequencyAxis = frequencyAxis(:);
nFreq = numel(frequencyAxis);

% Compute an effective sampling upper limit `fs` consistent with original code.
% Original used: fs = freguencyAx(end) + freguencyAx(2)
% (preserves the original behavior; keep same here)
if nFreq < 2
    error('frequencyAxis must contain at least two elements.');
end
fsEstimate = frequencyAxis(end) + frequencyAxis(2);

% Log-frequency axis (base-2)
logFreq = log2(frequencyAxis);

% Determine center frequencies (fcSet)
fcLow = 1000*2^(-6); % lowest center frequency, preserved from original code
maxOctaveIndex = log2(fsEstimate/2 / fcLow);
octaveIndices = 0:stepInOctave:maxOctaveIndex;
fcSet = fcLow * 2.0 .^ octaveIndices;
nChannel = numel(fcSet);

% Gaussian sigma in log-frequency units:
% original used: baseSigm = norminv(0.75)*2; sigm = bandWidth/2/baseSigm;
% Keep same numeric relation; provide fallback if norminv is unavailable.
if exist('norminv','file') == 2
    baseSigma = norminv(0.75) * 2;
else
    % norminv(0.75) = sqrt(2) * erfinv(0.5)
    baseSigma = sqrt(2) * erfinv(0.5) * 2;
end
sigmaLog = bandWidthInOctave / 2 / baseSigma;

% Pre-allocate filter weight matrix (frequency x channel)
filterWeight = zeros(nFreq, nChannel);
filterWeightRaw = zeros(nFreq, nChannel);

% Build Gaussian weights on the log-frequency axis and normalize per channel
for ch = 1:nChannel
    centerLog = log2(fcSet(ch));
    % Gaussian in log2-frequency domain
    g = exp(-((logFreq - centerLog).^2) / (2 * sigmaLog^2));
    % Normalize each column to sum to 1 (preserves relative energy per channel)
    filterWeightRaw(:, ch) = g;
    g = g / sum(g);
    filterWeight(:, ch) = g;
end

% Prepare output: transpose filterWeight to match original (nChannel x nFreq)
output.nChannel = nChannel;
output.filterWeight = filterWeight';
output.filterWeightRaw = filterWeightRaw';
output.quadfilterWeight = sqrt(abs(filterWeightRaw));
output.fcSet = fcSet;
output.bandWidthInOctave = bandWidthInOctave;
output.stepInOctave = stepInOctave;
output.elapsedTime = toc(startTimer);
end
