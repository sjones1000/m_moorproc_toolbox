% function seaguard_raw2use(infile,infofile,'outpath',outpath)%% basic preprocessing for Seaguard RCM data (with T, C and P sensors)% % required inputs: infile - name and path of .raw file%                  infofile - name and path of info.dat file%% optional inputs: outpath - path to output processed files to - otherwise%                            outputs to directory function run from%                  plot_interval - matrix of start and end dates for plot%                                  e.g. [2004 02 01 00; 2005 06 01 00]%                                  dates are:- yyyy mm dd hh%% features%      1. eliminate launching and recovery period%      2. save data to rodb file%      3. create data overview sheet%% uses timeaxis.m, auto_filt.m, julian.m, rodbload.m, rodbsave.m% 31/10/2009 - DR modified from nortek_raw2use_01 on cruise D344function seaguard_raw2use(Serial_number,infile,infofile,varargin)  if nargin==0    help seaguard_raw2use;    returnend% check for optional argumentsa=strmatch('outpath',varargin,'exact');if a>0    outpath=char(varargin(a+1));else    outpath = './';enda=strmatch('plot_interval',varargin,'exact');if a>0    plot_interval=varargin(a+1);    plot_interval=str2mat(plot_interval);    plot_interval=eval(plot_interval);else    plot_interval=0;endif isunix    [gash, operator]=system('whoami');  % This line will not work if run from a PC. May need to edit it out.else    operator='unknown';end[id,sn,z,s_t,s_d,e_t,e_d,lat,lon,wd,mr]  =  rodbload(infofile,'instrument:serialnumber:z:Start_Time:Start_Date:End_Time:End_Date:Latitude:Longitude:WaterDepth:Mooring');index=find(sn==str2double(Serial_number));indep=z(index);fid_stat= fopen([outpath 'Seaguard_stage2.log'],'a');fprintf(fid_stat,['Processing steps taken by ' mfilename ':\n']);fprintf(fid_stat,'  1. eliminate lauching and recovery period\n');fprintf(fid_stat,'  2. save data to rdb file\n');fprintf(fid_stat,'\n Operated by:%s on %s\n',operator,datestr(clock)); % Determine plot_interval if not input to functionif plot_interval==0    plot_interval = zeros(2,4);    plot_interval(1,1) = s_d(1); plot_interval(1,2) = s_d(2)-1; plot_interval(1,3) = 1; plot_interval(1,4) = 0;    plot_interval(2,1) = e_d(1); plot_interval(2,2) = e_d(2)+1; plot_interval(2,3) = 1; plot_interval(2,4) = 0;    if plot_interval(1,2)==0        plot_interval(1,2)=12; plot_interval(1,1)=plot_interval(1,1)-1;    end    if plot_interval(2,2)==13        plot_interval(2,2)=1; plot_interval(2,1)=plot_interval(2,1)+1;    endend%-----------------------------------------% --- preprocessing loop -------------------% ----------------------------------------jd_s  = julian(s_d(1),s_d(2),s_d(3),s_t(1)+s_t(2)/60);  % start timejd_e  = julian(e_d(1),e_d(2),e_d(3),e_t(1)+e_t(2)/60);  % end timecolumns = 'YY:MM:DD:HH:U:V:CS:CD:CSSD:MSS:HDG:PIT:ROL:T:C:TC:P:TP:IPOW';if exist(infile,'file')==0   disp(['infile: ' infile ' does not exist.'])elseif exist(infile,'file')   > 0    rodbfile= infile;   outfile_index=strfind(rodbfile,'/');   rodbfile=rodbfile(outfile_index(end):end);   rodbfile(end-2:end)='use';   outfile = [outpath,rodbfile];   fprintf(fid_stat,'Infile %s \n',infile);   fprintf(fid_stat,'Outfile %s \n',outfile);        [YY,MM,DD,HH,u,v,cs,cd,cssd,mss,hdg,pit,rol,t,c,tc,p,tp,ipow] = ...            rodbload(infile,columns);        %------------------------------------------         %----- cut off launching and recovery period        %------------------------------------------        disp('cut off launching and recovery period')        jd  = julian(YY,MM,DD,HH);        ii  = find(jd <= jd_e & jd >= jd_s );        YY=YY(ii);MM=MM(ii);DD=DD(ii);HH=HH(ii);        t=t(ii);p=p(ii);c=c(ii);        tp=tp(ii);tc=tc(ii);        u=u(ii);v=v(ii);cssd=cssd(ii);        hdg=hdg(ii);pit=pit(ii);rol=rol(ii);        mss=mss(ii);        ipow=ipow(ii); cs=cs(ii); cd=cd(ii);        jd  = jd(ii);         cycles     = length(ii);        Start_Date = [YY(1) MM(1) DD(1)];        Start_Time = HH(1);        End_Date = [YY(cycles) MM(cycles) DD(cycles)];        End_Time = HH(cycles);                  %-----------------------------------------------------        %  write output to logfile ---------------------------        %-----------------------------------------------------        fprintf(fid_stat,'Operation interval: %s  to  %s\n', ...              datestr(gregorian(jd(1))),datestr(gregorian(jd(end)) ));        fprintf(fid_stat,'\n');        %-----------------------------------          %--- write data to rodb format -----        %-----------------------------------        disp(['writing data to ',outfile])         fort ='%4.4d %2.2d %2.2d %7.5f %6.3f %6.3f %6.3f %5.1f %6.2f %6.3f %5.1f %4.1f %4.1f %6.3f %6.3f %6.3f %5.1f %6.3f %5.3f';        rodbsave(outfile,...          'Latitude:Longitude:Columns:Start_Date:Start_Time:SerialNumber:Mooring:WaterDepth:Instrdepth:End_Date:End_Time',...           fort,...           lat,lon,columns,Start_Date,Start_Time,str2double(Serial_number),mr,wd,indep,End_Date,End_Time,...          [ YY,MM,DD,HH, u, v, cs, cd, cssd, mss, hdg, pit, rol, t, c, tc, p, tp, ipow]);        %%%%%%%%%% Graphics %%%%%%%%%%%%%%%%        jd0 = julian(-1,1,1,24);        jd1 = julian(plot_interval(1,:))-jd0;        jd2 = julian(plot_interval(2,:))-jd0;         sampling_rate = 1/median(diff(jd));        STR = ['Temperature [deg C]   ';               'Pressure [dbar]       ';                 'Conductivity [mS/cm]  ';               'Zonal Velocity [cm/s] ';               'Merid. Velocity [cm/s]'];         VAR1= ['t';'p';'c';'u';'v'];         panels=5;        figure(1);clf        for sub = 1 : 5          eval(['var1 = ',VAR1(sub),';'])          var2=[];          ok = plot_timeseries(jd,var1,var2,sampling_rate,STR(sub,:),sub,[jd1 jd2],'n',panels);        end        subplot(5,1,1)        title(['Seaguard s/n: ',Serial_number])        orient tall        eval(['print -depsc ',outfile,'.eps'])         figure(2);clf        for sub = 1 : 5          eval(['var1 = ',VAR1(sub),';'])          ok = plot_timeseries(jd,var1,var2,sampling_rate,STR(sub,:),sub,[jd1 jd2],'y',panels);        end        subplot(5,1,1)        title(['Seaguard s/n: ',Serial_number])        orient tall        eval(['print -depsc ',outfile,'.filtered.eps'])         end % if exist(infile)==0end % function  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  function ok = plot_timeseries(jd,var1,var2,sr,str,sub,jdlim,filt,panels)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot time series  jd0 = julian(-1,1,1,24);  i1    = find(~isnan(var1) & var1~=0);   if strcmp(filt,'y')    var1  = auto_filt(var1(i1),sr,1/2,'low',4);  else    var1  = var1(i1);  end   if ~isempty(var2)    i2    = find(~isnan(var2) & var2~=0);    if strcmp(filt,'y')      var2  = auto_filt(var2(i2),sr,1/2,'low',4);    else      var2  = var2(i2);    end  end  subplot(panels,1,sub);           plot(jd(i1)-jd0,var1)  hold on  if ~isempty(var2)    plot(jd(i2)-jd0,var2,'r')  end   ylabel(str)  grid on  xlim([jdlim])  datetick('x',12)        ok=1;  end