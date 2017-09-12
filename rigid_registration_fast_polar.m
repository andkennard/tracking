reader = bfGetReader('20x_1xopt_Wounding_fish_2_Max.tif');
im1 = double(bf_getFrame(reader,1,1,1));
gfilt1 = fspecial('gaussian',[1,128],64);
gfilt2 = fspecial('gaussian',[128,1],64);
im1_f = imfilter(im1,gfilt1,'symmetric');
im1_f = imfilter(im1_f,gfilt2,'symmetric');
sizeT = reader.getSizeT();
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();
W = 5;
regimfname = initAppendFile('test_rigid_reg.tif');
offsets = zeros(10,2);
peak_locs = zeros(10,2);
fracs = zeros(10,2);
thetas = zeros(10,1);
im8 = uint8((255/(max(im1(:)) - min(im1(:)))) * (im1 - min(im1(:))));
imwritemulti(im8,regimfname);
for iT = 2:10
    im2 = double(bf_getFrame(reader,1,1,iT));
    %
    %Polar registration
    im1fft = fftshift(abs(fft2(im1)));
    im1polt = polTransformFast(im1fft,[1,sizeX/2],[20,64]);

    im2fft = fftshift(abs(fft2(im2)));
    im2polt = polTransformFast(im2fft,[1,sizeX/2],[20,64]);

    product = fft2(im2polt) .* conj(fft2(ifftshift(im1polt)));
    correlation = real(ifft2(product));
    [peakr,peakc] = find(correlation == max(correlation(:)));
    %Subpixel localization
    searchWindow = correlation((peakr-W):(peakr+W), (peakc-W):(peakc+W));
    thresh4 = mean(searchWindow(:)) + 1 * std(searchWindow(:));
    [threshR, threshC] = find(searchWindow > thresh4);
    numThresh = size(threshR, 1);

    threshI = searchWindow(searchWindow>thresh4) - thresh4;

    centroidR = sum(threshR .* threshI) / sum(threshI);
    centroidC = sum(threshC .* threshI) / sum(threshI);
    midW = W+1;
    centroidA = (centroidC - midW) + peakc;

    thetas(iT) = thetas(iT-1) + (centroidA - (sizeX/4)) * (360/sizeX);
    
    im2rot = imrotate(im2,-thetas(iT),'bicubic','crop');
    %}
    
    %Proceed to translation registration
    im2_f = imfilter(im2rot,gfilt1,'symmetric');
    im2_f = imfilter(im2_f,gfilt2,'symmetric');
    
    trans_xc = normxcorr2(im1_f,im2_f);
    [ypeak,xpeak] = find(trans_xc == max(trans_xc(:)));
    peak_locs(iT,:) = [xpeak-sizeX,ypeak-sizeY];
    %Subpixel localization
    searchWindow = trans_xc((ypeak - W):(ypeak+W),(xpeak-W):(xpeak+W));
    thresh4 = mean(searchWindow(:)) + 1 * std(searchWindow(:));
    [threshR,threshC] = find(searchWindow > thresh4);
    numThresh = size(threshR,1);
    threshI = searchWindow(searchWindow > thresh4) - thresh4;
    centroidR = sum(threshR .* threshI) / sum(threshI);
    centroidC = sum(threshC .* threshI) / sum(threshI);
    midW  = W+1;
    fracs(iT,:) = [(centroidC - midW) ,(centroidR-midW)];
    offsets(iT,:) = offsets(iT-1,:) + [(centroidC - midW) + xpeak,(centroidR - midW) + ypeak] - [sizeX,sizeY];
    im2trans = imtranslate(im2rot,-offsets(iT,:),'cubic');
    im2t8 = uint8((255/(max(im2trans(:)) - min(im2trans(:)))) * (im2trans - min(im2trans(:))));
    imwritemulti(im2t8,regimfname);
    im1_f = im2_f;
end
    %%
    im2trans = imtranslate(im2,-offset);
    figure,imshowpair(im1,im2)
    figure,imshowpair(im1,im2trans)
    %%
    trans_corr_offset = -[(ypeak - orig_sizeY)
                         (xpeak - orig_sizeX)];
    offsets(iT,:) = offsets(iT-1,:) + trans_corr_offset';
    im2trans = imtranslate(im2rot,offsets(iT,:));
    im2trans_8 = uint8((255/(max(im2trans(:))- min(im2trans(:)))) * (im2trans - min(im2trans(:))));
    imwritemulti(im2trans_8,regimfname);