function varargout = InitializeSuite(varargin)
%
% EG Gaffin-Cahn
% 06/2014
% 
% %%%%%%%%%%%%%%% HELP FILES FOR RETINOTOPIC MAPPING SUITE %%%%%%%%%%%%%%%
% 
% 
% Call INITIALIZESUITE to load the GUI. You'll have the option to choose
% several parameters within several types of experiments and styles. See
% below for descriptions of the settings.
% 
% 
% GENERAL
% 
%   Sub - subject number
% 
%   Run - run number for current experiment and subject
% 
%   DEBUG - will not track eyes, and will show several figures in the
%   process of making stimuli (slow)
% 
%   Track Eyes - do eye tracking, and add gaze lost as a predictor in the
%   PRT
% 
%   Custom Calibration - do a custom calibration for the eye tracker where
%   you'll choose 5 location on the screen; this is helpful in a scanner
%   setting where the subject's view of the screen is partially obscured
% 
%   Experiment - type of stimulus to show (rotating wedge, expanding
%   annulus, etc.)
% 
%   Style - decides color, spatial, and temporal properties of the stimulus
% 
% 
% 
% TIMING
% 
%   TR - repetition time for the scan
% 
%   TRs Discarded - number of volumes to add to the scan as warm up which
%   will be discarded upon analysis
% 
%   Wait at Beginning - rest period with no stimulus at beginning (does not
%   include TRs Discarded)
% 
%   Wait at End - rest period with no stimulus at end
% 
%   Cycles - number of full stimulus cycles to complete
% 
%   Cycle Times - seconds to complete one full cycle (for Meridian, one
%   full cycle will be stimulus-rest-stimulus-rest; for Motion, one full
%   cycle will be dynamic-rest-static-rest)
% 
%   Calculated Volumes - calculates the number of volumes to report to the
%   scanner based on other Timing variables
% 
%   Split PRT - number of experimental predictors to split the timing of
%   the stimulus (for Meridian/Motion, divide this by 4 to get the time for
%   one section of the cycle)
% 
%   Remove Lost Gaze Conditions - remove the times when gaze is lost or
%   moves outside the allowed bounds from the experimental predictors in
%   the PRT
% 
% 
% 
% STIMULUS
% 
%   Start Angle - location of first stimulus relative to right horizontal
%   (PolarAngle only)
% 
%   Wedge Arc Angle - width of the wedge in degrees (for Eccentricity, this
%   represents only half of the stimulus)
% 
%   Wedge Radii - number of radii or spokes in the wedge dividing the
%   color/luminance changes
% 
%   Wedge Annuli - number of annuli or concentric circles in the wedge
%   dividing the color/luminance changes
% 
%   Annulus Thickness - maximum size from edge of screen to inner bounds of
%   the stimulus (yc is the center of the screen in the y-dimension, so
%   'yc-50' means that the wedge/allowed area will be 50
%   pixels short of traversing the entire half-width of the screen)
% 
%   Background Color - RGB color behind the stimulus (for Parvo, this will
%   be determined by running the isoluminance threshold -IsoThresh- test)
% 
%   Flip Rate - flickers per second
% 
%   Anti-Aliasing - a Psychtoolbox parameter to make the screen's central
%   pixels cleaner during the highly compressed color modulations in Parvo
% 
%   Contrast - color contrast to present the stimuli
% 
%   Reverse Direction - reverses the entire stimulus presentation (wedges
%   will move counterclockwise, annuli will contract, motion dots will move
%   inward)
% 
% 
% 
% MOTION PARAMETERS (for Motion Experiment only)
% 
%   Number of Dots - number of dots to present simultaneously
% 
%   Max Dot Size - maximum size of any dot before it resets to random new
%   location and size
% 
%   Dot Speed - how many pixels the dots will translate on each flip (but
%   scaled, so that 'closer' dots move faster)
% 
%   Dot Growth Speed - how many pixels to increase the dot size on each
%   flip (but scaled, so that 'closer' dots grow faster)
% 
%   Dot Color - the RGB color of the dots
% 
% 
% 
% SAVE PARAMETERS - saves the current settings as a .fig in the current
% directory; the experiment can be run by loading it and clicking START
% 
% START - begin the experiment
% 
% 
% If you want to edit any of the defaults, you'll have to open
% INITIALIZESUITE and find the function auto_change_settings. Find the
% parameter you want to change the default for, and change the variable
% value{end+1} to be what you want. Make sure you change it for the right
% combination of Experiment/Style.
% 
% 
% %%%%%%%%%%%%%%% HELP FILES FOR RETINOTOPIC MAPPING SUITE %%%%%%%%%%%%%%%
% 

