%% load MEDIPROD-V CTD files and convert to RODB format%count=0;for n=0:160  disp(n)  filename=['s',int2str(n)];  if exist(filename)    count=count+1;    fid=fopen(filename,'rt');    line=fgetl(fid);		% cruise name    cruise=line(1:20);    line=fgetl(fid);		% ship name    ship=line(1:15);    line=fgetl(fid);		% Station number    station=sscanf(line,'%f');    line=fgetl(fid);    line=fgetl(fid);    line=fgetl(fid);		% year    dat(1)=sscanf(line,'%f');    line=fgetl(fid);		% month    dat(2)=sscanf(line,'%f');    line=fgetl(fid);		% day    dat(3)=sscanf(line,'%f');    line=fgetl(fid);		% hour    time(1)=sscanf(line,'%f');    line=fgetl(fid);		% minute    time(2)=sscanf(line,'%f');    for k=1:7      line=fgetl(fid);    end    line=fgetl(fid);		% latitude    lat=sscanf(line,'%f')';    line=fgetl(fid);		% longitude    lon=sscanf(line,'%f')';    [latstr,lonstr]=pos2str([lat,lon]);    for k=1:4      line=fgetl(fid);    end    data=fscanf(fid,'%f');    fclose(fid);    outfile=['su5_',int2strv(count,1,'0',3),'.ctd'];    if dat(1)<100      dat(1)=dat(1)+1900;    end    fid=fopen(outfile,'wt');    fprintf(fid,['Filename       = ',filename,'\n'],0);    fprintf(fid,['Shipname       = ',ship,'\n'],0);    fprintf(fid,['Cruise         = ',cruise,'\n'],0);    fprintf(fid,['Date           = ',int2str(dat(1)),'/',...				   int2strv(dat(2),1,'0',2),'/',...				   int2strv(dat(3),1,'0',2),'\n'],0);    fprintf(fid,['Time           = ',int2strv(time(1),1,'0',2),':',...				   int2strv(dat(2),1,'0',2),'\n'],0);    fprintf(fid,['Station        = ',int2str(station),'\n'],0);    fprintf(fid,['Latitude       = ',latstr,'\n'],0);    fprintf(fid,['Longitude      = ',lonstr,'\n'],0);    fprintf(fid,['Columns        = p:t:s\n'],0);    fprintf(fid,'%6.1f %7.4f %7.4f\n',data);    fclose(fid);  endend    