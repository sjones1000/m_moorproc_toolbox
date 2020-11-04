% reads ascii raw data from the combined sontek argonaut and seabird MicroCAT % data and converts it to standard Rapid Data Base (RDB) format%%% uses hms2h.m%% Kanzow, 13 April 2005clear allclose allmoor     = 'wb2_1_200419';operator = 'scu';%%inpath   = ['/data/rapid/cd170/moorings/raw/arg/'];%%outpath  = ['/data/rapid/cd170/moorings/',moor,'/arg/'];%%infofile = ['/data/rapid/cd170/moorings/',moor,'/',moor,'info.dat'];inpath   = ['/Users/scu/Documents/RAPID-MOC/CD170/data/moor/raw/arg/'];outpath  = ['/Users/scu/Documents/RAPID-MOC/CD170/data/moor/proc/',moor,'/arg/'];infofile = ['/Users/scu/Documents/RAPID-MOC/CD170/data/moor/proc/',moor,'/',moor,'info.dat'];out_ext  = ['.raw'];% ----- read infofile / open logfile  ------------------------------------infovar = 'instrument:serialnumber:z:Start_Time:Start_Date:End_Time:End_Date:Latitude:Longitude:WaterDepth'; [id,sn,z,s_t,s_d,e_t,e_d,lat,lon,wd]  =  rodbload(infofile,infovar);%[id,sn,z,lat,lon]= rodbload(infofile,'instrument:serialnumber:z:latitude:longitude');combo    =  find(id == 366337);combo_sn =  sn(combo);combo_z  =  z(combo);fidlog   = fopen([outpath,'stage1_log'],'w');fprintf(fidlog,'Transformation of ascii data to rodb format \n');fprintf(fidlog,'Processing carried out by %s at %s\n\n\n',operator,datestr(clock));fprintf(fidlog,'Mooring   %s \n',moor);fprintf(fidlog,'Latitude  %6.3f \n',lat);fprintf(fidlog,'Longitude %6.3f \n\n\n',lon);bg = julian([s_d(:)' hms2h([s_t(:)' 0])]); %started = julian([e_d(:)' hms2h([e_t(:)' 0])]); %endfor instr = 1 : length(combo)  indep  = combo_z(instr);  index  = find(z== indep & id == 337);   serial_mc  = sn(index);  index      = find(z== indep & id == 366);   serial_arg = sn(index);  % -------- load data --------------  infile  = [inpath,'WB2',sprintf('%3.3d',combo_sn(instr)),'001.dat'];  outfile = [outpath,moor,'_',sprintf('%4.4d',combo_sn(instr)),out_ext];  fprintf(fidlog,'infile : %s\n',infile);  fprintf(fidlog,'outfile: %s\n',outfile);  fprintf(fidlog,'Serial number  : %d\n',combo_sn(instr));  fprintf(fidlog,'MicroCAT number: %d\n',serial_mc);  fprintf(fidlog,'Argonaut number: %d\n',serial_arg);     fid = fopen(infile,'r');  zeile = fscanf(fid,'%c');  fclose(fid);  ret = sprintf('\n');  retx = findstr(zeile,ret);  % car. return indices  % convert string to numbers  data      = str2num(zeile(retx(1)+1:end));  dat       = [data(:,[1:3]) hms2h(data(:,4:6))];  jd        = julian(dat);  valI      = find(jd<ed & jd>bg);  uvw       = data(:,7:9);  uvw_sd    = data(:,10:12); % signal standard deviation  uvw_snr   =  data(:,13:15); %?  uvw_ss    = data(:,16:18); % signal strength  uvw_noise = data(:,19:21); % signal strength   pgp     =  data(:,22);  hpr     = data(:,23:25); %heading pitch roll  hpr_sd  = data(:,26:28); %heading pitch roll stand. dev.  t     = data(:,29);  p     = data(:,30);  p_sd  = data(:,31);  volt  = data(:,32);  cell  = data(:,33:34);  vel   = data(:,35);  dir   = data(:,36);  t_mc  = data(:,37);  c_mc  = data(:,38);  p_mc  = data(:,39);% ----- save data to rdb -----------------columns = 'YY:MM:DD:HH:T:TCAT:P:PCAT:C:U:V:W:HDG:PIT:ROL:USD:VSD:WSD:USS:VSS:WSS:HDGSD:PITSD:ROLSD:IPOW';  data = [dat t t_mc p p_mc c_mc*10 uvw hpr uvw_sd  uvw_ss hpr_sd volt];   fort =['%4.4d %2.2d %2.2d  %6.4f    %7.4f %7.4f %6.2f %6.2f %7.4f   %6.2f %6.2f %6.2f   %4.1f %4.1f %4.1f   %6.2f %6.2f %6.2f   %3.3d %3.3d %3.3d   %4.1f %4.1f %4.1f   %4.2f'];infovar = ['Mooring:Start_Time:Start_Date:End_Time:End_Date:Latitude:Longitude:WaterDepth:' ...           'Columns:SerialNumber:InstrDepth:MicrocatSN:ArgonautSN']; rodbsave(outfile,infovar,fort,...	 moor,s_t,s_d,e_t,e_d,lat,lon,wd,columns,combo_sn(instr),indep,...         serial_mc,serial_arg,...     data);% -------- generate logfile entries --------------sz   =   size(data);fprintf(fidlog,'Instrument Target Depth[m]  : %d\n',indep);fprintf(fidlog,'Start date and time         : %s \n',datestr(gregorian(jd(1))));fprintf(fidlog,'End date and time           :   %s \n',datestr(gregorian(jd(end))));sampling_rate = round(1./median(diff(jd)));ex_samples = round((jd(end)-jd(1))*sampling_rate+1);fprintf(fidlog,'Sampling Frequency [per day]: %d \n',sampling_rate);fprintf(fidlog,'Number of samples           : %d; expected: %d \n',sz(1),ex_samples);m_uvw = median(uvw(valI,:));m_uvwsd = median(uvw_sd(valI,:));m_uvwss = median(uvw_ss(valI,:));m_uvwsnr = median(uvw_snr(valI,:));m_uvwnoise = median(uvw_noise(valI,:));m_pgp = median(pgp(valI));m_hpr = median(hpr(valI,:));m_hprsd = median(hpr_sd(valI,:));m_t = median([t(valI) t_mc(valI)]);m_p = median([p(valI) p_mc(valI)]);m_psd = median(p_sd(valI));m_volt = median(volt(valI));m_vel = median(vel(valI));m_dir = median(dir(valI));m_c = median(c_mc(valI)*10);fprintf(fidlog,'Median temperature Argonaut/Microcat [deg C]: %5.2f / %5.2f\n',m_t);fprintf(fidlog,'Median MicroCAT conductivity [mS/cm]        : %5.2f\n',m_c);fprintf(fidlog,'Median pressure Argonaut/Microcat [dbar]    : %6.2f / %6.2f\n',m_p);fprintf(fidlog,'Median velocity u / v / w [cm/s]            : %4.1f  %4.1f  %4.1f\n',m_uvw);fprintf(fidlog,'Median heading / pitch / roll [deg]         : %4.1f  %4.1f  %4.1f\n',m_hpr);fprintf(fidlog,'Median velocity STD u / v / w [cm/s]                : %4.1f  %4.1f  %4.1f\n',m_uvwsd);fprintf(fidlog,'Median velocity signal strength u / v / w [count]   : %3.3d  %3.3d  %3.3d\n',m_uvwss);fprintf(fidlog,'Median velocity signal to noise ratio u / v / w [??]: %4.1f  %4.1f  %4.1f\n',m_uvwsnr);fprintf(fidlog,'Median velocity noise  u / v / w [??]               : %4.1f  %4.1f  %4.1f\n',m_uvwnoise);fprintf(fidlog,'Median percent good pings                           : %4.1f \n',m_pgp);fprintf(fidlog,'Median heading / pitch / roll STD [deg]             : %4.1f  %4.1f  %4.1f\n',m_hprsd);fprintf(fidlog,'Median power input level [V]                        : %4.1f\n\n\n',m_volt);end  % instr loop