% 
% INITIALIZESUITE_LABEL MATLAB code for InitializeSuite_label.fig
%      INITIALIZESUITE_LABEL, by itself, creates a new INITIALIZESUITE_LABEL or raises the existing
%      singleton*.
%
%      H = INITIALIZESUITE_LABEL returns the handle to a new INITIALIZESUITE_LABEL or the handle to
%      the existing singleton*.
%
%      INITIALIZESUITE_LABEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INITIALIZESUITE_LABEL.M with the given input arguments.
%
%      INITIALIZESUITE_LABEL('Property','Value',...) creates a new INITIALIZESUITE_LABEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before InitializeSuite_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to InitializeSuite_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help InitializeSuite_label

% Last Modified by GUIDE v2.5 15-Jul-2014 16:45:27

%#ok<*INUSD>
%#ok<*INUSL>
%#ok<*DEFNU>
%#ok<*AGROW>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @InitializeSuite_OpeningFcn, ...
    'gui_OutputFcn',  @InitializeSuite_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before InitializeSuite_label is made visible.
function InitializeSuite_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to InitializeSuite_label (see VARARGIN)

% Choose default command line output for InitializeSuite_label
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes InitializeSuite_label wait for user response (see UIRESUME)
% uiwait(handles.InitializeSuite_label);

calculate_volumes(handles)
auto_change_settings(handles)

try
    Eyelink('IsConnected');
