% MC_CALL_CALDIP_OC459 is a script that performs stage1 processing
% on microcat data from CTD calibration casts (caldips).  It
% converts microcat data from raw to rodb format for an entire
% caldip, and plots it with CTD data.
%
% It calls microcat2rodb_3 (to convert microcat_data), rodbload.m,
% timeaxis.m, auto_filt.m, julian.m 
%
% quick-look for microcat calibration profiles and conversion to rodb 
%
% 10/07 scu, D324: now reads and plots ctd ctu file using pload
% 28/10/08 ZBS: modified to print combined graphs for d334
% 22/10/09 PGW: updated for D344
% 26/03/10 SCU: Added mload to import netcdf CTD 1hz file
% 27/03/10 scu/zbs, oc459: updated for oc459, copied this file from
%   mc_call_calib2_oc459.m, added a descriptive header
% 19/12/10 efw, d359: updated for d359, copied this file from
%   mc_call_caldip_oc459.m.
% clear all
% startup
% close all


% -----------------------------------------------------------------
% --- This is the information that needs to be modified for -------
% --- different users, directory trees, and moorings --------------
% ----------------------------------------------------------------

cruise = 'd382'; % used for microcat data
cruise2='di382'; % used for ctd data
cast = '11';
ctdnum = sprintf('%03d',str2num(cast));
doctd = 0; % whether to load and plot CTD data 
%doctd  = 1;

% setup paths during d359.  Currently only for running from eurus directly.
%  Basedir is set in the startup file if you start matlab while in the
%  directory /noc/users/pstar/rpdmoc/rapid/data/exec/d359
% old setup paths below
[gash,host] = unix('hostname');
%if strfind(host,'dhcp108') % being run on Brianking computer
%    rootdir = '/Users/surman/rpdmoc/'; % OC459
%else % being run on another computer, with /Volumes/surman a mounted drive
%    rootdir = '/volumes/surman/rpdmoc/'; % OC459
%end

basedir = ['/noc/users/pstar/rpdmoc/rapid/data/']; % JC064
%ctddir = ['/local/users/pstar/Data/rpdmoc/cruises/' cruise '/ctd/']; % D344
%ctddir = '/noc/users/pstar/rpdmoc/jc064/data/ctd/';
%ctddir  = [rootdir 'cruises/' cruise '/data/ctd/']; % OC459
ctddir = '/noc/users/pstar/rpdmoc/di382/data/ctd/';

% -----------------------------------------------------------------


% --- set paths for data input and output ---

inpath    = [basedir 'moor/raw/' cruise '/microcat_cal_dip/cast',cast,'/'];  
outpath   = [basedir 'moor/proc_calib/' cruise '/cal_dip/microcat/cast' cast '/'];
infofile  = [basedir 'moor/proc_calib/' cruise '/cal_dip/cast',cast,'info.dat'];
ctdinfile = [ctddir  'ctd_' cruise2 '_',ctdnum,'_psal.nc'];
ctdinfile = [ctddir  'ctd_' cruise2 '_',ctdnum,'_raw.nc'];

%addpath('/noc/users/pstar/di359/data/mexec_processing_scripts/',path);
jd0 = julian(2012,1,0,0);
% ----------------- load CTD DATA   ----------------------------------
if doctd == 1;
  m_setup; % scu JC032
