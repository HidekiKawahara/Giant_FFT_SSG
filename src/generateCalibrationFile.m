%[text] # Generate one-octave wide sum of sinusoids for sound pressure level calibration
%[text:tableOfContents]{"heading":"目次"}
%[text] ## Select the sampling rate
close all
clear variables
fs = 48000; %[control:dropdown:114f]{"position":[6,11]}
disp(fs); %[output:54742c1e]
%%
tic;
tt = (1:fs)'/fs;
fc = 1000; % center frequency
fcList = round(fc*2^(-1/2)):round(fc*2^(1/2));
x = zeros(fs,1);
for ii = 1:length(fcList)
    x = x + sin(2*pi*(fcList(ii)*tt+rand));
end
x = x/std(x)*0.1;
toc %[output:78fc7475]
fName = "oneOct1sSS"+num2str(fs)+"Hz.wav";
audiowrite(fName,x,fs,"BitsPerSample",24);

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[control:dropdown:114f]
%   data: {"defaultValue":"8000","itemLabels":["8000","10000","12000","16000","20000","22050","32000","44100","48000","88200","96000","176400","192000"],"items":["8000","10000","12000","16000","20000","22050","32000","44100","48000","88200","96000","176400","192000"],"label":"Sampling rate","run":"Section"}
%---
%[output:54742c1e]
%   data: {"dataType":"text","outputData":{"text":"       48000\n\n","truncated":false}}
%---
%[output:78fc7475]
%   data: {"dataType":"text","outputData":{"text":"経過時間は 0.121985 秒です。\n","truncated":false}}
%---
