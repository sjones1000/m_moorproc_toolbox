function [out]=corrcoefnan(x);% CORRCOEFNAN uses CORRCOEF, but accepts NaNs in data.% function [out]=corrcoefnan(x);% For corrcoef, NaNs are replaced by % linear interpolation in between and% nearest neighbour at the beginning/end (Columnwise).%% Andreas Macrander, 12.4.2000.[tx,ty]=size(x);txv=[1:1:tx]';for i=1:ty      %Checking columnwise for NaNs iii=~isnan(x(:,i));    %Replacing NaNs in between by lin interpolation. if ~isempty(iii)  xi(:,i)=interp1(txv(iii),x(iii,i),txv,'linear'); end iii=~isnan(xi(:,i));   %Checking for remaining NaNs at beginning/end. diffiii=diff(iii); jjj=find(diffiii~=0); if ~isempty(jjj)  for j=1:jjj(1)      %Replacing NaNs at beginning of column i.   xi(j,i)=xi(jjj(1)+1,i);  end  for j=(jjj(length(jjj))+1):length(xi(:,i))  %Same at end of column i.   xi(j,i)=xi(jjj(length(jjj)),i);  end endendout=corrcoef(xi);%%%%%%%%%%%