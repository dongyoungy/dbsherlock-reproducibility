function [meanPrec meanRecall meanF] = calculateMeanPrecRecallF(prec, recall, f)
    num_case = size(prec,2);
    
    meanPrec = zeros(1,num_case);
    meanRecall = zeros(1,num_case);
    meanF = zeros(1,num_case);
    
    for i=1:num_case
        x = prec{i};
        x(find(isnan(x)))=0;
        meanPrec(i) = mean(x);
        
        x = recall{i};
        x(find(isnan(x)))=0;
        meanRecall(i) = mean(x);
        
        x = f{i};
        x(find(isnan(x)))=0;
        meanF(i) = mean(x);
    end
end