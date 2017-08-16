function [pts, validity] = correctOutOfBoundPts(old_pts,old_valid,sz)
%%% CORRECTOUTOFBOUNDPTS clean up points tracked out of image region
%%% During the tracking process some points will be assigned to positions
%%% outside of the image. Correct these (i.e. bring coordinates in bounds)
%%% and mark the points as invalid.
%%% old_pts: Nx2 vector of points to correct
%%% old_valid: Nx1 vector of validity
%%% sz:      [sizeY sizeX] 1x2 vector of the size of the image

%Checking for errors
[num_p,~] = size(old_pts);
[num_v,~] = size(old_valid);
assert(num_p == num_v,'Error: mismatch in size of points and validity');


pts = double(old_pts);
validity = logical(old_valid);
%Find points whose x or y coordinate is less than 0 and adjust to 1
[low_bounds,~] = find(old_pts <= 0);
disp(low_bounds)
pts(low_bounds,:) = ones(numel(low_bounds),2,'double');
validity(low_bounds) = false;

%Find points whose x or y coordinate is greater than the image bounds
%Recall pts are in (x,y) format not (row,col) format
[high_bounds,~] = find((old_pts(:,1)>sz(2)) | (old_pts(:,2)>sz(1)));

pts(high_bounds,:) = ones(numel(high_bounds),2,'double');
validity(high_bounds) = false;

