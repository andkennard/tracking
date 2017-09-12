reader = bfGetReader('test_myosignal_kerats_removed_t1to12_512x512.tif');
im1 = double(bf_getFrame(reader,1,1,1));
gfilt1 = fspecial('gaussian',[1,128],64);
gfilt2 = fspecial('gaussian',[128,1],64);
im1_f = imfilter(im1,gfilt1,'symmetric');
im1_f = imfilter(im1_f,gfilt2,'symmetric');
sizeT = reader.getSizeT();
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();

im0_ref = imref2d([sizeY,sizeX],0.5*[-sizeX,sizeX],0.5*[-sizeY,sizeY]);

W = 5;
regimfname = initAppendFile('test_rigid_reg_myo.tif');
offsets = zeros(sizeT,2);
accumDisp = zeros(sizeT,2);
thetas = zeros(sizeT,1);
accumAngle = zeros(sizeT,1);
tforms = cell(sizeT,1); 
total_warp = eye(3);
im8 = uint8((255/(max(im1(:)) - min(im1(:)))) * (im1 - min(im1(:))));
imwritemulti(im8,regimfname);
for iT = 2:11
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

    thetas(iT) = (centroidA - ((sizeX/4)+1)) * (360/sizeX);
    accumAngle(iT) = accumAngle(iT-1) + thetas(iT);
    %This is just used to register the translation of the next image
    im2rot = imrotate(im2,-thetas(iT),'bicubic','crop');

    %}
    
    %Proceed to translation registration
    im2_f = imfilter(im2rot,gfilt1,'symmetric');
    im2_f = imfilter(im2_f,gfilt2,'symmetric');
    
    trans_xc = normxcorr2(im1,im2);
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
    tvec = [(centroidC - midW) + xpeak - sizeX, (centroidR - midW) + ypeak - sizeY];
    offsets(iT,:) = tvec;
    accumDisp(iT,:) = accumDisp(iT-1,:) + offsets(iT,:);
    %
    im2trans = imtranslate(im2rot,-tvec);
    tforms{iT} = [cosd(thetas(iT)), -sind(thetas(iT)), 0;...
                  sind(thetas(iT)),  cosd(thetas(iT)), 0;...
                  -tvec,                               1];
    total_warp = total_warp * tforms{iT};
    im2w = imwarp(im2,im0_ref,affine2d(total_warp),'cubic','OutputView',im0_ref);
    %im2trans = imtranslate(im2rot,-offsets(iT,:),'cubic');
    im2w8 = uint8((255/(max(im2w(:)) - min(im2w(:)))) * (im2w - min(im2w(:))));
    %im2t8 = uint8((255/(max(im2trans(:)) - min(im2trans(:)))) * (im2trans - min(im2trans(:))));
    imwritemulti(im2w8,regimfname);
    %}
    im1_f = im2_f;
    im1 = im2;

end

%%
reader = bfGetReader('max_lifeact_1024x1024.tif');
regfname = initAppendFile('test_rigid_reg_lifeact_from_myo.tif');
im0_ref = imref2d([1024,1024],[-256,768],[-441,583]);
for iT = 1:11
    im = bf_getFrame(reader,1,1,iT);
    rotation_matrix = [cosd(accumAngle(iT)),-sind(accumAngle(iT)),0;...
                       sind(accumAngle(iT)), cosd(accumAngle(iT)),0;...
                       0,                    0,                   1];
    translation_matrix = [1    , 0    , 0;...
                          0    , 1    , 0;...
                          -accumDisp(iT,:),1];
    imw = imwarp(im,im0_ref,affine2d(rotation_matrix * translation_matrix),'cubic','OutputView',im0_ref);
    imwritemulti(im2uint8(imw),regfname);
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