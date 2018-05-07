%% Produce training set

% NOTE: using only left eye data for simplicity
% future change might be to double the dimmension space
% with right eye data on the same row

function produce_set(tagged_flag)
    if tagged_flag, filename = "training_data";
    else, filename =  "testing_data"; end
    
    fprintf("Creating %s \n", filename);
    file = input('Name of data file-->', 's');
    fid = fopen(['./data/' file '.txt']);
    
    disp("Parsing and cleaning.........");
    while true
        line = fgetl(fid);
        if contains(line, 'SYNCTIME')
            break;
        end
    end
    
    left_data = [];
    current_type = 0;
    while true
        data = strsplit(char(fgetl(fid)));
        if(strcmp(data{1}, 'SFIX')), current_type = 1;
        elseif(strcmp(data{1}, 'EFIX')), continue;
        elseif(strcmp(data{1}, 'SSACC')), current_type = 2;
        elseif(strcmp(data{1}, 'ESACC')), continue;
        elseif(strcmp(data{1}, 'SBLINK')), current_type = -1;
        elseif(strcmp(data{1}, 'EBLINK')), continue;
        end

        if(length(data) == 8 && current_type ~= -1)
            left_data = [left_data; str2double(cell2mat(data(1,1))), str2double(cell2mat(data(1,2))), str2double(cell2mat(data(1,3))), current_type];
        end

        if ~feof(fid) == 0, break; end
    end

    csvwrite("./cleaned/" + filename + ".csv" , left_data);
end