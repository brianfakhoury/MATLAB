%% Train and test script
clearvars
clc
% use training scripts from
% training scripts folder
addpath('training_scripts/');
disp("Running analysis script///");
%% test knn model

% produce a cleann set of data for training
% and a separate one for testing
% uses different trial data
produce_set(true);
produce_set(false);
% read the train and test sets
dataset_train = csvread('./cleaned/training_data.csv');
dataset_test = csvread('./cleaned/testing_data.csv');

disp("Data registered in ./cleaned");
disp("Cleaned data read.");

% Pass function handles
model_handles = {@knn @multisvm @tree};
for i=1:length(model_handles)
    test_model(model_handles{i}, dataset_train, dataset_test);
end

function test_model(name, dataset_train, dataset_test)

    % use the given script (./training_scripts) to train a model on the train set
    trainfn_model = name(dataset_train);

    % produce an unlabeled matrix for the returned prediction function
    test_set = dataset_test(:,1:3);

    % run the prediction function
    prediction_set = trainfn_model.predict(test_set);

    % get the actual answers from known data
    actual_set = dataset_test(:,4);

    % calulate accuracy with logic comparison normalized
    score = 100 * sum(prediction_set == actual_set) / length(prediction_set);

    fprintf("The %s model scored %f%%\n", func2str(name), score);
end