%  [d h]=mload(ctdinfile,'timeJ','prDM','t090C','c0S_slash_m',' ');
 [d h]=mload(ctdinfile,'time','press','temp1','cond1',' ');
 
 HH = h.data_time_origin(4)+h.data_time_origin(5)/60+h.data_time_origin(6)/3600;
 jtime=h.data_time_origin(1:3);
 jtime=[jtime HH];
 d.timeJ=julian(jtime)+d.time/86400-jd0;
 
 % Correction for Di382
 d.cond1=d.cond1*10;  
 
 %if strmatch(cast,'2')
 %    d.timeJ=julian(jtime)+d.time/86400-jd0+datenum([0 0 0 0 10.1 0]);% temp cludge on jc064 due to mysterious ctd time offset
 %    d.cond1=d.cond1*10;
 %elseif strmatch(cast,'1')
 %    d.timeJ=julian(jtime)+d.time/86400-jd0+datenum([0 0 0 0 8.2 0]);% temp cludge on jc064 due to mysterious ctd time offset
 %    d.cond1=d.cond1*10;
 %end
  % when loading a mat-file, for D344
  % ctd_file = [ctddir 'ctd_di344_' num2str(str2num(cast),'%03d') '_1hz.mat'];
  % ctd = load(ctd_file);
  % ctd_press = ctd.press;
  % ctd_temp = ctd.temp2; % use the secondary sensor for casts 001 and 002, since it has better salinity
  % ctd_cond = (ctd.cond2)/10;
  % ctd_salin = sw_salt(ctd.cond2,ctd.temp2,ctd.press);
  % ctd_hours = hms2h(ctd.hour,ctd.minute,ctd.sec);
  % ctd_jd = julian(ctd.year,ctd.month,ctd.day,ctd_hours);
end

% --- get mooring information from infofile ---
[id,sn]= rodbload(infofile,'instrument:serialnumber');

% --- vector of serial numbers ---
ii = find(id >= 332 & id <= 337);
vec = sn(ii);

% --- initialize figures
figure(34);clf;hold on
col = 'brgkmcybrgkmcybrgkmc';
figure(35);clf;hold on
col = 'brgkmcybrgkmcybrgkmc';
figure(36);clf;hold on
col = 'brgkmcybrgkmcybrgkmc';

% --- create log file ---
%fidlog = fopen([outpath,'microcat2rodb.log'],'a');
fidlog = fopen([outpath,'microcat2rodb.log'],'w');

% --- read data loop --
for i = 1:length(vec)
  % display( [,num2str(vec(i)),])
   fprintf(fidlog,'\n\n');

   infile = [inpath,sprintf('%4.4d',vec(i)),'cal2.asc'];

   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'cal.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%3.3d',vec(i)),'cal.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'CAL.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%3.3d',vec(i)),'CAL.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,'cal',sprintf('%4.4d',vec(i)),'.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip2.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data2.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_test.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip.asc'];
   end
   if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data.asc'];
   end
      if exist(infile) ~= 2
     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data.cnv'];
   end

   outfile = [outpath, 'cast', cast ,'_',sprintf('%4.4d',vec(i)),'.raw'];
   
   % --- convert from raw to rodb format ---
 
   microcat2rodb_3(infile,outfile,infofile,fidlog,'w',0)

   % --- load rodb data ---
   [yy,mm,dd,hh,c,t,p] = rodbload(outfile,'yy:mm:dd:hh:c:t:p');
 %  if (i > 6 & i<=12)  lstr='--'; elseif i>12  lstr ='-.'; else lstr = '-'; end 
   if (i > 7 & i<=14)  lstr='--'; elseif i>14  lstr ='-.'; else lstr = '-'; end 
 
   disp(['plotting ',num2str(i),': s/n:',num2str(sn(i))])
%    pause
% correct timing errors for a number of microcats
   jd = julian(yy,mm,dd,hh)-jd0;
   
%   if(str2num(cast) == 5 & sn(i) < 6000) % for instruments set to BST in error
%       jd=jd-(1/24);
%   end
%   if(str2num(cast) == 6 & sn(i) == 5766)
%       jd=jd-(0.2309);
%   end
%   if(str2num(cast) == 10 & sn(i) == 6125)
%       jd=jd+(0.04160);
%   elseif(str2num(cast) == 10 & sn(i) == 6332)
%       jd=jd+(0.04160);
%   elseif(str2num(cast) == 10 & sn(i) == 6333)
%       jd=jd+(0.04160);
%   elseif(str2num(cast) == 10 & sn(i) == 6331)
%       jd=jd+(1);
%   end
   
   figure(34)
   plot(jd,c,[col(i),lstr]); grid on
   figure(35)
   plot(jd,t,[col(i),lstr]); grid on
   figure(36)
   plot(jd,p,[col(i),lstr]); grid on
