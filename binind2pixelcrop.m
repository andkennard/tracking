function crop_window = binind2pixelcrop(bin_sz,edges_x,edges_y,iB)
%%% BININD2PIXELcrop Get Pixel crop window (xy) from linear bin index.
%%% Similar to ind2sub, convert from the linear index of a
%%% binned image into the XY pixel coordinates of the image. 
%%% Further convert that to a crop window [x y width height] used by
%%% imcrop.
%%% Inputs
%%% bin_sz: [bin_siz_y bin_sz_x] 1x2 vector indicating the dimensions of
%%% the bin grid
%%% edges: vectors of the starting coordinates of the bins (NB: they may start
%%% at 0); the last entry is the ending coordinate of the last bin
%%% iB: the linear bin index (row-column style) that needs to be converted
%%% to two bin indices.

% Error handling
assert(iB<=bin_sz(1) * bin_sz(2),'bin index lies outside bin_size range');


%edges are for assuming continuous space values ranging from e.g. 0 to
%sizeX-1, while for imcropping you need discrete 1-based indexing. This
%requires some transformation of the edges: everything increases by 1
%except the last index.

edges_x(1:end-1) = edges_x(1:end-1) + 1;

edges_y(1:end-1) = edges_y(1:end-1) + 1;


%Convert linear index into subscripts (for the bins)
[iBY,iBX] = ind2sub(bin_sz,iB);

%Get the dimensions of the crop window from the edge lines (remember
%bin k goes from edge(k)<= bin(k) < edge(k+1)
iX = edges_x(iBX);
width = edges_x(iBX+1) - iX - 1;
iY = edges_y(iBY);
height = edges_y(iBY+1) - iY - 1;

crop_window = [iX iY width height];
