function [tab] = DSI2tck(infile, dim)
    
% Converts txt DSI file to tck Mrtrix file.
%
% INPUT:
% infile : full name of the DSI file to be converted
% dim : array of the 3 dimensions of the DTI image used to get tck file from Mrtrix
%
% EXAMPLE: DSI2tck('dsiChiasma.txt', [128,128,26]);

    % Read the DSI file
    fid = fopen(infile, 'r');
    data = fscanf(fid, '%f');
    fclose(fid);
    
    % Reshape the data into 3 columns
    data = reshape(data, 3, [])';
    
    % Initialize the output cell array
    tab = cell(1, size(data, 1));
    
    for k = 1:size(data, 1)
        fib = data(k, :);
        fib = reshape(fib, 3, [])';
        
        % Convert coordinates
        fib(:,2) = dim(2) + 1 - fib(:,2);
        fib(:,1) = dim(1) + 1 - fib(:,1);
        
        tab{k} = fib;
    end
end