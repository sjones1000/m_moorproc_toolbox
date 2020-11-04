function cdfot = mcontr(cdfin,ncfile)
% function mcontr(cdf,ncfile)
%


m_common
MEXEC_A.Mprog = 'mcontr';
m_proghd;

ntickdef = [10 10 10]; % third element is default number of contour intervals
cdfot = [];
if nargin < 1
    % no argments, create empty cdf
    cdfin = [];
    cdfot = [];
else
    cdfot = cdfin;
end


% % if nargin < 2
% %     m = 'At present, this program requires precisely two arguments';
% %     m2 = 'Which must be a fully-configured cdf and the file name';
% %     m3 = 'In due course it can be added to to supply sensible defaults,';
% %     m4 = 'but that is a job still to do';
% %     fprintf(MEXEC_A.Mfider,'%s\n',m,m2,m3,m4)
% %     return
% % else
% %     cdfot = cdfin;
% % end

% if ncfile is input argument, use it;
% override cdfin.ncfile even if present
if nargin >= 2
    cdfin.ncfile = ncfile;
end

% sort out filename
if isfield(cdfin,'ncfile')
    ncfile = m_resolve_filename(cdfin.ncfile);
else
    fprintf(MEXEC_A.Mfidterm,'%s','Enter name of input disc file  ')
    fn_in = m_getfilename;
    ncfile = m_resolve_filename(fn_in);
end

ncfile = m_openin(ncfile); % check we have found a valid mstar file name
cdfot.ncfile = ncfile;

h = m_read_header(cdfot.ncfile);
m_print_header(h);



% sort out xlist and ylist
if ~isfield(cdfin,'xlist')
    ok = 0;
    while ok == 0
        m = sprintf('%s\n','Type variable name or number of independent (x) variable: ');
        var = m_getinput(m,'s');
        vlist = m_getvlist(var,h);
        if length(vlist) ~= 1
            m = 'Must select one only';
            fprintf(MEXEC_A.Mfider,'%s\n',' ',m,' ');
            continue
        else
            ok = 1;
        end
    end
    cdfot.xlist = h.fldnam{vlist};
end

if ~isfield(cdfin,'ylist')
    ok = 0;
    while ok == 0
        m = sprintf('%s\n','Type variable name or number of independent (y) variable (precisely one): ');
        var = m_getinput(m,'s');
        vlist = m_getvlist(var,h);
        if length(vlist) == 1
            ok = 1;
        end
    end
    cdfot.ylist = h.fldnam{vlist};
    cdfot.ylist = m_remove_outside_spaces(cdfot.ylist);
end

if ~isfield(cdfin,'zlist')
    ok = 0;
    while ok == 0
        m = sprintf('%s\n','Type variable name or number of dependent (z) variable (precisely one): ');
        var = m_getinput(m,'s');
        vlist = m_getvlist(var,h);
        if length(vlist) == 1
            ok = 1;
        end
    end
    cdfot.zlist = h.fldnam{vlist};
    cdfot.zlist = m_remove_outside_spaces(cdfot.zlist);
end


%turn x and y var lists to numbers
xnumlist = m_getvlist(cdfot.xlist,h);
ynumlist = m_getvlist(cdfot.ylist,h);
znumlist = m_getvlist(cdfot.zlist,h);

xnum = xnumlist(1);
xname = h.fldnam{xnum};
ynum = ynumlist(1);
yname = h.fldnam{ynum};
znum = znumlist(1);
zname = h.fldnam{znum};



x = nc_varget(ncfile.name,xname); x = x(1,:);
y = nc_varget(ncfile.name,yname); y = y(:,1);
z = nc_varget(ncfile.name,zname);




m_figure

set(gcf,'papertype','a4');
orient landscape

% sort out axes & ticks
if isfield(cdfin,'xax')
    xax = cdfin.xax;
    if isfield(cdfin,'ntick')
        nxt = cdfin.ntick(1);
    else
        nxt = ntickdef(1);
    end
else
    % use a simple plot to detect limits and ticks for x
    plot(x,x);
    h0 = gca;
    xax = get(h0,'xlim');
    xt = get(h0,'xtick');
    nxt = length(xt)-1;
    clf;
    %     xax = m_autolims(x,nxt);
