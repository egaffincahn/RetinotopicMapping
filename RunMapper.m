function RunMapper(handles)


try
    
    fields = fieldnames(handles);
    for f = 1:length(fields)
        if ~isempty(strfind(fields{f},'label')) || ~isempty(strfind(fields{f},'output')) || ~isempty(strfind(fields{f},'save'))
            continue
        end
        switch get(handles.(fields{f}),'Style')
            case 'popupmenu'
                contents = cellstr(get(handles.(fields{f}),'String'));
                value = contents{get(handles.(fields{f}),'Value')};
            case {'slider','checkbox'}
                value = get(handles.(fields{f}),'Value');
            case 'edit'
                value = get(handles.(fields{f}),'String');
            otherwise
                error('Unknown field style %s for handle %s', get(handles.(fields{f}),'Style'), get(handles.(fields{f}),'Tag'))
        end
        Params.(fields{f}) = value;
    end
    
    fields = fieldnames(Params);
    for f = 1:length(fields)
        eval([fields{f} ' = Params.(fields{f});'])
    end

    % Turn some warnings off
    warning('OFF','images:initSize:adjustingMag');
    warning('OFF','images:imshow:magnificationMustBeFitForDockedFigure');
    Screen('Preference','SkipSyncTests',DEBUG);
    commandwindow;
    
    % do some checks
    if isempty(Sub); Sub = input('Subject number: ','s'); end
    if isempty(Run); Run = input('Run number: ','s'); end
    if track_eyes && ~exist('confirmFixation.m','file'); error('Make sure confirmFixation.m is on the path'); end
    
    % special cases
    Params.start_time = clock;
    Sub = eval(Sub); Params.Sub = Sub;
    Run = eval(Run); Params.Run = Run;
    volumes = eval(volumes); Params.volumes = volumes;
    TR = TR / 1000;
    wait_beginning = wait_beginning + TR*TRs_discarded;
    if ~get(handles.DEBUG,'Value') && get(handles.Style,'Value')==3; % non-DEBUG, Parvo
        [Params.red Params.green] = IsoThresh;
        background_color = num2str(Params.red);
    else
        Params.red(1,1,:) = eval(['[' background_color ']']); Params.green(1,1,:) = [0 255 0];
    end
    
    background_color = reshape(eval(['[' background_color ']']),[1,1,3]); Params.background_color = background_color;
    dot_color = reshape(eval(['[' dot_color ']']),[1,1,3]); Params.dot_color = dot_color;
    
    save_filename = sprintf('%s_%s_Sub%d_Run%d',Params.Experiment,Params.Style,Params.Sub,Params.Run);
    saveas(handles.output,save_filename);
    disp(Params)

    % psychtoolbox
    [w rect] = Screen('OpenWindow',max(Screen('Screens')),background_color(:),[],[],[],[],multisample);
    refresh_rate = 1 / Screen('GetFlipInterval',w);
    Screen('TextSize', w, 36);
    Screen('DrawText',w,'Making stimuli...',50,50);
    Screen('Flip', w);
    
    xc = rect(3)/2;
    yc = rect(4)/2;
    h = 6;
    Params.w = w;
    Params.rect = rect;
    Params.xc = xc;
    Params.yc = yc;
    Params.refresh_rate = refresh_rate;
    
    % set the priority level to give the psychtoolbox operations higher
    % priority on the CPU
    priority_level = MaxPriority(w);
    Priority(priority_level);
    
    % list of x,y coordinates for the fixation cross
    fixlist = [...
        xc-h/2,  yc-3*h/2; xc+h/2,  yc-3*h/2; xc+h/2,yc-h/2;...
        xc+3*h/2,yc-h/2;   xc+3*h/2,yc+h/2;   xc+h/2,yc+h/2;...
        xc+h/2,  yc+3*h/2; xc-h/2,  yc+3*h/2; xc-h/2,yc+h/2;...
        xc-3*h/2,yc+h/2;   xc-3*h/2,yc-h/2;   xc-h/2,yc-h/2];
    
    % use an intermediate anonymous function to avoid doing the Eyelink
    % functions when we're in debug mode
    if DEBUG || ~track_eyes
        call_Eyelink = @(varargin) 'DEBUG';
        elSettings.bounds = nan(1,4);
        if length(Screen('Screens'))==1 % can't see stim being created if only one screen
            sca;
        end
    else
        call_Eyelink = @Eyelink;
        elSettings = SetupEyeLink(Params);
        EyelinkDoDriftCorrect(elSettings.el);
    end
    
    gaze_failed = prt_split_clock + 1; % prt condition index for eye tracking
    
    % some code that can be evaluated quickly in the main script
    get_time = @(start,since) round((since-start)*1000);
    check_eyes = [...
        'if ~track_eyes; return; end; '...                             % avoid the rest of this code if not tracking eyes
        'elSettings = confirmFixation(elSettings); '...                % checks if eye is in bounds
        'if ~gaze_ok && elSettings.endstatus(end) == 1 '...            % if eye was out of bounds but is back in
        '    prt{gaze_failed}(end,2) = get_time(start,GetSecs); '...   % end the prt condition timer
        '    gaze_ok = 1; '...                                         % acknowledge that the eye is back in bounds
        'elseif gaze_ok && elSettings.endstatus(end) == 3 '...         % gaze was in bounds but is out now
        '    prt{gaze_failed}(end+1,1) = get_time(start,GetSecs); '... % start the prt condition timer
        '    gaze_ok = 0; '...                                         % acknowledge that the eye is out of bounds
        'end'
        ];
    
    if DEBUG
        figure;
    else
        HideCursor;
    end
    
    [Params,tex] = MakeStimuli(Params);
    
    % initialize some variables
    quit_early = 0;
    gaze_ok = 1; % variable that stores whether the eye is in bounds or not
    stim_duration_less_slack = (1 / flip_rate) - (.5 / refresh_rate); % just less than the stim duration
    stopper = 1e-5;
    GetSecs; % load the mex file b/c it takes a few hundred ms the first time
    
    % initialize prt info
    conditions = prt_split_clock + 1; % extra condition is for eye info
    prt = cell([1,conditions]); % one cell for each prt condition
    
    % take care of individual cases
    switch Experiment %%%%  PERHAPS IN REPMAT DIVIDE WITHINCYCLE LENGTH BY LENGTH OF TEX ITSELF
        case 'PolarAngle'
            jump_angle = 360 / (flip_rate * cycle_time); % degrees to jump on every flip
            within_cycle = start_angle : jump_angle : start_angle+360-stopper;
            tex = repmat(tex,[1,length(within_cycle)/length(tex)]);
        case 'Eccentricity'
            within_cycle = 1 : flip_rate*cycle_time;
            tex = repmat(tex,[1,length(within_cycle)/length(tex)]);
        case 'Meridian'
            within_cycle = 1 : flip_rate*cycle_time;
            repeats = length(within_cycle) / (prt_split_clock * length(tex)); % repetitions of same location
            blank = Screen('MakeTexture',w,repmat(background_color,[rect(4),rect(3)])); % make blank screen
            tex = repmat([repmat(tex,[1,repeats]), repmat([blank,blank],[1,repeats])], [1,length(tex)]); % b/w,b/w,b/w...,blank..., repeat
        case 'Motion'
            within_cycle = 1 : flip_rate*cycle_time;
            dynamic = tex; % tex is the moving stims
            static = repmat(dynamic(:,:,round(size(dynamic,3)/2)), [1,1,size(dynamic,3)]); % take the middle tex for the static cond
            blank = zeros(size(dynamic)); % make the empty condition
            tex = cat(3,dynamic,blank,static,blank);
    end
    if reverse_direction; within_cycle = sort(within_cycle,2,'descend'); end
    
    % trigger screen
    Screen('TextSize', w, 36);
    Screen('DrawText', w, 'Waiting for trigger...', 50, 50);
    Screen('DrawText', w, sprintf('%d volumes',volumes), 50, 85); % includes throwaway TRs!
    Screen('Flip', w);
    
    % eye tracking
    call_Eyelink('StartRecording');
    WaitSecs(.050);
    call_Eyelink('Command', 'draw_box %d %d %d %d 15', elSettings.bounds(1),elSettings.bounds(2),...
        elSettings.bounds(3),elSettings.bounds(4));
    
    % wait for trigger
    fprintf('\n\nWaiting for trigger from scanner or the tilde button (~)\n\n')
    KbName('UnifyKeyNames');
    trigger = KbName('`~');
    [~,~,key] = KbCheck(-1);
    while ~key(trigger);
        WaitSecs(.001);
        [~,~,key] = KbCheck(-1);
    end
    fprintf('\n\nStarting experiment %s %s...\n\n',Experiment,Style)
    
    % rest at beginning
    Screen('FillRect',w,background_color(:));
    Screen('FramePoly', w, [0 0 0], fixlist);
    start = Screen('Flip', w) + TR*TRs_discarded;
    call_Eyelink('Message','SCANNER SYNCTIME');
    while GetSecs - start < wait_beginning - TR*TRs_discarded % wait for rest time to be up
        eval(check_eyes) % check fixation while we wait
        [~,~,keyCode] = KbCheck(-1);
        if keyCode(KbName('q')) % Q to quit early
            quit_early = 1;
            break
        end
    end
    flip = GetSecs; % finished rest
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% STIMULUS PRESENTATION %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for r = 1:cycles
        if quit_early; break; end
        for cyc = within_cycle
            
            eval(check_eyes)
            
            [~,~,keyCode] = KbCheck(-1); % check if experimenter pressed anything
            if keyCode(KbName('c')) % C to to eye tracker setup again
                prt{current_condition}(end,2) = get_time(start,GetSecs);
                if ~DEBUG; EyelinkDoTrackerSetup(elSettings.el); end
                Screen('FillRect',w,background_color(:));
                flip = Screen('Flip',w);
                prt{current_condition}(end+1,1) = get_time(start,flip);
            elseif keyCode(KbName('q')) % Q to quit early
                prt{current_condition}(end,2) = get_time(start,GetSecs);
                quit_early = 1;
                break
            end
            
            % choose the stimulus and the prt condition
            switch Experiment
                % rotation_angle: how many degrees to rotate the stimulus
                % current_condition: determine which condition in the prt
                % destination_rect: determine how much to scale the stimulus
                case 'PolarAngle'
                    current_condition = rem(floor((cyc-90)*prt_split_clock/360),prt_split_clock) + 1;
                    rotation_angle = cyc - wedge_arc_angle/2;
                    Screen('DrawTexture', w, tex(cyc==within_cycle), [], [], rotation_angle);
                case 'Eccentricity'
                    current_condition = floor((cyc-1)*prt_split_clock/(flip_rate*cycle_time))+1;
                    cob = Params.outer_boundaries(flip_rate*cycle_time-cyc+1); % Current Outer Bounds of stim (start small and go big)
                    destination_rect = [xc-cob*xc/yc, yc-cob, xc+cob*xc/yc, yc+cob];
                    Screen('DrawTexture', w, tex(cyc==within_cycle), [], destination_rect);
                case 'Meridian'
                    current_condition = ceil(prt_split_clock*cyc/(flip_rate*cycle_time));
                    rotation_angle = (90-wedge_arc_angle/2) * (2*floor(prt_split_clock*(cyc-1)/(2*flip_rate*cycle_time)) + 1);
                    Screen('DrawTexture', w, tex(cyc==within_cycle), [], [], rotation_angle);
                case 'Motion'
                    current_condition = ceil(prt_split_clock*cyc/(flip_rate*cycle_time));
                    Screen('FillOval', w, dot_color(:), tex(:,:,cyc==within_cycle));
            end
            
            % wait up the rest of the time before the next flip
            Screen('FramePoly', w, [0 0 0], fixlist);
            flip = Screen('Flip',w,flip+stim_duration_less_slack);
            
            % setting ending prt times of previous condition and starting
            % prt times for current condition
            if r == 1 && cyc == within_cycle(1) % very first time only
                prt{current_condition}(end+1,1) = get_time(start,flip);
            elseif current_condition ~= previous_condition
                prt{previous_condition}(end,2) = get_time(start,flip);
                prt{current_condition}(end+1,1) = get_time(start,flip);
            end
            previous_condition = current_condition;
            
        end
        call_Eyelink('Message',sprintf('Cycle %d Over',r));
    end
    
    % rest at end
    if ~quit_early
        
        % put only the fixation cross back on
        Screen('FillRect',w,background_color(:));
        Screen('FramePoly', w, [0 0 0], fixlist);
        finish = Screen('Flip',w,flip+stim_duration_less_slack);
        
        call_Eyelink('Message','Rest Start');
        prt{previous_condition}(end,2) = get_time(start,finish);
        
        while GetSecs - finish < wait_end
            eval(check_eyes)
            [~,~,keyCode] = KbCheck(-1);
            if keyCode(KbName('q')) % Q to quit early
                break
            end
        end
    end
    
    % close out
    if ~isempty(prt{gaze_failed}) && (length(prt{gaze_failed})==1 || prt{gaze_failed}(end,2) == 0) % if gaze was gone at the end,
        prt{gaze_failed}(end,2) = get_time(start,GetSecs); % put an end time on it
    end
    
    fprintf('\n\n%.2fs elapsed. %d - %d discarded = %ds expected\n\n', ...
        get_time(start,GetSecs)/1000, ...
        Params.volumes*TR, ...
        TR*TRs_discarded, ...
        TR*(Params.volumes-TRs_discarded))
    
    
    % closing eyelink calls
    call_Eyelink('Message','!V IAREA RECTANGLE %d %d %d %d %d %s',1,elSettings.bounds(1),...
        elSettings.bounds(2),elSettings.bounds(3),elSettings.bounds(4),'fixation');
    call_Eyelink('StopRecording');
    call_Eyelink('CloseFile');
    call_Eyelink('ReceiveFile');
    
    sca;
    Priority(0);
    
    % make the PRT
    switch Experiment
        case {'PolarAngle','Eccentricity'}
            for c = 1:prt_split_clock
                condition_names{c} = sprintf('%s%d',Experiment,c);
            end
        case 'Meridian'
            conditions = conditions - 2;
            prt = prt(1:2:5); % drop the blanks
            condition_names = {'Vertical','Horizontal'};
        case 'Motion'
            conditions = conditions - 2;
            prt = prt(1:2:5); % drop the blanks
            condition_names = {'Dynamic','Static'};
    end
    condition_names{end+1} = 'GazeDiverted';
    Params.PRT.condition_names = condition_names;
    Params.PRT.Conditions = conditions;
    Params.PRT.prt = prt;
    MakePRT(Params);
    
    save(save_filename)

catch me
    % include a second try...catch statement in case the initial error
    % occurred before variables used here were set
    try
        sca;
        Priority(0);
        save(['Error_' save_filename])
        call_Eyelink('StopRecording');
    catch catch_error
        warning(catch_error.message);
    end
    rethrow(me)
end


