function im_p = trackingImPreprocess(im)
%%% Function to preprocess images before tracking. 

%Currently use a median filter with a 3x3 window to remove hot pixels,
%followed by adaptive histogram equalization (default choices in MATAB)

im_medfilt = medfilt2(im,[3,3]);
im_p = adapthisteq(im_medfilt);
end