end
cdfot.xax = xax;
cdfot.ntick(1) = nxt;

if isfield(cdfin,'yax')
    yax = cdfin.yax;
    if isfield(cdfin,'ntick')
        nyt = cdfin.ntick(2);
    else
        nyt = ntickdef(2);
    end
else
    % use a simple plot to detect limits and ticks for y
    plot(y,y);
    h0 = gca;
    yax = get(h0,'ylim');
    yt = get(h0,'ytick');
    nyt = length(yt)-1;
    clf;
    %     xax = m_autolims(x,nxt);
end
cdfot.yax = yax;
cdfot.ntick(2) = nyt;


% normalise x and y data onto [0 1] This will allow decreasing as well as
% increasing limits to be specified in cdf

% calculate tick values
xr = xax(2)-xax(1); % xrange
yr = yax(2)-yax(1); % y ranges
xti = xr/nxt; % x tick interval
yti = yr/nyt; % ytick interval for first y variable
xt = xax(1):xti:xax(2); % x tick values
xtraw = xt; %save for later; position of ticks will be normalised.
yt = yax(1):yti:yax(2); % y tick values
ytraw = yt; %save for later; position of ticks will be normalised.

xnorm = (x-xax(1))/xr;
ynorm = (y-yax(1))/yr;
xt = (xt-xax(1))/xr; %normalised ticks
yt = (yt-yax(1))/yr; % normalised ticks

% Set up up the parameters that control the plot layout
ox = 4; %axis origin in cm from bottom left of page
oy = 3; %axis origin in cm from bottom left of page
t1 = 0.3; % separation in cm between tick annotations and plot area
th = 0.8; % height allowed for text
tw = 2.0; % width allowed for text
yw = 4; % width alowed for y variable names 3 and above
fs0 = 14; % default font size
if isfield(cdfin,'plotsize')
    plotsize = cdfin.plotsize;
else
    plotsize = [18 12]; % default plot size
end
cdfot.plotsize = plotsize;
pw = plotsize(1);
ph = plotsize(2);
posaxes = [ox oy plotsize];
fscale = min([plotsize(1)/max(16,plotsize(1)) plotsize(2)/max(12,plotsize(2)) 1]); %scaling of fonts if plot falls below a certain size
allscale = min([plotsize(1)/max(12,plotsize(1)) plotsize(2)/max(10,plotsize(2)) 1]); %scaling of distances if plot falls below a certain size
fontsize = max(4,floor(fs0*fscale));
t1 = t1*allscale;
th = th*allscale;
tw = tw*allscale;
yw = yw*allscale;

% plot the data, compiling the y ticklabels as we go
clear ytlabel ytstr
global hplot


% plot first data
if isfield(cdfin,'ntick')
    nzt = cdfin.ntick;
    if length(nzt) > 2
        nzt = nzt(3);
    else
        nzt = ntickdef(3);
    end
else
    nzt = ntickdef(3);
end
cdfin.ntick(3) = nzt;
zlims = m_autolims([min(min(z)) max(max(z))],nzt);
if isfield(cdfin,'clev')
    clev = cdfin.clev;
else
    clev = zlims(1):(zlims(2)-zlims(1))/nzt:zlims(2); % default contours
end
clev = unique(clev);
cdfot.clev = clev;
if zlims(1) < clev(1); 
    clev = [zlims(1) clev]; 
else
    clev = [clev(1)-(clev(2)-clev(1)) clev];
end
if zlims(2) > clev(end); 
    clev = [clev zlims(2)]; 
else
    clev = [clev clev(end)+(clev(end)-clev(end-1))];
end
% cdfot.clev = clev;

% colorbar_limits = zlims;
% colorbar_limits = [clev(1) clev(end)];
% colorbar_limits = [-10 20];
% clmin = min([zlims(1) clev(1)-(clev(2)-clev(1))]);
% clmax = max([zlims(2) clev(end)+(clev(end)-clev(end-1))]);
% colorbar_limits = [clmin clmax];
delta_c = hcf(diff(clev));
colorbar_limits = [clev(1)-delta_c clev(end)+delta_c];

