clc;
clearvars;
format compact

W = [2 1 1; 1 2 1];
disp(W);
fprintf('\n');
fprintf('\n');
weight_sum = sum(W,2);
weight_sum = weight_sum(1);
p1 = [1; 0; 1];
p2 = [0; 1; 0];
hebb_matrix_template = [1 0 1; 0 1 0];
curr = p1;
for i=1:96
    output = W*curr;
    [M, index] = max(output);
    synaptic_activity = [0; 0];
    synaptic_activity(index) = 1;
    hebb_matrix = hebb_matrix_template .* synaptic_activity;
    W = W + hebb_matrix;
    row_sums = sum(W,2);
    target_sum = row_sums(index);
    normalization_factor = weight_sum/target_sum;
    normalization_matrix = [1; 1];
    normalization_matrix(index) = normalization_factor;
    W = W .* normalization_matrix;
    fprintf("Iteration %i, connectivity matrix is", i);
    fprintf('\n');
    disp(W);
    fprintf('\n');
    if isequal(curr, p1), curr = p2;
    else, curr = p1; end
end
