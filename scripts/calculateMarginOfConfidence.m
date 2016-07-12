function [moc] = calculateMarginOfConfidence(confidence, exclude)
   if nargin < 2
     exclude = [];
   end
   num_case = size(confidence,1);
   num_dataset = size(confidence{1,1}, 2);
   moc = zeros(1, num_case);

   cases = [1:num_case];
   cases = setdiff(cases, exclude);
   moc(exclude) = -inf;

   for i=1:num_case
     c = cases(i);
     other_cases = setdiff(cases, c);
     for k=1:num_dataset
       current_conf = confidence{c,c}(k);
       other_conf = [];
       for j=1:num_case-1
         other_case = other_cases(j);
         other_conf(end+1) = confidence{other_case, c}(k);
       end
       max_other_conf = max(other_conf);
       moc(i) = moc(i) + (current_conf - max_other_conf);
     end
     moc(i) = moc(i) / num_dataset;
   end

   % old implementation (incorrect)
   %for i=1:num_case
       %conf = confidence{i,i};
       %conf(isnan(conf)) = 0;
       %moc(i) = mean(conf);
   %end

   %for i=1:num_case
       %sameOtherConfidence(i,1) = mean(confidence{i,i});
       %otherConfidence = [];
       %for j=1:num_case
        %if i == j || j==3
          %continue
        %end
        %otherConfidence(end+1) = mean(confidence{j,i});
       %end
       %otherMaxConfidence = max(otherConfidence);
       %moc(i) = moc(i) - otherMaxConfidence;
   %end
end