catch %#ok<CTCH>
    set(handles.track_eyes,'Value',0);
    set(handles.track_eyes,'Enable','off');
    track_eyes_Callback(handles.track_eyes, eventdata, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = InitializeSuite_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in timing_box_label.
function Experiment_Callback(hObject, eventdata, handles)

auto_change_settings(handles);


function Experiment_CreateFcn(hObject, eventdata, handles)


% --- Executes on selection change in Style.
function Style_Callback(hObject, eventdata, handles)

auto_change_settings(handles)


function Style_CreateFcn(hObject, eventdata, handles)

function Sub_Callback(hObject, eventdata, handles)

function Sub_CreateFcn(hObject, eventdata, handles)

function Run_Callback(hObject, eventdata, handles)

function Run_CreateFcn(hObject, eventdata, handles)


% --- Executes on button press in help_label.
function help_label_Callback(hObject, eventdata, handles)
% hObject    handle to help_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

help InitializeSuite


% --- Executes on button press in DEBUG.
function DEBUG_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(handles.track_eyes,'Value',0);
    set(handles.track_eyes,'Enable','off');
    track_eyes_Callback(handles.track_eyes, eventdata, handles);
else
    try
        Eyelink('IsConnected');
        set(handles.track_eyes,'Enable','on');
        track_eyes_Callback(handles.track_eyes, eventdata, handles);
    catch %#ok<CTCH>
    end
end


% --- Executes on button press in track_eyes.
function track_eyes_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(handles.remove_eye_condition_from_predictors,'Value',1)
    set(handles.remove_eye_condition_from_predictors,'Enable','on');
    set(handles.custom_calibration,'Enable','on');
else
    set(handles.remove_eye_condition_from_predictors,'Value',0);
    set(handles.remove_eye_condition_from_predictors,'Enable','off');
    set(handles.custom_calibration,'Enable','off');
end


function custom_calibration_Callback(hObject, eventdata, handles)


% --- Executes on slider movement.
function TR_Callback(hObject, eventdata, handles)

update_label(handles,hObject);
calculate_volumes(handles)


function TR_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function TRs_discarded_Callback(hObject, eventdata, handles)

update_label(handles,hObject)
calculate_volumes(handles)


function TRs_discarded_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function wait_beginning_Callback(hObject, eventdata, handles)

update_label(handles,hObject)
calculate_volumes(handles)


function wait_beginning_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function wait_end_Callback(hObject, eventdata, handles)

update_label(handles,hObject)
calculate_volumes(handles)


function wait_end_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function cycles_Callback(hObject, eventdata, handles)

update_label(handles,hObject)
calculate_volumes(handles)


function cycles_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function cycle_time_Callback(hObject, eventdata, handles)

update_label(handles,hObject)
calculate_volumes(handles)


function cycle_time_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function prt_split_clock_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function prt_split_clock_CreateFcn(hObject, eventdata, handles)

function volumes_Callback(hObject, eventdata, handles)

function volumes_CreateFcn(hObject, eventdata, handles)


function calculate_volumes(handles)

TR = get(handles.TR,'Value') / 1000;
TRs_discarded = get(handles.TRs_discarded,'Value');
cycles = get(handles.cycles,'Value');
cycle_time = get(handles.cycle_time,'Value');
wait_beginning = get(handles.wait_beginning,'Value') + TR*TRs_discarded;
wait_end = get(handles.wait_end,'Value');

volumes = ceil(((wait_beginning + wait_end) + cycles*cycle_time) / TR);
set(handles.volumes,'String',num2str(volumes));
set(handles.seconds_label,'String',[num2str(volumes * TR) 's']);


function seconds_label_Callback(hObject, eventdata, handles)

function seconds_label_CreateFcn(hObject, eventdata, handles)


% --- Executes on button press in remove_eye_condition_from_predictors.
function remove_eye_condition_from_predictors_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(handles.track_eyes,'Value',1);
end


% --- Executes on slider movement.
function start_angle_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function start_angle_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function wedge_arc_angle_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function wedge_arc_angle_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function wedge_radii_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function wedge_radii_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function wedge_annuli_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function wedge_annuli_CreateFcn(hObject, eventdata, handles)

function annulus_thickness_Callback(hObject, eventdata, handles)

function annulus_thickness_CreateFcn(hObject, eventdata, handles)

function background_color_Callback(hObject, eventdata, handles)

function background_color_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function flip_rate_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function flip_rate_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function multisample_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function multisample_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function michelson_contrast_Callback(hObject, eventdata, handles)

value = get(hObject,'Value');
set(handles.michelson_contrast_label,'String',sprintf('Contrast: %.0f%%',100*value));


function michelson_contrast_CreateFcn(hObject, eventdata, handles)

function reverse_direction_Callback(hObject, eventdata, handles)


% --- Executes on slider movement.
function number_of_dots_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function number_of_dots_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function max_dot_size_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function max_dot_size_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function dot_speed_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function dot_speed_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function dot_growth_speed_Callback(hObject, eventdata, handles)

update_label(handles,hObject)


function dot_growth_speed_CreateFcn(hObject, eventdata, handles)

function dot_color_Callback(hObject, eventdata, handles)

function dot_color_CreateFcn(hObject, eventdata, handles)

function update_label(handles,hObject)

value = round(get(hObject,'Value'));
set(hObject,'Value',value);
tag = [get(hObject,'Tag') '_label'];
label = regexprep(get(handles.(tag),'String'),'\d+|NaN',num2str(value));
set(handles.(tag),'String',label);


function auto_change_settings(handles)

contents = cellstr(get(handles.Experiment,'String'));
Experiment = contents{get(handles.Experiment,'Value')};


eObject = {};
enable = {};
value = {};

% For Motion, make Style = Magno and enable/disable Motion Parameters box
eObject{end+1} = handles.Style;
switch Experiment
    case 'Motion'; enable{end+1} = 'off'; value{end+1} = []; set(handles.Style,'Value',2);
    otherwise;     enable{end+1} = 'on';  value{end+1} = [];
end

contents = cellstr(get(handles.Style,'String'));
Style = contents{get(handles.Style,'Value')};

% settings not to change based on experiment:
% cycles
% cycle_time

% start_angle
eObject{end+1} = handles.start_angle;
switch Experiment
    case 'PolarAngle';   enable{end+1} = 'on';  value{end+1} = 90;
    case 'Eccentricity'; enable{end+1} = 'off'; value{end+1} = NaN;
    case 'Meridian';     enable{end+1} = 'off'; value{end+1} = 45;
    case 'Motion';       enable{end+1} = 'off'; value{end+1} = NaN;
end

% wedge_arc_angle
eObject{end+1} = handles.wedge_arc_angle;
switch Experiment
    case 'PolarAngle';   enable{end+1} = 'on';  value{end+1} = 32;
    case 'Eccentricity'; enable{end+1} = 'off'; value{end+1} = 180;
    case 'Meridian';     enable{end+1} = 'on';  value{end+1} = 90;
    case 'Motion';       enable{end+1} = 'off'; value{end+1} = NaN;
end

% annulus_thickness
eObject{end+1} = handles.annulus_thickness;
switch Experiment
    case 'PolarAngle';   enable{end+1} = []; value{end+1} = 'yc-50';
    case 'Eccentricity'; enable{end+1} = []; value{end+1} = '150';
    case 'Meridian';     enable{end+1} = []; value{end+1} = 'yc-50';
    case 'Motion';       enable{end+1} = []; value{end+1} = 'yc-20';
end

% prt_split_clock
eObject{end+1} = handles.prt_split_clock;
switch Experiment
    case 'PolarAngle';   enable{end+1} = 'on';  value{end+1} = 8;
    case 'Eccentricity'; enable{end+1} = 'on';  value{end+1} = 8;
    case 'Meridian';     enable{end+1} = 'off'; value{end+1} = 4;
    case 'Motion';       enable{end+1} = 'off'; value{end+1} = 4;
end

% reverse_direction
eObject{end+1} = handles.reverse_direction;
switch Experiment
    case 'PolarAngle';   enable{end+1} = 'on';  value{end+1} = 0;
    case 'Eccentricity'; enable{end+1} = 'on';  value{end+1} = 0;
    case 'Meridian';     enable{end+1} = 'on';  value{end+1} = 0;
    case 'Motion';       enable{end+1} = 'off'; value{end+1} = 0;
end

% flip_rate
eObject{end+1} = handles.flip_rate;
switch Style
    case 'Full';  enable{end+1} = []; value{end+1} = 5;
    case 'Magno'; enable{end+1} = []; value{end+1} = 15;
    case 'Parvo'; enable{end+1} = []; value{end+1} = 1;
end

% background_color
eObject{end+1} = handles.background_color;
switch Style
    case 'Full';  enable{end+1} = 'on';  value{end+1} = '200 200 200'; set(handles.RunMapper_label,'String','START');
    case 'Magno'; enable{end+1} = 'on';  value{end+1} = '200 200 200'; set(handles.RunMapper_label,'String','START');
    case 'Parvo'; 
        if get(handles.DEBUG,'Value')
            enable{end+1} = 'on'; value{end+1} = '255 0 0';
            set(handles.RunMapper_label,'String','START');
        else
            enable{end+1} = 'off'; value{end+1} = 'Will Run IsoTresh';
            set(handles.RunMapper_label,'String','RUN ISOTHRESH');
        end
end

% multisample
eObject{end+1} = handles.multisample;
switch Style
    case 'Full';  enable{end+1} = []; value{end+1} = 0;
    case 'Magno'; enable{end+1} = []; value{end+1} = 0;
    case 'Parvo'; enable{end+1} = []; value{end+1} = 4;
end

% michelson_contrast
eObject{end+1} = handles.michelson_contrast;
switch Style
    case 'Full';  enable{end+1} = 'off'; value{end+1} = 1;
    case 'Magno'; enable{end+1} = 'on';  value{end+1} = .05;
    case 'Parvo'; enable{end+1} = 'off'; value{end+1} = 0;
end

% wedge_radii
% wedge_annuli
eObject{end+1} = handles.wedge_radii;
eObject{end+1} = handles.wedge_annuli;
switch Experiment
    case 'Motion'; enable{end+1} = 'off'; enable{end+1} = 'off';
    otherwise;     enable{end+1} = 'on';  enable{end+1} = 'on';
end
switch [Experiment,Style]
    
    %     Experiment      Style     wedge_radii         wedge_annuli
    
    case ['PolarAngle',   'Full'];  value{end+1} = 4;   value{end+1} = 25; 
    case ['PolarAngle',   'Magno']; value{end+1} = 3;   value{end+1} = 4;
    case ['PolarAngle',   'Parvo']; value{end+1} = 4;   value{end+1} = 4;
        
    case ['Eccentricity', 'Full'];  value{end+1} = 36;  value{end+1} = 5;
    case ['Eccentricity', 'Magno']; value{end+1} = 4;   value{end+1} = 6;
    case ['Eccentricity', 'Parvo']; value{end+1} = 5;   value{end+1} = 40;
        
    case ['Meridian',     'Full'];  value{end+1} = 18;  value{end+1} = 25;
    case ['Meridian',     'Magno']; value{end+1} = 3;   value{end+1} = 6;
    case ['Meridian',     'Parvo']; value{end+1} = 3;   value{end+1} = 6;
        
    otherwise; value{end+1} = NaN; value{end+1} = NaN;
        
end

% number_of_dots
% max_dot_size
% dot_speed
% dot_growth_speed
% dot_color
eObject{end+1} = handles.number_of_dots;
eObject{end+1} = handles.max_dot_size;
eObject{end+1} = handles.dot_speed;
eObject{end+1} = handles.dot_growth_speed;
eObject{end+1} = handles.dot_color;
switch Experiment
    case 'Motion'
        enable{end+1} = 'on'; value{end+1} = 200;
        enable{end+1} = 'on'; value{end+1} = 25;
        enable{end+1} = 'on'; value{end+1} = 50;
        enable{end+1} = 'on'; value{end+1} = 5;
        enable{end+1} = 'on'; value{end+1} = '0 0 0';
    otherwise
        for i = 1:5; enable{end+1} = 'off'; value{end+1} = []; end
end

% set the values and run the callbacks
for object = 1:length(eObject)

    switch get(eObject{object},'Style')
        case {'popupmenu','slider','checkbox'}
            type = 'Value';
        case 'edit'
            type = 'String';
        otherwise
            error('Wrong field style')
    end
    
    if ~isempty(enable{object}); set(eObject{object},'Enable',enable{object});    end
    if ~isempty(value{object});  set(eObject{object},type,value{object}); end
    if ~isempty(regexp(get(eObject{object},'Tag'),'Style|Experiment','once')); continue; end
    eval([get(eObject{object},'Tag') '_Callback(eObject{object},[],handles)'])
end


% --- Executes on button press in save_parameters_label.
function save_parameters_label_Callback(hObject, eventdata, handles)

saveas(gcf,sprintf('Params %s.fig',datestr(now, 'yyyy-mm-dd HH.MMPM')),'fig')


% --- Executes on button press in RunMapper_label.
function RunMapper_label_Callback(hObject, eventdata, handles)

RunMapper(handles);
fprintf('\n\nFINISHED!\n\n')
