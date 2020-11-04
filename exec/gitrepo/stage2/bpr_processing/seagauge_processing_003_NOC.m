% SEAGAUGE_PROCESSING_002_OC459 is a script that performs stage2
% processing on seagauge data from one mooring.  This consists of
% adding a linear clock drift (if any) and determining what
% functional form to use for the pressure drift.
%
% It calls purge_bp_003.m, rodbload.m, rodbsave.m, julian.m,
% gregorian.m, auto_filt.m

% 16.03.05 Kanzow
% 06.11.08 Szuts
% 27.03.10 ZB Szuts: modify for oc459, add descriptive headers,
%   clean up a bit
% 2011 Apr 13 EFW
% 2012 Feb 15 SKYE

clear all
close all

% -----------------------------------------------------------------
% --- This is the information that needs to be modified for -------
% --- different users, directory trees, and moorings --------------
% -----------------------------------------------------------------
% jym 22 April 2005: Request to all operators who change path names 
% for development purposes -
% PLEASE change them back to work on the common computer, so that we do
% not have to reinvent the changes over and over again.

%  mooring = 'mar1l4_4_200941';
%   mooring = 'mar0_3_200943';
%   mooring = 'mar3l4_4_200938';
%  mooring = 'eb1l5_5_200834';
%moor = 'wb1_7_201008';
%moor = 'wb2_8_201003';
%moor = 'wbh2_4_201004';
%moor = 'wb4_7_201026';
%moor = 'wb6_4_201001';
%mooring = 'mar0_4_201029';
%cruise      = 'jc064';
cruise = 'rb1201';
mooring = 'wb4l6_6_201002';
operator  = 'dr400';
basedir = '/noc/mpoc/rpdmoc/rapid/data/';

plot_interval = [2010  3  1 00;   % start time of time axis on plot
                 2012 03 1 00];  % end time of time axis on plot

% -----------------------------------------------------------------


% --- set paths for data input and output ---
% NB The seagauge dir in outpath must be created first

inpath     = [basedir 'moor/proc/' mooring '/seagauge/'];
outpath    = [basedir 'moor/proc/' mooring '/seagauge/'];
info       = [basedir 'moor/proc/' mooring '/' mooring 'info.dat'];
clock_file = [basedir 'moor/raw/' cruise '/seagauge/bpr_clock_offset.dat'];

% ZB Szuts, 27.03.10, oc459
% There are 2 clock offset files for BPR instruments:
% clock_offset.dat (in raw/oc459/) and BPR_clock_offset.dat in
% (raw/oc459/seagauge/):
% - clock_offset.dat corrects for constant day/year offsets that
% arise from incorrect instrument setup at the beginning of the
% record.
% - bpr_clock_offset.dat corrects for smaller offsets measured upon
% recovery in stage2 processing, and are applied as linear trends
% for the whole record.

programme = mfilename; %    = 'seagauge_processing_003_d382.m';
sg_code       = 465;  % seagauge identifier
dum           = -9999; % dummy value


% --- get mooring information from infofile ---
[lat,lon,wd,sdate,stime,edate,etime,z,type,serial]= ...
    rodbload(info,...
             ['Latitude:Longitude:WaterDepth:StartDate:StartTime:'...
              'EndDate:EndTime:z:instrument:serialnumber']);


% --- find all the seagauges on the mooring ---
sgI          = find(type==sg_code);
sn  = serial(sgI);


