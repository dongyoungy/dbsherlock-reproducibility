function [result top_one_correct top_two, incorrect_case] = testNumberOfCorrectIdentification(confidence, exclude)
    if nargin < 2
      exclude = [];
    end
    num_case = size(confidence,1);
    num_samples = size(confidence{1,1},2);
    result = {};
    incorrect_case = [];

    for i=1:num_case
        if ismember(i, exclude)
            continue
        end
        correct_count = zeros(num_case, 1);
       for j=1:num_samples
            correct_confidence = confidence{i,i}(j);
            other_cases = [1:num_case];
            other_cases(ismember(other_cases,i)) = [];
            other_cases(ismember(other_cases,exclude)) = [];
            others = vertcat(confidence{other_cases, i});
            others = others(:,j);
            others(find(isnan(others)))=0;

            [m idx] = max(others);
            max_other_idx = other_cases(idx);

            others_sorted = sortrows(others, -1);

            max_confidence_others = max(others);
            for k=1:size(others_sorted,1)
                if (correct_confidence > others_sorted(k))
                    correct_count(k,1) = correct_count(k,1) + 1;
                end
            end
            correct_count(num_case,1) = num_samples;
             if (correct_confidence < max_confidence_others)
               incorrect_case(end+1, i) = max_other_idx;
             end
        end
        result{i} = correct_count;
    end

    total_sample = 0;
    correct_sample = 0;
    correct_sample_2 = 0;

    for i=1:num_case
        if ismember(i, exclude)
            continue
        end
        correct_count = result{i};
        correct_sample = correct_sample + correct_count(1);
        correct_sample_2 = correct_sample_2 + correct_count(2);
        total_sample = total_sample + num_samples;
    end
    top_one_correct = correct_sample / total_sample;
    top_two = correct_sample_2 / total_sample;
end
