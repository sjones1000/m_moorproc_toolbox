function sig = sigma(p,t,s,pref)
%	function sig=sigma(p,t,s,[pref])
%	
% computation of density of seawater 
% referenced to arbitrary pressures 
% based on 'alpha.m'
%
% input  :	p		: pressure [dbar]
%		t		: in situ temperature [degrees Celsius]
%		s		: salinity [psu]
%		pref	[p]	: optional reference pressure
%
% output :	sig		: density of seawater at pressure P (adiabatic)
%				  [kg/m^3]
%
% check values :	sigma(0,40,40) = 21.6788   kg/m^3
%               	sigma(0, 0,35) = 28.106331 kg/m^3
%
% uses :	alpha.m
%
% version 1.1.0		last change 01.09.1995

% modified from SIGMATH, Uwe Send, March 1995
% optional without Pref		G.Krahmann, IfM Kiel, Sep 1995

if (nargin<4)
  xats=alpha(p,t,s);
else
  xats=alpha(pref,theta(p,t,s,pref),s);
end
sig=1./xats-1000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  S U B R O U T I N E
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [spv,k,steran] = alpha(p,t,s)
% function [spv,k,steran] = alpha(p,t,s)
%
% EQUATION OF STATE FOR SEAWATER PROPOSED BY JPOTS 1980
%
% input  :      p               : pressure [dbar]
%               t               : temperature [degrees Celsius]
%               s               : salinity [psu]
%
% output :      spv             : specific volume [m^3/kg]
%               k               : secant bulk modulus [dbar]
%               steran          : steric anomaly [m^3/kg]
%
% check values :        alpha(10000,40,40) = 9.435561e-4 m^3/kg
%
% version 1.1.0         last change 06.09.1995

% reference : Landolt-Boernstein V/3a pp 237-242
%       IFM KIEL        T.MUELLER
%       18/02/92, C. Mertens, IfM Kiel, changed to Matlab
% revised header, added bulk-modulus, steric anomaly
%       G.Krahmann, IfM Kiel, Sep 1995

[m,n] = size(p) ;
if (n == 1 & m~= 1)
        [m,n] = size(t) ;
        p = p*ones(1,n) ;
end

p = p/10 ;
sr = sqrt(abs(s)) ;
%pure water density at atm pressure
rhow = ((((6.536332E-9*t - 1.120083E-6).*t +1.001685E-4).*t - 9.095290E-3).*t ...
         + 6.793952E-2).*t + 999.842594 ;

%seawater density at atm pressure
r1 = (((5.3875E-9*t - 8.2467E-7).*t + 7.6438E-5).*t - 4.0899E-3).*t ...
      + 8.24493E-1 ;
r2 = (-1.6546E-6*t + 1.0227E-4).*t - 5.72466E-3 ;
r3 = 4.8314E-4 ;
rho0 = (r3.*s + r2.*sr + r1).*s + rhow ;
%specific volume at atm pressure
spv = 1 ./ rho0 ;

%compute secant bulk modulus k(p,t,s)
e = (9.1697E-10*t + 2.0816E-8).*t -9.9348E-7 ;
bw = (5.2787E-8*t - 6.12293E-6).*t + 8.50935E-5 ;
b = bw + e.*s ;
d = 1.91075E-4 ;
c = (-1.6078E-6*t - 1.0981E-5).*t + 2.2838E-3 ;
aw = ((-5.77905E-7*t + 1.16092E-4).*t + 1.43713E-3).*t + 3.239908 ;
a = (d.*sr + c).*s + aw ;
b1 = (-5.3009E-4*t + 1.6483E-2).*t + 7.944E-2 ;
a1 = ((-6.1670E-5*t + 1.09987E-2).*t -0.603459).*t + 54.6746 ;
kw = (((-5.155288E-5*t + 1.360477E-2).*t - 2.327105).*t + 148.4206).*t ...
       + 19652.21 ;

%compute k(0,t,s)
k0 = (b1.*sr + a1).*s + kw ;

%evaluate k(p,t,s)
k = (b.*p + a).*p + k0 ;
spv = spv.*(1-p./k) ;

% convert k to dbar for output
k = k*10;

% compute steric anomaly
if sumnan(sumnan(t+s-35))
  steran=spv-alpha(p,0,35);
else
  steran=zeros(size(p,1),size(p,2));
end
