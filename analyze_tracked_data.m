%% Parameters
CV_THRESH = 0.1;

%% Put all position data into a matrix; each row is x1,y1,x2,y2,...xN,yN for
%  each trajectory (NaN otherwise). 
[num_trajectories,num_timepoints] = findPositionMatrixDimensions(all_points);
position_data = nan(num_trajectories,2*num_timepoints);

for t = 1:num_timepoints
    goodpts = find(all_points(t).validity);
    goodIDs = all_points(t).ID(goodpts);
    goodcoords = all_points(t).points(goodpts,:);
    position_data(goodIDs,(2*t-1):(2*t)) = goodcoords;
end
%Clean-up data: Find trajectories that are 1 timepoint or less

no_tracks = find(sum(~isnan(position_data),2)<=2);
position_data(no_tracks,:) = [];
%% Get the x and y displacement components u and v (resp.) for the data
pixel_scale = 0.225; %microns per pixel
time_scale  = 30; %30 seconds per timepoint
velocity_scale = pixel_scale / time_scale;
u =  velocity_scale * (position_data(:,3:2:end) - position_data(:,1:2:(end-2)));
%y-coordinates for image are flipped from how we usually think of them
v = -velocity_scale * (position_data(:,4:2:end) - position_data(:,2:2:(end-2)));

speed = sqrt(u.^2 + v.^2);
%% Create a bin index for the data
bin_size = 32;
num_bins_x = sizeX/bin_size;
num_bins_y = sizeY/bin_size;
[~,~,SUB_X] = histcounts(position_data(:,1:2:end),0:bin_size:sizeX);
[~,~,SUB_Y] = histcounts(position_data(:,2:2:end),0:bin_size:sizeY);




%% Take the mean of data with accumarray
subsY = SUB_Y(:,1:(end-1));
subsX = SUB_X(:,1:(end-1));
subsT = repmat(1:(num_timepoints-1),length(SUB_Y),1);
%Find a way to deal with NaN values -- put them in the t=40 area
subsT((subsY==0) | (subsX==0)) = 40;
subsY(subsY==0) = 1;
subsX(subsX==0) = 1;

subs = [subsY(:) subsX(:) subsT(:)];
mean_speed = accumarray(subs,speed(:),[],@(x) nanmean(x));
var_speed  = accumarray(subs,speed(:),[],@(x) nanvar(x));
cv_speed   = var_speed./mean_speed;


%% Check for outliers
speed_cellarray = accumarray(subs,speed(:),[],@(x) {x});

%%
%mean_speed_display = mean_speed;
%mean_speed_display(isnan(mean_speed_display)) = 0;
kymograph_along_x = nanmean(mean_speed,1);
kymograph_along_x = reshape(kymograph_along_x,[32,40]);
%kymograph_along_x(isnan(kymograph_along_x)) = 0;
figure,imshow(kymograph_along_x,[])
kymograph_im = uint8((255/(max(kymograph_along_x(:)) - min(kymograph_along_x(:)))) * (kymograph_along_x - min(kymograph_along_x(:))));
imwrite(kymograph_im,'kymograph_point_tracking.tif');

