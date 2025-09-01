function [r, num]= find_bins(N)
    
    % REGIONS = eq_regions(2,N);

    % R=ones(1,N*2).*20;
    % reg=reshape(REGIONS(2,:,:),1,N*2);
    % p=1;
    % for i=1:N*2
    %     k=0;

    %     for j=1:p
    %         if(single(reg(i))==single(R(j)))
    %             k=1;

    %         end
    %     end

    %     if k==0

    %         R(p)=reg(i);
    %         p=p+1;
    %     end
    % end
    % r=R(1:p-1);

    % num=ones(1,(length(r)-1));
    % for i=1:(length(r)-1)
    %     k=0;
    %     for j=1:N
    %       if single(REGIONS(2,1,j))==single(r(i))
    %           k=k+1;
    %       end
    %     end
    %     num(i)=k;            
    % end

    REGIONS = eq_regions(2, N);

    % Flatten region values into a row
    reg = reshape(REGIONS(2,:,:), 1, []);

    % Get unique values directly
    r = unique(reg, 'stable');   % preserves original order

    % Count occurrences of each unique value in REGIONS(2,1,:)
    vals = squeeze(REGIONS(2,1,:));
    num = histc(vals, r);  % or use histcounts(vals, 'BinMethod','integers')
    
end

