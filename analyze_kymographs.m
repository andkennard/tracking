%% Get the file names for all the datasets

[WT1_fname,WT1_path] = uigetfile('*.mat');
[WT2_fname,WT2_path] = uigetfile('*.mat');
[WT3_fname,WT3_path] = uigetfile('*.mat');

%% Load the data
fnames = {WT1_fname,WT2_fname,WT3_fname};
paths  = {WT1_path,WT2_path,WT3_path};
data   = cell(size(fnames));
mean_speeds = cell(size(fnames));
for k = 1:numel(fnames)
    data{k} = load(fullfile(paths{k},fnames{k}));
    mean_speeds{k} = data{k}.mean_speed;
end

%% Get the size of the aggregate array (max size of all the other arrays
size_x = max(cellfun(@(x) size(x,2),mean_speeds))+1;
size_y = max(cellfun(@(x) size(x,1),mean_speeds))+1;

total_speeds = zeros(size_y,size_x);
total_counts = zeros(size_y,size_x);
for k =1:numel(mean_speeds)
    s = mean_speeds{k};
    [sY,sX] = size(s);
    counts = ones(size(s));
    t = size_x - sX;
    s = padarray(s,[0,size_x-size(s,2)],'post');
    s = padarray(s,[size_y-size(s,1),0],'pre');
    counts = padarray(counts,[0,size_x-size(counts,2)],'post');
    counts = padarray(counts,[size_y-size(counts,1),0],'pre');
    total_speeds = total_speeds + s;
    total_counts = total_counts + counts;
end

avg_speed = total_speeds ./ total_counts;
figure,imshow(avg_speed,[])
    
%%
[XV,YV] = meshgrid(0:30:1200,0:10:630);
x =avg_speed(end:-1:1,:);
figure('units','inches');
v = [0,.05:.01:max(avg_speed(:))];
[c,h] = contourf(XV,YV,cavg,v,'LineWidth',2);
daspect([3,1,1])
set(gca,'FontSize',18)
ylabel('Distance from Wound (µm)')
xlabel('Time (s)')
cb = colorbar;
caxis([0,max(avg_speed(:))])
ylabel(cb,'Speed (µm/s)','FontSize',18)
axis([0,800,0,350])

%%
havg = fspecial('average');
hgaus = fspecial('gaussian');
cavg = imfilter(x,havg,'symmetric');
figure,contour(XV,YV,cavg,v,'LineWidth',2);
cgaus = conv2(x,hgaus,'same');
figure,contour(XV,YV,cgaus,v,'LineWidth',2);

%%
[FX,FY] = gradient(cavg,30,10);
figure,imshow(FX,[])
figure,quiver(FX,FY)
figure,contourf(cavg,v)
[xi,yi] = ginput
%%
grad_x_i = interp2(1:41,1:64,FX,xi,yi,'cubic');
grad_y_i = interp2(1:41,1:64,FY,xi,yi,'cubic');
slope = -grad_x_i./grad_y_i;
figure,plot(slope)