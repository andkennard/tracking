reader = bfGetReader('20x_1xopt_Wounding_fish_2_Max.tif');

%%
params.num_bins = [8,8];
params.preprocess_func = @trackingImPreprocessBackgroundSub;
params.MaxBidirectionalError = 1;
params.BlockSize = [41,41];
params.track_margin = 1;
params.init_margin_mask = imread('MarginMask_2.tif');
params.testing_stop_frame = 0;
params.point_update_delay = 5;
params.point_density_thresh = 0.008;
params.point_update_interval = 4;
params.alphaParam = 20;
%%
all_points = trackPoints(reader,params);

%%
im_filename = initAppendFile('im_tracked.tif');
sizeT = reader.getSizeT();
for iT = 1:sizeT
    im = bf_getFrame(reader,1,1,iT);
    im = double(trackingImPreprocessBackgroundSub(im));
    im = uint8((255/(max(im(:)) - min(im(:)))) * (im - min(im(:))));
    goodpts_interior = all_points(iT).coords(all_points(iT).validity & ~all_points(iT).is_margin,:);
    goodpts_margin   = all_points(iT).coords(all_points(iT).validity &  all_points(iT).is_margin,:);
    im_marked = insertMarker(im,goodpts_interior,'+','Color','Green');
    im_marked = insertMarker(im_marked,goodpts_margin,'+','Color','Blue');
    imwritemulti(im_marked,im_filename);
end

%%
