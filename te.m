clear all;

% Define desired frequencies for each box (Hz), with 40 different frequencies
desiredFreqs = linspace(5, 15, 40); % Example: linearly spaced frequencies between 5 and 15 Hz

% Assuming a common refresh rate of 60 Hz for simplicity
refreshRate = 60; % Screen refresh rate in Hz
maxduration = 1000; % Define the maximum length of SSVEP display

% Initialize freq patterns
freq = cell(1, length(desiredFreqs));
for i = 1:length(desiredFreqs)
    cycleLength = refreshRate / desiredFreqs(i); % Calculate the number of frames per cycle
    halfCycle = round(cycleLength / 2);
    freq{i} = repmat([zeros(1, halfCycle), ones(1, halfCycle)], 1, ceil(refreshRate / cycleLength));
end

%% Generate display matrices for movies

% Calculate LCM of the lengths of all variables 'freq'
lcmFreq = numel(freq{1});
for i = 2:length(freq)
    lcmFreq = lcm(lcmFreq, numel(freq{i}));
end

% Generate full movie matrix of frequency
freqCombine = zeros(length(freq), lcmFreq);
for i=1:length(freq)
    patternLength = numel(freq{i});
    freqCombine(i,:) = repmat(freq{i}, 1, lcmFreq / patternLength);
end

% Revert value because in Matlab 255 is white and 0 is black
freqCombine = 1 - freqCombine;

try
    % Find my screen index (for PTB to know where to display the animation)
    myScreen = max(Screen('Screens'));

    % Initiate PTB display
    [win, winRect] = Screen('OpenWindow', myScreen, [], [0 0 1500 1500]);

    % Get width and height
    [width, height] = RectSize(winRect);

    % Background color dark green, just to make sure
    Screen('FillRect', win, [0 127 0]);

    %% Make movie
    
    % Define dimensions of the grid
    numRows = 5;
    numCols = 8;

    % Define height and width of the SSVEP rectangles
    targetWidth = width / (numCols + 1); % Adjust for spacing
    targetHeight = height / (numRows + 1); % Adjust for spacing

    % Calculate positions for the rectangles to be aligned in a grid
    rects = zeros(numRows*numCols, 4);
    idx = 1;
    for row = 1:numRows
        for col = 1:numCols
            startX = (col-1) * (targetWidth + 10) + (width - numCols * targetWidth) / (numCols + 1);
            startY = (row-1) * (targetHeight + 10) + (height - numRows * targetHeight) / (numRows + 1);
            rects(idx, :) = [startX, startY, startX + targetWidth, startY + targetHeight];
            idx = idx + 1;
        end
    end

    % Define refresh rate.
    ifi = Screen('GetFlipInterval', win);

    % Define variables for frame timing
    frameCounter = 0;

    % Run in this duration
    deadline = GetSecs + maxduration;

    % Initiate an index that gets updated at every movie loop
    indexflip = 1;

    % Tell computer OS to prioritize this task (to increase time precision)
    Priority(1);

    % Characters to display in each box
    % Characters from A to Z
    charsAZ = char(65:90); % ASCII values for 'A' to 'Z'
    
    % Numbers from 0 to 9
    charsNum = char(48:57); % ASCII values for '0' to '9'
    
    % Special characters for comma, period, newline, and space
    % Since MATLAB doesn't handle an 'enter' key directly in strings, we use newline (\n) as a placeholder.
    % Note: In the context of drawing text on the screen with Psychtoolbox, handling a newline or 'enter' may vary.
    charsSpecial = [',', '.', char(10), ' ']; % char(10) is the newline character in ASCII.
    
    % Combine all characters
    chars = [charsAZ, charsNum, charsSpecial];

    %% Start looping movie: keep looping until 'q' is pressed or time exceeds deadline
    KbName('UnifyKeyNames');
    quitKey = KbName('q');
    while (~KbCheck) && (GetSecs < deadline)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(quitKey)
                break; % Exit loop if 'q' is pressed
            end
        end

        % Compute color for each rectangle based on freqCombine and current indexflip
        for i = 1:numRows*numCols
            color = freqCombine(mod(i-1, length(freq)) + 1, indexflip) * 255;
            Screen('FillRect', win, color, rects(i, :));
            
            desiredTextSize = 40;
            Screen('TextSize', win, desiredTextSize);

            if i <= length(chars)
                text = chars(i); % Display character if within range
            else
                text = ''; % Otherwise, set text to empty
            end
            DrawFormattedText(win, text, 'center', 'center', [0 0 0], [], [], [], [], [], rects(i, :));
        end

        % Flip frame
        Screen('Flip', win);

        % Update number of flips occurring
        indexflip = indexflip + 1;

        % Reset index at the end of freq matrix
        if indexflip > lcmFreq
            indexflip = 1;
        end
    end

    % Change priority back to zero
    Priority(0);

    % Close SSVEP display
    Screen('CloseAll');

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
