function [Params,tex] = MakeStimuli(Params)

% MakeStimuli(Params) takes the settings for the current experiment and
% generates either Psychtoolbox textures or simple arrays for the RunMapper
% script to use to present the images. Run in DEBUG mode to view
% visualizations of some of the steps in the process. See the body of the
% script for details on each step.

global DEBUG

% Unpack the Params structure into its field names and put them in the
% workspace (just for ease).
fields = fieldnames(Params);
for f = 1:length(fields)
    eval([fields{f} ' = Params.(fields{f});'])
end

% Get the outer and inner bounds (pixels) of the stimulus (the largest
% annulus in the case of eccentricity mapping). With screens wider than
% they are tall, use yc because a rotating wedge will hit the upper and
% lower bounds of the monitor.
largest_outer_bounds = yc;
annulus_thickness = eval(annulus_thickness);
largest_inner_bounds = largest_outer_bounds - annulus_thickness;

% Make the bowl for measuring radii and annuli. rr and cc are arrays the
% size of the monitor, where each column in a row codes the row number (or
% vice versa). By subtracting off the center of the screen (yc,xc), we can
% calculate an array the size of the monitor, where every cell encodes the
% Euclidian distance from the screen center. This array is called bowl.
x = 1:rect(3);
y = 1:rect(4);
[rr cc] = meshgrid(x,y);
bowl = sqrt((rr-xc).^2 + (cc-yc).^2);
show_stimulus_creation(rr, 'mesh', 0);
show_stimulus_creation(cc, 'mesh', 0);
show_stimulus_creation(bowl, 'mesh', 0.5);

% Initialize a grid the size of the screen of ones.
stim_build = ones(rect(4),rect(3));

switch Experiment
    case 'Motion'
        
        % Only allow dot locations in where distances from the screen
        % (bowl) center are greater than the radius given by the
        % largest_inner_bounds.
        stim_build = logical(stim_build) & bowl > largest_inner_bounds;
        show_stimulus_creation(stim_build, 'imshow', 0.5);
        
        % Randomly assign dot locations and dot sizes. Use mnrnd to sample
        % from the multinomial distribution of all the pixels in our
        % stim_build. We sample from it number_of_dots times, and this
        % gives us a list of logicals, whose indices will be our dot
        % centers. Then we convert those indices back to (y,x) space. Each
        % dot gets a randomly chosen dot size between 1 pixel and half the
        % max_dot_size.
        dot_center_indices = find(mnrnd(number_of_dots, stim_build(:)/sum(stim_build(:))));
        [dot_centers_y dot_centers_x] = ind2sub(size(stim_build), dot_center_indices);
        dot_sizes = randi(round(max_dot_size/2),[1,number_of_dots]);
        
        % As dots move outward, new locations and sizes must be drawn, so
        % scroll through each screen flip and calculate the changes. The
        % number_of_flips is divided by 4 to split it into dynamic, rest,
        % static, rest.
        number_of_flips = cycle_time * flip_rate / 4;
        for t = 1:number_of_flips
            
            % Check if any dot sizes are bigger than the max_dot_size, or
            % if the locations are beyond the edge of the screen. If any of
            % them are, reset them back to new locations, randomly
            % distributed in space and size. Take all the dots that no
            % longer fit the criteria and reset them based on the
            % original steps.
            invalid_dots = dot_sizes > max_dot_size | dot_centers_x < 0 | dot_centers_y < 0 | dot_centers_x > rect(3) | dot_centers_y > rect(4);
            if any(invalid_dots)
                dot_center_indices = find(mnrnd(length(find(invalid_dots)), stim_build(:)/sum(stim_build(:))));
                [dot_centers_y(invalid_dots) dot_centers_x(invalid_dots)] = ind2sub(size(stim_build), dot_center_indices);
                dot_sizes(invalid_dots) = randi(round(max_dot_size/2),[1,length(find(invalid_dots))]);
            end
            
            % Dots grow in size linearly with the distance from the center
            % of the screen. Calculate that distance, scale those distances
            % to values between 0 and 1, then add them to the current
            % dot_sizes.
            distances_from_screen_center = sqrt( (xc-dot_centers_x).^2 + (yc-dot_centers_y).^2 );
            dot_sizes = dot_sizes + dot_growth_speed * distances_from_screen_center / sqrt(xc^2 + yc^2);

            % For x and y dimensions separately, dot speeds are scaled
            % linearly to distances from the x/y center. Locations are
            % normalized with respect to the center of the screen,
            % multiplied by the dot_speed, and then converted back into
            % Psychtoolbox coordinates.
            dot_centers_x_centered = dot_centers_x - xc;
            dot_centers_y_centered = dot_centers_y - yc;
            dot_centers_x = dot_centers_x + dot_speed * dot_centers_x_centered / xc;
            dot_centers_y = dot_centers_y + dot_speed * dot_centers_y_centered / yc;

            show_stimulus_creation({dot_centers_x,dot_centers_y},'scatter',0,...
                'axis',[0 rect(3) 0 rect(4)],'title',sprintf('%.0f out of %.0f screens',t,number_of_flips))
            
            % For use in Psychtoolbox, dot coordinates, as calculated by
            % position and size, are placed into the output tex variable.
            % These will be used in a call to Screen('FillOval'), where the
            % dots are represented by an Nx4 matrix, where N is
            % number_of_dots and the rows are ordered
            % [xmin,ymin,xmax,ymax].
            tex(:,:,t) = round([...
                dot_centers_x - dot_sizes/2; dot_centers_y - dot_sizes/2;...
                dot_centers_x + dot_sizes/2; dot_centers_y + dot_sizes/2]);
            
        end
        
        % No need to do any of the rest of this script if doing Motion
        return
