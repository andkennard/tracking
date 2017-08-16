function [ edges, bin_widths ] = calcBinEdgesWidths(bin_size,domain_size)
% CALCBINEDGESWIDTHS Figure out positions of edges and width of bins
%   Given a domain with size domain_size, and the target size of bins
%   bin_size, determine the positions of edges that will cover all positive
%   integers up to domain_size such that each bin is at least as wide as
%   bin_size. (The last bin may be larger). 

%
edges = 0:bin_size:domain_size;
%In the case that bin_size does not divide domain_size, make sure the last
%edge includes everything in the domain.
edges(1) = 0;
edges(end) = domain_size;
bin_widths = edges(2:end) - edges(1:end-1);

end