% --- write header info to log file ---
logfile = [outpath,'stage2_log'];
fidlog  = fopen(logfile,'w');
fprintf(fidlog,['Stage 2 processing of SBE26 (or SBE53) \n data from '...
                'mooring %s \n Date: %s \n'],mooring,datestr(clock)');
fprintf(fidlog,'Operator: %s\n',operator');
fprintf(fidlog,'Programme: %s\n',programme);


% --- loop through each instrument on the mooring ---
for ins = 1 : length(sgI)

  serialnumber = sn(ins);
  instrdepth   = z(sgI(ins));

  disp(['SBE-26 instrument ',num2str(serialnumber),' has been found'])

  % --- make input and output file names ---
  file    = [inpath,mooring,'_',sprintf('%5.5d',serialnumber),'.raw'];
  outfile = [outpath,mooring,'_',sprintf('%4.4d',serialnumber),'.use'];

  % --- write to log file ---
  fprintf(fidlog,'Serialnumber %d \n',serialnumber);
  fprintf(fidlog,'Target Depth [m]: %4.4d\n',instrdepth);
  fprintf(fidlog,'Infile %s \n',file);
  fprintf(fidlog,'Outfile %s \n',outfile);


  % --- load data and carry out basic checks ---
  [yy,mm,dd,hh,P,T] = rodbload(file,'YY:MM:DD:HH:P:T');

  jd = julian(yy,mm,dd,hh);


  % ------- check data ----------------

  sampling_rate = round(1./median(diff(jd))); % nominal sampling rate [per day] 

  % ---- check for a time offset entry in the 'clock_file' -----

  time_corr = input(['Shall time be corrected for clock offset? y/n '],'s');

  if strcmp(time_corr,'y')
    eval(['load ',clock_file])
    ins = find(serialnumber == bpr_clock_offset(:,2) & ...
               sg_code      == bpr_clock_offset(:,1));

    if isempty(ins)
      fprintf(1,['Clock offset not found in %s'],clock_file);
      fprintf(fidlog,['Clock offset not found in %s'],clock_file);
      coff = input('Enter post deployment clock offset [s] from log sheet ');
    else 
      coff = bpr_clock_offset(ins,3);
    end

    % --- calculate a linear clock drift and subtract it from jd ---
    len  = length(jd);
    coff = linspace(0,coff/86400,len); % assume linear clock drift
    jd   = jd - coff';  % subtract drift

    
    fprintf(1,'Clock offset at recovery of %d s (relative to UTC)\n',coff)
    fprintf(1,['Calculated a linear trend going through '...
               'jd([1 end]) and [0 %s]\n'],coff);
    fprintf(1,'and subtracted it from the recorded time')

    fprintf(fidlog,'Clock offset at recovery of %d s (relative to UTC)\n',coff)
    fprintf(fidlog,['Calculated a linear trend going through '...
                    'jd([1 end]) and [0 %s]\n'],coff);
    fprintf(fidlog,'and subtracted it from the recorded time')
    
  end

  jd_start = julian([sdate' hms2h([stime;0]')']);
  jd_end   = julian([edate' hms2h([etime;0]')']);


  % --- calculate fits for pressure drifts ---
  [pr_int,pr_exfit,t_int,jd_grid,pr_linfit,coef_exfit,coef_linfit] =  ... 
      purge_bp_003(sampling_rate,jd,P,T,[jd_start jd_end],fidlog);


  % ------------ graphics ------------------------

  jd0 = julian(-1,1,1,24);
  jd1 = julian(plot_interval(1,:))-jd0;
  jd2 = julian(plot_interval(2,:))-jd0; 

  % --- plot original data ---
  figure(21); 
  clf
  subplot(2,1,1); 
  % SKYE 
  ii = find(~isnan(pr_int) & pr_int~=dum);
  plot(jd_grid(ii)-jd0,pr_int(ii))
  title(['Seagauge s/n: ',num2str(serialnumber),...
         '; Target Depth: ',num2str(instrdepth)])
  ylabel('Pressure [dbar]')
  grid on
  xlim([jd1 jd2])
  %timeaxis(plot_interval(1,1:3));   
  datetick('x',12)

  subplot(2,1,2); ii = find(~isnan(t_int) & t_int~=dum);
  plot(jd_grid(ii)-jd0,t_int(ii))
  ylabel('Temperature [deg C]')
  grid on
  xlim([jd1 jd2])
  %   timeaxis(plot_interval(1,1:3));   
  orient tall
  datetick('x',12)

  eval(['print -depsc ',outfile,'.1.eps']) 

  
  % --- plot filtered data ---
  figure(22);clf     % 2 day low pass

  subplot(3,1,1); ii = find(~isnan(pr_int) & pr_int~=dum);
  plot(jd_grid(ii)-jd0,auto_filt(pr_int(ii),sampling_rate,1/2,'low',4))
  hold on, grid on
  plot(jd_grid-jd0,pr_exfit,'r')
  plot(jd_grid-jd0,pr_linfit,'g')
  legend('data','exp-lin fit','lin fit')
  title(['Seagauge s/n: ',num2str(serialnumber),...
         '; Target Depth: ',num2str(instrdepth),' 2-day low pass'])
  ylabel('Pressure [dbar]')
  xlim([jd1 jd2])
  %    timeaxis(plot_interval(1,1:3));   
  datetick('x',12)


  % --- decide whether an exponential+linear or ---
  % --- linear fit is more apropriate ---

  disp('Which empirical fit should be stored (see figure 22):')
  fit_select = input('  (1) exponential-linear  or  (2) linear ? ');
  
  if fit_select == 1
    fprintf(fidlog,'Exponential-linear pressure fit to be stored with data \n');
    fprintf(fidlog,'  amplitude of exponential decay: %f db \n',coef_exfit(1));
    fprintf(fidlog,'  time-constant of exponential decay: %f days \n',1/coef_exfit(2));
    fprintf(fidlog,'  linear slope: %f db/day \n',coef_exfit(3));
    fprintf(fidlog,'  mean offset: %f db \n',coef_exfit(4));
    
    fprintf(1,'Exponential-linear pressure fit to be stored with data \n');
    fprintf(1,'  amplitude of exponential decay: %f db \n',coef_exfit(1));
    fprintf(1,'  time-constant of exponential decay: %f days \n',1/coef_exfit(2));
    fprintf(1,'  linear slope: %f db/day \n',coef_exfit(3));
    fprintf(1,'  mean offset: %f db \n',coef_exfit(4));
    pfit = pr_exfit;

  elseif fit_select == 2
    fprintf(fidlog,'Linear pressure fit to be stored with data \n');
    fprintf(fidlog,'  linear slope: %f db/day \n',coef_linfit(1));
    fprintf(fidlog,'  mean offset: %f db \n',coef_linfit(2));

    fprintf(1,'Linear pressure fit to be stored with data \n');
    fprintf(1,'  linear slope: %f db/day \n',coef_linfit(1));
    fprintf(1,'  mean offset: %f db \n',coef_linfit(2));
    pfit = pr_linfit;

  end 


  subplot(3,1,2); 
  plot(jd_grid(ii)-jd0,auto_filt(pr_int(ii),sampling_rate,1/2,'low',4)-pfit)
  title('Empirical drift estimate subtracted') 
  ylabel('Pressure [dbar]')
  grid on
  xlim([jd1 jd2])
  %    timeaxis(plot_interval(1,1:3));   
  datetick('x',12)

  subplot(3,1,3); ii = find(~isnan(t_int) & t_int~=dum);
  plot(jd_grid(ii)-jd0,auto_filt(t_int(ii),sampling_rate,1/2,'low',4))
  ylabel('Temperature [deg C]')
  grid on
  xlim([jd1 jd2])
  %    timeaxis(plot_interval(1,1:3));   
  datetick('x',12)

  orient tall
  eval(['print -depsc ',outfile,'.2.eps']) 



  % ------ save data in rodb format ---------

  cols      = 'YY:MM:DD:HH:P:T:PFIT';
  fort      = '%4.4d  %2.2d  %2.2d  %7.5f   %8.4f %7.4f %8.4f';
  time      = gregorian(jd_grid);
  data      = [time(:,1:3) hms2h(time(:,4:6)) pr_int(:) t_int(:) pfit(:)];

  rodbsave(outfile,...
           ['Latitude:Longitude:Columns:Start_Date:Start_Time:'...
            'SerialNumber:Mooring:WaterDepth:Instrdepth:End_Date:End_Time'],...
           fort,...
           lat,lon,cols,sdate,stime(1:2),...
           serialnumber,mooring,wd,instrdepth,edate,etime(1:2),...
           data);

end % for ins = 1 : length(sgI)

fclose(fidlog);
