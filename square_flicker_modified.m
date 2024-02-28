% borrowed and adapted from: https://github.com/bobvo23/flicker_stimulator

% function square_flicker_modified()

clear all
close all

%% Lab streaming layer
% Load LSL library
lib = lsl_loadlib();

% Create a new stream info (here we name the stream 'MyMarkerStream', with type 'Markers', 
% 1 channel, nominal rate of 0, and we set the channel format to be strings, and source_id can be any unique identifier)
info = lsl_streaminfo(lib, 'MyMarkerStream', 'Markers', 1, 0, 'cf_string', 'event_marker_matlab');

% Create an outlet to send out markers
outlet = lsl_outlet(info);

%%
AssertOpenGL;

Screen('Preference', 'SkipSyncTests', 1);

% Define frequency to use
f(1) = 8;
f(2) = 10;
f(3) = 12;
f(4) = 14;

% Create freq table
for i=1:numel(f)
    freqCombine(i,:) = freqApproxMethod(f(i));
end

% Define the maximum length of SSVEP display (we don't want it keep going forever)
maxduration = 1000;

% Find my screen index (for PTB to know where to display the animation)
myScreen = max(Screen('Screens'));
% myScreen = 0;

% Initiate PTB display (specify display size [0 0 1000 900]) 
[win,winRect] =   Screen(myScreen,'OpenWindow',[],[0 0 1000 900]);
% [win,winRect] =   Screen(myScreen,'OpenWindow');

% Get width and height
[width, height] = RectSize(winRect);

% Background color dark green, just to make sure
Screen('FillRect',win,[0 127 0]);

%% Define cues
% Define cue location
cue_r = 105;
cue_locs = [height*1/3, width*1/3; ...
    height*1/3, width*2/3; ...
    height*2/3, width*1/3;...
    height*2/3, width*2/3];

% Cue rects
for i=1:4
    cue_rects(i,:) = [cue_locs(i,2)-cue_r, cue_locs(i,1)-cue_r, cue_locs(i,2)+cue_r, cue_locs(i,1)+cue_r];
end

% Define cue sequence
cue_sequence = repmat(1:4,1,3); % Repeat each cue 3 times
cue_sequence = Shuffle(cue_sequence);

% Define cue duration for each SSVEP trial (e.g., 4 secs)
cue_dur = 4;
nFlips_per_cue = cue_dur * 60; % since refresh rate = 60 frames per sec
nFlips_all = nFlips_per_cue * numel(cue_sequence);

% Define positions for cue text
cueText_rects(:,1) = cue_rects(:,1) + 80;
cueText_rects(:,2) = cue_rects(:,2) + 110;

% Define deadline based on cue_dur_nFlips
% deadline = GetSecs + nFlips_per_cue + 5;

%% Make movie

% make textures clipped to screen size
% Draw texture to screen: Draw 16 states or texture depens on the value of
screenMatrix = flickerTexture_modified(width, height);

% Create texture
for  i =1:16
    texture(i) = Screen('MakeTexture', win, uint8(screenMatrix{i})*255);
end

% Define refresh rate.
ifi = Screen('GetFlipInterval', win);

% Preview SSVEP squares briefly before starting movie
Screen('DrawTexture',win,texture(16));
VBLTimestamp = Screen('Flip', win, ifi);

% Wait 2 secs
WaitSecs(2);

% Initiate an index for keeping count of elements in freqCombine
freqCombine_ind = 1;

% Index for counting number of cues presented in the exp.
cue_count = 1;

% Index for counting number of loops
cue_ind = 0;

% Tell computer OS to prioritize this task (to increase time precision)
Priority(1);

%% Start looping movie: keep looping until any key is pressed (KbCheck) or time exceeds deadline

while (~KbCheck) && (cue_count < numel(cue_sequence))

    % Compute texture value based on an index and freq long matrixes
    textureValue = freqCombine(:, freqCombine_ind) .* [1; 2; 4; 8];
    textureValue = textureValue(4)+textureValue(3)+textureValue(2)+ textureValue(1) +1;

    % Draw frame
    Screen('DrawTexture',win,texture(textureValue));

    % Draw cue
    Screen('FrameRect',win,[255 0 0],cue_rects(cue_sequence(cue_count),:),10);

    % Tell PTB that drawing commands for the current frame have been completed
    Screen('DrawingFinished', win);

    % Draw text
    DrawFormattedText(win, 'go', cueText_rects(1,1), cueText_rects(1,2), [0 0 0]);
    DrawFormattedText(win, 'stop', cueText_rects(2,1), cueText_rects(2,2), [0 0 0]);
    DrawFormattedText(win, 'kick', cueText_rects(3,1), cueText_rects(3,2), [0 0 0]);
    DrawFormattedText(win, 'punch', cueText_rects(4,1), cueText_rects(4,2), [0 0 0]);

    % Flip frame
    Screen('Flip', win);

    % Send LSL marker
    if cue_ind <= 1
        marker = ['cue_' num2str(cue_sequence(cue_count))];
        outlet.push_sample({marker});
        disp('marker sent')
    end
    
    % Update indices
    freqCombine_ind = freqCombine_ind+1;
    cue_ind = cue_ind + 1;

    % If cue_ind reaches nFlips per cue, update cue_count and reset cue_ind
    if cue_ind >= nFlips_per_cue
        cue_count = cue_count + 1;
        cue_ind = 1;
    end

    % Reset index at the end of freq matrix
    if freqCombine_ind > size(freqCombine,2)
        freqCombine_ind = 1;
    end
end

% Change priority back to zero
Priority(0);

% How long does it take for PTB to flip from one frame to the next
frame_duration = Screen('GetFlipInterval', win);

% Close SSVEP display
Screen('CloseAll');
Screen('Close');
