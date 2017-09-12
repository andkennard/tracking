%% Try to identify distinct regions of cell behavior as a function of distance from the wound centroid

[v_fname,v_path] = uigetfile('*.tif');

reader = bfGetReader(fullfile(v_path,v_fname));

%%
reader= bfGetReader('20x_1xopt_Wounding_fish_2_Max.tif');
%%

sizeT = reader.getSizeT();
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();
im = zeros(sizeY,sizeX,'uint8');
coords = all_points(1).coords(:,1:2);
d = 0.7*sqrt((coords(:,1)-centroid_position(1)).^2 + (coords(:,2)-centroid_position(2)).^2);
c1 = coords(d<175,:);
c2 = coords(d>250,:);
xpos1 = min(c1(:,1));
xpos2 = max(c2(:,1));

%% Identify points who are less than 175µm away
v_radius_fname = initAppendFile(fullfile(v_path,'movie_with_regions.tif'));
iT = 1;
sizeX = reader.getSizeX();
sizeY = reader.getSizeY();
v_reader = bfGetReader(fullfile(v_path,v_fname));
v_im = zeros(sizeY,sizeX,3,'uint8');
for iT = 1:sizeT
    mask = zeros(sizeY,sizeX,3,'uint8');
    im = bf_getFrame(reader,1,1,iT);
    [~,imBW] = trackingImPreprocessBackgroundSub(im);
    imBW3 = repmat(imBW,[1,1,3]);
    %Find points that are less than 175
    first_circle = [centroid_position(2*iT-1),centroid_position(2*iT),175/0.7];
    second_circle = [centroid_position(2*iT-1),centroid_position(2*iT),250/0.7];
    colors = [255,5,5;244,176,66]; %related to the parula colormap
    mask = insertShape(mask,'Circle',[first_circle;second_circle],'Color',colors,'LineWidth',5);
    mask(~imBW3) = 0;
    %{
    for iC = 1:3
        v_im(:,:,iC) = bf_getFrame(v_reader,1,iC,iT);
    end
    %}
    im3 = repmat(im2uint8(im),[1,1,3]);
   	im3(mask~=0) = mask(mask~=0);
    imwritemulti(im3,v_radius_fname);
end
%% Look at tracks that are never NaN for the entire dataset and get total displacement
always_valid = all(~isnan(position_data),2);
coords = position_data(always_valid,:);
displacements = 0.7*sqrt((coords(:,1:2:end-2) - coords(:,3:2:end)).^2 +...
                         (coords(:,2:2:end-2) - coords(:,4:2:end)).^2);
total_disp = sum(displacements,2);
edges = linspace(0,max(total_disp),50);
[~,~,disp_bin_idx] = histcounts(total_disp,edges);
colormap(plasma);
cmap = colormap(plasma(numel(edges)));
cmap = 255*cmap;
marker_colors = cmap(disp_bin_idx,:);

im = bf_getFrame(reader,1,1,1);
[~,imBW] = trackingImPreprocessBackgroundSub(im);
imBW3=repmat(imBW,[1,1,3]);
first_circle = [centroid_position(1:2),175/0.7];
second_circle = [centroid_position(1:2),250/0.7];
colors = [255,5,5;244,176,66]; %related to the parula colormap

mask = zeros(sizeY,sizeX,3,'uint8');
mask = insertShape(mask,'Circle',[first_circle;second_circle],'Color',colors,'LineWidth',5);
mask(~imBW3) = 0;

im = insertMarker(im2uint8(im),coords(:,1:2),'s','Color',marker_colors,'Size',1);
im = insertShape(im,'Circle',[centroid_position(1:2),8],'Color','red','LineWidth',3);
im(mask~=0) = mask(mask~=0);
figure,imshow(im)
colormap(plasma(numel(edges)))

cbh=colorbar();
cbh.TicksMode = 'manual';
%Determine ticks 
slope = edges(2) - edges(1);
ticklocs = (0:20:max(total_disp))/slope;
cbh.Ticks = ticklocs;
cbh.TickLabels = 0:20:max(total_disp);

%% Plot speed in colorscale
edges = linspace(0,0.4,50);
[~,~,speed_bin_idx] = histcounts(speed,edges);
cmap  = colormap(parula(numel(edges)));
cmap = 255*cmap;

for t=1:(num_timepoints-1)
    im_c = im2uint8(bf_getFrame(reader,1,1,t));
    positions = position_data(speed_bin_idx(:,t)~=0,(2*t-1):(2*t));
    b = speed_bin_idx(speed_bin_idx(:,t)~=0,t);
    marker_colors = cmap(b,:);
    im_c = insertMarker(im_c,positions,'+','Color',marker_colors);
    im_c = insertMarker(im_c,centroid_position((2*t-1):(2*t)),'o','Color','Red','Size',5);
    imwritemulti(im_c,speedcolorfname);
end
figure,imshow(im_c,[])
%%
for iT = 1:1
    for iC = 1:3
        im(:,:,iC) = bf_getFrame(reader,1,iC,iT);
    end
    im = insertShape(im,'Line',[xpos1,0,xpos1,sizeY],'LineWidth',3,'Color','Red');
    im = insertShape(im,'Line',[xpos2,0,xpos2,sizeY],'LineWidth',3,'Color','blue');
end
figure,imshow(im)