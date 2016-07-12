function [moc fscore] = reproduce_cui
  warning('off', 'all');
  addpath './scripts'
  experiment_prompt = 'Select an experiment to reproduce (1-? or any other input to exit): ';
  dataset_prompt = 'Select an input dataset to be used for the experiment (1-3 or any other input to return to experiment selection): ';
  dataset_name = '';

  while true
    % display experiment options
    fprintf('\n');
    fprintf('\t<< DBSherlock Experiments >>\n');
    fprintf('\t1. Accuracy of Single Causal Models (Sec 8.3)\n');
    fprintf('\t2. DBSherlock Predicates versus PerfXplain (Sec 8.4)\n');
    fprintf('\t3. Effectiveness of Merged Causal Models (Sec 8.5)\n');
    fprintf('\n');

    experiment_option = input(experiment_prompt, 's');
    experiment_option = str2num(experiment_option);
    if isempty(experiment_option) || experiment_option < 1 || experiment_option > 3
      return;
    else
      % choose dataset
      fprintf('\n');
      fprintf('\t<< Choose an input dataset >>\n');
      fprintf('\t1. dataset from running normal workload of TPC-C (scale factor: 16 warehouses)\n');
      fprintf('\t2. dataset from running normal workload of TPC-C (scale factor: 500 warehouses)\n');
      fprintf('\t3. dataset from running normal workload of TPC-E (scale factor: 3000)\n')
      fprintf('\n');
      dataset_option = input(dataset_prompt, 's');
      switch dataset_option
      case '1'
        dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      case '2'
        dataset_name = 'dbsherlock_dataset_tpcc_500w.mat';
      case '3'
        dataset_name = 'dbsherlock_dataset_tpce_3000.mat';
      otherwise
        continue;
      end

      data = load(['datasets/' dataset_name]);
      causes = data.causes;

      switch experiment_option
      case 1
        [conf fscore] = perform_evaluation_causal_models(dataset_name, 500, 0.2, 10, 1, 1);
        moc = calculateMarginOfConfidence(conf);
        fscore = calculateMeanConfidence(fscore);

        % plot result
        hold off;
        val = horzcat(moc', fscore');
        bar(val);
        axes_exp1 = gca;
        fig_exp1 = gcf;
        xlabel(axes_exp1, 'Test Cases');
        ylabel(axes_exp1, 'Confidence/F1-measure (%)');
        set(axes_exp1, 'XtickLabel', causes);
        set(axes_exp1, 'XtickLabelRotation', 45);
        set(axes_exp1, 'FontSize', 18);
        legend(axes_exp1, 'Margin of Confidence of the Correct Model', 'F1-Measure of the Correct Model');
        title(axes_exp1, 'Experiment 1 (Sec 8.3): Accuracy of Single Causal Models');
        set(fig_exp1, 'Position', [0 0 1024 768]);
      case 2
        [prec_dbseer recl_dbseer f_dbseer prec_perfxplain recl_perfxplain f_perfxplain] = perform_evaluation_perfxplain(dataset_name, 500, 0.05, 10);
        [prec_dbseer recl_dbseer f_dbseer] = calculateMeanPrecRecallF(prec_dbseer, recl_dbseer, f_dbseer);
        [prec_perfxplain recl_perfxplain f_perfxplain] = calculateMeanPrecRecallF(prec_perfxplain, recl_perfxplain, f_perfxplain);
        prec_perfxplain = prec_perfxplain * 100; % convert to %
        recl_perfxplain = recl_perfxplain * 100;
        f_perfxplain = f_perfxplain * 100;

        % plot result
        hold off
        val = horzcat(prec_perfxplain', prec_dbseer', recl_perfxplain', recl_dbseer', f_perfxplain', f_dbseer');
        bar(val);
        axes_exp2 = gca;
        fig_exp2 = gcf;
        xlabel(axes_exp2, 'Test Cases');
        ylabel(axes_exp2, 'Precision/Recall/F1-measure (%)');
        set(axes_exp2, 'XtickLabelRotation', 45);
        set(axes_exp2, 'XtickLabel', causes);
        set(axes_exp2, 'FontSize', 18);
        legend(axes_exp2, 'PerfXplain (Precision)', 'DBSherlock (Precision)', 'PerfXplain (Recall)', 'DBsherlock (Recall)', 'PerfXplain (F1-measure)', 'DBSherlock (F1-measure)');
        title(axes_exp2, 'Experiment 2 (Sec 8.4): DBSherlock Predicates versus PerfXplain');
        set(fig_exp2, 'Position', [0 0 1024 768]);
      case 3
        conf_single = perform_evaluation_causal_models(dataset_name, 500, 0.2, 10, 1, 1);
        conf_merged_2 = perform_evaluation_causal_models(dataset_name, 500, 0.05, 10, 2, 50);
        conf_merged_3 = perform_evaluation_causal_models(dataset_name, 500, 0.05, 10, 3, 50);
        conf_merged_4 = perform_evaluation_causal_models(dataset_name, 500, 0.05, 10, 4, 50);
        conf_merged_5 = perform_evaluation_causal_models(dataset_name, 500, 0.05, 10, 5, 50);
      otherwise
        return;
      end
    end
  end
  warning('on', 'all');
end
