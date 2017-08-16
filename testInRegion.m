function in_region = testInRegion(p,mask)
%%% Given a list of points, determine if they are in the region of a given
%%% mask
%%% p - Nx2 list of x,y coordinates of points
%%% mask - binary mask with same domain as the image from which the points
%%%        p were extracted.
%%% Returns in_region, a set of logical values testing if the point is in
%%% the region or not
mask = logical(mask);
[sizeY,sizeX] = size(mask);
%Ensure the points can be interpreted as pixel indices
p = round(double(p));
p(p<1) = 1;
p(p(:,1)>sizeX) = sizeX;
p(p(:,2)>sizeY) = sizeY;

pidx = sub2ind([sizeY,sizeX],p(:,2),p(:,1));
in_region = mask(pidx);
end
