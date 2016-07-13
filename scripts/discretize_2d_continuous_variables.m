function bins = discretize_2d_continuous_variables(X, Y, bin_size)

sizeX = size(X,1);
sizeY = size(Y,1);
bins = zeros(bin_size, bin_size);

minX = min(X);
maxX = max(X);
rangeX = range(X);
bin_edges_X = minX:rangeX/bin_size:maxX;
bin_index_X = discretize(X, bin_edges_X);

minY = min(Y);
maxY = max(Y);
rangeY = range(Y);
bin_edges_Y = minY:rangeY/bin_size:maxY;
bin_index_Y = discretize(Y, bin_edges_Y);

for i=1:size(X,1)
	bins(bin_index_X(i), bin_index_Y(i)) = bins(bin_index_X(i), bin_index_Y(i)) + 1;
end

end

