% function [un, vn, wn] = dgvf_calc(I, niter, miu, dt, dx, dy, dz)
% 	% Generate the diffusion gradient vector field as in Xu and Prince 1998
% 	% dgvf_calc is the three dimensional extension of the 2D version described in Equation 12
% 	% Xu and Prince 1998,"Snakes, Shapes, and Gradient Vector Flow", IEEE Transactions on Image Processing Vol.7(3)
%     % Input:
%     %			I: three dimensional image (matrix)
%     %			miu: the smoothing parameter (more smoothing -- higher miu-- for noisy images)   
% 	%			niter: number of iterations
% 	%			dt: time step
% 	%			dx, dy,dz: pixel spacing, set all to one for isotropic images
% 	% Output:
% 	%			un, vn, wn: the gradient vector field
% 	% Example usage:
% 	%			[un vn wn] = dgvf_calc(I,sqrt(numel(I)), 0.5, 1, 1, 1, 1)
%     %
%     % Author:   Dr.Khaled Khairy, Janelia Farm Research Campus, Howard Hughes Medical Institute.
%     %			June 2011. Please send corrections or comments to khairyk@janelia.hhmi.org
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% verbose = 0;
% [un, vn, wn] = gradient(double(I)); 
% E = -sqrt(un.^2 + vn.^2 + wn.^2); 		% Energy as in Xu and Prince 1998 Equation 2
%                                         % if the image is a line drawing
%                                         % then use: E = I --> Eq. 4
% [fx, fy, fz] = gradient(-E); clear E;	
% b = fx.^2 + fy.^2 + fz.^2;              % Equation 15
% c1 = b.*fx; clear fx
% c2 = b.*fy; clear fy
% c3 = b.*fz; clear fz

% r = miu*dt/dx/dy/dz;                	% Equation 17 (Xu and Prince 1998)
% if (dt>(dx*dy*dz/6/miu)), disp('convergence not guaranteed!!!! Resetting dt');dt =(dx*dy*dz/6/miu/2);disp(dt);end; % Equation 18

