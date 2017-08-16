function [n_valid,bin_areas,edges_x,edges_y] = getNumValidPoints(coords,SZ,BIN_SZ)
% GETNUMVALIDPOINTS Get grid showing number of points in each bin.
%     Given a list of points (size N x 2, x,y coordinates), the size of the image
%     they were drawn from SZ (sizeX sizeY), and the target size (in pixels) of each bin
%     BIN_SZ [bin_sz_X,bin_sz_Y], generate a grid in the same indexing system
%     as the image (i.e. row col not xy) that gives the number of points in
%     coords in each of the specified bins.

[edges_x,bin_widths_x] = calcBinEdgesWidths(BIN_SZ(1),SZ(1));
[edges_y,bin_widths_y] = calcBinEdgesWidths(BIN_SZ(2),SZ(2));
num_bins_x = numel(bin_widths_x);
num_bins_y = numel(bin_widths_y);

%Compute number of pixels in each bin by an outer product (remember row-col
%orientation vs xy orientation
bin_areas = bin_widths_y' * bin_widths_x;

%Compute the x and y bin subindices for each point
[~,~,BIN_X] = histcounts(coords(:,1),edges_x);
[~,~,BIN_Y] = histcounts(coords(:,2),edges_y);

%Get the number of points in each spot in the 2D binned area (with row-col
%indexing rather than xy indexing)
n_valid = accumarray([BIN_Y,BIN_X],ones(size(BIN_Y)),[num_bins_y,num_bins_x]);
end