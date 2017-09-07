%function im_p = trackingImPreprocess(im)
%%% Function to preprocess images before tracking. 

%Currently use a median filter with a 3x3 window to remove hot pixels,
%followed by adaptive background subtraction and histogram equalization (default choices in MATAB)
filename = initAppendFile('masked_im.tif');
for t = 1:sizeT
    im = bf_getFrame(reader,1,1,t);
im_medfilt = medfilt2(im,[3,3]);
%Get a mask for the fish region
    img = imgradient(im);
    img_holes = imfill(img,'holes');
    img_open = imopen(img_holes,strel('disk',5));
    imbw = logical(img_open);
    imbw_clean = bwareaopen(imbw,10^4);
    

im_p = adapthisteq(im_medfilt);
im_p(~imbw_clean) = 0;
imwritemulti(im_p,filename);
end
%end