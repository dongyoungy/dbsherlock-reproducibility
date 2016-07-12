function clearCausalModels(path)
    model_files = [path '/*.mat'];
    delete(model_files);
end
