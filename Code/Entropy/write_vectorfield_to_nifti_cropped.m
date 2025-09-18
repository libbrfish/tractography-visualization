function write_vectorfield_to_nifti_cropped(vectorfield, bounds, ref_filename, nifti_filename)
    % Write cropped spherical vector field vectorfield to a NIfTI using a 3D reference image
    % vectorfield: 4D array (sx x sy x sz x 2), vectorfield(:,:,:,1)=theta, vectorfield(:,:,:,2)=phi
    % bounds: [xmin, xmax, ymin, ymax, zmin, zmax] voxel indices from crop1
    % ref_filename: reference 3D NIfTI filename
    % nifti_filename: output NIfTI filename
    
    % Load reference NIfTI
    ref_nii = load_untouch_nii(ref_filename);  % Requires NIfTI toolbox
    ref_dim = size(ref_nii.img);       % 3D reference size

    % Determine target cropped size in reference
    target_size = [bounds(2)-bounds(1)+1, bounds(4)-bounds(3)+1, bounds(6)-bounds(5)+1];

    % Resample each vectorfield component to match target size
    % theta_resamp = imresize3(vectorfield(:,:,:,1), target_size, 'linear');
    % phi_resamp   = imresize3(vectorfield(:,:,:,2), target_size, 'linear');

    % [vx, vy, vz] = sph2cart2(theta_resamp, phi_resamp);
    vx = imresize3(vectorfield(:,:,:,1), target_size, 'linear');
    vy = imresize3(vectorfield(:,:,:,2), target_size, 'linear');
    vz = imresize3(vectorfield(:,:,:,3), target_size, 'linear');


    % Flatten the vectors into 3 x N
[sx, sy, sz] = size(vx);
vec = [vx(:)'; vy(:)'; vz(:)'];  % 3 x N

% Get affine from reference NIfTI
if ref_nii.hdr.hist.sform_code > 0
    affine = [ref_nii.hdr.hist.srow_x; ref_nii.hdr.hist.srow_y; ref_nii.hdr.hist.srow_z; 0 0 0 1];
elseif ref_nii.hdr.hist.qform_code > 0
    affine = computeQform(ref_nii);  % user-defined function if needed
else
    affine = eye(4);
end

R = affine(1:3,1:3);  % linear part of affine

% Apply affine linear transform to the vectors
vec_scanner = R * vec;  % 3 x N

% Reshape back to 3D arrays
vx = reshape(vec_scanner(1,:), sx, sy, sz);
vy = reshape(vec_scanner(2,:), sx, sy, sz);
vz = reshape(vec_scanner(3,:), sx, sy, sz);

% Print range of Cartesian vectors


    
    % Allocate 4D volume (same size as reference, 4th dim = 3 for vx, vy, vz)
    V = zeros([ref_dim, 3]);
    
    % Determine indices in reference volume
    x_idx = bounds(1):bounds(2);
    y_idx = bounds(3):bounds(4);
    z_idx = bounds(5):bounds(6);
    
    % Place vectors into the reference-aligned volume
    V(x_idx, y_idx, z_idx, 1) = vx;
    V(x_idx, y_idx, z_idx, 2) = vy;
    V(x_idx, y_idx, z_idx, 3) = vz;

    ref_nii.hdr.dime.dim(5) = 3;   % set 4th dimension size = 3
    ref_nii.hdr.dime.dim(1) = 4;   % 4D image
    ref_nii.hdr.dime.dim(2:4) = ref_dim;
    ref_nii.hdr.dime.pixdim(5) = 1; % spacing for 4th dim
    ref_nii.img = V;
    % Copy header from reference and replace image
    out_nii = ref_nii;
    out_nii.img = V;
    
    % Save new NIfTI
    save_untouch_nii(out_nii, nifti_filename);
    
    fprintf('Vector field saved to %s with reference alignment.\n', nifti_filename);
end
