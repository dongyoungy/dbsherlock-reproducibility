function [finalConf meanConfidence] = calculateMeanConfidence(confidence)
   meanConfidence = []; 
   num_case = size(confidence,1);
   for i=1:num_case
       for j=1:num_case
           conf = confidence{i,j};
           conf(isnan(conf)) = 0;
           meanConfidence(i,j) = mean(conf);
       end
   end
   
   sameOtherConfidence = [];
   for i=1:num_case
       sameOtherConfidence(i,1) = mean(confidence{i,i});
       others = [1:num_case];
       others(ismember(others,i)) = [];
       sameOtherConfidence(i,2) = mean(horzcat(confidence{i, others}));
   end

   finalConf = [];
   for i=1:num_case
    finalConf(i) = meanConfidence(i,i);
   end
   % meanConfidence = finalConf
end