color_level_boundaries = clev;
if isfield(cdfin,'colortable')
    colortable = cdfin.colortable;
    while size(colortable,1) < length(clev)-1
        m = ['Colortable was too short' sprintf(' %d',size(colortable,1)) ' provided;' sprintf(' %d',length(clev)-1) ' required;'] ;
        m1 = '   Cycling round from start; some colors will be repeated';
        fprintf(MEXEC_A.Mfider,'%s\n',m,m1);
        colortable = [colortable; cdfin.colortable];
    end
    colortable = colortable(1:length(clev)-1,:);
else
    nc = length(clev)-1;
    colortable = jet(nc);
end
cdfot.colortable = colortable;
colortable2 = [colortable(1,:); colortable; colortable(end,:)];
cmap = make_colorbar(colorbar_limits,color_level_boundaries,colortable2);
[cplot,hplot] = contourf(xnorm,ynorm,z,clev,'k-');
clabel(cplot,hplot);
colormap(cmap);
caxis(colorbar_limits-1e-5)
ca = caxis;

keyboard
ha = gca;
set(ha,'position',[.1 .15 .7 .7]);
axis([0 1 0 1]);
set(ha,'xtick',xt);
set(ha,'ytick',yt);
% switch off xtick labels
for k = 1:length(xt)
    empty{k} = '';
end
set(ha,'xticklabel',empty);
% switch off ytick labels
for k = 1:length(yt)
    empty{k} = '';
end
set(ha,'yticklabel',empty);
hold on; %grid on;

set(gca,'units','centimeters');
set(gcf,'defaultaxesfontsize',fontsize)
set(gcf,'defaulttextfontsize',fontsize)

posnew = [posaxes];
set(gca,'position',posnew);



% y tick labels
% remove trailing 0 or decimal point
for k = 1:length(yt);
    str = sprintf('%10.3f',ytraw(k));
    while strcmp(str(end),'0') == 1; str(end) = []; end
    while strcmp(str(end),'.') == 1; str(end) = []; end
    while strcmp(str(1),' ') == 1; str(1) = []; end
    ht = text(0,yt(k),str);
    set(ht,'units','centimeters')
    pp = get(ht,'position');
    pp(1) = -t1;
    set(ht,'position',pp)
    set(ht,'HorizontalAlignment','right');
    set(ht,'VerticalAlignment','middle')
end

% x tick labels
for k = 1:length(xt);
    str = sprintf('%10.3f',xtraw(k));
    while strcmp(str(end),'0') == 1; str(end) = []; end
    while strcmp(str(end),'.') == 1; str(end) = []; end
    while strcmp(str(1),' ') == 1; str(1) = []; end
    ht = text(xt(k),0,str);
    set(ht,'units','centimeters')
    pp = get(ht,'position');
    pp(2) = -t1;
    set(ht,'position',pp)
    set(ht,'HorizontalAlignment','center')
    set(ht,'VerticalAlignment','top')
end

% x minor ticks at location of x grid points in data array
for k = 1:length(xnorm)
    xminorx = [xnorm(k) xnorm(k)];
    xminory = [1+t1/10 1];
    hxminor = plot(xminorx,xminory,'k-','linewidth',1);
    set(hxminor,'clipping','off');
end

%Plot the title
% hh = ylabel('number'); set(hh,'interpreter','none');
plot_title = ['<dn>  ' h.dataname '  <vers>  ' sprintf('%s  ',h.mstar_site) sprintf('%4d ',h.version) ];
hh = text(.5,1,plot_title); set(hh,'interpreter','none');
set(hh,'units','centimeters')
set(hh,'position',[pw/2,ph+t1+th]);
set(hh,'HorizontalAlignment','center')
set(hh,'VerticalAlignment','bottom')

%File name & z variable
str = [h.fldnam{znum} ' (' m_remove_outside_spaces(h.fldunt{znum}) ')'];
plot_filename = ['File name:  ' ncfile.name '       variable: ' str ];
hh = text(.5,1,plot_filename); set(hh,'interpreter','none');
set(hh,'units','centimeters')
set(hh,'position',[pw/2,ph+t1+th+th]);
set(hh,'HorizontalAlignment','center')
set(hh,'VerticalAlignment','bottom')


