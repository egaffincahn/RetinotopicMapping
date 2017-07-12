function [red green] = IsoThresh

% The purpose of the ISOTHRESH function is to get the RGB values of red and
% green such that the brightness of the two colors will be equal
% (isoluminant). This is important in biasing stimuli towards the
% parvocellular visual pathway.
% 
% Subjects will press the 1 and 2 key to change the contrast of the
% flickering blob until the flickering disappears or become as unnoticeable
% as possible. They press the 0 key when they would like to accept their
% choice. The subject will do this three times, the first will be a
% practice, and the real values will be an average of the second and third.

KbName('UnifyKeyNames');
down = KbName('1!');
up = KbName('2@');
ok = KbName('0)');

starting_contrast = 100; %starting contrast
contrast = starting_contrast;
GammaValues = [2 2 2];
step = .25; % change in contrast at each press

%color set-up
background_color(1,1,:) = [180 180 0];
rcolor1     = round(255*((50-contrast/2)/100)^(1/GammaValues(1)));
rcolor2     = round(255*((50+contrast/2)/100)^(1/GammaValues(1)));
gcolor1     = round(255*((50-contrast/2)/100)^(1/GammaValues(2)));
gcolor2     = round(255*((50+contrast/2)/100)^(1/GammaValues(2)));

[w rect] = Screen('OpenWindow',max(Screen('Screens')),background_color(:));
xc = rect(3)/2;
yc = rect(4)/2;
h = 6;
fixation = [xc-h, yc-h, xc+h, yc+h];
blob_width = 200;
blob = [xc-blob_width/2, yc-blob_width/2, xc+blob_width/2, yc+blob_width/2];
wait = 1.5 / Screen('FrameRate',w);

Screen(w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

ms = blob_width - 1;
alpha_layer = 4;
[rr,cc] = meshgrid(-ms:ms,-ms:ms);
maskblob = repmat(background_color, [2*ms+1, 2*ms+1]);

sd = ms / 2;
bowl = rr.^2 + cc.^2;
dome = - bowl / sd^2;
maskblob(:,:,alpha_layer) = 255 * (1 - exp(dome));
maskblob = uint8(maskblob);
mask_texure = Screen('MakeTexture',w,maskblob);

for i = 1:3
    
    finished = 0;
    VBL = GetSecs;
    contrast = starting_contrast;
    
    while ~finished
        
        Screen('FillRect',w,[rcolor1 gcolor2 0],blob);
        Screen('DrawTexture',w, mask_texure,[],blob);
        Screen('FillOval',w,[0 0 0],fixation);
        VBL = Screen('Flip',w,VBL+wait);
        
        Screen('FillRect',w,[rcolor2 gcolor1 0],blob);
        Screen('DrawTexture',w, mask_texure,[],blob);
        Screen('FillOval',w,[0 0 0],fixation);
        VBL = Screen('Flip',w,VBL+wait);
        
        [~,~,key] = KbCheck;
        if key(down)
            contrast = contrast - step;
        elseif key(up)
            contrast = contrast + step;
        elseif key(ok)
            finished = 1;
        end
        contrast = abs(rem(contrast,starting_contrast));
        
        gcolor1=round(255*((50-contrast/2)/100)^(1/GammaValues(2)));
        gcolor2=round(255*((50+contrast/2)/100)^(1/GammaValues(2)));
        
    end
    
    green_temp(i,:) = [rcolor1 gcolor2 0];
    red_temp(i,:) = [rcolor2 gcolor1 0];

    Screen('FillOval',w,[255 255 255],fixation);
    Screen('Flip',w);
    WaitSecs(2);
    while key(ok)
        [~,~,key] = KbCheck;
    end
    
end

Screen('Close',w);

green(1,1,:) = mean(green_temp(2:3,:),1);
red(1,1,:) = mean(red_temp(2:3,:),1);
