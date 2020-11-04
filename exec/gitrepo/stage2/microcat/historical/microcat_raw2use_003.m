% MICROCAT_RAW2USE_003 is a script that performs stage2 processing
% on microcat data:
%      1. eliminates lauch and recovery periods
%      2. saves data to rodb file
%      3. creates data overview figures
% 
% uses timeaxis.m, auto_filt.m, julian.m 

% 11.01.01 Kanzow 
% 13.08.02 Kanzow : debugged
% Paths changed for D344 18 October 2009 P Wright
% 22.03.2010 ZB Szuts: modified for Oceanus 459
%      

clear all
close all
%startup

% ----- This is the information that needs to be modified for ---------
% ----- different users, locations, directory trees, and moorings -----

% the location where the processing is done (a cruise name, NOCS, etc)
cruise = 'dy078';
operator = 'loh';
moor = 'test_ODO2017';

if exist('pathosnap','var')
    basedir = [pathosnap '/'];
else
    basedir = '/home/mstar/osnap/';
end

% the start and end times of the time axis for plotting
plot_interval = [2017 01 30;
       2017 01 31];


% ----------------- set path for data input and output --------------
%inpath   = [basedir,'moor/raw/',cruise,'/microcat/'];
inpath  = [basedir,'data/moor/proc/',moor,'/microcat/'];
outpath  = [basedir,'data/moor/proc/',moor,'/microcat/'];
% outpath  = ['/noc/users/dr400/temp/']; % reprocessing at NOCS
infofile = [basedir,'data/moor/proc/', moor,'/',moor,'info.dat'];

%inpath    = [basedir 'moor/raw/' cruise '/microcat_cal_dip/cast',cast,'/'];  
%outpath   = [basedir 'moor/proc_calib/' cruise '/cal_dip/microcat/cast' cast '/'];
%infofile  = [basedir 'moor/proc_calib/' cruise '/cal_dip/cast',cast,'info.dat'];
%ctdinfile = [ctddir  'ctd_di359_',ctdnum,'_psal.nc'];
%ctdinfile = [ctddir  'ctd_di359_',ctdnum,'_raw.nc'];

% -------------------------------------------------------------------


mc_id    = [333 337] ;             % microcat id numbers


% --- get mooring information from infofile 

[id,sn,z,s_t,s_d,e_t,e_d,lat,lon,wd,mr] = ...
    rodbload(infofile,['instrument:serialnumber:z:Start_Time:Start_Date:'...
                    'End_Time:End_Date:Latitude:Longitude:WaterDepth:Mooring']);

ii = find(id >= mc_id(1) & id<=mc_id(2));
sn = sn(ii);
z  = z(ii);
id = id(ii);

%sn = sn(1:2); z = z(1:2); id = id(1:2);

 
[z,zx] = sort(z);  % sort instruments by their depth
sn     = sn(zx);
id     = id(zx);



fid_stat = fopen([outpath,'stage2_log'],'w');
fprintf(fid_stat,'Processing steps taken by microcat_rdb2use.m:\n');
fprintf(fid_stat,'  1. eliminate lauching and recovery period\n');
fprintf(fid_stat,'  2. save data to rdb file\n');
fprintf(fid_stat,'\n Operated by:%s on %s\n',operator,datestr(clock)); 
fprintf(fid_stat,['        MicroCAT in Mooring ',moor,'\n\n\n']);
fprintf(fid_stat,'     ID    Depth   Start         End      Cycles  Spikes  Gaps   Mean     STD     Max     Min\n');          

% ---- despike paramenters

%T_range = [-15 +15];
%C_range = [-30 +30];  
%P_range = [-100 2000]; 

%dT_range = 18;  % accepted standard deviation envelope of adjecent T-values
%dC_range = 18;  % accepted standard deviation envelope of adjecent C-values 
%dP_range = 18;  % accepted standard deviation envelope of adjecent P-values 
%nloop    = 3;

dummy    = -9999;



%-----------------------------------------
% --- preprocessing loop -------------------
% ----------------------------------------

inst = 1;

jd_s  = julian(s_d(1),s_d(2),s_d(3),s_t(1)+s_t(2)/60);  % start time
jd_e  = julian(e_d(1),e_d(2),e_d(3),e_t(1)+e_t(2)/60);  % end time

