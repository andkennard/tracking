function [num_trajectories, num_timepoints] = findPositionMatrixDimensions(all_points)
    num_trajectories = max(all_points(end).ID);
    num_timepoints = length(all_points);
end