% % % %Date string
% % % str = datestr(now,31);
% % % dateposx = 0;
% % % dateposy = 1.02;
% % % hh = text(dateposx,dateposy,str); %position normalised on xax and yax scales
% % % set(hh,'units','centimeters')
% % % set(hh,'position',[-0.9*ox,ph+th]);
% % % set(hh,'HorizontalAlignment','left')
% % % set(hh,'VerticalAlignment','bottom')
% % % set(hh,'fontsize',max(4,fontsize-4));

% % % %Prog string
% % % str = MEXEC_A.Mprog;
% % % progposx = 0;
% % % progposy = 1.1;
% % % hh = text(progposx,progposy,str); %position normalised on xax and yax scales
% % % set(hh,'units','centimeters')
% % % set(hh,'position',[-0.9*ox,ph+th+th]);
% % % set(hh,'HorizontalAlignment','left')
% % % set(hh,'VerticalAlignment','bottom')
% % % set(hh,'fontsize',max(4,fontsize-4));

%Prog & date string combined and rotated
str = [MEXEC_A.Mprog '  ' datestr(now,31)];
progposx = 0;
progposy = 1.1;
hh = text(progposx,progposy,str); %position normalised on xax and yax scales
set(hh,'units','centimeters')
set(hh,'position',[-0.9*ox,ph+t1+th]);
set(hh,'HorizontalAlignment','right')
set(hh,'VerticalAlignment','top')
set(hh,'Rotation',90);
set(hh,'fontsize',max(4,fontsize-4));


% % % % % %Start and stop strings
% % % % % if dctime > 0
% % % % %     cdfot.dctime = 1;
% % % % %     % this is a time
% % % % %     v1 = datevec(time_start);
% % % % %     doy1 = 1 + floor(time_start - datenum([v1(1) 1 1 0 0 0]));
% % % % %     v2 = datevec(time_stop);
% % % % %     doy2 = 1 + floor(time_stop - datenum([v1(1) 1 1 0 0 0]));
% % % % %     
% % % % %     strstart = ['Start  ' sprintf('%04d%02d%02d %s %3d) %02d%02d%02d',v1(1:3),'(daynum',doy1,floor(v1(4:6)))];
% % % % %     strstart = [strstart sprintf('%s%d',' dc ',x1)];
% % % % %     strstop =  ['Stop  ' sprintf('%04d%02d%02d %s %3d) %02d%02d%02d',v2(1:3),'(daynum',doy2,floor(v2(4:6)))];
% % % % %     strstop =  [strstop sprintf('%s%d',' dc ',x2)];
% % % % % else
% % % % %     cdfot.dctime = 0;
% % % % %     strstart = ['Start ' sprintf('%s%d',' dc ',x1)];
% % % % %     strstop = ['Stop ' sprintf('%s%d',' dc ',x2)];
% % % % % end
% % % % % 
% % % % % startposx = -0.12;
% % % % % startposy = -0.06;
% % % % % hh = text(startposx,startposy,strstart); %position normalised on xax and yax scales
% % % % % set(hh,'units','centimeters')
% % % % % set(hh,'position',[-0.9*ox,-t1-th]);
% % % % % set(hh,'HorizontalAlignment','left')
% % % % % set(hh,'VerticalAlignment','top')
% % % % % set(hh,'fontsize',max(4,fontsize-2));
% % % % % 
% % % % % 
% % % % % stopposx = -0.12;
% % % % % stopposy = -0.12;
% % % % % hh = text(stopposx,stopposy,strstop); %position normalised on xax and yax scales
% % % % % set(hh,'units','centimeters')
% % % % % set(hh,'position',[-0.9*ox,-t1-th-th]);
% % % % % set(hh,'HorizontalAlignment','left')
% % % % % set(hh,'VerticalAlignment','top')
% % % % % set(hh,'fontsize',max(4,fontsize-2));