%    plot(jd,p,[col(i),'.']);
   if doctd % interpolate CTD onto microcat for a rough and ready mean diff

     pi = interp1(d.timeJ, d.press, jd);
     ti = interp1(d.timeJ, d.temp1, jd);
     ci = interp1(d.timeJ, d.cond1, jd);
     dp = diff(pi) ;
     idp = find(dp(floor(length(dp)/2)-36:end-36) < 0.5);

     pdiff = ['mean p diff = ' num2str(nanmean(abs(p(idp) - pi(idp)))) ...
                   ' --- ' num2str(vec(i))];
     cdiff = ['mean c diff = ' num2str(nanmean(abs(c(idp) - ci(idp)))) ...
                   ' --- ' num2str(vec(i))];
     tdiff = ['mean t diff = ' num2str(nanmean(abs(t(idp) - ti(idp)))) ...
                   ' --- ' num2str(vec(i))];

     disp(pdiff)
     disp(cdiff)
     disp(tdiff)

     fprintf(fidlog,'%s \n',pdiff);
     fprintf(fidlog,'%s \n',cdiff);
     fprintf(fidlog,'%s \n',tdiff);
   end

   disp(['proceeding to next file ']) 

end % for i = 1:length(vec)

fclose(fidlog)


% --- tidy-up graphics, add CTD data ---

outfig = [outpath, 'cast', cast ,'_all'];

figure(34)
num_legend(vec(:)',[],4)
ylabel('conductivity')
xlabel('yearday (relative to 2011/1/0 00:00)')
title(['CAST ' cast ' Calibration Dip'])
if doctd
% plot(ctd_jd - jd0 ,ctd_cond*10,'k-')
%  plot(d.timeJ,d.c0S_slash_m*10.,'k-')
  plot(d.timeJ,d.cond1,'k-')
  title(['CAST ' cast  ' Calibration Dip (-k=CTD)'])
end
orient tall
print(gcf,'-depsc',[outfig '_cond.ps'])
saveas(gcf,[outfig '_cond.fig'],'fig')
%print(['-f' num2str(gcf)],[outfig '_cond.fig'])

figure(35)
num_legend(vec(:)',[],4)
ylabel('temperature')
xlabel('yearday (relative to 2011/1/0 00:00)')
title(['CAST ' cast ' Calibration Dip'])
if doctd
% plot(ctd_jd - jd0,ctd_temp,'k-')
  plot(d.timeJ,d.temp1,'k-');  
%  plot(d.timeJ,d.t090C,'k-');  
  title(['CAST ' cast ' Calibration Dip (-k=CTD)'])
  title(['CAST ' cast ' Calibration Dip (-k=CTD)'])
end
orient tall
print(gcf,'-depsc',[outfig '_temp.ps'])
saveas(gcf,[outfig '_temp.fig'],'fig')
%print(['-f' num2str(gcf)],[outfig '_temp.fig'])

figure(36)
num_legend(vec(:)',[],4)
ylabel('pressure')
xlabel('yearday (relative to 2011/1/0 00:00)')
title(['CAST ' cast ' Calibration Dip'])
if doctd
% plot(ctd_jd - jd0 ,ctd_press,'k-')
  plot(d.timeJ,d.press,'k-');    
  title(['CAST ' cast ' Calibration Dip (-k=CTD)'])
end
orient tall
print(gcf,'-depsc',[outfig '_pres.ps'])
saveas(gcf,[outfig '_pres.fig'],'fig')
%print(['-f' num2str(gcf)],[outfig '_pres.fig'])

disp(['number of MicroCATs processed = ' num2str(length(vec))])

figure(34)
%timeaxis([2008,1,0])
figure(35)
%timeaxis([2008,1,0])
figure(36)
%timeaxis([2008,1,0])




