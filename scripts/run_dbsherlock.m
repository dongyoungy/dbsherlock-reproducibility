function [explanation causalModels predicates extra] = run_dbsherlock(dataset, abnormalIdx, normalIdx, attribute_types, exp_param)

  data = dataset.data;
  field_names = dataset.field_names;
  if ~isa(exp_param, 'ExperimentParameter')
    error('exp_param must be an object of the class ExperimentParameter');
  end
  extra = struct;

  model_directory = [pwd '/causal_models'];

  % some constants
  HAS_PREDICATE = 0;
  IN_CONFLICT = 1;

  NORMAL_PARTITION = 1;
  ABNORMAL_PARTITION = 2;

  NUMERIC = 0;
  CATEGORICAL = 1;

  numRow = size(data, 1);
  numAttr = size(data, 2);

  % set attribute types (i.e., numeric or categorical)
  if nargin < 4 || isempty(attribute_types)
    attribute_types = zeros(1, numAttr);
  end

  % dbsherlock parameters
  num_discrete = exp_param.num_discrete;
  normalized_diff_threshold = exp_param.diff_threshold;
  abnormal_multiplier = exp_param.abnormal_multiplier;
  createModel = exp_param.create_model;
  causeStr = exp_param.cause_string;
  modelName = exp_param.model_name;

  lags = zeros(1, numAttr);
  detected_lag_error = [];
  lagged_abnormal_indexes = {};
  lagged_normal_indexes = {};

  % expand normal region
  if exp_param.expand_normal_region
    data = expand_normal_region(data, exp_param.expand_normal_size, abnormalIdx, normalIdx);
  end

  % introduce a random lag for each attribute.
  if exp_param.introduce_lag
    for i=3:numAttr
      random_lag = randi([exp_param.lag_min exp_param.lag_max]);
      lags(i) = random_lag;
      lagged_abnormalIdx = abnormalIdx + random_lag;

      if (max(lagged_abnormalIdx) > numRow)
        min_ind = min(lagged_abnormalIdx);
        lagged_abnormalIdx = [min_ind:numRow];
      end

      lagged_abnormal_indexes{i} = lagged_abnormalIdx;
    end
  end

  % detect lag for each attribute and adjust accordingly.
  if exp_param.find_lag
    lags_found = find_individual_lag(dataset, lagged_abnormal_indexes, normalIdx);
    for i=3:numAttr
      err = abs(lags(i) - lags_found(i)) / lags(i) * 100;
      detected_lag_error(end+1) = err;
      lags(i) = lags(i) - lags_found(i);
      lagged_abnormal_indexes{i} = lagged_abnormal_indexes{i} - lags_found(i);
      if (min(lagged_abnormal_indexes{i}) < 1)
        lagged_abnormal_indexes{i} = [1:max(lagged_abnormal_indexes{i})];
      end
    end
  end

  % get normal region for each attribute
  if exp_param.introduce_lag
    for i=3:numAttr
      if isempty(normalIdx)
        normal_index = [];
        for j=1:size(data,1)
          if ~ismember(j, lagged_abnormal_indexes{i}) && data(j,2) > 0
            normal_index(end+1) = j;
          end
        end
        lagged_normal_indexes{i} = normal_index;
      else
        lagged_normal_indexes{i} = normalIdx;
      end

      lagged_normal_matrix{i} = data(lagged_normal_indexes{i}, :);
      lagged_abnormal_matrix{i} = data(lagged_abnormal_indexes{i}, :);
    end
  end

  if isempty(normalIdx)
    normalIdx = [];
    for i=1:size(data,1)
      if ~ismember(i, abnormalIdx) && data(i,2) > 0
        normalIdx(end+1) = i;
      end
    end
  end

  % divide matrix into two regions
  normal_matrix = data(normalIdx, :);
  abnormal_matrix = data(abnormalIdx, :);

  lagged_training_data = {};
  training_data = [];
  rowCount = 1;

  % note that we do not check for overlapping abnormal and normal regions.
  % training_data is for mining causal association rules.
  for i=1:numRow
    if ismember(i, abnormalIdx)
      training_data(rowCount,:) = [data(i,:) -1]; % -1 if abnormal
      rowCount = rowCount + 1;
    end
    if ismember(i, normalIdx)
      training_data(rowCount,:) = [data(i,:) 1]; % 1 if normal
      rowCount = rowCount + 1;
    end
  end

  % some global variables for debugging
  global partitionLabels
  global partitionLabelsInitial
  global partitionLabelsAfterReset
  global numAlternatingPartitions
  global boundaries
  global myTemp
  global conflictCount
  global forcedNeutralCount

  normalPartitions = {};
  abnormalPartitions = {};
  partitionLabels = {};
  partitionLabelsInitial = {};
  partitionLabelsAfterReset = {};
  numAlternatingPartitions = {};
  conflictCount = {};
  forcedNeutralCount = {};

  attributeStatus = {};
  normalizedNormalAverage = {};
  normalizedAbnormalAverage = {};

  normalAverage = {};
  abnormalAverage = {};
  categorical_predicates = {};
  boundaries = {};

  % Generate predicates using our predicate generation algorithm
  for i=3:numAttr

    if exp_param.introduce_lag
      abnormalMatrix = lagged_abnormal_matrix{i};
      normalMatrix = lagged_normal_matrix{i};
    else
      abnormalMatrix = abnormal_matrix;
      normalMatrix = normal_matrix;
    end

    % handle categorical attributes here
    if attribute_types(i) == CATEGORICAL
      categories_from_abnormal = unique(abnormalMatrix(:,i));
      categories_from_normal = unique(normalMatrix(:,i));
      categories = horzcat(categories_from_abnormal, categories_from_normal);
      category_predicate = {};
      for c=1:size(categories,1)
        category = categories(c);
        abnormal_count = size(find(abnormalMatrix(:,i) == category), 1);
        normal_count = size(find(normalMatrix(:,i) == category), 1);
        if abnormal_count > normal_count
          category_predicate{end+1} = category;
        end
      end
      if size(category_predicate, 2) > 0
        categorical_predicates{i} = category_predicate;
      end
      continue
    end

    categorical_predicates{i} = {};
    conflictCount{i} = 0;
    forcedNeutralCount{i} = 0;
    partitionLabels{i} = [];

    % creating a partition space
    maxValue = max(data(:,i));
    minValue = min(data(:,i));
    range = maxValue - minValue;
    discrete_size = range / (num_discrete);
    boundaries{i} = [minValue:discrete_size:maxValue];
    boundary_count = size(boundaries{i},2);
    if boundary_count == 0
      continue
    end

    currentNormalPartitions = zeros(1, boundary_count);
    currentAbnormalPartitions = zeros(1, boundary_count);
    currentPartitionLabels = zeros(1, boundary_count);
    current_boundary = boundaries{i};

    isConflict = false;
    normalizedNormalSum = 0;
    normalizedNormalCount = 0;
    normalizedAbnormalSum = 0;
    normalizedAbnormalCount = 0;

    % partition labeling
    for j=1:size(current_boundary,2)
      if j == size(current_boundary,2)
        currentNormalPartitions(j) = sum(normalMatrix(:,i) >= current_boundary(j));
        currentAbnormalPartitions(j) = sum(abnormalMatrix(:,i) >= current_boundary(j));
      else
        currentNormalPartitions(j) = sum(normalMatrix(:,i) >= current_boundary(j) & normalMatrix(:,i) < current_boundary(j+1));
        currentAbnormalPartitions(j) = sum(abnormalMatrix(:,i) >= current_boundary(j) & abnormalMatrix(:,i) < current_boundary(j+1));
      end

      if currentNormalPartitions(j) > 0 && currentAbnormalPartitions(j) > 0
        isConflict = true;
        conflictCount{i} = conflictCount{i} + 1;
        continue;
      end

      if currentNormalPartitions(j) > 0
        currentPartitionLabels(j) = NORMAL_PARTITION;
      end
      if currentAbnormalPartitions(j) > 0
        currentPartitionLabels(j) = ABNORMAL_PARTITION;
      end

      if isConflict
        if currentNormalPartitions(j) > currentAbnormalPartitions(j)
          currentPartitionLabels(j) = NORMAL_PARTITION;
        elseif currentNormalPartitions(j) < currentAbnormalPartitions(j)
          currentPartitionLabels(j) = ABNORMAL_PARTITION;
        end
      end
    end

    for j=1:size(current_boundary,2)
      if currentPartitionLabels(j) == NORMAL_PARTITION
        normalizedNormalSum = normalizedNormalSum + ( (current_boundary(j) - minValue) / range );
        normalizedNormalCount = normalizedNormalCount + 1;
      elseif currentPartitionLabels(j) == ABNORMAL_PARTITION
        normalizedAbnormalSum = normalizedAbnormalSum + ( (current_boundary(j) - minValue) / range );
        normalizedAbnormalCount = normalizedAbnormalCount + 1;
      end
    end
    normalizedNormalAverage{i} = normalizedNormalSum / normalizedNormalCount;
    normalizedAbnormalAverage{i} = normalizedAbnormalSum / normalizedAbnormalCount;

    % pertition filtering
    markForNeutral = zeros(size(currentPartitionLabels));
    for j=1:(size(currentPartitionLabels,2)-1)
      currentPartition = currentPartitionLabels(j);
      if currentPartition == 0
        continue
      end
      for k=(j+1):size(currentPartitionLabels,2)
        if (currentPartitionLabels(k) > 0)
          if (currentPartitionLabels(k) ~= currentPartition)
            markForNeutral(j) = 1;
            markForNeutral(k) = 1;
          end
          break;
        end
      end
    end

    forcedNeutralCount{i} = sum(markForNeutral);
    partitionLabelsInitial{i} = currentPartitionLabels;

    normalCount = sum(currentPartitionLabels == NORMAL_PARTITION);
    abnormalCount = sum(currentPartitionLabels == ABNORMAL_PARTITION);

    for j=1:size(markForNeutral,2)
      if (markForNeutral(j) == 1)
        if (currentPartitionLabels(j) == NORMAL_PARTITION) && (normalCount > 1)
          currentPartitionLabels(j) = 0;
        elseif (currentPartitionLabels(j) == ABNORMAL_PARTITION) && (abnormalCount > 1)
          currentPartitionLabels(j) = 0;
        end
      end
    end
    partitionLabelsAfterReset{i} = currentPartitionLabels;

    normalCount = sum(currentPartitionLabels == NORMAL_PARTITION);
    abnormalCount = sum(currentPartitionLabels == ABNORMAL_PARTITION);

    if (normalCount == 0 && abnormalCount > 0)
      normalMean = mean(normalMatrix(:,i));
      for j=1:size(current_boundary,2)
        if j == size(current_boundary,2)
          if (normalMean >= current_boundary(j))
            currentPartitionLabels(j) = NORMAL_PARTITION;
            break
          end
        else
          if (normalMean >= current_boundary(j) & normalMean < current_boundary(j+1))
            currentPartitionLabels(j) = NORMAL_PARTITION;
            break
          end
        end
      end
    end

    % filling the gap
    markForNeutral = zeros(size(currentPartitionLabels));
    for j=1:size(currentPartitionLabels,2)
      if (currentPartitionLabels(j) == 0)
        distanceToNormal = num_discrete * 2 * abnormal_multiplier;
        distanceToAbnormal = num_discrete * 2 * abnormal_multiplier;
        k=j-1;
        while k >= 1
          if currentPartitionLabels(k) == NORMAL_PARTITION
            if distanceToNormal > abs(k-j)
              distanceToNormal = abs(k-j);
            end
            break
          end
          if currentPartitionLabels(k) == ABNORMAL_PARTITION
            if distanceToAbnormal > abs(k-j)
              distanceToAbnormal = abs(k-j) * abnormal_multiplier;
            end
            break
          end
          k = k - 1;
        end

        k=j+1;
        while k <= size(currentPartitionLabels,2)
          if currentPartitionLabels(k) == NORMAL_PARTITION
            if distanceToNormal > abs(k-j)
              distanceToNormal = abs(k-j);
            end
            break
          end
          if currentPartitionLabels(k) == ABNORMAL_PARTITION
            if distanceToAbnormal > abs(k-j)
              distanceToAbnormal = abs(k-j) * abnormal_multiplier;
            end
            break
          end
          k = k + 1;
        end

        if distanceToNormal < distanceToAbnormal
          markForNeutral(j) = NORMAL_PARTITION;
        elseif distanceToAbnormal < distanceToNormal
          markForNeutral(j) = ABNORMAL_PARTITION;
        end

      end
    end

    for j=1:size(currentPartitionLabels,2)
      if (currentPartitionLabels(j) == 0)
        currentPartitionLabels(j) = markForNeutral(j);
      end
    end

    normalPartitions{i} = currentNormalPartitions;
    abnormalPartitions{i} = currentAbnormalPartitions;
    partitionLabels{i} = currentPartitionLabels;
    normalAverage{i} = mean(normalMatrix(:,i));
    abnormalAverage{i} = mean(abnormalMatrix(:,i));
  end

  predicates = {};

  % extracing predicates from each attribute
  for i=3:numAttr
    if isempty(partitionLabels{i}) || sum(partitionLabels{i}==ABNORMAL_PARTITION) == 0
      continue
    end

    partitions = partitionLabels{i};
    boundary = boundaries{i};

    predicateName = field_names{i};
    if ~isempty(strfind(predicateName, 'dbmsCum'))
      continue; % skip cumulative DB metrics.
    end
    predicateString = '';
    predicateCount = 0;
    lower = -inf;
    upper = inf;

    for j=1:size(partitions,2)-1
      if j == 1 && partitions(j) == ABNORMAL_PARTITION
        predicateCount = predicateCount + 1;
      end
      if partitions(j) ~= ABNORMAL_PARTITION && partitions(j+1) == ABNORMAL_PARTITION
        if ~isempty(predicateString)
          predicateString = sprintf('%s OR %s', predicateString, sprintf('> %.6f', boundary(j+1)));

        else
          predicateString = sprintf('> %.6f', boundary(j+1));

        end
        lower = boundary(j+1);
        predicateCount = predicateCount + 1;
      elseif partitions(j) == ABNORMAL_PARTITION && partitions(j+1) ~= ABNORMAL_PARTITION
        if ~isempty(predicateString)
          predicateString = sprintf('%s and ', predicateString);

        end
        predicateString = sprintf('%s%s', predicateString, sprintf('< %.6f', boundary(j+1)));
        upper = boundary(j+1);
        predicateCount = predicateCount + 1;
      end
    end

    if ~isempty(predicateString)
      predicateString = sprintf('%s %s', predicateName, predicateString);
    end

    if (predicateCount > 0 && predicateCount <= 2) || (attribute_types(i) == CATEGORICAL && size(categorical_predicates{i}, 2) > 0)
      predicates{end+1, 1} = i; % predicate index
      predicates{end, 2} = predicateString;
      predicates{end, 3} = attribute_types(i); % predicate type.
      predicates{end, 4} = abs(normalizedNormalAverage{i} - normalizedAbnormalAverage{i}); % normalized avg. difference
      predicates{end, 5} = lower;
      predicates{end, 6} = upper;
      predicates{end, 7} = categorical_predicates{i};
      predicates{end, 8} = predicateName;
      predicates{end, 9} = normalAverage{i};
      predicates{end, 10} = abnormalAverage{i};
    end
  end

  prev_predicates = predicates;
  extra.num_should_be_filtered = 0;
  extra.num_should_not_be_filtered = 0;
  extra.num_filtered_correct = 0;
  extra.num_filtered_incorrect = 0;
  extra.before_false_positive = 0;
  extra.before_false_negative = 0;

  effect = {};

  % create causal models from predicates after applying domain knowledge if it is enabled.
  if createModel
    count = 1;
    effectCount = 1;
    extra.predicates_before = predicates;
    if ~isempty(exp_param.domain_knowledge)
      [predicates c incorrect r should_not_be_filtered before_stat] = filter_with_domain_knowledge(data, predicates, exp_param.domain_knowledge, exp_param.correct_filter_list);
      extra.num_filtered_correct = extra.num_filtered_correct + c;
      extra.num_should_be_filtered = extra.num_should_be_filtered + r;
      extra.num_filtered_incorrect = extra.num_filtered_incorrect + incorrect;
      extra.num_should_not_be_filtered = extra.num_should_not_be_filtered + should_not_be_filtered;
      extra.before_false_positive = extra.before_false_positive + before_stat.false_positive;
      extra.before_false_negative = extra.before_false_negative + before_stat.false_negative;
    end
    sorted_predicates = {};
    if size(predicates, 1) > 0
      sorted_predicates = sortrows(predicates, [-4]);
    end
    for j=1:size(sorted_predicates,1)
      if (sorted_predicates{j,1} <= 0)
        continue
      end
      count=count+1;

      if (sorted_predicates{j,4} > normalized_diff_threshold)
        effect{effectCount, 1} = sorted_predicates{j,8}; % predicate name.
        effect{effectCount, 2} = sorted_predicates{j,3}; % predicate type. (numeric or categorical)
        effect{effectCount, 3} = [sorted_predicates{j,5} sorted_predicates{j,6}]; % value for numeric attribute.
        effect{effectCount, 4} = sorted_predicates{j,7}; % category values for categorical attribute.
        effectCount = effectCount + 1;
      end
    end
  end

  model = struct();
  model = setfield(model, 'predicates', effect);

  if isempty(modelName)
    model_path = tempname(model_directory);
  else
    model_path = [model_directory '/' modelName];
  end

  if createModel && size(sorted_predicates, 1) > 0
    model = setfield(model, 'cause', causeStr);
    save(model_path, 'model')
  end

  causalModels = loadCausalModels_Combiner;
  causeRank = cell(size(causalModels,2), 2);

  % Let's do causal model analysis
  for i=1:size(causalModels,2)
    cause = causalModels{i}.cause;
    effectPredicates = causalModels{i}.predicates;

    coveredAbnormalRatioAverage = 0;
    coveredNormalRatioAverage = 0;
    precisionAverage = 0;
    recallAverage = 0;

    for j=1:size(effectPredicates,1)

      field = effectPredicates{j, 1};
      fieldIndex = find(ismember(field_names, field));
      if isempty(fieldIndex)
        disp(sprintf('the field: %s not found!', field))
        continue
      end

      if effectPredicates{j,2} == NUMERIC
        predicate = effectPredicates{j, 3};
      elseif effectPredicates{j,2} == CATEGORICAL
        predicate = effectPredicates{j, 4};
      end

      if attribute_types(fieldIndex) == NUMERIC
        currentPartition = partitionLabelsInitial{fieldIndex};
        partitionBoundaries = boundaries{fieldIndex};
        normalPartitionCount = 0;
        abnormalPartitionCount = 0;
        coveredPartitionCount = 0;
        coveredNormalCount = 0;

        for k=1:size(currentPartition,2)
          if currentPartition(k) == ABNORMAL_PARTITION
            abnormalPartitionCount = abnormalPartitionCount + 1;
            for p=1:size(predicate,1)
              lower = predicate(p, 1);
              upper = predicate(p, 2);
              if lower ~= -inf && lower > partitionBoundaries(k)
                continue
              elseif upper ~= inf && k ~= size(currentPartition,2) && upper <= partitionBoundaries(k+1)
                continue
              end
              coveredPartitionCount = coveredPartitionCount + 1;
              break
            end
          elseif currentPartition(k) == NORMAL_PARTITION
            normalPartitionCount = normalPartitionCount + 1;
            for p=1:size(predicate,1)
              lower = predicate(p, 1);
              upper = predicate(p, 2);
              if lower ~= -inf && lower > partitionBoundaries(k)
                continue
              elseif upper ~= inf && k ~= size(currentPartition,2) && upper <= partitionBoundaries(k+1)
                continue
              end
              coveredNormalCount = coveredNormalCount + 1;
              break
            end
          end
        end

        ratio = (coveredPartitionCount / abnormalPartitionCount);
        if isnan(ratio)
          ratio = 0;
        end
        coveredAbnormalRatioAverage = coveredAbnormalRatioAverage + ratio;

        ratio = (coveredNormalCount / normalPartitionCount);
        if isnan(ratio)
          ratio = 0;
        end
        coveredNormalRatioAverage = coveredNormalRatioAverage + ratio;

        ratio = (coveredPartitionCount / (coveredNormalCount + coveredPartitionCount));
        if isnan(ratio)
          ratio = 0;
        end
        precisionAverage = precisionAverage + ratio;

      elseif attribute_types(fieldIndex) == CATEGORICAL

        normalCount = size(normalMatrix, 1);
        abnormalCount = size(abnormalMatrix, 1);
        coveredNormalCount = size(find(ismember(normalMatrix(:,fieldIndex), predicate)), 1);
        coveredAbnormalCount = size(find(ismember(abnormalMatrix(:,fieldIndex), predicate)), 1);

        ratio = (coveredAbnormalCount / abnormalCount);
        if isnan(ratio)
          ratio = 0;
        end
        coveredAbnormalRatioAverage = coveredAbnormalRatioAverage + ratio;

        ratio = (coveredNormalCount / normalCount);
        if isnan(ratio)
          ratio = 0;
        end
        coveredNormalRatioAverage = coveredNormalRatioAverage + ratio;

        ratio = (coveredAbnormalCount / (coveredNormalCount + coveredAbnormalCount));
        if isnan(ratio)
          ratio = 0;
        end
        precisionAverage = precisionAverage + ratio;

      end
    end
    coveredAbnormalRatioAverage = coveredAbnormalRatioAverage / size(effectPredicates,1);
    coveredNormalRatioAverage = coveredNormalRatioAverage / size(effectPredicates,1);
    precisionAverage = precisionAverage / size(effectPredicates, 1);

    if isnan(coveredAbnormalRatioAverage)
      coveredAbnormalRatioAverage = 0;
    end
    if isnan(coveredNormalRatioAverage)
      coveredNormalRatioAverage = 0;
    end
    if isnan(precisionAverage)
      precisionAverage = 0;
    end

    causeRank{i, 1} = cause;
    causeRank{i, 2} = (coveredAbnormalRatioAverage - coveredNormalRatioAverage) * 100; % confidence
    causeRank{i, 3} = precisionAverage * 100; % precision
    causeRank{i, 4} = 2 * (coveredAbnormalRatioAverage * precisionAverage) / (coveredAbnormalRatioAverage + precisionAverage) * 100; % f1-measure
    causeRank{i, 5} = coveredAbnormalRatioAverage * 100; % recall
  end

  causeRank = sortrows(causeRank, -2);
  explanation = causeRank;
end
