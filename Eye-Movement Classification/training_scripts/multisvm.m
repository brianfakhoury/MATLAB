%% svm model

function model = multisvm(data)
    predictors = data(:, 1:3);
    type = data(:, 4);
    
    t = templateSVM('Standardize', 1);
    
    model = fitcecoc(predictors, type, 'Learners', t ... 'Classnames', ['Normal' 'Fixation' 'Saccade']
        );
    
end
