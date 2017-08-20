reader = bfGetReader('20x_1xopt_Wounding_fish_2_MAX_8bit_cropped.tif');

%%
params.num_bins = [8,8];
params.preprocess_func = @trackingImPreprocess;
params.MaxBidirectionalError = 2;
params.BlockSize = [41,41];
params.track_margin = 0;
params.init_margin_mask = imread('MarginMask.tif');
params.testing_stop_frame = 0;
params.point_update_delay = 5;
params.point_density_thresh = 0.008;
params.point_update_interval = 4;

all_points = trackPoints(reader,params);

%%
sizeT = reader.getSizeT();
for iT = 1:sizeT
    im = bf_getFrame(reader,1,1,iT);
    im = trackingImPreprocess(im);
    goodpts = all_points(iT).coords(all_points(iT).validity,:);
    im_marked = insertMarker(im,goodpts,'+','Color','Green');
    imwritemulti(im_marked,'im_tracked.tif');
end