% x label
strx = xname;
xunits = h.fldunt{xnum};
strxu = ['(' m_remove_outside_spaces(xunits) ')'];
xlabx = .5;
xlaby = -0.06;
xlabxu = .5;
xlabyu = -0.12;
hh = text(xlabx,xlaby,strx); %position normalised on xax and yax scales
set(hh,'units','centimeters')
set(hh,'position',[pw/2,-t1-th]);
set(hh,'HorizontalAlignment','center')
set(hh,'VerticalAlignment','top')
set(hh,'interpreter','none');
hh = text(xlabxu,xlabyu,strxu); %position normalised on xax and yax scales
set(hh,'units','centimeters')
set(hh,'position',[pw/2,-t1-th-th]);
set(hh,'HorizontalAlignment','center')
set(hh,'VerticalAlignment','top')
set(hh,'interpreter','none');


% string for y variable
xlaby = [-t1-tw]; % put first two ylabels at left of axis; remainder below axis
ylaby = [ph];
str = [yname ' (' m_remove_outside_spaces(h.fldunt{ynum}) ')'];
hh = text(0,0,str);
set(hh,'units','centimeters')
set(hh,'position',[xlaby ylaby]);
set(hh,'HorizontalAlignment','right')
set(hh,'VerticalAlignment','bottom')
set(hh,'rotation',90)
set(hh,'interpreter','none');


% % set(gca,'units','centimeters');
% % posaxes = get(gca,'position');
% % if isfield(cdfin,'plotsize')
% %     plotsize = cdfin.plotsize;
% % else
% %     plotsize = [18 12];
% % end
% % cdfotot.plotsize = plotsize;
% % posnew = [posaxes(1) posaxes(2) plotsize(1) plotsize(2)];
% % set(gca,'position',posnew);

% need to review all labelling;
% consider the detailed location and scaling; use mm instead of scaled values;
% need xtick labels


%plot colorbar as contourf
pos = get(gca,'position');

subplot('position',[.99 0 .01 .01])

axis([0 1 0 1]);

set(gca,'units','centimeters');
set(gcf,'defaultaxesfontsize',fontsize)
set(gcf,'defaulttextfontsize',fontsize)

posnew = [pos(1)+ pw + 1,pos(2),1,ph];
set(gca,'position',posnew);

xc = [0 1];
dely = (ca(2)-ca(1))/100;
yc = ca(1):dely:ca(2);
yc = clev(1)+(clev(end)-clev(1))*[0:.01:1];
yca = yc(1) - 0.0*(yc(end)-yc(1));
ycb = yc(end) + 0.0*(yc(end)-yc(1));
yc = [yca yc ycb];

yc = clev;

[xcg,ycg]= meshgrid(xc,yc);
zc = ycg;

% keyboard
[c2,h2] = contourf(xc,1:length(clev),zc,clev,'k-');
% set(h2,'linestyle','none')
for k = 1:length(clev)
    str = sprintf('%20.4f',clev(k));
    while strcmp(str(end),'0') == 1; str(end) = []; end
    while strcmp(str(end),'.') == 1; str(end) = []; end
    while strcmp(str(1),' ') == 1; str(1) = []; end
    ylab{k} = str;
end
set(gca,'ytick',[2:length(clev)-1]);
set(gca,'xtick',[]);
set(gca,'yticklabel',ylab(2:end-1));
set(gca,'yaxislocation','right');


colormap(cmap);
% caxis
caxis(ca)

return


% % % % % % xax = pdf.xax;
% % % % % % yax = pdf.yax;
% % % % % ntdef = 0; % record whether number of ticks was default
% % % % % if isfield(pdf,'ntick')
% % % % %     ntick = pdf.ntick;
% % % % % else
% % % % %     ntick = [10 10];
% % % % %     ntdef = 1; % note that the number of ticks comes form default
% % % % %     pdf.ntick = ntick;
% % % % % end
% % % % % 

% % % % % nxt = ntick(1);
% % % % % nyt = ntick(2);
% % % % % 
% % % % % 
% % % % % %read header
% % % % % % h = m_read_header(ncfile);
% % % % % % m_print_header(h);
% % % % % 
% % % % % %turn x and y var lists to numbers
% % % % % xnumlist = m_getvlist(pdf.xlist,h);
% % % % % ynumlist = m_getvlist(pdf.ylist,h);
% % % % % 
% % % % % xnum = xnumlist(1);
% % % % % xname = h.fldnam{xnum};
% % % % % % x = nc_varget(ncfile.name,xname);
% % % % % % x = reshape(x,1,numel(x)); % reshape to row
% % % % % 
% % % % % numy = length(ynumlist);
% % % % % yname = {}; y = [];
% % % % % for k =1:numy
% % % % %     ykname = h.fldnam{ynumlist(k)};
% % % % %     yname = [yname ; ykname];
% % % % % %     yk = nc_varget(ncfile.name,ykname);
% % % % % %     yk = reshape(yk,1,numel(yk)); % reshape to rows
% % % % % %     y = [y; yk];
% % % % % end
% % % % % 