for proc = 1 : length(sn),
    disp('plotting')
    
  infile  = [inpath,moor,'_',sprintf('%4.4d',sn(proc)),'.raw'];
  if exist(infile)
 
    rodbfile= [moor,'_',sprintf('%4.4d',sn(proc)),'.use']; % MPC: change 'inst' to 'sn' in filename 
    % infile  = [inpath,moor,'_',sprintf('%4.4d',sn(proc)),'.mc'];
    outfile = [outpath,rodbfile];

    inst = inst +1;
    [YY,MM,DD,HH,C,T,P] = rodbload(infile,'YY:MM:DD:HH:C:T:P');

    %------------------------------------------ 
    %----- cut off launching and recovery period
    %------------------------------------------
    disp('cut off launching and recovery period')
 
    jd = julian(YY,MM,DD,HH);
    ii = find(jd <= jd_e & jd >= jd_s );
    YY = YY(ii);   MM = MM(ii);   DD = DD(ii);
    HH = HH(ii);   c = C(ii);     t = T(ii);
    jd = jd(ii); 
    if length(P) > 1,  p = P(ii); end

    cycles     = length(ii);
    Start_Date = [YY(1) MM(1) DD(1)];
    Start_Time = HH(1);
    End_Date = [YY(cycles) MM(cycles) DD(cycles)];
    End_Time = HH(cycles);     

    %------------------------------------------
    %--- despike ------------------------------
    %------------------------------------------
    % disp('ddspike')   

    % [t,tdx,tndx] = ddspike(T,T_range,dT_range,nloop,'y',dummy); 
    % [c,cdx,cndx] = ddspike(C,C_range,dC_range,nloop,'y',dummy); 
    % if length(P) > 1 
    %   [p,pdx,pndx] = ddspike(P,P_range,dP_range,nloop,'y',dummy); 
    % end

    % -----------------------------------------
    % ---  basic statistics -------------------
    % -----------------------------------------
    % tstat = find(t ~= dummy);
    % cstat = find(c ~= dummy);    
    % tstat = t(tstat);
    % cstat = c(cstat);

    tm = meannan(t);
    cm = meannan(c);
  
    tsd= stdnan(t);
    csd= stdnan(c);

    tmx = max(t);
    cmx = max(c);
    tmn = min(t);
    cmn = min(c);

    if length(P) > 1
      % pstat = find(p ~= dummy);
      pm  = meannan(p);
      psd = stdnan(p);
      pmx = max(p);
      pmn = min(p);
    end 
     
    %------------------------------------------
    %---- fill time gaps  with dummy
    %------------------------------------------

    disp(' fill time gaps  with dummy')

    djd = diff(jd);           % time step  
    sr  = median(djd);        % sampling interval
    ii  = find(djd > 1.5*sr);  % find gaps
    gap = round(djd(ii)/sr)-1;
    addt= []; 

    for i = 1 : length(gap), 
      addt = [addt; [[1:gap(i)]*sr + jd(ii(i))]'];
                         
    end 

    [jd,xx] = sort([jd; addt]);   % add time
    ngap    = length(addt);       % number of time gaps         
    gt      = gregorian(jd);
    YY = gt(:,1);   MM = gt(:,2);   DD = gt(:,3); 
    if size(gt,2) == 6
       HH=hms2h(gt(:,4),gt(:,5),gt(:,6)); 
    else 
       HH= gt(:,4);
    end    
       
   
    t = [t;dummy*ones(ngap,1)]; t = t(xx);
    c = [c;dummy*ones(ngap,1)]; c = c(xx); 
    if length(P) > 1
       p = [p;dummy*ones(ngap,1)]; p = p(xx); 
    end
    %-----------------------------------------------------
    %  write output to logfile ---------------------------
    %-----------------------------------------------------

    disp(' write output to logfile')


    fprintf(fid_stat,'T   %5.5d  %4.4d  %2.2d/%2.2d/%2.2d   %2.2d/%2.2d/%2.2d   %d         %d   %5.2f   %5.2f   %5.2f   %5.2f \n',...
               sn(proc),z(proc),Start_Date,End_Date,cycles,ngap,tm,tsd,tmx,tmn'); 

    fprintf(fid_stat,'C   %5.5d  %4.4d  %2.2d/%2.2d/%2.2d   %2.2d/%2.2d/%2.2d   %d         %d   %5.2f   %5.2f   %5.2f   %5.2f \n',...
               sn(proc),z(proc),Start_Date,End_Date,cycles,ngap,cm,csd,cmx,cmn'); 

    if length(P) > 1
      fprintf(fid_stat,'P   %5.5d  %4.4d  %2.2d/%2.2d/%2.2d   %2.2d/%2.2d/%2.2d  %d        %d    %5.1f   %5.2f   %5.2f   %5.2f \n',...
               sn(proc),z(proc),Start_Date,End_Date,cycles,ngap,pm,psd,pmx,pmn');  
    end
    fprintf(fid_stat,'\n');

    %-----------------------------------  
    %--- write data to rodb format -----
    %-----------------------------------

    disp(['writing data to ',outfile]) 
    
    rodboutvars = ['Latitude:Longitude:Columns:Start_Date:Start_Time:'...
                   'SerialNumber:Mooring:WaterDepth:Instrdepth:'...
                   'End_Date:End_Time'];
    if length(P) <= 1
      sub =2;
      fort = '%4.4d   %2.2d   %2.2d   %8.5f   %6.4f   %6.4f';
      cols = 'YY:MM:DD:HH:T:C';
      rodbsave(outfile,rodboutvars,fort,...
               lat,lon,cols,Start_Date,Start_Time,sn(proc),mr,wd,...
               z(proc),End_Date,End_Time,[YY MM DD HH t c]);
    else
      sub  = 3;  
      fort = '%4.4d   %2.2d   %2.2d   %8.5f   %6.4f   %6.4f  %5.1f';
      cols = 'YY:MM:DD:HH:T:C:P';
      rodbsave(outfile,rodboutvars,fort,...
               lat,lon,cols,Start_Date,Start_Time,sn(proc),mr,wd,...
               z(proc),End_Date,End_Time,[YY MM DD HH t c p]);
    end

    %%%%%%%%%% Graphics %%%%%%%%%%%%%%%%

    jd1 = julian(plot_interval(1,:));
    jd2 = julian(plot_interval(2,:)); 

    figure(1);clf
    subplot(sub,1,1); ii = find(~isnan(t)&t>dummy);
    
    plot(jd(ii)-jd1,t(ii))
    title(['MicroCAT s/n: ',num2str(sn(proc)),'; Target Depth: ',num2str(z(proc))])
    ylabel('Temperature [deg C]')
    grid on
    xlim([0 jd2-jd1])
    timeaxis(plot_interval(1,1:3));   
    
    subplot(sub,1,2); ii = find(~isnan(c)&c>dummy);

    plot(jd(ii)-jd1,c(ii))
    ylabel('Conductivity [mS/cm]')
    grid on
    xlim([0 jd2-jd1])
    timeaxis(plot_interval(1,1:3));   

    if sub == 3 

      subplot(sub,1,3); ii = find(~isnan(p)&p>dummy);
      plot(jd(ii)-jd1,p(ii))

      ylabel('Pressure [dbar]')
      grid on 
      xlim([0 jd2-jd1])
      timeaxis(plot_interval(1,1:3));   

    end
    eval(['print -dps ',outfile,'.ps']) 
    % JC064 scu
     eval(['print -dps ',outfile,'.ps']) 

    sampling_rate = 1/median(diff(jd));
    tf            = auto_filt(t, sampling_rate, 1/2,'low',4);
    cf            = auto_filt(c, sampling_rate, 1/2,'low',4);
    pf            = auto_filt(p, sampling_rate, 1/2,'low',4);
    figure(2);clf
    subplot(sub,1,1); ii = find(~isnan(t)&t>dummy);

    plot(jd-jd1,tf)
    title(['2-day low-pass; MicroCAT s/n: ',num2str(sn(proc)),'; Target Depth: ',num2str(z(proc))])
    ylabel('Temperature [deg C]')
    grid on  
    xlim([0 jd2-jd1])
    timeaxis(plot_interval(1,1:3));   
    
    subplot(sub,1,2); ii = find(~isnan(c)&c>dummy);
    
    plot(jd-jd1,cf)
    ylabel('Conductivity [mS/cm]')
    grid on
    xlim([0 jd2-jd1])
    timeaxis(plot_interval(1,1:3));   

    if sub == 3 
      
      subplot(sub,1,3)
      
      plot(jd-jd1,pf)
      ylabel('Pressure [dbar]')
      grid on 
      xlim([0 jd2-jd1])
      timeaxis(plot_interval(1,1:3));   

    end
    eval(['print -dps ',outfile,'_lowpass.ps']) 
    

  end % if exist(infile)
  
end % for proc = 1 : length(sn),


  
