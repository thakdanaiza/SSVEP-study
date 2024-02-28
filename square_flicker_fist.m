clear all

% Define frequency to use (1=black; 0=white)
seven_five =        [0 0 0 0 1 1 1 1]; % 7.5 Hz
ten =               [0 0 0 1 1 1]; % 10.0 Hz
six_six =           [0 0 0 0 1 1 1 1 1]; % 6.6 Hz       
eight_fiveseven =   [0 0 0 1 1 1 1]; % 8.57 Hz 

% Create freq table
freq{1} = six_six;  
freq{2} = seven_five;
freq{3} = eight_fiveseven; 
freq{4} = ten;

%% Generate display matrices for movies

% Find LCM (least common multiple) of the lengths of all variables 'freq'
lcmFreq = lcm(lcm(length(freq{1}), length(freq{2})), lcm(length(freq{3}), length(freq{4})));

% Generate full movie matrix of frequency
for i=1:4
    freqCombine(i,:) = repmat(freq{i}, 1, lcmFreq/length(freq{i}));
end

% Revert value because in Matlab 255 is white and 0 is black
freqCombine = 1 - freqCombine;

% Define the maximum length of SSVEP display (we don't want it keep going forever)
maxduration = 1000;

try
    % Find my screen index (for PTB to know where to display the animation)
    myScreen = max(Screen('Screens'));

    % Initiate PTB display
    [win, winRect] = Screen('OpenWindow', myScreen, [], [0 0 900 900]);

    % Get width and height
    [width, height] = RectSize(winRect);

    % Background color dark green, just to make sure
    Screen('FillRect', win, [0 127 0]);

    %% Make movie
    
    % Define height and width of the SSVEP rectangles, doubled size
    targetWidth = 200; % Doubled
    targetHeight = 200; % Doubled

    % Calculate positions for the rectangles to be centered and aligned horizontally
    gap = 50; % Gap between rectangles
    totalWidth = 4 * targetWidth + 3 * gap; % Total width of all rectangles including gaps
    startX = (width - totalWidth) / 2; % Starting X position to center rectangles
    startY = (height - targetHeight) / 2; % Starting Y position to center rectangles vertically
    
    % Rectangles positions
    for i = 1:4
        rectX = startX + (i-1) * (targetWidth + gap);
        rects(i, :) = [rectX, startY, rectX + targetWidth, startY + targetHeight];
    end

    % Define refresh rate.
    ifi = Screen('GetFlipInterval', win);

    % Define variables for frame timing
    frameCounter = 0;
    changeFrame = 600; % 10 seconds at 60 Hz refresh rate

    % Run in this duration
    deadline = GetSecs + maxduration;

    % Initiate an index that gets updated at every movie loop
    indexflip = 1;
    currentRect = 1; % Current rectangle to highlight

    % Tell computer OS to prioritize this task (to increase time precision)
    Priority(1);

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
        for i = 1:4
            color = freqCombine(i, indexflip) * 255;
            Screen('FillRect', win, color, rects(i, :));
            
            % Add text to each rectangle
            Screen('TextSize', win, 20); % Set text size
            text = sprintf('Freq %d', i); % Create text string
            DrawFormattedText(win, text, 'center', 'center', [0 0 0], [], [], [], [], [], rects(i, :));
        end

        % Highlight the current rectangle with red border
        Screen('FrameRect', win, [255, 0, 0], rects(currentRect, :), 5);

        % Flip frame
        Screen('Flip', win);

        % Update number of flips occurring
        indexflip = indexflip + 1;

        % Increment frame counter and check if it's time to change the highlighted rectangle
        frameCounter = frameCounter + 1;
        if frameCounter >= changeFrame
            frameCounter = 0; % Reset counter
            currentRect = mod(currentRect, 4) + 1; % Move to next rectangle, wrap around after the 4th
        end

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
