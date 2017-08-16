im = bf_getFrame(reader,1,1,1);
sizeY = reader.getSizeY();
sizeX = reader.getSizeX();
immedfilt = medfilt2(im,[3,3]);
im_heq = adapthisteq(immedfilt);

points0obj = detectMinEigenFeatures(im);
points0 = points0obj.Location();

points_filt_obj = detectMinEigenFeatures(im_heq);
points_filt = points_filt_obj.Location();

point0Image = insertMarker(im,points0,'+','Color','Green');
pointfiltImage = insertMarker(im_heq,points_filt,'+','Color','Green');

figure,imshow(point0Image,[])
figure,imshow(pointfiltImage,[])

%%
im = bf_getFrame(reader,1,1,1);
figure,imshow(im,[])
Hrect = imrect;
mask = Hrect.createMask();
ac = activecontour(im,mask);
figure,imshow(ac,[])

%%
margin_mask = logical(imread('MarginMask.tif'));
points_filt = round(points_filt);
points_filt(points_filt<1) = 1;
points_filt(points_filt(:,1)>sizeX,:) = sizeX;
points_filt(points_filt(:,2)>sizeY,:) = sizeY;
idx = sub2ind([sizeY,sizeX],points_filt(:,2),points_filt(:,1));
margin_point = margin_mask(idx);

%%
pts = round(all_points(1).points);
pts(pts<1) = 1;
pts(pts(:,1)>sizeX) = sizeX;
pts(pts(:,2)>sizeY) = sizeY;
idx = sub2ind([sizeY,sizeX],pts(:,2),pts(:,1));
margin_pts = margin_mask(idx);


goodpts_margin = find(all_points(1).validity &  margin_pts);
goodpts_inner  = find(all_points(1).validity & ~margin_pts);
for k = 1:5
    im = bf_getFrame(reader,1,1,k);
    imPoints = insertMarker(im,all_points(k).points(goodpts_inner,:),'+','Color','Green');
    imPoints = insertMarker(imPoints,all_points(k).points(goodpts_margin,:),'+','Color','Blue');
    imwritemulti(imPoints,'tracked_margin.tif');
end

%%
x = double(all_points(5).points(goodpts_margin,:));
%figure,plot(x(:,1)',x(:,2)','.')
shp = alphaShape(x(:,1),x(:,2));
alphas = 10:2:30;
areas = zeros(size(alphas));
for j = 1:numel(alphas);
shp.Alpha = alphas(j);
areas(j) = area(shp);
figure,plot(shp);
titlestr = sprintf('\alpha = %d',alphas(j));
title(titlestr,'FontSize',16,'FontWeight','Bold')
end
figure,plot(alphas,areas)

%%
shrink_factors = 0.4;
areas = zeros(size(shrink_factors));
perimeters = zeros(size(shrink_factors));
for j = 1
    [bidx,A] = boundary(x,shrink_factors(j));
    bcoords = x(bidx,:);
    pointwise_disps = bcoords(2:end,:) - bcoords(1:(end-1),:);
    pointwise_dist = sqrt(sum(pointwise_disps.^2,2));
    perimeter = sum(pointwise_dist,1) + sqrt((bcoords(1,1)-bcoords(end,1))^2 + (bcoords(1,2)-bcoords(end,2))^2);
    perimeters(j) = perimeter;
    areas(j) = A;
    %
    figure,plot(x(:,1),x(:,2),'b.')
    hold on
    plot(x(bidx,1),x(bidx,2),'r-')
    titlestr = sprintf('Shrink factor %d',shrink_factors(j));
    title(titlestr,'Fontsize',16,'FontWeight','Bold');
    axis equal
    %}
end
figure,semilogx(shrink_factors,areas)
title('Areas')
figure,semilogx(shrink_factors,perimeters)
title('Perimeters')
figure,semilogx(shrink_factors,perimeters./areas)
title('P/A')