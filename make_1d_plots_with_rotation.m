%% Project data onto a line through the centroid of the margin and the centroid of the interior points.
%% Bin by that projection coordinate and plot 1D

% xy has coordinates with wound centroid at the origin
% Find the centroid of the interior points at each time

interior_centroid = nanmean(xy,1);

interior_centroid_mag = sqrt((interior_centroid(1:2:end).^2 + interior_centroid(2:2:end).^2));
interior_centroid_mag = reshape([interior_centroid_mag;interior_centroid_mag],[1,2*numel(interior_centroid_mag)]);
interior_unit_vec = interior_centroid ./ interior_centroid_mag;

interior_centroid_vecs = mat2cell(interior_unit_vec,1,2*ones(1,numel(interior_unit_vec)/2));

%proj_vecs = cellfun(@(x) x'*x,interior_centroid_vecs,'UniformOutput',false);
%projection = blkdiag(proj_vecs{:});
%projected_coords = 0.7*(xy * projection);

rot_vecs = cellfun(@(x) [-x(1), x(2) ; -x(2), -x(1)],interior_centroid_vecs,'UniformOutput',false);
rotation = blkdiag(rot_vecs{:});
rotated_coords = 0.7 * ( xy * rotation);

coords_1d = rotated_coords(:,1:2:end);
%% Calculate rotation to "rotate" coordinates into the appropriate frame


edges = (min(coords_1d(:)) -1) : 10 : (max(coords_1d(:)) + 1);
bins = (edges(2:end) + edges(1:end-1))/2;
[N,~,bin_idx] = histcounts(coords_1d,edges);
[num_good_trajectories,~] = size(coords_1d);
SUB_T = repmat(1:(num_timepoints-1),num_good_trajectories,1);
SUB_D = bin_idx(:,1:(end-1));
SUB_T(SUB_D==0) = num_timepoints;
SUB_D(SUB_D==0) = 1;
subs = [SUB_D(:),SUB_T(:)];
mean_speed = accumarray(subs,speed(:),[],@(x) nanmean(x));
%mean_speed = mean_speed(end:-1:1,:);
mean_speedu8 = uint16((65355/(max(mean_speed(:)) - min(mean_speed(:)))) * (mean_speed(:,1:end-1) - min(mean_speed(:))));
%imwrite(mean_speedu8,kymograph_fname);
f = figure;
hold on
set(gca,'FontSize',16)
axis([-600,100,0,0.24]);
xlabel('Distance from wound (µm)');
ylabel('Speed (µm/s)');

for k = 1:num_timepoints -1
plot(bins',mean_speed(:,k),'b-','LineWidth',3);
fname = sprintf('/Users/akennard/Data/2017-07-07_UASLifeActGFP_hspMyoLCmApple/20x_1xopt_Wounding_fish_2/plot1d_movie/all_x_t_%i',k);
print(fname,'-dpng');
children = get(gca,'children');
delete(children(1));

end
close(f)

