
%% Put all position data into a matrix; each row is x1,y1,x2,y2,...xN,yN for
%  each trajectory (NaN otherwise). 
[num_trajectories,num_timepoints] = findPositionMatrixDimensions(all_points);
position_data = nan(num_trajectories,2*num_timepoints);
distances = nan(num_trajectories,num_timepoints);
%Identify centroid of the margin points over time
margin_position = nan(num_trajectories,2*num_timepoints);
for t = 1:num_timepoints
    good_margin_pts   = find(all_points(t).validity &  all_points(t).is_margin);
    
    good_margin_coords = all_points(t).coords(good_margin_pts,:);
    good_margin_IDs = all_points(t).ID(good_margin_pts);
    margin_position(good_margin_IDs,(2*t-1):(2*t)) = good_margin_coords;
    
end

no_tracks = find(sum(~isnan(margin_position),2)<=2);
margin_position(no_tracks,:) = [];

% Track the centroid of margin points
centroid_position = nanmean(margin_position,1);

for t = 1:num_timepoints
    good_interior_pts = find(all_points(t).validity & ~all_points(t).is_margin);
    good_interior_IDs = all_points(t).ID(good_interior_pts);
    good_interior_coords = all_points(t).coords(good_interior_pts,:);
    
    position_data(good_interior_IDs,(2*t-1):(2*t)) = good_interior_coords;
end
centroid_all_position = nanmean(position_data,1);
centroid_position_mat = repmat(centroid_position,num_trajectories,1);
%Determine distance to the centroid of the margin points
xy = position_data - centroid_position_mat;
distances = sqrt(xy(:,1:2:end).^2 + xy(:,2:2:end).^2);
%distances = sqrt((position_data(:,1:2:end) - centroid_position_mat(:,1:2:end)).^2 +...
%                 (position_data(:,2:2:end) - centroid_position_mat(:,2:2:end)).^2);
            
%Clean-up data: Find trajectories that are 1 timepoint or less

no_tracks = find(sum(~isnan(position_data),2)<=2);
distances(no_tracks,:) = [];
position_data(no_tracks,:) = [];
xy(no_tracks,:) = [];
%% Get the x and y displacement components u and v (resp.) for the data
pixel_scale = 0.7; %microns per pixel
time_scale  = 30; %30 seconds per timepoint
velocity_scale = pixel_scale / time_scale;
u =  velocity_scale * (position_data(:,3:2:end) - position_data(:,1:2:(end-2)));
%y-coordinates for image are flipped from how we usually think of them
v = -velocity_scale * (position_data(:,4:2:end) - position_data(:,2:2:(end-2)));

speed = sqrt(u.^2 + v.^2);

%% Determine the true distance (in microns) for each point from the margin
pixel_scale = 0.7;
time_scale = 30;

true_distances = pixel_scale * distances;
%speed = abs(v);

%% Bin points by distance from margin, and plot their absolute speed
kymograph_fname = initAppendFile(fullfile(pathname,'distance_kymograph.tif'));
bins = 0:10:(max(true_distances(:))+10);
[num_good_trajectories,~] = size(true_distances);
[N,~,bin_idx] = histcounts(true_distances,bins);
SUB_T = repmat(1:(num_timepoints-1),num_good_trajectories,1);
SUB_D = bin_idx(:,1:(end-1));
SUB_T(SUB_D==0) = num_timepoints;
SUB_D(SUB_D==0) = 1;
subs = [SUB_D(:),SUB_T(:)];
mean_speed = accumarray(subs,speed(:),[],@(x) nanmean(x));
mean_speed = mean_speed(end:-1:1,:);
mean_speedu8 = uint16((65355/(max(mean_speed(:)) - min(mean_speed(:)))) * (mean_speed(:,1:end-1) - min(mean_speed(:))));
imwrite(mean_speedu8,kymograph_fname);
figure,imshow(mean_speedu8,[])

