function [E, bounds, pixnerve] = entropy_matrix_to_nii(filename, init_size, param, refNii, outPrefix)
% Compute entropy matrix and vector field; write MRtrix-compatible NIfTIs
%
% Inputs:
%   filename   - fiber file (.tck/.txt)
%   init_size  - original DTI size, e.g. [129 129 27]
%   param      - neighborhood sizes for entropy, e.g. [3 3 3]
%   refNii     - optional reference NIfTI for voxel size
%   outPrefix  - output prefix (directory + base name)
%
% Outputs:
%   E          - entropy matrix (cropped/resampled)
%   bounds     - crop bounds [xmin xmax ymin ymax zmin zmax]
%   pixnerve   - coordinates of the nerve in cropped/resampled space

if nargin < 5
    outPrefix = 'entropy';
end
if isstring(outPrefix)
    outPrefix = char(outPrefix);
end

fprintf('Computing entropy matrix and vector field...\n');

%% 1) Load fibers and crop
nerve = tracks2array(filename);
if size(nerve,2) < 20
    error('Empty file or not enough fibers');
end
[crop_nerve, dim, bounds] = crop1(nerve, init_size, []);

%% 2) Create binary image and resample
[pixnerve, I] = fib_3D_image(crop_nerve, 3, dim);
resample = round(size(I,1)/double(dim(1)));

%% 3) Convert to spherical vector field (theta,phi)
[DT, vectorfield, vectorfield2] = im2field(I);  % size: sx x sy x sz x 2
[sx, sy, sz, ~] = size(DT);
outFile = [outPrefix '_vector.nii.gz'];
outFile2 = [outPrefix '_vector2.nii.gz'];
write_vectorfield_to_nifti_cropped(vectorfield, bounds, refNii, outFile);
write_vectorfield_to_nifti_cropped(vectorfield2, bounds, refNii, outFile2);

%% 4) Compute entropy
[T, P] = find_bins(60);
Emat = cell(1, size(param,1));
fprintf('%s\n', "Entropy matrices computed...");

fullSize_hr = init_size .* resample;  % full volume size
DT_fill = nan(init_size*3);
DT_fill(1:size(DT,1), 1:size(DT, 2), 1:size(DT, 3), 1:size(DT,4)) = DT; 

% Computes entropy map
for i = 1:size(param, 1)
    mat = entropy3D_codegen(DT_fill, [size(DT,1), size(DT,2), size(DT,3)], param(i, :), 60, T, P); 
    Emat{i} = apply_mask(mat, pixnerve); 
end

% Multi-scale if required
if size(param, 1) == 1
    E = Emat{1};
else
    E = multiscale(Emat, param); 
end 

% Normalizing entropy to [0, 1] for comparison purposes
minV = nanmin(nanmin(nanmin(E)));
maxV = nanmax(nanmax(nanmax(E)));
E = (E-minV)/(maxV-minV);

end
