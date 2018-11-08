function elSettings = SetupEyeLink(Params)

w = Params.w;
rect = Params.rect;
elSettings.gazeDepend = 0; % enforce fixation (0=don't wait for fixation to continue)
elSettings.flipToWarn = 0; % don't change the screen when checking fixation
elSettings.printInfo = 0; % don't print out a bunch of info during eye checking
elSettings.bounds = [rect(3)/2-75,rect(4)/2-75,rect(3)/2+75,rect(4)/2+75]; % allowed bounds for eyes
elSettings.el = EyelinkInitDefaults(w); % initialize eyelink (el) defaults

EyelinkInit(0); % initializes connection
Eyelink('OpenFile',sprintf('%s%d_R%d.edf',Params.Experiment(1:3),Params.Sub,Params.Run)); % name the edf file

Eyelink('Command', 'add_file_preamble_text ''%s''',Params.Experiment);
Eyelink('Command', 'calibration_type = HV5');
Eyelink('Command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, rect(3)-1, rect(4)-1); % sets screen size
Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, rect(3)-1, rect(4)-1); % sets display size

if Params.custom_calibration
    
    % instructions: move the mouse around and talk to subject until you find a
    % good place. When you have a good place for a calibration spot, click the
    % mouse.
    [x y samples] = run_custom_calibration(w);
    
    Eyelink('Command', 'generate_default_targets = NO');
    Eyelink('Command','calibration_samples = %d',samples+1);
    Eyelink('Command','calibration_sequence = 0,1,2,3,4,5');
    Eyelink('Command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
        x(1),y(1),  x(2),y(2),  x(3),y(3),  x(4),y(4),  x(5),y(5) );
    Eyelink('Command','validation_samples = %d',samples+1);
    Eyelink('Command','validation_sequence = 0,1,2,3,4,5');
    Eyelink('Command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
        x(1),y(1),  x(2),y(2),  x(3),y(3),  x(4),y(4),  x(5),y(5) );
else
    Eyelink('Command', 'generate_default_targets = YES');
end

Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT'); % what info is available in the edf
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT'); % what info is available on-line
Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA,HTARGET,GAZERES,STATUS,INPUT');

if Eyelink('IsConnected')~=1; % make sure we're still connected.
    error('EyeLink no longer connected\n');
end

EyelinkUpdateDefaults(elSettings.el); % update the defaults with our newly edited settings
EyelinkDoTrackerSetup(elSettings.el); % do calibration and validation


function [xdot ydot samples] = run_custom_calibration(w)

samples = 5; % number of locations
B = 25; % radius of larger circle
S = 5; % radius of inner circle
xdot = []; ydot = []; % centers of the calibration dots
found = 0;
for i = 1:samples % scroll through each calibration dot location
    dot = i;
    ready = 0;
    while ~ready % continue this code while a new point hasn't been set
        
        % button click saves the location
        [x,y,buttons] = GetMouse(w);
        if any(buttons) % if the mouse was clicked, save the location
            fprintf('Dot %d: [%.0f %.0f]\n',dot,x,y)
            xdot(dot) = x; ydot(dot) = y;
            found = found + 1;
            while any(buttons); [~,~,buttons] = GetMouse(w); end % wait for button release
            ready = 1;
        end
        
        % backspace goes back one location dot
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('Backspace'))
            dot = dot - 1;
            xdot(dot) = []; ydot(dot) = [];
        end
        
        % draw current location of mouse
        Screen('FillRect',w,[128 128 128]);
        Screen('DrawText',w,sprintf('%d / %d',dot,samples),50,50);
        Screen('FillOval',w,[0 0 0],[x-B, y-B, x+B, y+B]);
        Screen('FillOval',w,[128 128 128],[x-S, y-S, x+S, y+S]);
        Screen('Flip',w);
    end
    
end