%% Plot distance from wound in colorscale
distance_fname = initAppendFile(fullfile(pathname,'marked_image_distance_colorcoded.tif'));
num_bins = max(bin_idx(:));
cmap = colormap(parula(num_bins));
cmap = 255*cmap(end:-1:1,:);
for t=1:num_timepoints
im_c = im2uint8(bf_getFrame(reader,1,1,t));
positions = position_data(bin_idx(:,t)~=0,(2*t-1):(2*t));
b = bin_idx(bin_idx(:,t)~=0,t);
marker_colors = cmap(b,:);
im_c = insertMarker(im_c,positions,'+','Color',marker_colors);
imwritemulti(im_c,distance_fname)
end
figure,imshow(im_c,[])


%% Save data
[~,fn,~] = fileparts(filename);
savefname = fullfile(pathname,sprintf('%s_trajectory_data.mat',fn));

save(savefname,'all_points','true_distances','speed','pixel_scale','time_scale','mean_speed','centroid_position','params');
    
%{
%% Collect coordinates of points on margin at each timepoint
[num_trajectories,num_timepoints] = findPositionMatrixDimensions(all_points);
margin_position = nan(num_trajectories,2*num_timepoints);
distances = nan(num_trajectories,num_timepoints);
for t = 1:num_timepoints
    good_margin_pts   = find(all_points(t).validity &  all_points(t).is_margin);
    
    good_margin_coords = all_points(t).coords(good_margin_pts,:);
    good_margin_IDs = all_points(t).ID(good_margin_pts);
    margin_position(good_margin_IDs,(2*t-1):(2*t)) = good_margin_coords;
    
end

no_tracks = find(sum(~isnan(margin_position),2)<=2);
margin_position(no_tracks,:) = [];

%% Track the centroid of margin points

centroid_position = nanmean(margin_position,1);
figure,plot(centroid_position(1:2:end),centroid_position(2:2:end),'b-')
xlim([0,897])
ylim([0,435])

figure,plot(centroid_all_position(1:2:end),centroid_all_position(2:2:end),'b-')
xlim([0,897])
ylim([0,435])
%}

%% Plot speed as a function of time in color scale
speedcolorfname= initAppendFile(fullfile(pathname,'marked_image_speed_colorcoded.tif'));
edges = linspace(0,0.4,50);
[~,~,speed_bin_idx] = histcounts(speed,edges);
cmap  = colormap(parula(numel(edges)));
cmap = 255*cmap;

for t=1:(num_timepoints-1)
    im_c = im2uint8(bf_getFrame(reader,1,1,t));
    positions = position_data(speed_bin_idx(:,t)~=0,(2*t-1):(2*t));
    b = speed_bin_idx(speed_bin_idx(:,t)~=0,t);
    marker_colors = cmap(b,:);
    im_c = insertMarker(im_c,positions,'+','Color',marker_colors);
    im_c = insertMarker(im_c,centroid_position((2*t-1):(2*t)),'o','Color','Red','Size',5);
    imwritemulti(im_c,speedcolorfname);
end
figure,imshow(im_c,[])
%% Try to actually plot trajectories
velocity_fname = initAppendFile(fullfile(pathname,'velocities_marked.tif'));
im1  = im2uint8(bf_getFrame(reader,1,1,1));
valid_pts = all(~isnan(position_data(:,1:4)),2);
im1 = insertShape(im1,'FilledCircle',[position_data(valid_pts,1:2),ones(sum(valid_pts),1)],'Color','Yellow');

imwritemulti(im1,velocity_fname);
for t= 1:(num_timepoints-1)
    valid_velocities = all(~isnan(position_data(:,(2*t-1):(2*(t+1)))),2);
    im_c = im2uint8(bf_getFrame(reader,1,1,t));
    im_c = insertShape(im_c,'Line',position_data(valid_velocities,(2*t-1):(2*(t+1))));
    imwritemulti(im_c,velocity_fname);
end
figure,imshow(im_c,[])
    

%{
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

%%
t=1;
 goodpts = find(all_points(t).validity);
    goodIDs = all_points(t).ID(goodpts);
    goodcoords = all_points(t).coords(goodpts,:);
    goodismargin = all_points(t).is_margin(goodpts,:);
interior_pts = goodcoords(~goodismargin,:);
margin_pts = goodcoords(goodismargin,:);
distances = pdist2(interior_pts,margin_pts);
%}