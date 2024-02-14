clear all

% Define desired frequencies for each box (Hz)
desiredFreqs = [6.6, 7.5, 8.57, 10]; % Example frequencies in Hz

% Generate frequency patterns based on desired frequencies
% Assuming a common refresh rate of 60 Hz for simplicity
refreshRate = 60; % Screen refresh rate in Hz
maxduration = 1000; % Define the maximum length of SSVEP display

% Initialize freq patterns
freq = cell(1, length(desiredFreqs));

for i = 1:length(desiredFreqs)
    cycleLength = refreshRate / desiredFreqs(i); % Calculate the number of frames per cycle
    halfCycle = round(cycleLength / 2);
    freq{i} = [zeros(1, halfCycle), ones(1, halfCycle)];
    %
end
disp(freq{1});
%% The rest of the code for setting up Psychtoolbox window and displaying the stimuli remains the same.
