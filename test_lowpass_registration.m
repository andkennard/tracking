%% Try registration with blurring of the image (essentially long-pass out
%% the cell information

reader = bfGetReader('20x_1xopt_Wounding_fish_2_Max.tif');

im1 = double(bf_getFrame(reader,1,1,30));
im2 = double(bf_getFrame(reader,1,1,40));


%%
gfilt = fspecial('gaussian',[64,64],25);
gfilt1 = fspecial('gaussian',[1,64],25);
gfilt2 = fspecial('gaussian',[64,1],25);

%%

im1_f = imfilter(im1,gfilt1,'symmetric');
im1_f = imfilter(im1_f,gfilt2,'symmetric');
im2_f = imfilter(im2,gfilt1,'symmetric');
im2_f = imfilter(im2_f,gfilt2,'symmetric');
[sizeY,sizeX] = size(im1);
cc = normxcorr2(im1_f,im2_f);
[ypeak,xpeak] = find(cc == max(cc(:)));
yoffset = ypeak - sizeY;
xoffset = xpeak - sizeX;

tvec = -[xoffset,yoffset];
im2t = imtranslate(im2,tvec);
figure,imshowpair(im1,im2t)

%%
im1fft = fftshift(abs(fft2(im1)));
im1polt = polTransformFast(im1fft,[1,283],[20,64]);

im2fft = fftshift(abs(fft2(im2)));
im2polt = polTransformFast(im2fft,[1,283],[20,64]);

product = fft2(im2polt) .* conj(fft2(ifftshift(im1polt)));
correlation = real(ifft2(product));
thresh3 = max(correlation(:));

[peakr,peakc] = find(correlation == thresh3);
searchWindow = correlation((peakr-5):(peakr+5), (peakc-5):(peakc+5));
thresh4 = mean(searchWindow(:)) + 1 * std(searchWindow(:));
[threshR, threshC] = find(searchWindow > thresh4);
numThresh = size(threshR, 1);
if numThresh < 1
  error('peak centroid calculation failed');
end
threshI = zeros(size(threshR));
for m = 1:numThresh
%   threshI(m) = searchWindow(threshR(m), threshC(m));
  threshI(m) = searchWindow(threshR(m), threshC(m)) - thresh4;
end
centroidR = sum(threshR .* threshI) / sum(threshI);
centroidC = sum(threshC .* threshI) / sum(threshI);
centroidA = (centroidC - 6) + peakc;

rotA = (centroidA - 144) * (180/283);

im2rot = imrotate(im2,-rotA);
im2trans = imtranslate(im2,[50,50]);
figure,imshowpair(im1,im2rot);
figure,imshowpair(im1,im2);

%%
im1p = log(abs(im1polt));
im1p_8 = uint8((255/(max(im1p(:)) - min(im1p(:)))) * (im1p - min(im1p(:))));
imwrite(im1p_8,'testpolar.tif');