end

stopper = 1e-5; % don't let values go completely around (subtract a bit)

switch Style
    
    case 'Full'
        
        % Here, we make the spokes (radii) of a grid. To do so, we create a
        % plane similar to cc or rr, but where each cell is coding the
        % value of proportional to tangent of the current angle. The
        % current angle (i) scrolls from 0 to wedge_arc_angle, in step
        % sizes determined by the number of radii we want to draw. The
        % planes we build are compared to cc, and in any cell where cc is
        % less that our new plane, the logical values in stim_build are
        % reversed (0 to 1 and 1 to 0). As (i) changes, the tangent values
        % change, and therefore which cells are subject to reversal shift
        % over a bit. This creates an alternating pattern centered around
        % the center of the screen.
        for i = 0 : wedge_arc_angle/wedge_radii : wedge_arc_angle-stopper
            radius = cc < repmat(tand(i) .* (x - xc) + yc, [length(y) 1]);
            stim_build = ~xor(stim_build, radius);
            show_stimulus_creation(stim_build,'imshow',0.25);
        end
        
        % After the radii, we do the same thing with concentric circles
        % (annuli) from the outside in. This creates a checkerboard pattern
        % where the squares close to the center are smaller because we are
        % in log space instead of linear space.
        for i = logspace(log10(largest_outer_bounds), log10(largest_inner_bounds), wedge_annuli)
            circle = bowl > i;
            stim_build = ~xor(stim_build, circle);
            show_stimulus_creation(stim_build,'imshow',0.25);
        end
        
        
    otherwise % Parvo, Magno
        
        radial_linear = bowl; % encodes linear Euclidian distance from (yc,xc)
        polar = atand((yc-cc) ./ (xc-rr)); % encodes the angle around xc line
        
        % We do a transformation to the linear Euclidian distance values if
        % Style is Parvo and Experiment is PolarAngle or Meridian. We do
        % this because we like the color undulations in Parvo to be tightly
        % bound, but less so towards the outer edge of the screen.
        if (strcmp(Experiment,'PolarAngle') || strcmp(Experiment,'Meridian')) && strcmp(Style,'Parvo')
            
            % Transformations: The purpose is to make outer sine waves have
            % wider spaces between the peaks. The transformations need to
            % keep fixed the outer values of the ring radial(1,xc)=540 and
            % the value at the largest_inner_bounds because when we take
            % the sine of the radial values, we don't want the edges to be
            % mid-phase, or else the stimulus and the background will have
            % an edge.
            radial_A = radial_linear + 100; % Adding before taking log weakens the effect of the transformations
            radial_B = log(radial_A); % Weaken relative strength of outer values
            radial_C = radial_B - radial_B(yc,xc); % Make minimum value 0
            radial_D = radial_C * yc / max(radial_C(:,xc)); % Scale so values are between 0 and yc
            radial_E = radial_D - radial_D(annulus_thickness,xc); % Fix values so largest_inner_bounds is at 0
            radial = radial_E * annulus_thickness / max(radial_E(:,xc)); % Scale values so outer ring is at yc
            
        else
            radial = radial_linear - largest_inner_bounds;
        end
        
        % 1/freq is number of pixels for one cycle
        freq_radial = wedge_annuli / annulus_thickness;
        freq_polar = wedge_radii / wedge_arc_angle;
        
        % Taking the sine of radial and polar will end up varying the color
        % intensity (RGB or grey) either by distance from the screen center
        % (radial) or in a circle around the center (polar). The
        % frequencies dictate the number of peaks between our areas of
        % interest.
        wave_radial = sin(2*pi*freq_radial*radial);
        wave_polar = sin(2*pi*freq_polar*polar);
        wave_polar(yc,xc) = 0;
        
        % The sine values range between -1 and 1, so we multiply the two
        % waves to get a composite wave. Color modulations in both
        % directions are preserved, but now incorporate the other so that
        % we can have smooth edges on all boundaries of the stimulus.
        wave_2D = (wave_radial .* wave_polar);
        
        show_stimulus_creation(wave_polar, 'mesh', .5);
        show_stimulus_creation(wave_radial, 'mesh', .5);
        show_stimulus_creation(wave_2D, 'mesh', .5);
        
