function [result ratio_correct] = testCorrectAnswerForCompoundCase(confidence, K)
    num_case = 6;
    num_samples = 11;
    result = {};
    ratio_correct = [];
    correct_answers = [4 7 9;3 8 0;3 6 0;3 7 0;3 4 0;3 9 0];
    num_correct_answers = [3 2 2 2 2 2];

    for i=1:num_case
        case_no = i;
        correct_count = zeros(num_samples, 1);
        for j=1:num_samples
            confidences = [];
            for n=1:10
                confidences(n,1) = n;
                confidences(n,2) = confidence{n, case_no}(j);
            end
            confidences = sortrows(confidences, -2);
            top_k = confidences([1:K],1);

            for k=1:K
                if (ismember(top_k(k), correct_answers(i,:)))
                    correct_count(j) = correct_count(j) + 1;
                end
            end
        end
        result{i} = correct_count;
        ratio_correct(i) = sum(correct_count) / (num_correct_answers(i) * num_samples) * 100;
    end
end
