%% knn model

function model = knn(data)
    predictors = data(:, 1:3);
    type = data(:, 4);
    
    model = fitcknn(predictors, type, 'NumNeighbors', 1);
    
end
