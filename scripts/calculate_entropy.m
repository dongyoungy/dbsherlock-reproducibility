function e = calculate_entropy(p_x)

e = 0;
total_x = sum(sum(p_x));
for i=1:size(p_x, 1)
	for j=1:size(p_x, 2)
		p = p_x(i,j) / total_x;
		if p ~= 0
			e = e + (p * log2(p));
		end
	end
end
e = e * -1;
end
