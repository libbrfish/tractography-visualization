function write_mrtrix_tracks(filename, tracks)

% function: write_mrtrix_tracks(filename, tracks)
%
% writes a structure containing the header information and data for the MRtrix 
% format track file 'filename' (i.e. files with the extension '.tck'). 
% The track data should be stored as a cell array in the 'data' field of the
% input variable 'tracks'.
%
% NOTE: for nii file: Dt=load_nii(filename) (cf nii_reader toolbox) ordre
% des coefficients:  Dxx, Dyy, Dzz, Dxy, Dxz, Dyz
% To convert nii to mif: mrconvert old.nii new.mif

f = fopen(filename, 'w');
assert(f ~= -1, 'error opening %s', filename);

% Write the header
fprintf(f, 'mrtrix tracks\n');
fields = fieldnames(tracks);
for i = 1:length(fields)
    if strcmp(fields{i}, 'data')
        continue;
    end
    value = getfield(tracks, fields{i});
    if iscell(value)
        for j = 1:length(value)
            fprintf(f, '%s: %s\n', fields{i}, value{j});
        end
    else
        fprintf(f, '%s: %s\n', fields{i}, value);
    end
end
fprintf(f, 'file: . %d\n', ftell(f));
fprintf(f, 'END\n');

% Write the track data
data = [];
for i = 1:length(tracks.data)
    fib = tracks.data{i};
    data = [data; fib; NaN(1, 3)];
end
fwrite(f, data', tracks.datatype);

fclose(f);
end