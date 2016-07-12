function [new_predicates num_filtered_correct num_filtered_incorrect num_filtered_required num_filtered_not_required before_stat] = filter_with_domain_knowledge(data, predicates, domain_knowledge, correct_filter_list)

num_attr = size(data,2) - 2;
domain_knowledge = domain_knowledge + 2;
pred_index = cell2mat(predicates(:,1));
pred_index_before = pred_index;
knowledge_size = size(domain_knowledge,1);

predicates_to_filter = [];
predicates_not_to_filter = [];
correctly_filtered = [];
incorrectly_filtered = [];

num_filtered_required = 0;
num_filtered_not_required = 0;
num_filtered_correct = 0;
num_filtered_incorrect = 0;

%pred_index_before
%correct_filter_list
%pause;

for i=1:knowledge_size 
	knowledge = domain_knowledge(i,:);
	if size(knowledge, 2) < 2
		continue
	end

	cause = knowledge(1,1);
	effects = knowledge(1,2:end);

	% if cause variable is in the predicates...
	if ~isempty(find(pred_index==cause))
		pred_to_filter = [];
		for j=1:size(effects,2)
			effect = effects(j);
			% if effect variable is also in the predicates...
			if ~isempty(find(pred_index==effect))
				p_xy = discretize_2d_continuous_variables(data(:, cause), data(:, effect), 100);
				p_x = sum(p_xy, 2);
				p_y = sum(p_xy, 1);

				entropy_x = calculate_entropy(p_x);
				entropy_y = calculate_entropy(p_y);
				entropy_xy = calculate_entropy(p_xy);

				mutual_information = entropy_x + entropy_y - entropy_xy;
				mutual_info_gain = mutual_information^2 / (entropy_x * entropy_y);
				if mutual_info_gain > 0
					%res = [cause-2 effect-2 mutual_info_gain]
					pred_to_filter(end+1) = effect;
				end

				%cor = corrcoef(data(:,cause), data(:,effect));
				%cor = abs(cor(1,2))
				%if cor >= 0.7
					%pred_to_filter(end+1) = effect;
				%end
			end
		end

		if ~isempty(correct_filter_list)
			filter_idx = find(cell2mat(correct_filter_list(:,1))+2 == cause);
			correct_list = cell2mat(correct_filter_list(filter_idx, 2));
			incorrect_list = cell2mat(correct_filter_list(filter_idx, 3));
			predicates_to_filter = horzcat(predicates_to_filter, correct_list);
			predicates_not_to_filter = horzcat(predicates_not_to_filter, incorrect_list);
			correct_list = correct_list + 2;
			incorrect_list = incorrect_list + 2;

			filtered_correctly = intersect(correct_list, pred_to_filter);
			filtered_incorrectly = intersect(incorrect_list, pred_to_filter);

			if isempty(correctly_filtered)
				correctly_filtered = filtered_correctly;
		else
			correctly_filtered = horzcat(correctly_filtered, filtered_correctly);
		end
			if isempty(incorrectly_filtered)
				incorrectly_filtered = filtered_incorrectly;
			else
				incorrectly_filtered = horzcat(incorrectly_filtered, filtered_incorrectly);
			end
		end
		%filtered_incorrectly = setdiff(pred_to_filter, correct_list);
		%if ~isempty(filtered_correctly)
			%num_filtered_correct = num_filtered_correct + size(filtered_correctly, 2);
		%end
		%if ~isempty(filtered_incorrectly)
			%num_filtered_incorrect = num_filtered_incorrect + size(filtered_incorrectly, 2);
		%end

		for j=1:size(pred_to_filter,2)
			index = pred_to_filter(j);
			index_to_filter = find(pred_index==index);
			predicates(index_to_filter, :) = [];
			pred_index = cell2mat(predicates(:,1));
		end
	end
end

predicates_to_filter = unique(predicates_to_filter);
%num_filtered_correct = size(unique(correctly_filtered), 2);
if isempty(correctly_filtered)
	num_filtered_correct = 0;
else
	num_filtered_correct = size(unique(correctly_filtered), 2);
end

if isempty(incorrectly_filtered)
	num_filtered_incorrect = 0;
else
	num_filtered_incorrect = size(unique(incorrectly_filtered), 2);
end

num_filtered_required = sum(find(predicates_to_filter>0)>0);
if isempty(predicates_not_to_filter)
	num_filtered_not_required = 0;
else
	num_filtered_not_required = size(unique(predicates_not_to_filter), 2);
end
new_predicates = predicates;

%if num_filtered_incorrect > 0
	%incorrectly_filtered - 2
	%error('asdf')
	%%pause;
%end

before_stat = struct();
before_filtered = setdiff([1:num_attr-1]+2, pred_index_before);

predicates_to_filter(predicates_to_filter==0) = [];
predicates_not_to_filter(predicates_not_to_filter==0) = [];

before_stat.false_negative = size(unique(intersect(pred_index_before'-2, predicates_to_filter)), 2);
before_stat.false_positive = size(unique(intersect(before_filtered, predicates_not_to_filter)), 2);


end
