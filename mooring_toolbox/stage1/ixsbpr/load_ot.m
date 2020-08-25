function [Z,T,jd,meas,sampling_rate,qflag] = load_ot(file,log);% function [Z,T,jd,meas,sampling_rate,qflag] = load_ot(file,log);%% uses julian.m hms2h.m isint.m%% Kanzow, 25.03.05% Special characters used in this format ret  = sprintf('\n'); slsh = '/'; cln  = ':'; scln = ';'; tstr = 'deg C.'; zstr = 'cm'; databegin = ' 1 ;'; Estr  = 'E+.';   Tstr  = 'TEMPERATURE'; Pstr  = 'TIDE LEVEL';% ------ load data ------------fid = fopen(file,'r');disp('load_ot.m: loading data')zeile = fscanf(fid,'%c');  %read data into stringdisp('complete')fclose(fid);% --------- detect temperature and pressure columnif findstr(Tstr,zeile)<findstr(Pstr,zeile)  TI = 8;  PI = 9;else  TI = 9;  PI = 8;end  % --------- detect data begin + cut off headerretI  = findstr(zeile,ret);  % car. return indicesbegI  = findstr(zeile,databegin);disp('ot_load.m: Data begin detected')begI2 = find(retI<begI);zeile = zeile(retI(begI2(end)):end);% ------- eliminate special characters ---------nonum = findstr(zeile,slsh); zeile(nonum) = ' ' ;nonum = findstr(zeile,cln);zeile(nonum) = ' ' ;nonum = findstr(zeile,scln);zeile(nonum) = ' ' ;nonum = findstr(zeile,tstr);nonum = [nonum [nonum+1] [nonum+2] [nonum+4] [nonum+5]]; zeile(nonum) = ' ' ;nonum = findstr(zeile,zstr);nonum = [nonum [nonum+1]]; zeile(nonum) = ' ' ;nonum = findstr(zeile,Estr);nonum = [nonum [nonum+1] [nonum+2] [nonum+3] [nonum+4] [nonum+5]]; zeile(nonum) = ' ' ;% -identify format deviation ----------retI    = findstr(zeile,ret);  % car. return indicesrowlen  = diff(retI);mrowlen = median(rowlen);dev     = find(abs(rowlen-mrowlen)>2);if ~isempty(dev)  disp(['ot_load.m: Warning: Format deviation found in data row ',num2str(dev)])  fprintf(log,'ot_load.m: Warning: Format deviation found in data row %5.5d \n',dev) ;  if dev == length(rowlen)    zeile = zeile(1:retI(end-1));     disp(['ot_load.m: Last data row skipped'])    fprintf(log,'ot_load.m: Last data row skipped \n') ;  end  end% Replace format errors by dummies E     = findstr(zeile,'E+');blank = findstr(zeile,' ');for err = 1:length(E)  a   = find(blank<E(err));  b   = find(blank>E(err));  vec = (blank(a(end))+1: blank(b(1))-1);  zeile(vec(1:5))   = '-9999';  zeile(vec(6:end)) = ' ';end% -- convert data string to numbers --------data = str2num(zeile);[m,n] = size(data);%%keyboarddata(:,2) = data(:,2)  + 2000;jd   = julian([data(:,[2 3 4]) hms2h(data(:,[5 6 7]))]);Z    = data(:,PI)/100;  % water head [m]T    = data(:,TI);meas = data(:,1);if 0 if n == 9   % no conductivity   C = NaN;   S = NaN; elseif n>9   C = data(:,10);   S = data(:,11); endendsampling_rate = round(1/median(diff(jd))); % quality checkqflag = find(isint(Z));     