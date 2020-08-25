% Idronaut Data Conversion Routine% Written by Darren Rayner% CHANGES:-% INPUTS:- infile - idronaut ascci data file%          outfile - output rodb file%          infofile - mooring info file%          log - filename of log file% Uses the following functions:-% hms2h.m% rodbload.m% rodbsave.m% julian.m% timeaxis.mfunction idronaut2rodb(infile,outfile,infofile,log);if nargin~=4    infile = input('Please enter name and full path of input idronaut ascii file:','s')    outfile= input('Please enter name and full path of output rodb file:','s')    infofile= input('Please enter name and full path of mooring info file:','s')    log= input('Please enter name and full path of log file:','s')endplot_interval = [2004 02 01 00;   % start time of time axis on plot		 2005 05 01 00];  % end time of time axis on plotInstrument = 'IDRONAUT';           % Instr. info for rodb headercols       = 'YY:MM:DD:HH:T:C:P';    % column info for rodb headerfort       = '%4.4d  %2.2d  %2.2d  %7.5f   %5.3f  %5.3f  %6.2f  '; %data output format% check if infile and infofile existif exist(infofile) ~= 2   disp(['infofile:  ',infofile,' does not exist'])   returnendif exist(infile) ~= 2   disp(['infile:  ',infile,' does not exist'])   returnendif exist(outfile) == 2   disp(['oufile:  ',outfile,' alredy exists!!'])     overwrite =  input('Overwrite y/n  ','s');    if overwrite ~='y'     disp('data conversion stop')     return   endendfid_log=fopen(log,'a')  % opens log file for appending tofid = fopen(infile,'r');if fid == -1   disp(['unable to open infile:  ',infile])   returnelse  disp(['loading ',infile]);end % START READING ASCII DATA FILE% =============================================% START OF IGNORING CHARACTERS AT START OF FILEcheck=1;while check==1   % Scrolls through file until finds first header line    dataline=fgetl(fid);    linecheck=findstr('  Press   Temp    Cond    Sal   ',dataline);    check=isempty(linecheck);endcheck=1; % resets check variablei=1;while check==1    dataline=fgetl(fid);    linecheck2=findstr('<any key>',dataline);    if isempty(linecheck2);        linecheck=findstr('.',dataline); % checks line has a . in it so can differentiate from header lines        if ~isempty(linecheck)            pressure(i,:)=dataline(1:7);            temperature(i,:)=dataline(10:15);            conductivity(i,:)=dataline(18:23);            salinity(i,:)=dataline(26:31);            time(i,:)=dataline(33:40);            date(i,:)=[dataline(45:46),'-',dataline(42:43),'-',dataline(48:51)];            date_time(i,:)=[date(i,:),' ',time(i,:)];            %data(i,:)=dataline;            i=i+1;        end    else        check=0;    endendpressure=pressure(1:i-1,:); % removes extra line at end of datatemperature=temperature(1:i-1,:); % removes extra line at end of dataconductivity=conductivity(1:i-1,:); % removes extra line at end of datasalinity=salinity(1:i-1,:); % removes extra line at end of datatime=time(1:i-1,:); % removes extra line at end of datadate=date(1:i-1,:); % removes extra line at end of datadate_time=date_time(1:i-1,:); % removes extra line at end of datanum_samples=size(pressure);num_samples=num_samples(1);date_time=datestr(date_time,'dd/mm/yyyy HH:MM:SS');start_date=date(1,:);start_time=time(1,:);if str2num(date(1,1:2))<str2num(date(2,1:2))    sample_interval=[num2str(str2num(time(2,1:2))-str2num(time(1,1:2))),':',num2str(str2num(time(2,4:5))-str2num(time(1,4:5))),':',num2str(str2num(time(2,7:8))-str2num(time(1,7:8)))];else    sample_interval=[num2str(str2num(time(3,1:2))-str2num(time(2,1:2)),'%02d'),':',num2str(str2num(time(3,4:5))-str2num(time(2,4:5)),'%02d'),':',num2str(str2num(time(3,7:8))-str2num(time(2,7:8)),'%02d')];endsample_interval%---------------------------------------------------------------% get missing header variables from info.dat file%---------------------------------------------------------------infovar ='Mooring:Latitude:Longitude:Waterdepth:id:serialnumber:z:StartDate:StartTime:EndDate:EndTime'; [mo,la,lo,wd,id,sn,z,sdate,stime,edate,etime]=rodbload(infofile,infovar); if isempty(id) | isnan(id)  infovar ='Mooring:Latitude:Longitude:Waterdepth:instrument:serialnumber:z:StartDate:StartTime:EndDate:EndTime';   [mo,la,lo,wd,id,sn,z,sdate,stime,edate,etime]=rodbload(infofile,infovar); endif iscell(mo)  mo = deal(mo{:}); % convert cell arrayendserial_number=input('Please enter instrument serial number e.g. 1103034 :- ')ii = find(serial_number == sn);z  = z(ii);         % instrument depth% END OF DATA READ IN PART% =================================================% Start of Writing info to log file[gash, operator]=system('whoami');  % This line will not work if run from a PC. May need to edit it out.if strfind(operator,'pstar')    operator=input('Please enter operator name:- ','s')endfprintf(fid_log,'Transformation of Idronaut ascii data to rodb format \n');fprintf(fid_log,'Processing carried out by %s at %s\n\n\n',operator,datestr(clock));fprintf(fid_log,'Mooring   %s \n',mo);fprintf(fid_log,'Latitude  %6.3f \n',la);fprintf(fid_log,'Longitude %6.3f \n',lo);fprintf(fid_log,'Infile: %s\n',infile);fprintf(fid_log,'Outfile: %s\n',outfile);fprintf(fid_log,'Serial Number: %7d \n',serial_number);fprintf(fid_log,'Start Date: %s/%s/%s\n',start_date(4:5),start_date(1:2),start_date(7:10));fprintf(fid_log,'Start Time: %s\n',start_time);fprintf(fid_log,'Sampling Interval (minutes): %s\n',sample_interval);fprintf(fid_log,'Number of Samples: %d\n',num_samples);comment = input('Enter additional comment to be saved in Log file: -\n','s'); if ~isempty(comment)  fprintf(fid_log,'\n COMMENT:\n %s',comment)end% End of writing info to log file% =================================================% START OF DATE CONVERSIONday_=str2num(date_time(1:num_samples,1:2));month_=str2num(date_time(1:num_samples,4:5));year_=str2num(date_time(1:num_samples,7:10));hour_=hms2h(str2num(date_time(1:num_samples,12:13)),str2num(date_time(1:num_samples,15:16)),str2num(date_time(1:num_samples,18:19)));% hms2h is a function written by Torsten Kanzow% END OF DATE CONVERSION% ==============================================% START OF SAVE TO RODB FORMATdisp(['writing data to ',outfile]) data = [year_ month_ day_ hour_ str2num(temperature) str2num(conductivity) str2num(pressure)]; rodbsave(outfile,...       'Latitude:Longitude:Columns:SerialNumber:Mooring:WaterDepth:Instrdepth:StartDate:StartTime:EndDate:EndTime',...         fort,...         la,lo,cols,serial_number,mo,wd,z,sdate,stime,edate,etime,...         data);     fclose('all');% END OF RODB SAVE% ==============================================% START OF GRAPHICS jd = julian(year_,month_,day_,hour_);if z==0    z=' CTD cast ';    plot_interval = [year_(1) month_(1) day_(1) floor(hour_(1));   % start time of time axis on plot		 year_(num_samples) month_(num_samples) day_(num_samples) ceil(hour_(num_samples))];  % end time of time axis on plotelse    z=num2str(z);endjd1 = julian(plot_interval(1,:));jd2 = julian(plot_interval(2,:));figure(1);clfsubplot(3,1,1); plot(jd-jd1,str2num(temperature))title(['Idronaut s/n: ',num2str(serial_number), ...                '; Target Depth: ',z])ylabel('Temperature [deg C]')grid onif z~=0    xlim([0 jd2-jd1])    timeaxis(plot_interval(1,1:3));   end    subplot(3,1,2)plot(jd-jd1,str2num(conductivity))ylabel('Conductivity [mS/cm]')grid onif z~=0    xlim([0 jd2-jd1])    timeaxis(plot_interval(1,1:3));   endsubplot(3,1,3);plot(jd-jd1,str2num(pressure))ylabel('Pressure [dbar]')grid on if z~=0    xlim([0 jd2-jd1])    timeaxis(plot_interval(1,1:3));   endeval(['print -dps ',outfile,'.ps']) 