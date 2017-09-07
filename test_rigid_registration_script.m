reader = bfGetReader('20x_1xopt_Wounding_fish_2_Max_downsampled.tif');
im1 = double(bf_getFrame(reader,1,1,30));
im2 = double(bf_getFrame(reader,1,1,40));
[sizeY,sizeX] = size(im1);
x = hann(sizeY);
xx = repmat(x,[1,sizeX]);
%imwrite(xx,'hann_window_464x464.tif');
im1_hann = im1.*xx;
im2_hann = im2.*xx;
im1_sq = padarray(im1_hann,[(sizeX-sizeY)/2,0]);
im2_sq = padarray(im2_hann,[(sizeX-sizeY)/2,0]);

figure,imshow(im1_sq,[])
im1f = fftshift(fft2(im1_sq));
figure,imshow(log(abs(im1f)),[])

im1pfft = PFFT(im1_sq);
im2pfft = PFFT(im2_sq);
figure,imshow(log(abs(im1pfft)),[])
figure,imshow(log(abs(im2pfft)),[])

%%
figure,imshowpair(log(abs(im1pfft)),log(abs(im2pfft)))
x = log(abs(im1pfft));
x8 = uint8((255/(max(x(:))-min(x(:)))) * (x - min(x(:))));
imwrite(x8,'im1pfft.tif');
%%
im1_bp = abs(im1pfft(320:440,:));
im2_bp = abs(im2pfft(320:440,:));
[sizeY,sizeX] = size(im1_bp);

a= fft2(im1_bp);
b = fft2(im1_bp);
ccor = ifft2(conj(a).*b);
%figure,imshow(ccor,[])
cc = normxcorr2(im1_bp,im2_bp);
%figure,imshow(abs(cc),[])
%surf(abs(cc)),shading flat

[ypeak,xpeak] = find(cc == max(cc(:)));
yoffset = ypeak - sizeY;
xoffset = xpeak - sizeX;

theta = -9*180/928;


%%
im2rot = imrotate(im2,theta,'bicubic','crop');
[sizeY,sizeX] = size(im1);

%%
translate_cc = normxcorr2(im1,im2rot);

[ypeak,xpeak] = find(translate_cc == max(translate_cc(:)));
yoffset = ypeak - 288;
xoffset = xpeak - 464;

tvec = -[xoffset,yoffset];
%%
im2trans = imtranslate(im2rot,tvec);
figure,imshowpair(im1,im2trans)
figure,imshowpair(im1,im2rot)
figure,imshowpair(im1,im2)

%% 
tonly_cc = normxcorr2(im1,im2);
[ypeak,xpeak] = find(tonly_cc == max(tonly_cc(:)));
yoffset = ypeak - sizeY;
xoffset = xpeak - sizeX;

tonly_vec = -[xoffset,yoffset];
im2tonly = imtranslate(im2,tvec);
figure,imshowpair(im1,im2);
title('no reg')
figure,imshowpair(im1,im2rot)
title('rotation only')
figure,imshowpair(im1,im2tonly)
title('translation only')
figure,imshowpair(im1,im2trans)
title('rotation+translation')


%%
regimfname = initAppendFile('test_rigid_registration.tif');
freq_ratio_high = 0.3103;
freq_ratio_low  = 0.0517;
im1 = double(bf_getFrame(reader,1,1,1));
sizeT = reader.getSizeT();
[orig_sizeY,orig_sizeX] = size(im1);
%Make square and smooth out to 1 with a Hann window
x = hann(orig_sizeY);
xx = repmat(x,[1,orig_sizeX]);
im1_hann = im1.*xx;
im1_sq = padarray(im1_hann,[(orig_sizeX-orig_sizeY)/2,0]);

im1_pfft = PFFT(im1_sq);
thetas = zeros(sizeT,1);
offsets = zeros(sizeT,2);
im1_8 = uint8((255/(max(im1(:)) - min(im1(:)))) * (im1 - min(im1(:))));
imwritemulti(im1_8,regimfname);
for iT = 2:5
    im2 = double(bf_getFrame(reader,1,1,iT));
    im2_hann = im2.*xx;
    im2_sq = padarray(im2_hann,[(orig_sizeX-orig_sizeY)/2,0]);
    [sq_size,~] = size(im2_sq);
    im2_pfft = PFFT(im2_sq);
    freq_selection_high = round(sq_size*(1-freq_ratio_high));
    freq_selection_low  = round(sq_size*(1-freq_ratio_low));
    im1_bp = abs(im1_pfft(freq_selection_high:freq_selection_low,:));
    im2_bp = abs(im2_pfft(freq_selection_high:freq_selection_low,:));
    [p_sizeY,p_sizeX] = size(im1_bp);
    rot_xc = normxcorr2(im1_bp,im2_bp);
    [ypeak,xpeak] = find(rot_xc == max(rot_xc(:)));
    rot_corr_offset = [(ypeak - p_sizeY)
                       (xpeak - p_sizeX)];
    thetas(iT) = thetas(iT-1)+(rot_corr_offset(2)*180/p_sizeX); %get the rotation angle in degrees
    im2rot = imrotate(im2,thetas(iT),'bicubic','crop');
    trans_xc = normxcorr2(im1,im2rot);
    [ypeak,xpeak] = find(trans_xc == max(trans_xc(:)));
    trans_corr_offset = -[(ypeak - orig_sizeY)
                         (xpeak - orig_sizeX)];
    offsets(iT,:) = offsets(iT-1,:) + trans_corr_offset';
    im2trans = imtranslate(im2rot,offsets(iT,:));
    im2trans_8 = uint8((255/(max(im2trans(:))- min(im2trans(:)))) * (im2trans - min(im2trans(:))));
    imwritemulti(im2trans_8,regimfname);
    im1_pfft = im2_pfft;
    
end 

%%
tx = -75;
ty = -75;
t = [cosd(theta), -sind(theta),0;
     sind(theta),  cosd(theta),0;
     tx*cosd(theta)+ty*sind(theta)-tx+tvec(1), -tx*sind(theta)+ty*cosd(theta)-ty+tvec(2), 1];
tt = affine2d(t);
xw = imwarp(x,tt,'cubic','OutputView',R);
figure,imshowpair(x,xw)