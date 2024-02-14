function [flickerTexture]=flickerTexture(winWidth,winHeight,targetWidth,targetHeight)

%% Generate matrix for 4 target (Top, Right, Down, Left)

% Create empty targetMatrices
for i=1:5
    targetMatrix{i} = zeros(winHeight,winWidth,'uint8');
end

%conver maxtrix from zero to target
%     00100 Top
%     10001 Left/Right
%     00100 Down

for i =1:winHeight
    for j=1:winWidth

        % Target1 : Top --> targetMatrix{1}
        if (j>=(winWidth/2-targetWidth/2)) && (j<=winWidth/2+targetWidth/2) && (i<=targetHeight)
            targetMatrix{1}(i,j)=1;  
        end

        % Target3 : Down  --> targetMatrix{3}
        if (j>=(winWidth/2-targetWidth/2)) && (j<=winWidth/2+targetWidth/2) && (i>=(winHeight-targetHeight))
            targetMatrix{3}(i,j)=1; 
        end

        % Target2 : Right --> targetMatrix{2}
        if (j>=(winWidth-targetWidth)) && (i>=(winHeight/2-targetHeight/2)) && (i<=(winHeight/2+targetHeight/2))
            targetMatrix{2}(i,j)=1;
        end
        
        % Target4 : Left --> targetMatrix{4}
        if (j<= (targetWidth)) && (i>=(winHeight/2-targetHeight/2)) && (i<=(winHeight/2+targetHeight/2))
            targetMatrix{4}(i,j)=1;
        end

    end
end

%% Draw texture to screen: Draw 16 textures depending on the values of targetState
for targetState1=1:2
    for targetState2=1:2
        for targetState3=1:2
            for targetState4=1:2
                
                % Dfine textureNumber
                textureNumber = (targetState4-1)*8 + (targetState3-1)*4 + (targetState2-1)*2 + (targetState1-1)*1 + 1;
                 
                % Create screenMatrix
                screenMatrix{textureNumber} = targetMatrix{5} | targetMatrix{1}*uint8(targetState1-1) |...
                    targetMatrix{2}*uint8(targetState2-1) | targetMatrix{3}*uint8(targetState3-1) |...
                    targetMatrix{4}*uint8(targetState4-1);
            end
        end
    end
end

% Store data into output var flickerTexture
flickerTexture = screenMatrix;
end
