function MakePRT(Params)

prtName = sprintf('%s_Sub%d_Run%d.prt',Params.Experiment,Params.Sub,Params.Run); % name the prt

fid = fopen(prtName,'w'); % open the file for writing

% put in the headers
fprintf(fid,'\n');
fprintf(fid,'FileVersion:\t2\n\n');
fprintf(fid,'ResolutionOfTime:\tmsec\n\n');
fprintf(fid,'Experiment:\t%s\n\n',Params.Experiment);
fprintf(fid,'BackgroundColor:\t0\t0\t0\n');
fprintf(fid,'TextColor:\t255\t255\t255\n\n');
fprintf(fid,'TimeCourseColor:\t255\t255\t255\n');
fprintf(fid,'TimeCourseThick:\t2\n');
fprintf(fid,'ReferenceFuncColor:\t0\t255\t0\n');
fprintf(fid,'ReferenceFuncThick:\t1\n\n');
fprintf(fid,'NrOfConditions:\t%d',Params.PRT.Conditions);

% generate the colors (jet is a 64x3 color table blue-green-yellow-red):
colors = 255*jet; close(gcf);
prt_colors = round(linspace(1,length(colors),Params.PRT.Conditions-1));

% scroll through each condition and put the times down
for c = 1:Params.PRT.Conditions
    
    fprintf(fid,'\n\n%s\n',Params.PRT.condition_names{c});
    
    % get and print the number of instances of the current condition
    if c < Params.PRT.Conditions && Params.remove_eye_condition_from_predictors
        instances = remove_eye_condition_from_predictors(Params.PRT.prt{c},Params.PRT.prt{end});
    else
        instances = Params.PRT.prt{c};
    end
    
    num_instances = size(instances,1);
    fprintf(fid,'%d\n',num_instances);
    
    % write the start and end times for each instance of the condition
    for i = 1:num_instances
        fprintf(fid,'\t%.0f',instances(i,:));
        fprintf(fid,'\n');
    end
    
    % write the color
    if c < Params.PRT.Conditions
        fprintf(fid,'Color:');
        fprintf(fid,'\t%d',round(colors(prt_colors(c),:)));
    else
        fprintf(fid,'Color:\t255\t255\t255');
    end
end

fclose(fid);

function instances_removed = remove_eye_condition_from_predictors(condition_instances,gaze_instances)

instances_removed = [];

for c = 1:size(condition_instances,1)
    condition_times = condition_instances(c,1) : condition_instances(c,2);
    gaze_times = [];
    for g = 1:size(gaze_instances,1)
        gaze_times = [gaze_times, gaze_instances(g,1):gaze_instances(g,2)];
    end
    [~,unique2condition,~] = union(condition_times,gaze_times);
    valid_times = condition_times(unique2condition);
    
    start_times = valid_times([1, find(valid_times(1:end-1) ~= valid_times(2:end)-1)+1]);
    end_times = valid_times([find(valid_times(1:end-1) ~= valid_times(2:end)-1), length(valid_times)]);
    
    instances_removed = [instances_removed; start_times' end_times'];
end

