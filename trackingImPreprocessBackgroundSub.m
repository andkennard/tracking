function [im_p,imBW] = trackingImPreprocessBackgroundSub(im)
%%% Pre-process images with background subtraction
%%% Filter images to enhance contrast, and also remove the background
%%% (which includes small features that can screw up the point detector).
%%% Background subtraction is done by splitting the image into blocks and
%%% identifying blocks with low variance. The 99th percentile of grayscale
%%% intensity in these 'background blocks' is used as a background value.
BLOCK_SIZE = 64;
STD_THRESH = 200;
MEAN_THRESH = min(im(:)); %im2col zero-pads, which can affect the mean and variance within a block
BKGD_QUANTILE = 0.99;
GAMMA_SCALE = 0.5; %Should be less than 1

im_d = double(im);

%Median filter to remove hot spots
im_d = medfilt2(im_d,[3,3],'symmetric');

%Identify background level
colmat = im2col(im_d,[BLOCK_SIZE,BLOCK_SIZE],'distinct');
block_std = std(colmat);
block_mean = mean(colmat);

bkgd_blocks    = colmat(:,block_std<STD_THRESH & block_mean >= MEAN_THRESH);
bkgd_grayscale = quantile(bkgd_blocks(:),BKGD_QUANTILE);

%Background subtract
im_frgd = im_d - bkgd_grayscale;
im_frgd(im_frgd<0) = 0;
%Convert back to 16-bit
im16 = uint16((65535/max(im_frgd(:))) * im_frgd);
%Gamma-adjustment condenses the foreground pixels and spreads out the
%remaining background pixels for better thresholding with Otsu's method
im16adj = imadjust(im16,[0,1],[0,1],GAMMA_SCALE);

%Threshold the image (Otsu) and clean up the mask
imBW = im2bw(im16adj,graythresh(im16adj));
imBW = imfill(imBW,'holes'); %Remove holes inside the mask
imBW = imopen(imBW,strel('disk',3)); %Clean the edge
imBW = bwareaopen(imBW,10^4); %Remove any small spurious regions

%Mask the processed 16-bit image
im16_masked = im16;
im16_masked(~imBW) = 0;

%Adaptive histogram equalization to increase contrast within the foreground
im_p = adapthisteq(im16_masked);
%Apparently adapthisteq also will move 0 values upwards. Correct for this
%again...
im_p(~imBW) = 0;

end