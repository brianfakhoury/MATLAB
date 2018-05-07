%% knn model

function model = tree(data)
    predictors = data(:, 1:3);
    type = data(:, 4);
    
    model = fitctree(predictors, type);
    
end