end

% We take two more lines and two concentric circles to determine what area
% within the grid will be part of the final stimulus. If it's outside of
% the final stim, it's becomes a 1 (white). Then, only the stimulus area is
% left, and inside that is a white and black checkerboard. We do this
% twice, inverting the white and black that's inside the stimulus area.
switch Experiment
    case 'PolarAngle'
        split_horizontally = cc < repmat(yc, [length(y) length(x)]);
        split_diagonally = cc > repmat(tand(wedge_arc_angle) .* (x - xc) + yc, [length(y) 1]);
        split_screen = split_horizontally & split_diagonally;
    case 'Eccentricity'
        split_screen = ones(size(cc));
        smallest_outer_bounds = 50;
        Params.outer_boundaries = logspace(log10(largest_outer_bounds), log10(smallest_outer_bounds), flip_rate*cycle_time);
    case 'Meridian'
        split_vertically   = cc < repmat(tand(wedge_arc_angle) .* (x - xc) + yc, [length(y) 1]);
        split_horizontally = cc > repmat(yc - stopper, [length(y) length(x)]);
        split_screen = ~xor(split_vertically,split_horizontally);
end


% To convert these for use in Psychtoolbox, we turn them into textures, and
% then when we show them during presentation, we scale the textures for
% size or rotate them or both.
switch Style
    
    case 'Full'
        
        % Get the area that is outside the stimulus. Then take the white
        % (1) values wherever it is (outside the stimulus) or (inside and
        % already 1). This leaves us with the checkered wedge inside the
        % stimulus area and all white space outside of that area. For the
        % second iteration, it flips the checkered area only inside the
        % stimulus bounds.
        outside_stimulus = ~(split_screen & bowl < largest_outer_bounds & bowl > largest_inner_bounds);
        show_stimulus_creation(outside_stimulus, 'imshow', 0.5);
        for iteration = 1:2
            stim = xor(stim_build,iteration-1);
            stim = repmat(background_color(1)*uint8(stim | outside_stimulus),[1 1 3]);
            show_stimulus_creation(stim, 'imshow', 0);
            tex(iteration) = Screen('MakeTexture',w,stim);
        end
        
    case 'Magno'
        
        % Get the area that is outside the stimulus. The values of the sine
        % wave encode the greyscale intensity values from -1 to 1. These
        % values are then scaled by the michelson_contrast to make the
        % peaks (amplitude) smaller, and then multiplied up so that the
        % values halfway up the sine peak match the grey background. The
        % second iteration inverts the values of the sine wave of greyscale
        % intensity values.
        outside_stimulus = split_screen & bowl < largest_outer_bounds & bowl > largest_inner_bounds;
        show_stimulus_creation(outside_stimulus,'imshow',0.5);
        for iteration = 1:2
            stim = wave_2D .* outside_stimulus * (iteration * 2 - 3);
            amplitude = michelson_contrast * background_color(1);
            stim = uint8(repmat(background_color(1)+(stim.*amplitude),[1 1 3]));
            show_stimulus_creation(stim, 'imshow', 0.5);
            tex(iteration) = Screen('MakeTexture',w,stim);
        end
        
    case 'Parvo'
        
        % Take the absolute value of the radial/polar combination wave to
        % avoid having color values in the sine troughs.
        wave_2D_abs = abs(wave_2D);
        show_stimulus_creation(wave_2D_abs, 'mesh', 0.5);
        
        % Make arrays the size of the monitor that encode all red and all
        % green, and then duplicate the wave so that it has R, G, and B
        % channels.
        screen_green = repmat(green,size(wave_2D_abs));
        screen_red = repmat(red,size(wave_2D_abs));
        scale = repmat(wave_2D_abs,[1,1,3]);
        show_stimulus_creation(scale, 'image', 1);
        
        % Get the area that defines the shape of the stimulus.
        outside_stimulus = split_screen & bowl < largest_outer_bounds & bowl > largest_inner_bounds;
        show_stimulus_creation(outside_stimulus,'imshow',1);
        
        % For iteration = 1:2, the multipliers for green and red against
        % scale are [1,0] and [0,1]. Scale is just the combined
        % polar/radial sine wave from 0 to 1, so scale_green and scale_red
        % code opposite versions of scale.
        for iteration = 1:2
            scale_green = (iteration - 1) + (3 - 2 * iteration) * scale;
            scale_red = (2 - iteration) + (iteration * 2 - 3) * scale;
            
            % The background is green, but the mean values in the full_stim
            % are the green and red averaged. Because we took the absolute
            % value of the radial/polar wave, the minimum values will now
            % code for the background. Full_stim encodes the average of (the
            % green screen modulated by one version of scale) and (the red
            % screen modulated by the opposite intensities of scale). They
            % do not interfere with each other because the green and red
            % operate in different channels, but when combined, areas
            % between the troughs and peaks of the sine wave will have
            % intermediate values of red-green.
            full_stim = scale_green .* screen_green + scale_red .* screen_red;
            show_stimulus_creation(full_stim/255, 'image', 0.5);
            
            % Scroll through each channel of RGB, and wherever pixels are
            % outside the stimulus area, set the pixel to the background
            % color.
            for dim = 1:3
                stim = full_stim(:,:,dim);
                stim(~outside_stimulus) = background_color(dim);
                full_stim(:,:,dim) = stim;
            end
            
            show_stimulus_creation(full_stim/255, 'image', 1);
            tex(iteration) = Screen('MakeTexture',w,full_stim);
        end
end

% In DEBUG mode, if the computer setup only has one screen, we closed it in
% order to view the stimulus creations. Now we open it back up.
if DEBUG && length(Screen('Screens'))==1
    [w rect] = Screen('OpenWindow',max(Screen('Screens')),background_color(:),[],[],[],[],multisample);
end


function show_stimulus_creation(varargin)

% This function will create visualizations of the intermediate steps in the
% stimulus creation process if we are using DEBUG mode. The arguments must
% be (1) the stimulus values, or data, (2) the plot type to use, (3) any
% wait time after drawing the visualization. Optionally, more arguments can
% be used where the 4th, 6th, etc. are the function calls and the 5th,
% 7th, etc. are the arguments for those functions.

global DEBUG
if ~DEBUG; return; end


stimulus = varargin{1};
if ~iscell(stimulus)
    stimulus = {stimulus};
end


plot_command = [varargin{2} '('];
for s = 1:length(stimulus)
    if s < length(stimulus); character = ','; else character = ');'; end
    plot_command = [plot_command 'stimulus{' num2str(s) '}' character];
end
eval(plot_command)


for var = 4:2:length(varargin)
    eval([varargin{var} '(' varargin{var+1} ');']);
end


drawnow;
WaitSecs(varargin{3});


