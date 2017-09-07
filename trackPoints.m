function all_points = trackPoints(reader,params)
%%% Track points

%Initialize stuff
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();
sizeT = reader.getSizeT();
h = waitbar(0,'Initializing...');

%Load first image and get some points

im1 = bf_getFrame(reader,1,1,1);
im1_p = params.preprocess_func(im1);

p0_obj = detectMinEigenFeatures(im1_p);%TODO: Make it possible to change this function
p0     = p0_obj.Location;
[num_points,~] = size(p0);

%Initialize a tracker for these points
tracker = vision.PointTracker();
tracker.MaxBidirectionalError = params.MaxBidirectionalError;
tracker.BlockSize = params.BlockSize;
initialize(tracker,p0,im1_p);

%Initialize a structure all_points to keep track of all the points. Include their xy
%locations, whether or not they are successfully tracked in that frame, 
%a unique ID, and whether they are on the wound margin or not (if that type
%of tracking is enabled)
all_points = struct('coords',[],...
                    'validity',[],...
                    'ID',[],...
                    'is_margin',[]);
%Initialize all_points with the initial points
all_points(1).coords = double(p0);
all_points(1).validity = true(num_points,1);
all_points(1).ID = uint32(1:num_points)';
if params.track_margin ==1
    [margin_y,margin_x] = find(params.init_margin_mask);
    init_shp = alphaShape(margin_x,margin_y,20);
    all_points(1).is_margin = inShape(init_shp,double(p0));
    %all_points(1).is_margin = testInRegion(p0,params.init_margin_mask);
end
%%
%For testing purposes, choose an earlier point than the end of the movie to
%stop.
if params.testing_stop_frame>0
    stop_frame = params.testing_stop_frame;
else
    stop_frame = sizeT;
end

%LOOP THROUGH MOVIE
for iT = 2:stop_frame
    progress = iT / stop_frame;
    waitbar(progress,h,sprintf('Tracking frames, %d%% completed...',progress*100));
    %Preprocess frame
    im = bf_getFrame(reader,1,1,iT);
    im_p = params.preprocess_func(im);
    
    %Track points and update all_points
    [pT, validity] = step(tracker,im_p);
    %Some points may have been "tracked" to locations outside the image.
    %Mark those as no longer valid and "correct" the location so that they
    %do not interfere with the tracker
    [pT, validity] = correctOutOfBoundPts(pT,validity,[sizeY,sizeX]);
    all_points(iT).coords = double(pT);
    all_points(iT).validity = logical(validity);
    all_points(iT).ID = all_points(iT-1).ID; %no points have been updated yet
    all_points(iT).is_margin = all_points(iT-1).is_margin;
    %Update the list of points periodically (but wait a bit to avoid very
    %high point densities that confuse tracking)
    if (iT > params.point_update_delay) && ...
       mod(iT,params.point_update_interval)==0
   disp(iT)
       
       all_points(iT) = updatePoints(all_points(iT),im_p,params); %FINISH!!!
       setPoints(tracker,single(all_points(iT).coords),all_points(iT).validity);
    end
end
close(h)
end
       
        
    

