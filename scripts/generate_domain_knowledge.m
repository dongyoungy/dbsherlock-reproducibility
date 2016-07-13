function [domain_knowledge] = generate_domain_knowledge(data)

domain_knowledge = [];
f = data.test_datasets{1,1}.field_names;

% 1. DBMS CPU Usage -> OS CPU Usage
cause_idx = find(strcmp(f, 'dbmsMeasuredCPU'));
domain_knowledge(end+1, 1) = cause_idx;
effect_idx = find(strcmp(f, 'AvgCpuUser'));
domain_knowledge(end, end+1) = effect_idx;
effect_idx = find(strncmp(f, 'cpu_usr', 7));
for i=1:size(effect_idx,2)
  e = effect_idx(i);
  domain_knowledge(end, i+1) = e;
end

% 2. OS Allocated Pages -> OS Free Pages
cause_idx = find(strcmp(f, 'osNumberOfAllocatedPage'));
domain_knowledge(end+1, 1) = cause_idx;
effect_idx = find(strcmp(f, 'osNumberOfFreePages'));
domain_knowledge(end, 2) = effect_idx;

% 3. OS Used Swap Space -> OS Free Swap Sapce
cause_idx = find(strcmp(f, 'osUsedSwapSpace'));
domain_knowledge(end+1, 1) = cause_idx;
effect_idx = find(strcmp(f, 'osFreeSwapSpace'));
domain_knowledge(end, 2) = effect_idx;

% 4. OS CPU Usage -> OS CPU Idle
cause_idx = find(strcmp(f, 'AvgCpuUser'));
domain_knowledge(end+1, 1) = cause_idx;
effect_idx = find(strcmp(f, 'AvgCpuIdle'));
domain_knowledge(end, end+1) = effect_idx;
effect_idx = find(strncmp(f, 'cpu_idl', 7));
for i=1:size(effect_idx,2)
  e = effect_idx(i);
  domain_knowledge(end, i+1) = e;
end

end % end function
