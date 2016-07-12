function [confidence fscore] = perform_evaluation_causal_models(dataset_name, num_discrete, diff_threshold, abnormal_multiplier, num_train_samples, batch_count)

  data = load(['datasets/' dataset_name]);
  model_directory = [pwd '/causal_models'];
  mkdir(model_directory);

  num_case = size(data.test_datasets, 1);
  num_samples = size(data.test_datasets, 2);

  confidence = cell(num_case, num_case);
  fscore = cell(num_case, num_case);

  causes = data.causes;

  if isempty(num_discrete)
    num_discrete = 500;
  end
  if isempty(abnormal_multiplier)
    abnormal_multiplier = 10;
  end
  if isempty(diff_threshold)
    diff_threshold = 0.2;
  end

  train_param = ExperimentParameter;
  test_param = ExperimentParameter;
  train_param.create_model = true;

  if ~isempty(num_discrete)
    train_param.num_discrete = num_discrete;
    test_param.num_discrete = num_discrete;
  end
  if ~isempty(diff_threshold)
    train_param.diff_threshold = diff_threshold;
    test_param.diff_threshold = diff_threshold;
  end
  if ~isempty(abnormal_multiplier)
    train_param.abnormal_multiplier = abnormal_multiplier;
    test_param.abnormal_multiplier = abnormal_multiplier;
  end

  tic;

  if num_train_samples == 1
    batch_count=num_samples;
  end

  for batch=1:batch_count

    samples = [1:num_samples];
    if num_train_samples == 1
      train_samples = batch;
    else
      train_samples = datasample(samples, num_train_samples, 'Replace', false);
    end
    samples(ismember(samples,train_samples)) = [];
    test_samples = samples;

    clearCausalModels(model_directory);

    % construct a causal model from a number of training samples.
    for i=1:num_case
      for j=1:size(train_samples,2)
        train_idx = train_samples(j);
        train_param.cause_string = causes{i};
        train_param.model_name = ['cause' num2str(i) '-' num2str(train_idx)];
        run_dbsherlock(data.test_datasets{i,train_idx}, data.abnormal_regions{i,train_idx}, data.normal_regions{i,train_idx}, [], train_param);
      end
    end

    % calculate confidence
    for i=1:num_case
      for j=1:size(test_samples,2)
        test_idx = test_samples(j);

        explanation = run_dbsherlock(data.test_datasets{i,test_idx}, data.abnormal_regions{i,test_idx}, data.normal_regions{i,test_idx}, [], test_param);
        for k=1:num_case
          c2 = k;
          compare = strcmp(explanation, causes{c2});
          idx = find(compare(:,1));
          if ~isempty(idx)
            confidence{k,i}(end+1) = explanation{idx, 2};
            fscore{k,i}(end+1) = explanation{idx, 4};
          end
        end
      end
    end
  end

  timeElapsed = toc
end
