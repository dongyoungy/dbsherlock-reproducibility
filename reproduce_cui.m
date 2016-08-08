function reproduce_cui
  warning('off', 'all');
  addpath './scripts'
  experiment_prompt     = 'Select an experiment to reproduce (1-6 or other input to exit): ';
  dataset_prompt        = 'Select an input dataset (1-3 or other input to return)        : ';
  dataset_name          = '';
  compound_dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
  dataset_tpcc_16w      = 'dbsherlock_dataset_tpcc_16w.mat';
  dataset_tpcc_500w     = 'dbsherlock_dataset_tpcc_500w.mat';
  dataset_tpce          = 'dbsherlock_dataset_tpce_3000.mat';

  while true
    % display experiment options
    fprintf('\n');
    fprintf('\t<< DBSherlock Experiments >>\n');
    fprintf('\t1. Accuracy of Single Causal Models (Section 8.3)\n');
    fprintf('\t2. DBSherlock Predicates versus PerfXplain (Section 8.4)\n');
    fprintf('\t3. Effectiveness of Merged Causal Models (Section 8.5)\n');
    fprintf('\t4. Effect of Incorporating Domain Knowledge (Section 8.6)\n');
    fprintf('\t5. Explaining Compound Situations (Section 8.7)\n');
    fprintf('\t6. Run all of the above (ETC: 4-5 hours)\n');
    fprintf('\n');

    experiment_option = input(experiment_prompt, 's');
    experiment_option = str2num(experiment_option);
    if isempty(experiment_option) || experiment_option < 1 || experiment_option > 6
      return;
    else
      % choose dataset
      switch experiment_option
      case 1
        fprintf('Using TPC-C (scale factor: 500 warehouses) for the experiment...\n');
        dataset_name = 'dbsherlock_dataset_tpcc_500w.mat';
      case 2
        fprintf('Using TPC-C (scale factor: 16 warehouses) for the experiment...\n');
        dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      case 3
        fprintf('Using TPC-C (scale factor: 500 warehouses) for the experiment...\n');
        dataset_name = 'dbsherlock_dataset_tpcc_500w.mat';
      case 4
        fprintf('Using TPC-C (scale factor: 500 warehouses) for the experiment...\n');
        dataset_name = 'dbsherlock_dataset_tpcc_500w.mat';
      case 5
        fprintf('Using TPC-C (scale factor: 16 warehouses) for the experiment...\n');
        dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      case 6
        dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      otherwise
        return;
      end

      if isOctave
        fflush(stdout);
      end

      % if experiment_option == 5
      %   fprintf('Using TPC-C (scale factor: 16 warehouses) for the experiment...\n');
      %   dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      % else
      %   fprintf('\n');
      %   fprintf('\t<< Choose an input dataset >>\n');
      %   fprintf('\t1. dataset from running normal workload of TPC-C (scale factor: 16 warehouses)\n');
      %   fprintf('\t2. dataset from running normal workload of TPC-C (scale factor: 500 warehouses)\n');
      %   fprintf('\t3. dataset from running normal workload of TPC-E (scale factor: 3000)\n')
      %   fprintf('\n');
      %   dataset_option = input(dataset_prompt, 's');
      %   switch dataset_option
      %   case '1'
      %     dataset_name = 'dbsherlock_dataset_tpcc_16w.mat';
      %   case '2'
      %     dataset_name = 'dbsherlock_dataset_tpcc_500w.mat';
      %   case '3'
      %     dataset_name = 'dbsherlock_dataset_tpce_3000.mat';
      %   otherwise
      %     continue;
      %   end
      % end

      data = load(['datasets/' dataset_name]);
      causes = data.causes;

      tic;
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
        prec_perfxplain = prec_perfxplain * 100; % convert to percentage
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

        moc_single = calculateMarginOfConfidence(conf_single);
        moc_merged = calculateMarginOfConfidence(conf_merged_5);

        hold off;
        % plot result for figure 8(a)
        figure(1);
        val = horzcat(moc_single', moc_merged');
        bar(val);
        axes_exp3_1 = gca;
        fig_exp3_1 = gcf;
        xlabel(axes_exp3_1, 'Test Cases');
        ylabel(axes_exp3_1, 'Margin of Confidence (%)');
        set(axes_exp3_1, 'XtickLabelRotation', 45);
        set(axes_exp3_1, 'XtickLabel', causes);
        set(axes_exp3_1, 'FontSize', 18);
        legend(axes_exp3_1, 'Single Causal Model (1 Dataset)', 'Merged Causal Models (5 Datasets)');
        title(axes_exp3_1, 'Experiment 3(a) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(a))');
        set(fig_exp3_1, 'Position', [0 0 1024 768]);

        % plot result for figure 8(b)
        [res top_one top_two] = testNumberOfCorrectIdentification(conf_merged_5);
        top_one = top_one * 100; % convert to percentage
        top_two = top_two * 100;
        val = horzcat(top_one', top_two');
        figure(2);
        bar(val);
        axes_exp3_2 = gca;
        fig_exp3_2 = gcf;
        xlabel(axes_exp3_2, 'Test Cases');
        ylabel(axes_exp3_2, 'Percentage of Correct Explanations (%)');
        set(axes_exp3_2, 'XtickLabelRotation', 45);
        set(axes_exp3_2, 'XtickLabel', causes);
        set(axes_exp3_2, 'FontSize', 18);
        legend(axes_exp3_2, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp3_2, 'Experiment 3(b) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(b))');
        set(fig_exp3_2, 'Position', [30 30 1024 768]);

        % plot result for figure 8(c)
        [res top_one_single top_two_single] = testNumberOfCorrectIdentification(conf_single);
        [res top_one_merged_2 top_two_merged_2] = testNumberOfCorrectIdentification(conf_merged_2);
        [res top_one_merged_3 top_two_merged_3] = testNumberOfCorrectIdentification(conf_merged_3);
        [res top_one_merged_4 top_two_merged_4] = testNumberOfCorrectIdentification(conf_merged_4);
        [res top_one_merged_5 top_two_merged_5] = testNumberOfCorrectIdentification(conf_merged_5);
        top_ones = vertcat(top_one_single*100, top_one_merged_2*100, top_one_merged_3*100, top_one_merged_4*100, top_one_merged_5*100);
        top_twos = vertcat(top_two_single*100, top_two_merged_2*100, top_two_merged_3*100, top_two_merged_4*100, top_two_merged_5*100);
        val = horzcat(top_ones, top_twos);
        figure(3);
        bar(val);
        axes_exp3_3 = gca;
        fig_exp3_3 = gcf;
        xlabel(axes_exp3_3, '# of Datasets Used to Construct Merged Causal Models');
        ylabel(axes_exp3_3, 'Percentage of Correct Explanations (%)');
        set(axes_exp3_3, 'XtickLabelRotation', 45);
        labels = {};
        labels{1} = '1 Dataset';
        labels{2} = '2 Datasets';
        labels{3} = '3 Datasets';
        labels{4} = '4 Datasets';
        labels{5} = '5 Datasets';
        set(axes_exp3_3, 'XtickLabel', labels);
        set(axes_exp3_3, 'FontSize', 18);
        legend(axes_exp3_3, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp3_3, 'Experiment 3(c) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(c))');
        set(fig_exp3_2, 'Position', [60 60 1024 768]);

      case 4
        conf_without_dm = perform_evaluation_causal_models(dataset_name, 500, 0.2, 10, 1, 1);
        conf_with_dm = perform_evaluation_causal_models_with_domain_knowledge(dataset_name, 500, 0.2, 10, 1, 1);
        [res top_one_without_dm top_two_without_dm] = testNumberOfCorrectIdentification(conf_without_dm);
        [res top_one_with_dm top_two_with_dm] = testNumberOfCorrectIdentification(conf_with_dm);
        top_ones = vertcat(top_one_without_dm*100, top_one_with_dm*100);
        top_twos = vertcat(top_two_without_dm*100, top_two_with_dm*100);
        val = horzcat(top_ones, top_twos);

        % plot bar chart for Table 2
        hold off;
        bar(val);
        axes_exp4 = gca;
        fig_exp4 = gcf;
        ylabel(axes_exp4, 'Percentage of Correct Explanations (%)');
        labels = {};
        labels{1} = 'Without Domain Knowledge';
        labels{2} = 'With Domain Knowledge';
        set(axes_exp4, 'XtickLabelRotation', 45);
        set(axes_exp4, 'XtickLabel', labels);
        set(axes_exp4, 'FontSize', 18);
        legend(axes_exp4, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp4, 'Experiment 4 (Sec 8.6): Effect of Incorporating Domain Knowledge (Table 2)');
        set(fig_exp4, 'Position', [0 0 1024 768]);

      case 5
        [conf_compound fscore_compound] = perform_evaluation_compound_cases(compound_dataset_name, 500, 0.05, 10);

        [res ratio_correct] = testCorrectAnswerForCompoundCases(conf_compound, 3);
        compound_causes = data.compound_causes;
        correct_answers = [4 7 9;3 8 0;3 6 0;3 7 0;3 4 0;3 9 0];
        num_correct_answers = [3 2 2 2 2 2];
        fscores = [];
        for i=1:6 % # fo compound cases
          fscore_total = 0;
          for j=1:num_correct_answers(i)
            fscore = fscore_compound{correct_answers(i,j), i};
            fscore(isnan(fscore))= 0;
            fscore_total = fscore_total + mean(fscore);
          end
          fscores(i) = fscore_total / num_correct_answers(i);
        end

        val = horzcat(ratio_correct', fscores');
        % plot bar chart for Figure 10
        hold off;
        bar(val);
        axes_exp5 = gca;
        fig_exp5 = gcf;
        xlabel(axes_exp5, 'Compound Test Cases');
        ylabel(axes_exp5, 'Percentage/F1-measure of Correct Causes (%)');
        set(axes_exp5, 'XtickLabelRotation', 45);
        set(axes_exp5, 'XtickLabel', compound_causes);
        set(axes_exp5, 'FontSize', 18);
        legend(axes_exp5, 'Ratio of Correct Causes if Shown Top-3 Causes', 'Average F1-measure of Correct Causes');
        title(axes_exp5, 'Experiment 5 (Sec 8.7): Explaining Compound Situations (Figure 10)');
        set(fig_exp5, 'Position', [0 0 1024 768]);

      case 6 % run all experiments
        % gather all experiment data first
        [conf_single fscore_single] = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.2, 10, 1, 1);
        conf_merged_2 = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.05, 10, 2, 50);
        conf_merged_3 = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.05, 10, 3, 50);
        conf_merged_4 = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.05, 10, 4, 50);
        conf_merged_5 = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.05, 10, 5, 50);
        conf_without_dm = perform_evaluation_causal_models(dataset_tpcc_500w, 500, 0.2, 10, 1, 1);
        conf_with_dm = perform_evaluation_causal_models_with_domain_knowledge(dataset_tpcc_500w, 500, 0.2, 10, 1, 1);
        [prec_dbseer recl_dbseer f_dbseer prec_perfxplain recl_perfxplain f_perfxplain] = perform_evaluation_perfxplain(dataset_tpcc_16w, 500, 0.05, 10);
        [conf_compound fscore_compound] = perform_evaluation_compound_cases(compound_dataset_name, 500, 0.05, 10);

        hold off;
        % Experiment 1
        figure(1);
        moc = calculateMarginOfConfidence(conf_single);
        fscore = calculateMeanConfidence(fscore_single);
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

        % Experiment 2
        figure(2);
        [prec_dbseer recl_dbseer f_dbseer] = calculateMeanPrecRecallF(prec_dbseer, recl_dbseer, f_dbseer);
        [prec_perfxplain recl_perfxplain f_perfxplain] = calculateMeanPrecRecallF(prec_perfxplain, recl_perfxplain, f_perfxplain);
        prec_perfxplain = prec_perfxplain * 100; % convert to percentage
        recl_perfxplain = recl_perfxplain * 100;
        f_perfxplain = f_perfxplain * 100;
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
        set(fig_exp2, 'Position', [10 10 1024 768]);

        % Experiment 3
        moc_single = calculateMarginOfConfidence(conf_single);
        moc_merged = calculateMarginOfConfidence(conf_merged_5);

        figure(3);
        val = horzcat(moc_single', moc_merged');
        bar(val);
        axes_exp3_1 = gca;
        fig_exp3_1 = gcf;
        xlabel(axes_exp3_1, 'Test Cases');
        ylabel(axes_exp3_1, 'Margin of Confidence (%)');
        set(axes_exp3_1, 'XtickLabelRotation', 45);
        set(axes_exp3_1, 'XtickLabel', causes);
        set(axes_exp3_1, 'FontSize', 18);
        legend(axes_exp3_1, 'Single Causal Model (1 Dataset)', 'Merged Causal Models (5 Datasets)');
        title(axes_exp3_1, 'Experiment 3(a) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(a))');
        set(fig_exp3_1, 'Position', [20 20 1024 768]);

        figure(4);
        num_correct = testNumberOfCorrectIdentification(conf_merged_5);
        top_one = [];
        top_two = [];
        for i=1:size(num_correct,2)
          result = num_correct{i};
          top_one(i) = result(1) / result(end);
          top_two(i) = result(2) / result(end);
        end
        top_one = top_one * 100; % convert to percentage
        top_two = top_two * 100;
        val = horzcat(top_one', top_two');
        bar(val);
        axes_exp3_2 = gca;
        fig_exp3_2 = gcf;
        xlabel(axes_exp3_2, 'Test Cases');
        ylabel(axes_exp3_2, 'Percentage of Correct Explanations (%)');
        set(axes_exp3_2, 'XtickLabelRotation', 45);
        set(axes_exp3_2, 'XtickLabel', causes);
        set(axes_exp3_2, 'FontSize', 18);
        legend(axes_exp3_2, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp3_2, 'Experiment 3(b) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(b))');
        set(fig_exp3_2, 'Position', [30 30 1024 768]);

        figure(5);
        [res top_one_single top_two_single] = testNumberOfCorrectIdentification(conf_single);
        [res top_one_merged_2 top_two_merged_2] = testNumberOfCorrectIdentification(conf_merged_2);
        [res top_one_merged_3 top_two_merged_3] = testNumberOfCorrectIdentification(conf_merged_3);
        [res top_one_merged_4 top_two_merged_4] = testNumberOfCorrectIdentification(conf_merged_4);
        [res top_one_merged_5 top_two_merged_5] = testNumberOfCorrectIdentification(conf_merged_5);
        top_ones = vertcat(top_one_single*100, top_one_merged_2*100, top_one_merged_3*100, top_one_merged_4*100, top_one_merged_5*100);
        top_twos = vertcat(top_two_single*100, top_two_merged_2*100, top_two_merged_3*100, top_two_merged_4*100, top_two_merged_5*100);
        val = horzcat(top_ones, top_twos);
        bar(val);
        axes_exp3_3 = gca;
        fig_exp3_3 = gcf;
        xlabel(axes_exp3_3, '# of Datasets Used to Construct Merged Causal Models');
        ylabel(axes_exp3_3, 'Percentage of Correct Explanations (%)');
        set(axes_exp3_3, 'XtickLabelRotation', 45);
        labels = {};
        labels{1} = '1 Dataset';
        labels{2} = '2 Datasets';
        labels{3} = '3 Datasets';
        labels{4} = '4 Datasets';
        labels{5} = '5 Datasets';
        set(axes_exp3_3, 'XtickLabel', labels);
        set(axes_exp3_3, 'FontSize', 18);
        legend(axes_exp3_3, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp3_3, 'Experiment 3(c) (Sec 8.5): Effectiveness of Merged Causal Models (Figure 8(c))');
        set(fig_exp3_3, 'Position', [40 40 1024 768]);

        % Experiment 4
        figure(6);
        [res top_one_without_dm top_two_without_dm] = testNumberOfCorrectIdentification(conf_without_dm);
        [res top_one_with_dm top_two_with_dm] = testNumberOfCorrectIdentification(conf_with_dm);
        top_ones = vertcat(top_one_without_dm*100, top_one_with_dm*100);
        top_twos = vertcat(top_two_without_dm*100, top_two_with_dm*100);
        val = horzcat(top_ones, top_twos);
        bar(val);
        axes_exp4 = gca;
        fig_exp4 = gcf;
        ylabel(axes_exp4, 'Percentage of Correct Explanations (%)');
        labels = {};
        labels{1} = 'Without Domain Knowledge';
        labels{2} = 'With Domain Knowledge';
        set(axes_exp4, 'XtickLabelRotation', 45);
        set(axes_exp4, 'XtickLabel', labels);
        set(axes_exp4, 'FontSize', 18);
        legend(axes_exp4, 'Top-1 Cause Shown', 'Top-2 Causes Shown');
        title(axes_exp4, 'Experiment 4 (Sec 8.6): Effect of Incorporating Domain Knowledge (Table 2)');
        set(fig_exp4, 'Position', [50 50 1024 768]);

        % Experiment 5
        figure(7);
        [res ratio_correct] = testCorrectAnswerForCompoundCases(conf_compound, 3);
        compound_causes = data.compound_causes;
        correct_answers = [4 7 9;3 8 0;3 6 0;3 7 0;3 4 0;3 9 0];
        num_correct_answers = [3 2 2 2 2 2];
        fscores = [];
        for i=1:6 % # fo compound cases
          fscore_total = 0;
          for j=1:num_correct_answers(i)
            fscore = fscore_compound{correct_answers(i,j), i};
            fscore(isnan(fscore))= 0;
            fscore_total = fscore_total + mean(fscore);
          end
          fscores(i) = fscore_total / num_correct_answers(i);
        end

        val = horzcat(ratio_correct', fscores');
        bar(val);
        axes_exp5 = gca;
        fig_exp5 = gcf;
        xlabel(axes_exp5, 'Compound Test Cases');
        ylabel(axes_exp5, 'Percentage/F1-measure of Correct Causes (%)');
        set(axes_exp5, 'XtickLabelRotation', 45);
        set(axes_exp5, 'XtickLabel', compound_causes);
        set(axes_exp5, 'FontSize', 18);
        legend(axes_exp5, 'Ratio of Correct Causes if Shown Top-3 Causes', 'Average F1-measure of Correct Causes');
        title(axes_exp5, 'Experiment 5 (Sec 8.7): Explaining Compound Situations (Figure 10)');
        set(fig_exp5, 'Position', [60 60 1024 768]);

      otherwise
        return;
      end
      time_taken = toc;
      fprintf('Time taken = %f seconds\n', time_taken);
    end
  end
  warning('on', 'all');
end
