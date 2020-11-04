% S4 data conversion routine!% this routine should hopefully be able to deal with any ascii format that the S4 outputs% starting with the .S4A extension and including whether or not it has Special Record Blocks% and whatever analogue channels are recorded at each sample.% Due to the problems with converting .S4B files using the S4 processing software it was decided% that it would be best to download in ascii format (hex values) and use Matlab to do the conversions.%% Written by Darren Rayner% Written to only work with serial numbers that start with 35 as this covers the ones we have% in the Rapid 26.5N mooring array.% CHANGES:-    % 11/01/2006 - fixed bug with SRB_interval. previous version never    % followed "No SRB" route in code. DR.    % 12/01/2006 - fixed bug with using continuous operation (e.g. CTD    % calibration dips). Previous version could not handle on time being    % "00 FF 00". DR.    % 12/01/2006 - fixed bug with channels not being calculated correctly    % when using less than 5. DR.% INPUTS:- infile - s4 ascci data file%          outfile - output rodb file%          infofile - mooring info file%          log - filename of log file% Uses the following functions:-% hms2h.m% month_convert.m% rodbload.m% rodbsave.mfunction s42rodb(infile,outfile,infofile,log,channels,SRBchannels);if nargin==5 % does nothingelseif nargin==4 % does nothingelseif nargin==6 % does nothingelse    infile = input('Please enter name and full path of input S4 ascii file:','s')    outfile= input('Please enter name and full path of output rodb file:','s')    infofile= input('Please enter name and full path of mooring info file:','s')    log= input('Please enter name and full path of log file:','s')endaddpath /data/jrd/hydro10/rapid/data/exec/moor/rodb;addpath /data/jrd/hydro10/rapid/data/exec/moor/tools;Instrument = 'S4';           % Instr. info for rodb headercols5       = 'YY:MM:DD:HH:U:V:T:C:P:HDG';    % column info for rodb headerfort5       = '%4.4d  %2.2d  %2.2d  %7.5f   %7.4f  %7.4f  %6.4f  %6.4f  %6.4f  %4.1f'; %data output formatcols3       = 'YY:MM:DD:HH:U:V:T:C:P';    % column info for rodb headerfort3       = '%4.4d  %2.2d  %2.2d  %7.5f   %7.4f  %7.4f  %6.4f  %6.4f  %6.4f'; %data output format% cols5 and fort5 are for when Hx and Hy are recorded (5 channels total)% cols3 and fort3 are for when Hx and Hy are not recorded (3 channels total)% check if infile and infofile existif exist(infofile) ~= 2   disp(['infofile:  ',infofile,' does not exist'])   returnendif exist(infile) ~= 2   disp(['infile:  ',infile,' does not exist'])   returnendif exist(outfile) == 2   disp(['oufile:  ',outfile,' alredy exists!!'])     overwrite =  input('Overwrite y/n  ','s');    if overwrite ~='y'     disp('data conversion stop')     return   endendfid_log=fopen(log,'a')  % opens log file for appending tofid = fopen(infile,'r');if fid == -1   disp(['unable to open infile:  ',infile])   returnelse  disp(['loading ',infile]);end % =============================================% START OF IGNORING CHARACTERS AT START OF FILEstring='aaaaaa';check=sum(string~='35 61 '); % checks each character in string to see if it matcheswhile check>0    string(1)=fscanf(fid,'%c',1);   % reads in 6 characters individually    string(2)=fscanf(fid,'%c',1);   % into string (1:6) until string matches    string(3)=fscanf(fid,'%c',1);   % '35 61 ' which is the start of the header line    string(4)=fscanf(fid,'%c',1);   % for the instrument serial numbers we have    string(5)=fscanf(fid,'%c',1);    string(6)=fscanf(fid,'%c',1);    string(1:6);    check=sum(string~='35 61 ');    % if check = 0 then no characters do not equal each other                                    % i.e. string =='35 61 '    fseek(fid,-5,'cof');            % scrolls back 5 characters in file and starts loop again                                    % this should allow any number of random characters                                    % before the actual header line to be skipped.endfseek(fid,-1,'cof');     % scrolls back one more character once while loop has finished% END OF IGNORING CHARACTERS AT START OF FILE% ===========================================% START OF READING HEADER INFOserial_number='aaaaaaaa';gash='a';header='aaaaaaaaaaaaaaa';on_time='aa:aa:aa';sample_interval='aa:aa:aa';average_interval='aaaa'; % averaging interval is in half seconds so 1 implies no averagingchannels_at_average='aa'; % number of channels recorded in a normal sampleSRB_interval='aa'; % Special record block interval. as multiple of average_interval                   % e.g. 10 = one SRB every 10 normal records.start_date='aa/aa/aa'; % in dd/mm/yy formatstart_time='aa:aa';serial_number(1:2)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);serial_number(3:4)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);serial_number(5:6)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);serial_number(7:8)=fscanf(fid,'%c',2);  % end of reading in serial numbergash=fscanf(fid,'%c',1);header=fscanf(fid,'%c',15);             % all of header text read ingash=fscanf(fid,'%c',1);on_time(1:2)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);on_time(4:5)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);on_time(7:8)=fscanf(fid,'%c',2);        % end of reading in on_timegash=fscanf(fid,'%c',1);sample_interval(1:2)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);sample_interval(4:5)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);sample_interval(7:8)=fscanf(fid,'%c',2);  % end of reading in sample_intervalgash=fscanf(fid,'%c',1);average_interval(1:2)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',1);average_interval(3:4)=fscanf(fid,'%c',2); % end of reading in averaging intervalgash=fscanf(fid,'%c',1);                 channels_at_average(1:2)=fscanf(fid,'%c',2); % end of reading in channels_at_averagegash=fscanf(fid,'%c',1);SRB_interval(1:2)=fscanf(fid,'%c',2); % end of reading in SRB intervalgash=fscanf(fid,'%c',4); % not interested in Data Block Formatchannels_at_SRB(1:2)=fscanf(fid,'%c',2);gash=fscanf(fid,'%c',58); % not interested in anything up till Start Datestart_date(4:5)=fscanf(fid,'%c',2); % MM part of dategash=fscanf(fid,'%c',1);start_date(1:2)=fscanf(fid,'%c',2); % DD part of dategash=fscanf(fid,'%c',1);start_date(7:8)=fscanf(fid,'%c',2); % YY part of dategash=fscanf(fid,'%c',1);start_time(1:2)=fscanf(fid,'%c',2); % hh part of timegash=fscanf(fid,'%c',1);start_time(4:5)=fscanf(fid,'%c',2); % mm part of time% END OF READING HEADER INFO% ===============================================% START OF READING IN DATA% hex2dec conversions now occur in the loop whilst reading in the data so this is pretty slow going.gash=fscanf(fid,'%c',3);    % scroll forward three to start of data section.north = (zeros(2500000,1))';a=find(north==0);north(a)=NaN;east = north;analogue1=north;analogue2=north;analogue3=north;analogue4=north;analogue5=north;date_time=(blanks(2500000))';%check=1;start_ss=0;start_yyyy=['20',start_date(7:8)];N=datenum(str2num(start_yyyy),str2num(start_date(4:5)),str2num(start_date(1:2)),str2num(start_time(1:2)),str2num(start_time(4:5)),start_ss);average_interval=hex2dec(average_interval);sample_interval=str2num(sample_interval(7:8))+60*str2num(sample_interval(4:5))+60*24*str2num(sample_interval(1:2));on_time2=str2num(on_time(7:8))+60*str2num(on_time(4:5))+60*str2num(on_time(1:2));SRB_interval2=hex2dec(SRB_interval);if nargin==5   % does nothingelseif nargin==6   % does nothingelse    channels=input('How many channels are recorded with each average interval?\n');endchars_per_sample=7+channels*5;blank_locators=[7 12 17 22 27 32];i=1;j=0;k=0;n=1;format_errors=0;if SRB_interval=='00'  % no Special Record Blocks    disp('Followed "No SRB" route')    SRB_interval    while check==0 % while loop will stop when finds end of file ('eof')        a=1;        for a=1:(chars_per_sample)            check=fseek(fid,+1,'cof'); % scrolls forward characters singularly            a=a+1;                        % to check for end of file        end                                     if check==0        fseek(fid,-(chars_per_sample),'cof'); % rewinds if eof not found        sample=fscanf(fid,'%c',chars_per_sample);        if sample(blank_locators(1:channels+1))==' '            % checks for formatting errors - if all equal ' ' then no errors.            north(i)=hex2dec(sample(1:3));            east(i)=hex2dec(sample(4:6));                        if channels==1                analogue1(i)=hex2dec(sample(8:11));            elseif channels==2                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));            elseif channels==3                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));            elseif channels==4                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));                analogue4(i)=hex2dec(sample(23:26));            elseif channels==5                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));                analogue4(i)=hex2dec(sample(23:26));                analogue5(i)=hex2dec(sample(28:31));            end        else  % Below is what happens when have a format error            disp('format error')            format_errors=format_errors+1;  % keeps count of number of format errors found            fseek(fid,-(chars_per_sample-1),'cof');  % rewinds to start of where formatting went bad            check2=sum(sample(blank_locators(1:channels+1))==' ');            while check2<channels+1                sample=fscanf(fid,'%c',chars_per_sample); % scans in next sample and checks for errors                check2=sum(sample(blank_locators(1:channels+1))==' ');                if check2==channels+1                    continue                else                    fseek(fid,-(chars_per_sample-1),'cof');   % if still error, rewinds back to character                                                          % one after start of last scan and tries again                end            end            % following lines of code are duplicated from above            north(i)=hex2dec(sample(1:3));            east(i)=hex2dec(sample(4:6));                        if channels==1                analogue1(i)=hex2dec(sample(8:11));            elseif channels==2                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));            elseif channels==3                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));            elseif channels==4                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));                analogue4(i)=hex2dec(sample(23:26));            elseif channels==5                analogue1(i)=hex2dec(sample(8:11));                analogue2(i)=hex2dec(sample(13:16));                analogue3(i)=hex2dec(sample(18:21));                analogue4(i)=hex2dec(sample(23:26));                analogue5(i)=hex2dec(sample(28:31));            end            % duplicated up to here.        end         %calculate time stamps in same loop to save processing time        date_time(i,1:20)=datestr(N,0);        if j==239            j=-1;            N=N+28/60/24+0.5/60/60/24;        else            N=N+0.5/60/60/24;        end        j=j+1;        if i/1000-floor(i/1000)==0            i        end        i=i+1;     else        continue      end    end    num_samples=i-1;else   if nargin==6       % does nothing   else       SRBchannels=input('Please enter number of channels recorded at SRB\n');   end   SRB_chars=12+SRBchannels*5;   i=0;   s=1;   disp('Followed SRB route');   SRB_interval         while feof(fid)==0 % while loop will stop when finds end of file ('eof')       string=fgetl(fid);       size_string=size(string);       if isempty(string)           continue       elseif size_string(2)==SRB_chars           continue   % currently just ignoring special record blocks but may nee to be                       % checked if have problems with timings of records.       else           j=0;           samples_on_line=floor(size_string(2)/chars_per_sample);           while j<samples_on_line;  % NB - CURENTLY NO FORMAT CHECKING OF THIS TYPE OF FILE                                     % WILL WRITE IT IN WHEN FIND NEED IT.               north(i+1+j)=hex2dec(string(((chars_per_sample*j)+1):(3+(j*chars_per_sample))));               east(i+1+j)=hex2dec(string(((chars_per_sample*j)+4):(6+(j*chars_per_sample))));               if channels==1                   analogue1(i+1+j)=hex2dec(string(((chars_per_sample*j)+8):(11+(j*chars_per_sample))));               elseif channels==2                   analogue1(i+1+j)=hex2dec(string(((chars_per_sample*j)+8):(11+(j*chars_per_sample))));                   analogue2(i+1+j)=hex2dec(string(((chars_per_sample*j)+13):(16+(j*chars_per_sample))));               elseif channels==3                   analogue1(i+1+j)=hex2dec(string(((chars_per_sample*j)+8):(11+(j*chars_per_sample))));                   analogue2(i+1+j)=hex2dec(string(((chars_per_sample*j)+13):(16+(j*chars_per_sample))));                   analogue3(i+1+j)=hex2dec(string(((chars_per_sample*j)+18):(21+(j*chars_per_sample))));               elseif channels==4                   analogue1(i+1+j)=hex2dec(string(((chars_per_sample*j)+8):(11+(j*chars_per_sample))));                   analogue2(i+1+j)=hex2dec(string(((chars_per_sample*j)+13):(16+(j*chars_per_sample))));                   analogue3(i+1+j)=hex2dec(string(((chars_per_sample*j)+18):(21+(j*chars_per_sample))));                   analogue4(i+1+j)=hex2dec(string(((chars_per_sample*j)+23):(26+(j*chars_per_sample))));               elseif channels==5                   analogue1(i+1+j)=hex2dec(string(((chars_per_sample*j)+8):(11+(j*chars_per_sample))));                   analogue2(i+1+j)=hex2dec(string(((chars_per_sample*j)+13):(16+(j*chars_per_sample))));                   analogue3(i+1+j)=hex2dec(string(((chars_per_sample*j)+18):(21+(j*chars_per_sample))));                   analogue4(i+1+j)=hex2dec(string(((chars_per_sample*j)+23):(26+(j*chars_per_sample))));                   analogue5(i+1+j)=hex2dec(string(((chars_per_sample*j)+28):(31+(j*chars_per_sample))));               end               %calculate time stamps in same loop to save processing time               if on_time2*120==average_interval  % on_time2 is in minutes                for n=1:samples_on_line                    date_time(s,1:20)=datestr(N,0);                    N=N+sample_interval/60/24;                    s=s+1;                end               elseif on_time(4:5) == 'FF'   % on_time is read directly from data file.                                             % If operating in continuous mode                                             % on_time will be "00 FF 00"                for n=1:samples_on_line                    date_time(s,1:20)=datestr(N,0);                    N=N+average_interval/2/60/60/24;   % average_interval/2 gives seconds.                                                       % values depends on number of channels                    s=s+1;                end               else disp('Averaging interval does not equal on time')                   disp('and S4 is not in continuous mode.')                   disp('The s42rodb code needs to be modified to process this file')                   return               end               j=j+1;           end           i=i+samples_on_line;                  end   end   num_samples=i;end%---------------------------------------------------------------% get missing header variables from info.dat file%---------------------------------------------------------------infovar ='Mooring:Latitude:Longitude:Waterdepth:id:serialnumber:z:StartDate:StartTime:EndDate:EndTime'; [mo,la,lo,wd,id,sn,z,sdate,stime,edate,etime]=rodbload(infofile,infovar); if isempty(id) | isnan(id)  infovar ='Mooring:Latitude:Longitude:Waterdepth:instrument:serialnumber:z:StartDate:StartTime:EndDate:EndTime';   [mo,la,lo,wd,id,sn,z,sdate,stime,edate,etime]=rodbload(infofile,infovar); endif iscell(mo)  mo = deal(mo{:}); % convert cell arrayendii = find(str2num(serial_number) == sn);z  = z(ii);         % instrument depth% END OF DATA READ IN PART% =================================================% Start of Writing info to log file[gash, operator]=system('whoami');  % This line will not work if run from a PC. May need to edit it out.fprintf(fid_log,'Transformation of S4 ascii data to rodb format \n');fprintf(fid_log,'Processing carried out by %s at %s\n\n\n',operator,datestr(clock));fprintf(fid_log,'Mooring   %s \n',mo);fprintf(fid_log,'Latitude  %6.3f \n',la);fprintf(fid_log,'Longitude %6.3f \n',lo);fprintf(fid_log,'Infile: %s\n',infile);fprintf(fid_log,'Outfile: %s\n',outfile);fprintf(fid_log,'Serial Number: %s\n',serial_number);fprintf(fid_log,'Start Date: %s\n',start_date);fprintf(fid_log,'Start Time: %s\n',start_time);fprintf(fid_log,'Sampling Interval (minutes): %d\n',sample_interval);fprintf(fid_log,'On Time (minutes): %d\n',on_time2);fprintf(fid_log,'Number of 2Hz Samples Averaged Per Record: %d\n',average_interval);fprintf(fid_log,'Special Record Block Interval (Normal Records per SRB): %d\n',SRB_interval2);fprintf(fid_log,'Number of Samples: %d\n',num_samples);%comment = input('Enter additional comment to be saved in Log file','s'); %if ~isempty(comment)%  fprintf(fid_log,'\n COMMENT:\n %s',comment)%end% End of writing info to log file% =================================================% START OF CONVERSION PARTif nargin==5 | nargin==6    if channels==5        channel1=1; channel2=2; channel3=3; channel4=4; channel5=5;    elseif channels==4;        channel1=2; channel2=3; channel3=4; channel4=5; channel5=0;    elseif channels==3;        channel1=3; channel2=4; channel3=5; channel4=0; channel5=0;    elseif channels==2;        channel1=4; channel2=5; channel3=0; channel4=0; channel5=0;    elseif channels==1;        channel1=5; channel2=0; channel3=0; channel4=0; channel5=0;    else        channel1=0; channel2=0; channel3=0; channel4=0; channel5=0;    endelse    disp('Please indicate analogue channel parameters:-')    disp('(input 1=Hx, 2=Hy, 3=cond, 4=temp, 5=press, or 0=leave blank)')    channel1=input('Analogue channel 1 = ');    channel2=input('Analogue channel 2 = ');    channel3=input('Analogue channel 3 = ');    channel4=input('Analogue channel 4 = ');    channel5=input('Analogue channel 5 = ');    if isempty(channel1)        channel1=0;    end    if isempty(channel2)        channel2=0;    end    if isempty(channel3)        channel3=0;    end    if isempty(channel4)        channel4=0;    end    if isempty(channel5)        channel5=0;    endendnorth=north(1:num_samples); % cuts down excess rows in variableseast=east(1:num_samples);analogue1=analogue1(1:num_samples);analogue2=analogue2(1:num_samples);analogue3=analogue3(1:num_samples);analogue4=analogue4(1:num_samples);analogue5=analogue5(1:num_samples);date_time=date_time(1:num_samples,1:20);day_=str2num(date_time(1:num_samples,1:2));month_=date_time(1:num_samples,4:6);month_=month_convert(month_,num_samples);  % month_convert is a function written by Darren Rayner.month_=str2num(month_);year_=str2num(date_time(1:num_samples,8:11));hour_=hms2h(str2num(date_time(1:num_samples,13:14)),str2num(date_time(1:num_samples,16:17)),str2num(date_time(1:num_samples,19:20)));% hms2h is a function written by Torsten% currents (using Full Scale Range = 100)a=find(north>2047);north(a)=north(a)-4096;Vn=north*100/1750;a=find(east>2047);east(a)=east(a)-4096;Ve=east*100/1750;%disp('Calculating Current Speed');%current_speed=sqrt(Vn.*Vn+Ve.*Ve); % in cm/s%disp('Calculating Current Direction');%current_direction=atan(Ve./Vn)*180/pi;%a=find(Vn<0);%current_direction(a)=current_direction(a)+180;%a=find(Vn>0 & Ve<0);%current_direction(a)=current_direction(a)+360;% Heading (can only be calculated if both Hx and Hy logged. If so will always be in channels 1 and 2.if channel1==1 & channel2==2    disp('Calculating Heading');    heading=atan((analogue1-512)./(analogue2-512))*180/pi; % in degrees    a=find((analogue1-512)<0);    heading(a)=heading(a)+180;    a=find((analogue1-512)>0 & (analogue2-512)<0);    heading(a)=heading(a)+360;else heading='heading not recorded';endif channel1==3    disp('Calculating Conductivity') % only calculating for high resolution as these are the instruments                                     % we have on the 26.5N array    conductivity=analogue1/100; % in mS/cmelseif channel1==4    disp('Calculating Temperature') % again only high resolution    temperature=(50*analogue1/16383)-5; % in degrees Celseif channel1==5    disp('Calculating Pressure') % high resolution and pressure range of 6000.    pressure=6000*analogue1/16383; % in dbarendif channel2==3    disp('Calculating Conductivity') % only calculating for high resolution as these are the instruments                                     % we have on the 26.5N array    conductivity=analogue2/100; % in mS/cmelseif channel2==4    disp('Calculating Temperature') % again only high resolution    temperature=(50*analogue2/16383)-5; % in degrees Celseif channel2==5    disp('Calculating Pressure') % high resolution and pressure range of 6000.    pressure=6000*analogue2/16383; % in dbarendif channel3==3    disp('Calculating Conductivity') % only calculating for high resolution as these are the instruments                                     % we have on the 26.5N array    conductivity=analogue3/100; % in mS/cmelseif channel3==4    disp('Calculating Temperature') % again only high resolution    temperature=(50*analogue3/16383)-5; % in degrees Celseif channel3==5    disp('Calculating Pressure') % high resolution and pressure range of 6000.    pressure=6000*analogue3/16383; % in dbarendif channel4==4 % Channel 4 cannot be cond    disp('Calculating Temperature') % again only high resolution    temperature=(50*analogue4/16383)-5; % in degrees Celseif channel4==5    disp('Calculating Pressure') % high resolution and pressure range of 6000.    pressure=6000*analogue4/16383; % in dbarendif channel5==5 % Channel 5 can only be pressure if at all    disp('Calculating Pressure') % high resolution and pressure range of 6000.    pressure=6000*analogue5/16383; % in dbarend% END OF CONVERSION PART% ==============================================% START OF SAVE TO RODB FORMATdisp(['writing data to ',outfile]) data = [year_ month_ day_ hour_ Ve' Vn' temperature' conductivity' pressure']; cols = cols3;fort = fort3;if  channels == 5           % ie if recorded Hx and Hy to make heading  data = [data heading'];  cols = cols5;  fort = fort5;   endserial_number=str2num(serial_number);rodbsave(outfile,...       'Latitude:Longitude:Columns:SerialNumber:Mooring:WaterDepth:Instrdepth:StartDate:StartTime:EndDate:EndTime',...         fort,...         la,lo,cols,serial_number,mo,wd,z,sdate,stime,edate,etime,...         data);     fclose('all');