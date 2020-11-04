% MC_CALL_CALDIP_OC459 is a script that performs stage1 processing% on microcat data from CTD calibration casts (caldips).  It% converts microcat data from raw to rodb format for an entire% caldip, and plots it with CTD data.%% It calls microcat2rodb_3 (to convert microcat_data), rodbload.m,% timeaxis.m, auto_filt.m, julian.m % OC459 clear allclose all% -----------------------------------------------------------------% --- This is the information that needs to be modified for -------% --- different users, directory trees, and moorings --------------% -----------------------------------------------------------------cruise = 'oc459';cast = '6';ctdnum = sprintf('%03d',str2num(cast));doctd = 0   ; % whether to load and plot CTD data % setup paths during oc459, based on which computer is running matlab% on my macrootdir = '/Users/scu/documents/cruises/oc459/data/OC459_data/'basedir = [rootdir 'rapid/data/']; % OC459%ctddir = ['/local/users/pstar/Data/rpdmoc/cruises/' cruise '/ctd/']; % D344ctddir  = [rootdir 'cruises/' cruise '/data/ctd/']; % OC459% -----------------------------------------------------------------% --- set paths for data input and output ---inpath    = [basedir 'moor/raw/' cruise '/microcat_cal_dip/cast',cast,'/'];  outpath   = [basedir 'moor/proc_calib/' cruise '/cal_dip/microcat/cast' cast '/'];infofile  = [basedir 'moor/proc_calib/' cruise '/cal_dip/cast',cast,'info.dat'];ctdinfile = [ctddir  'ctd_',cruise,'_',ctdnum,'_raw.nc'];% ----------------- load CTD DATA   ----------------------------------if doctd;  m_setup; % scu OC459  [d h]=mload(ctdinfile,'timeJ','prDM','t090C','c0S_slash_m',' ');  % when loading a mat-file, for D344  % ctd_file = [ctddir 'ctd_di344_' num2str(str2num(cast),'%03d') '_1hz.mat'];  % ctd = load(ctd_file);  % ctd_press = ctd.press;  % ctd_temp = ctd.temp2; % use the secondary sensor for casts 001 and 002, since it has better salinity  % ctd_cond = (ctd.cond2)/10;  % ctd_salin = sw_salt(ctd.cond2,ctd.temp2,ctd.press);  % ctd_hours = hms2h(ctd.hour,ctd.minute,ctd.sec);  % ctd_jd = julian(ctd.year,ctd.month,ctd.day,ctd_hours);end% --- get mooring information from infofile ---[id,sn]= rodbload(infofile,'instrument:serialnumber');% --- vector of serial numbers ---ii = find(id >= 332 & id <= 337);vec = sn(ii);% --- initialize figuresfigure(34);clf;hold oncol = 'brgkmcybrgkmcybrgkmc';figure(35);clf;hold oncol = 'brgkmcybrgkmcybrgkmc';figure(36);clf;hold oncol = 'brgkmcybrgkmcybrgkmc';% --- create log file ---%fidlog = fopen([outpath,'microcat2rodb.log'],'a');fidlog = fopen([outpath,'microcat2rodb.log'],'w');% --- read data loop --% for i = 1:length(vec)for i = [1,5,6]; % 3932 K , 6829 P, 3247 D  % display( [,num2str(vec(i)),])   fprintf(fidlog,'\n\n');   infile = [inpath,sprintf('%4.4d',vec(i)),'cal2.asc'];   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'cal.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%3.3d',vec(i)),'cal.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'CAL.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%3.3d',vec(i)),'CAL.asc'];   end   if exist(infile) ~= 2     infile = [inpath,'cal',sprintf('%4.4d',vec(i)),'.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip2.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data2.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_test.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip.asc'];   end   if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data.asc'];   end      if exist(infile) ~= 2     infile = [inpath,sprintf('%4.4d',vec(i)),'_cal_dip_data.cnv'];   end    outfile = [outpath, 'cast', cast ,'_',sprintf('%4.4d',vec(i)),'.raw'];   %    % --- convert from raw to rodb format ---%    microcat2rodb_3(infile,outfile,infofile,fidlog,'w',0)   % --- load rodb data ---   [yy,mm,dd,hh,c,t,p] = rodbload(outfile,'yy:mm:dd:hh:c:t:p');   if (i > 7 & i<=14)  lstr='--'; elseif i>14  lstr ='-.'; else lstr = '-'; end       jd0 = julian(2010,1,0,0);   jd = julian(yy,mm,dd,hh)-jd0;   figure(34)   plot(jd,c,[col(i),lstr]); grid on   figure(35)   plot(jd,t,[col(i),lstr]); grid on   figure(36)   plot(jd,p,[col(i),lstr]); grid on      if doctd % interpolate CTD onto microcat for a rough and ready mean diff     pi = interp1(d.timeJ, d.prDM, jd);     ti = interp1(d.timeJ, d.t090C, jd);     ci = interp1(d.timeJ, d.c0S_slash_m*10., jd);     dp = diff(pi) ;     idp = find(dp(floor(length(dp)/2)-36:end-36) < 0.5);     pdiff = ['mean p diff = ' num2str(nanmean(abs(p(idp) - pi(idp)))) ...                   ' --- ' num2str(vec(i))];     cdiff = ['mean c diff = ' num2str(nanmean(abs(c(idp) - ci(idp)))) ...                   ' --- ' num2str(vec(i))];     tdiff = ['mean t diff = ' num2str(nanmean(abs(t(idp) - ti(idp)))) ...                   ' --- ' num2str(vec(i))];     disp(pdiff)     disp(cdiff)     disp(tdiff)     fprintf(fidlog,'%s \n',pdiff);     fprintf(fidlog,'%s \n',cdiff);     fprintf(fidlog,'%s \n',tdiff);   end   disp(['proceeding to next file ']) end % for i = 1:length(vec)fclose(fidlog)% --- tidy-up graphics, add CTD data ---outfig = [outpath, 'cast', cast ,'_all'];figure(34)num_legend(vec(:)',[],4)ylabel('conductivity')xlabel('yearday (relative to 2008/1/0 00:00)')title(['CAST ' cast ' Calibration Dip'])if doctd% plot(ctd_jd - jd0 ,ctd_cond*10,'k-')  plot(d.timeJ,d.c0S_slash_m*10.,'k-')  title(['CAST ' cast  ' Calibration Dip (-k=CTD)'])endorient tallprint(gcf,'-depsc',[outfig '_cond.ps'])saveas(gcf,[outfig '_cond.fig'],'fig')%print(['-f' num2str(gcf)],[outfig '_cond.fig'])figure(35)num_legend(vec(:)',[],4)ylabel('temperature')xlabel('yearday (relative to 2008/1/0 00:00)')title(['CAST ' cast ' Calibration Dip'])if doctd% plot(ctd_jd - jd0,ctd_temp,'k-')  plot(d.timeJ,d.t090C,'k-');    title(['CAST ' cast ' Calibration Dip (-k=CTD)'])endorient tallprint(gcf,'-depsc',[outfig '_temp.ps'])saveas(gcf,[outfig '_temp.fig'],'fig')%print(['-f' num2str(gcf)],[outfig '_temp.fig'])figure(36)num_legend(vec(:)',[],4)ylabel('pressure')xlabel('yearday (relative to 2008/1/0 00:00)')title(['CAST ' cast ' Calibration Dip'])if doctd% plot(ctd_jd - jd0 ,ctd_press,'k-')  plot(d.timeJ,d.prDM,'k-');      title(['CAST ' cast ' Calibration Dip (-k=CTD)'])endorient tallprint(gcf,'-depsc',[outfig '_pres.ps'])saveas(gcf,[outfig '_pres.fig'],'fig')%print(['-f' num2str(gcf)],[outfig '_pres.fig'])disp(['number of MicroCATs processed = ' num2str(length(vec))])figure(34)%timeaxis([2008,1,0])figure(35)%timeaxis([2008,1,0])figure(36)%timeaxis([2008,1,0])