function cmap = make_colorbar(colorbar_limits,color_level_boundaries,colortable)

% eg colorbar_limits = [-.1 .1];
% eg color_level_boundaries = [ -.06 -.04 -.02 -.01 -.005 .005 .01 .02 .04 .06];
% eg colortable = [
%         0         0    0.7000
%         0         0    0.9375
%         0    0.3125    1.0000
%         0    0.6875    1.0000
%    0.8000    1.0000    1.0000
%    1.0000    1.0000    1.0000
%    1.0000    1.0000    0.6000
%    1.0000    0.8750         0
%    1.0000    0.6000         0
%    1.0000    0.4000         0
%    1.0000    0.1250         0
%    ]

%In order to get nice blocks of color in the colorbar that
%correspond to the intervals between contours, define the
%color level boundaries and the rgb values of colours that
%fall between them. The color level boundaries don't have to be
%the same as the contours. ie you can have several contours between
%a color level boundary.

%this program builds a colormap by dividing the colorbar into evenly
%spaced blocks, and then repeating each defined colour the correct
%number of times so that the final colorbar changes color at the
%defined color levels.

%The size of the block is chosen with a Highest Common Factor routine.
%The routine uses a scaling, so that decimal color level boundaries
% appear as 'integers'. The default scaling is 1e6, so that
% boundaries with any reasonable number of decimal places produce
% the expected behaviour.


if nargin < 3
    colortable = jet(length(color_level_boundaries)+1);
end

%we need to know how many total blocks of color we require between colorbar_limits.
%then we'll work out how often to repeat each one.

%First check there is one more colour than colour level.
%we expect colors to be defined between each colour level, and above and below the
%first and last colour levels.

if length(colortable) ~= length(color_level_boundaries)+1
    disp('error')
    return
end

%size of colorblock is minimum gap between contours, or between
%contours and colorbar_limits.

%first find countours that fall within colorbar_limits

iok = find(color_level_boundaries > colorbar_limits(1) & color_level_boundaries < colorbar_limits(2));
use_levels =  [colorbar_limits(1) color_level_boundaries(iok) colorbar_limits(2)];
iok = [iok iok(end)+1]; %include one extra colour at the end; this is now the set of colours in the colorbar

diflev = diff(use_levels);
blocksize = hcf(diflev);  %highest common factor of diflev; use hcf default scaling.

clear cmap
numc = 0;

for k = 1:length(use_levels)-1
    numblock = round((use_levels(k+1)-use_levels(k))/blocksize);
    for kk = 1:numblock
        numc = numc+1;
        cmap(numc,:) = colortable(iok(k),:);
    end
end

return

function h = hcf(list,factor)

%find the highest common factor of a list of numbers.
%
%This was originally written to work with non-integer
%contour intervals, so I allow a user scaling to convert
%'reals', eg 0.01 0.02 and so on, into 'integers'

%search algorithm from PDK; 7 Mar 2005; coded by BAK.

if nargin == 1
    factor = 1000000;
end

factor = 1;
e = max(abs((factor*list - round(factor*list))));
while e > 1e-10
    factor = 10*factor;
    e = max(abs((factor*list - round(factor*list))));
end


list = list(:)';  %force to a row vector
list = round(list*factor); %apply scaling and convert to integers
list = unique(list);  %eliminate duplicates and sort ascending

if list(1) < 1
    h = nan;
    return
    %I only deal with sensible lists of positive numbers !
end


%Now we have real cases to deal with

while length(list) > 1
    list = unique([list(1) list(2:end)-list(1)]); %subtract smallest, sort and eliminate duplicates
    if list(1) == 1  %hcf must be unity, so bale out
        list = 1;
    end
end

h = list/factor;

return

