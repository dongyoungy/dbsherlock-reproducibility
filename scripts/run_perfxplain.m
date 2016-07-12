function [explanations meanPrecision meanRecall meanF predString] = run_perfxplain(trainMatrix, testMatrix, fieldNames, width)

    HAS_PREDICATE = 0;
    IN_CONFLICT = 1;

    NORMAL_PARTITION = 1;
    OUTLIER_PARTITION = 2;

    LT = -1;
    SIM = 0;
    GT = 1;
    operators = [LT SIM GT];
    operators_str = {'LT' 'SIM' 'GT'};

    predString = {};

    num_expected = 0; % latency = SIM
    num_observed = 0; % latency = GT

    expectedPairs = [];
    observedPairs = [];

    rowCount = size(trainMatrix,1);

    while num_expected < 1000 || num_observed < 1000
        index1 = randi(rowCount, 1);
        index2 = randi(rowCount, 1);
        if (index1 == index2)
            continue
        end
        latency1 = trainMatrix(index1, 2);
        latency2 = trainMatrix(index2, 2);

        if (latency1*0.5 < latency2 && latency2 < latency1*1.5) || (latency2*0.5 < latency1 && latency1 < latency2*1.5)
            if num_expected < 1000
                num_expected = num_expected + 1;
                expectedPairs(num_expected, 1) = index1;
                expectedPairs(num_expected, 2) = index2;
            end
        else
            if num_observed < 1000
                num_observed = num_observed + 1;

                observedPairs(num_observed, 1) = index1;
                observedPairs(num_observed, 2) = index2;
            end
        end

    end

    expectedMatrix = [];
    observedMatrix = [];

    for i=1:size(expectedPairs,1)
        expectedMatrix(i,1) = expectedPairs(i,1);
        expectedMatrix(i,2) = expectedPairs(i,2);
        index1 = expectedPairs(i,1);
        index2 = expectedPairs(i,2);
        for j=3:size(trainMatrix,2)
            val1 = trainMatrix(index1, j);
            val2 = trainMatrix(index2, j);
            if val1 >= 0
                if val1*0.9 < val2 && val2 < val1*1.1
                    expectedMatrix(i,j) = SIM;
                    continue;
                end
            else
                if val1*1.1 < val2 && val2 < val1*0.9
                    expectedMatrix(i,j) = SIM;
                    continue;
                end
            end
            if val1 < val2
                expectedMatrix(i,j) = LT;
            else
                expectedMatrix(i,j) = GT;
            end
        end
    end

    for i=1:size(observedPairs,1)
        observedMatrix(i,1) = observedPairs(i,1);
        observedMatrix(i,2) = observedPairs(i,2);
        index1 = observedPairs(i,1);
        index2 = observedPairs(i,2);
        for j=3:size(trainMatrix,2)
            val1 = trainMatrix(index1, j);
            val2 = trainMatrix(index2, j);
            if val1 >= 0
                if val1*0.9 < val2 && val2 < val1*1.1
                    observedMatrix(i,j) = SIM;
                    continue;
                end
            else
                if val1*1.1 < val2 && val2 < val1*0.9
                    observedMatrix(i,j) = SIM;
                    continue;
                end
            end
            if val1 < val2
                observedMatrix(i,j) = LT;
            else
                observedMatrix(i,j) = GT;
            end
        end
    end

    explanations = [];

    total = size(expectedMatrix,1) + size(observedMatrix,1);
    num_expected = size(expectedMatrix, 1);
    num_observed = size(observedMatrix, 1);

    current_entropy = -(num_observed/total)*log2(num_observed/total) - (num_expected/total)*log2(num_expected/total);

    predicates = [];

    for i=3:size(trainMatrix,2)

        predicates(i-2,1) = i;
        entropies = [];

        for k=1:size(operators,2)
            op = operators(k);
            num_expected_satisfying = sum(expectedMatrix(:,i)==op);
            num_observed_satisfying = sum(observedMatrix(:,i)==op);
            total_satisfying = num_expected_satisfying + num_observed_satisfying;
            num_expected_not_satisfying = num_expected - num_expected_satisfying;
            num_observed_not_satisfying = num_observed - num_observed_satisfying;
            total_not_satisfying = num_expected_not_satisfying + num_observed_not_satisfying;

            if num_expected_satisfying == 0
                entropy_satisfying(1) = 0;
            else
                entropy_satisfying(1) = -(num_expected_satisfying/total_satisfying)*log2(num_expected_satisfying/total_satisfying);
            end

            if num_observed_satisfying == 0
                entropy_satisfying(2) = 0;
            else
                entropy_satisfying(2) = -(num_observed_satisfying/total_satisfying)*log2(num_observed_satisfying/total_satisfying);
            end

            if num_expected_not_satisfying == 0
                entropy_not_satisfying(1) = 0;
            else
                entropy_not_satisfying(1) = -(num_expected_not_satisfying/total_not_satisfying)*log2(num_expected_not_satisfying/total_not_satisfying);
            end

            if num_observed_not_satisfying == 0
                entropy_not_satisfying(2) = 0;
            else
                entropy_not_satisfying(2) = -(num_observed_not_satisfying/total_not_satisfying)*log2(num_observed_not_satisfying/total_not_satisfying);
            end
            entropy = (total_satisfying/total)*sum(entropy_satisfying) + (total_not_satisfying/total)*sum(entropy_not_satisfying);
            entropies(k,1) = op;
            entropies(k,2) = current_entropy - entropy;
            entropies(k,3) = num_observed_satisfying / total_satisfying; % prec
            if (isnan(entropies(k,3)))
                entropies(k,3) = 0;
            end
            entropies(k,4) = total_satisfying / total; % generality
            entropies(k,5) = num_observed_satisfying / num_observed; % recall
            entropies(k,6) = num_expected_satisfying / num_expected;
        end
        entropies = sortrows(entropies,-2);
        predicates(i-2,2) = entropies(1,1);
        predicates(i-2,3) = entropies(1,2);
        predicates(i-2,4) = entropies(1,3);
        predicates(i-2,5) = entropies(1,4);
        predicates(i-2,6) = entropies(1,3);
        predicates(i-2,7) = entropies(1,5);
    end

    sort_by_prec = sortrows(predicates,-4);
    num_pred = size(predicates,1);
    for i=1:num_pred
        sort_by_prec(i,4) = (num_pred - i) / (num_pred-1) * 100;
    end
    sort_by_gen = sortrows(sort_by_prec, -5);
    for i=1:num_pred
        sort_by_gen(i,5) = (num_pred - i) / (num_pred-1) * 100;
        sort_by_gen(i,9) = 0.8 * sort_by_gen(i,4) + 0.2 * sort_by_gen(i,5);
    end
    sorted_predicates = sortrows(sort_by_gen, -9);

    %%% TEST SECTION %%%

    possiblePairs = nchoosek([1:size(testMatrix,1)], 2);

    num_expected = 0; % latency = SIM
    num_observed = 0; % latency = GT

    expectedPairs = [];
    observedPairs = [];

    for i=1:size(possiblePairs,1)
        index1 = possiblePairs(i,1);
        index2 = possiblePairs(i,2);
        latency1 = testMatrix(index1, 2);
        latency2 = testMatrix(index2, 2);

        if (latency1*0.5 < latency2 && latency2 < latency1*1.5) || (latency2*0.5 < latency1 && latency1 < latency2*1.5)
            num_expected = num_expected + 1;
            expectedPairs(num_expected, 1) = index1;
            expectedPairs(num_expected, 2) = index2;
        else
            num_observed = num_observed + 1;

            observedPairs(num_observed, 1) = index1;
            observedPairs(num_observed, 2) = index2;
        end

    end

    min_num = 1000;

    expectedPairs = datasample(expectedPairs, min_num, 'Replace', true);
    observedPairs = datasample(observedPairs, min_num, 'Replace', true);

    expectedMatrix = [];
    observedMatrix = [];

    for i=1:size(expectedPairs,1)
        expectedMatrix(i,1) = expectedPairs(i,1);
        expectedMatrix(i,2) = expectedPairs(i,2);
        index1 = expectedPairs(i,1);
        index2 = expectedPairs(i,2);
        for j=3:size(testMatrix,2)
            val1 = testMatrix(index1, j);
            val2 = testMatrix(index2, j);
            if val1 >= 0
                if val1*0.9 < val2 && val2 < val1*1.1
                    expectedMatrix(i,j) = SIM;
                    continue;
                end
            else
                if val1*1.1 < val2 && val2 < val1*0.9
                    expectedMatrix(i,j) = SIM;
                    continue;
                end
            end
            if val1 < val2
                expectedMatrix(i,j) = LT;
            else
                expectedMatrix(i,j) = GT;
            end
        end
    end

    for i=1:size(observedPairs,1)
        observedMatrix(i,1) = observedPairs(i,1);
        observedMatrix(i,2) = observedPairs(i,2);
        index1 = observedPairs(i,1);
        index2 = observedPairs(i,2);
        for j=3:size(testMatrix,2)
            val1 = testMatrix(index1, j);
            val2 = testMatrix(index2, j);
            if val1 >= 0
                if val1*0.9 < val2 && val2 < val1*1.1
                    observedMatrix(i,j) = SIM;
                    continue;
                end
            else
                if val1*1.1 < val2 && val2 < val1*0.9
                    observedMatrix(i,j) = SIM;
                    continue;
                end
            end
            if val1 < val2
                observedMatrix(i,j) = LT;
            else
                observedMatrix(i,j) = GT;
            end
        end
    end


    total = size(expectedMatrix,1) + size(observedMatrix,1);
    num_expected = size(expectedMatrix, 1);
    num_observed = size(observedMatrix, 1);

    precision = [];
    recall = [];

    for w=1:width
        idx = sorted_predicates(w, 1);
        op = sorted_predicates(w, 2);
        num_expected_satisfying = sum(expectedMatrix(:,idx)==op);
        num_observed_satisfying = sum(observedMatrix(:,idx)==op);
        total_satisfying = num_expected_satisfying + num_observed_satisfying;
        num_expected_not_satisfying = num_expected - num_expected_satisfying;
        num_observed_not_satisfying = num_observed - num_observed_satisfying;
        total_not_satisfying = num_expected_not_satisfying + num_observed_not_satisfying;

        if num_expected_satisfying == 0
            entropy_satisfying(1) = 0;
        else
            entropy_satisfying(1) = -(num_expected_satisfying/total_satisfying)*log2(num_expected_satisfying/total_satisfying);
        end

        if num_observed_satisfying == 0
            entropy_satisfying(2) = 0;
        else
            entropy_satisfying(2) = -(num_observed_satisfying/total_satisfying)*log2(num_observed_satisfying/total_satisfying);
        end

        if num_expected_not_satisfying == 0
            entropy_not_satisfying(1) = 0;
        else
            entropy_not_satisfying(1) = -(num_expected_not_satisfying/total_not_satisfying)*log2(num_expected_not_satisfying/total_not_satisfying);
        end

        if num_observed_not_satisfying == 0
            entropy_not_satisfying(2) = 0;
        else
            entropy_not_satisfying(2) = -(num_observed_not_satisfying/total_not_satisfying)*log2(num_observed_not_satisfying/total_not_satisfying);
        end

        precision(end+1) = num_observed_satisfying / total_satisfying; % prec
        recall(end+1) = num_observed_satisfying / num_observed; % recall

    end

    meanPrecision = mean(precision);
    meanRecall = mean(recall);
    meanF = 2 * (meanPrecision * meanRecall) / (meanPrecision + meanRecall);
end
