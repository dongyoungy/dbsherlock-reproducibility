function models = loadCausalModels_Combiner
    % model_directory = '/Users/dyoon/Work/dbseer/dbseer_front_end/causal_models';
    model_directory = [pwd '/causal_models'];

    modelFiles = dir([model_directory '/*.mat']);
    models = {};
    for i=1:length(modelFiles)
        modelFile = [model_directory '/' modelFiles(i).name];
        model = load(modelFile);
        model = model.model;

        isCombined = false;
        merged_predicate_index = [];
        % combine model with same cause
        for j=1:length(models)
            if strcmp(models{j}.cause, model.cause)
                current_predicates = models{j}.predicates;
                incoming_predicates = model.predicates;
                newPredicateIndex = [];
                
                % check each predicate
                for k=1:size(incoming_predicates,1)
                    idx = find(strcmp(current_predicates(:,1), incoming_predicates(k,1)));
                    if idx > 0
                        current_pred = current_predicates{idx,3};
                        incoming_pred = incoming_predicates{k,3};
                        new_pred = [];
                        new_pred(1) = min(current_pred(1), incoming_pred(1));
                        new_pred(2) = max(current_pred(2), incoming_pred(2));
                        % new_pred = vertcat(current_pred, incoming_pred);
                        models{j}.predicates{idx,3} = new_pred;
                        % models{j}.predicates{idx,2} = incoming_predicates{k,2};
                        models{j}.predicates{idx,4} = intersect(models{j}.predicates{idx,4}, incoming_predicates{k,4});
                        % merged_predicate_index(j,end+1) = idx;
                        newPredicateIndex(end+1) = idx;
                    % else
                    %     models{j}.predicates(end+1,:) = incoming_predicates(k,:);
                    end
                end
                
                isCombined = true;
                models{j}.predicates = models{j}.predicates(newPredicateIndex, :);
            end
        end
        
        if ~isCombined && ~isempty(model.predicates)
            models{end+1} = model;
        end
    end

    % for i=1:size(models,2)
    %     if size(merged_predicate_index, 1) >= i && size(merged_predicate_index(i,:),2) > 0
    %     models{i}.predicates = models{i}.predicates(merged_predicate_index(i,:), :);
    % end

    % check inconsistent predicates (e.g. lb > ub)
    for i=1:size(models,2)
        predicate_to_remove = [];
        for j=1:size(models{i}.predicates, 1)
            if (models{i}.predicates{j,2} == 0) % if numeric
                pred = models{i}.predicates{j, 3};
                if pred(1) > pred(2)
                    predicate_to_remove(end+1) = j;
                end
            end
        end
        if ~isempty(predicate_to_remove)
            models{i}.predicates(predicate_to_remove, :) = [];
        end
    end
end