function newpoint_struct = updatePoints(oldpoint_struct,reader,params)
    sizeX = reader.getSizeX();
    sizeY = reader.getSizeY();
    bin_size_x = floor(sizeX/params.num_bins(1));
    bin_size_y = floor(sizeY/params.num_bins(2));
    
    allcoords = oldpoint_struct.coords;
    allvalid  = oldpoint_struct.validity;
    allID     = oldpoint_struct.ID;
    
    goodcoords =  allcoords(allvalid,:);
    
    %Bin points into a 2D grid, and figure out how many points lie in each
    %point of the 2D grid (and how many pixels are in each sector of the
    %grid)
    [n_valid,bin_areas,edges_x,edges_y] = getNumValidPoints(goodcoords,[sizeX,sizeY],[bin_size_x,bin_size_y]);
    %Get the point density by dividing by the total number of pixels in
    %that bin
    point_density = n_valid ./ bin_areas;
    %Identify which bins need more points generated
    need_more_points = find(point_density < params.point_density_thresh);
    
    for p = need_more_points
        newpts = generateNewPoints(im_p,p,edges_x,edges_y,size(n_valid));
        %%% FINISH THIS FUNCTION!!!
end
    
    