% if verbose, disp('Calculating 3D diffusion gradient vector field');end
% %% Start the time stepping (Xu Prince 1998 p.363 using 3D version of Equation 16 (Xu and Prince 1998)
% for n = 1:niter,        
%     if verbose,disp(['Diffusion gradient calculation iteration : ' num2str(n) '  of  ' num2str(niter)]);end
    
%     un = (1-b.*dt).*un+ r.*(  circshift(un,[-1  0  0])...
%         + circshift(un,[ 1  0  0])...
%         + circshift(un,[ 0 -1  0] )...
%         + circshift(un,[ 0  1  0] )...
%         + circshift(un,[ 0  0 -1] )...
%         + circshift(un,[ 0  0  1])...
%         - 6.*un)...
%         + c1.*dt;
    
%     vn = (1-b.*dt).*vn+ r.*(  circshift(vn,[-1  0  0])...
%         + circshift(vn,[ 1  0  0])...
%         + circshift(vn,[ 0 -1  0] )...
%         + circshift(vn,[ 0  1  0] )...
%         + circshift(vn,[ 0  0 -1] )...
%         + circshift(vn,[ 0  0  1])...
%         - 6.*vn)...
%         + c2.*dt;
%     wn = (1-b.*dt).*wn+ r.*(  circshift(wn,[-1  0  0])...
%         + circshift(wn,[ 1  0  0])...
%         + circshift(wn,[ 0 -1  0] )...
%         + circshift(wn,[ 0  1  0] )...
%         + circshift(wn,[ 0  0 -1] )...
%         + circshift(wn,[ 0  0  1])...
%         - 6.*wn)...
%         + c3.*dt;
% end

% if sum(isnan([un(:)' vn(:)' wn(:)']));error('diffusion gradient calculation failed');end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [un, vn, wn] = dgvf_calc(I, niter, miu, dt, dx, dy, dz, opts)
% Faster 3D GVF (Xu & Prince) using a 6-neighbour Laplacian via imfilter.
% Preserves 'circular' boundary conditions like circshift.
%
% opts.useGPU (logical, default false)
% opts.tol     early-stop tolerance on max change (default 1e-4, set [] to disable)
% opts.precision 'single'|'double' (default 'single')

    if nargin < 8, opts = struct; end
    if ~isfield(opts,'useGPU'),    opts.useGPU = true; end
    if ~isfield(opts,'tol'),       opts.tol    = 1e-4;  end
    if ~isfield(opts,'precision'), opts.precision = 'single'; end

    % Precision
    castf = @(x) feval(opts.precision, x);

    % Initial gradient field
    I = castf(I);
    [un, vn, wn] = gradient(castf(I));

    % External force (fixed over iterations)
    E        = -sqrt(un.^2 + vn.^2 + wn.^2);    % Eq. 2 (line drawing: E = I)
    [fx, fy, fz] = gradient(-E);                % ∇(-E)
    clear E
    b  = fx.^2 + fy.^2 + fz.^2;                 % Eq. 15
    c1 = b .* fx;  clear fx
    c2 = b .* fy;  clear fy
    c3 = b .* fz;  clear fz

    % Coefficients
    r = miu*dt/(dx*dy*dz);                      % Eq. 17
    if dt > (dx*dy*dz)/(6*miu)
        warning('dgvf:dtReset', 'Convergence not guaranteed. Resetting dt.');
        dt = (dx*dy*dz)/(12*miu);               % half the stability limit
    end
    A   = 1 - b*dt;                              % (1 - b*dt), fixed
    C1  = c1*dt; C2 = c2*dt; C3 = c3*dt;         % fixed
    clear b c1 c2 c3

    % 3D 6-neighbour Laplacian kernel: sum of axis-adjacent neighbours - 6*center
    K = zeros(3,3,3,'double');   % must be double for imfilter on GPU
    K(2,2,1) = 1; K(2,2,3) = 1;
    K(2,1,2) = 1; K(2,3,2) = 1;
    K(1,2,2) = 1; K(3,2,2) = 1;
    K(2,2,2) = -6;

    % Optional GPU acceleration
    if opts.useGPU
        try
            un = gpuArray(un); vn = gpuArray(vn); wn = gpuArray(wn);
            A  = gpuArray(A);  C1 = gpuArray(C1); C2 = gpuArray(C2); C3 = gpuArray(C3);
            K  = gpuArray(K);
        catch
            warning('dgvf:gpu','GPU unavailable, falling back to CPU.');
            opts.useGPU = false;
        end
    end

    % Iterations with optional early stopping
    if isempty(opts.tol), opts.tol = -inf; end  % disable if tol is []

    for n = 1:niter
        % Discrete Laplacian via convolution (periodic boundaries to match circshift)
        Lu = imfilter(un, K, 'circular', 'same');
        Lv = imfilter(vn, K, 'circular', 'same');
        Lw = imfilter(wn, K, 'circular', 'same');

        un_new = A .* un + r .* Lu + C1;
        vn_new = A .* vn + r .* Lv + C2;
        wn_new = A .* wn + r .* Lw + C3;

        % Early stop check every few iterations (cheap)
        if opts.tol > 0 && (mod(n,5) == 0 || n==niter)
            delta = max([ ...
                gather(max(abs(un_new(:) - un(:)))), ...
                gather(max(abs(vn_new(:) - vn(:)))), ...
                gather(max(abs(wn_new(:) - wn(:)))) ]);
            if delta < opts.tol
                % fprintf('Converged at iter %d (Δ=%.3g)\n', n, delta);
                un = un_new; vn = vn_new; wn = wn_new; %#ok<NASGU>
                break
            end
        end

        un = un_new; vn = vn_new; wn = wn_new;
    end

    % Return to CPU if needed
    if opts.useGPU
        un = gather(un); vn = gather(vn); wn = gather(wn);
    end

    if any(isnan(un(:))) || any(isnan(vn(:))) || any(isnan(wn(:)))
        error('diffusion gradient calculation failed');
    end
end
