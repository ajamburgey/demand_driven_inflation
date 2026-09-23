 function [G1,C,impact,eu,SDX,zmat,NY,NX]=modCPSbase(param);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Date: March 6, 2009
% For given parameter values, this code solves the DSGE model of
% Cogley, Primiceri and Sargent (2009)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Index for endogenous variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p=1;            % inflation
y=2;            % output
lambda=3;       % MU
w=4;            % real wages
R=5;            % interst rate
z=6;            % growth rate of productivity
lambdap=7;      % mark-up process
Z=8;            % transitory productivity
b=9;            % preference process

ep=10;          % expectational variables
ey=11;
elambda=12;

ystar=13;       % the "star" or potential economy
lambdastar=14;
wstar=15;
Rstar=16;
eystar=17;
elambdastar=18;

y_1=19;         % lagged variables
p_1=20;
p_2=21;


y_2=22;         % extra variables
y_3=23;
eR=24;
eR2=25;
eR3=26;
tbr1=27;
z_1=28;
z_2=29;
ExpGap=30;

a1=31;
a2=32;
a3=33;
a4=34;

pit=35;

NY = 35;        % # of endogenous variables


% Index for exogenous shocks  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rs=1;           % MP
zs=2;           % Technology 
lambdaps=3;     % mark-up
Zs=4;           % transitory technology
bs=5;           % intertemporal preference

mps1=6;         % anticipated MP
mps2=7;
mps3=8;
mps4=9;

pits=10;

NX=10;           % # of exogenous shocks


% Index for forecast errors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pex=1; 
yex=2;
lambdaex=3;
ystarex=4;
lambdastarex=5;

Rex=6;
Rex2=7;
Rex3=8;

NETA=8;         % # of forecast errors


% Index for unknown coefficients 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calibrated parameters
niu=2;
lambdapss=0.1;
rhopit=0.995;

% Non SD parameters 
gamma100=param(1);
pss100=.5; % param(2);
Fbeta=param(3);
h=param(4);
xip=param(5);
fp=param(6);
fy=param(7);
rhoR=param(8); rhoz=param(9); rholambdap=param(10); rhob=param(11);

% Standard deviations 
sdR=param(12); sdz=param(13); sdlambdap=param(14);
sdpit=param(15);
sdb=param(16); 

% new additional parameters
iotap = param(17);
ExtraParam1 = param(18);
sdmps1 = param(19);
decay = param(20);
sdmps2=sdmps1*decay;
sdmps3=sdmps1*decay^2;
sdmps4=0;%sdmps1*decay^3;

rhoZ=param(21);
sdZ=0;%param(22);

SDX=diag([sdR sdz sdlambdap sdZ sdb sdmps1 sdmps2 sdmps3 sdmps4 sdpit]);

numpar=22;  % Number of parameters 


% Steady state
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gamma=gamma100/100;
beta=100/(Fbeta+100);
rss=exp(gamma)/beta-1;
rss100=rss*100;


% Matrices of gensys canonical form
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GAM0 = zeros(NY,NY) ;
GAM1 = zeros(NY,NY) ;
PSI = zeros(NY,NX) ;
PPI = zeros(NY,NETA) ;


% eq 1, Phillips Curve (p)
% -------------------------------------------------------------------------
GAM0(p,p)=1;
GAM0(p,ep)=-beta/(1+iotap*beta);
GAM1(p,p)=iotap/(1+iotap*beta);
GAM0(p,lambdap)=-1;
GAM0(p,w)=-(1-beta*xip)*(1-xip)/((1+iotap*beta)*xip*(1+niu*(1+1/lambdapss))); 
GAM0(p,Z)=(1-beta*xip)*(1-xip)/((1+iotap*beta)*xip*(1+niu*(1+1/lambdapss))); 


% eq 1b, the corresponding equation for the "star" economy
% -------------------------------------------------------------------------
GAM0(Rstar,wstar)=1;
GAM0(Rstar,Z)=-1;


% eq 2, marginal utility of consumption
% -------------------------------------------------------------------------
expg=exp(gamma);
GAM0(y,lambda)=(expg-h*beta)*(expg-h);
GAM0(y,b)=-(expg-h*beta*rhob)*(expg-h); 
GAM0(y,z)=-(beta*h*expg*rhoz-h*expg);
GAM0(y,y)=(expg^2+beta*h^2);
GAM0(y,ey)=-beta*h*expg;
GAM1(y,y)=expg*h;

% % external habit
% expg=exp(gamma);
% GAM0(y,lambda)=(expg-h);
% GAM0(y,b)=-(expg-h); 
% GAM0(y,z)=h;
% GAM0(y,y)=expg;
% GAM1(y,y)=h;

% eq 2b
% -------------------------------------------------------------------------
GAM0(ystar,lambdastar)=(expg-h*beta)*(expg-h);
GAM0(ystar,b)=-(expg-h*beta*rhob)*(expg-h); 
GAM0(ystar,z)=-(beta*h*expg*rhoz-h*expg);
GAM0(ystar,ystar)=(expg^2+beta*h^2);
GAM0(ystar,eystar)=-beta*h*expg;
GAM1(ystar,ystar)=expg*h;


% eq 3, euler equation
% -------------------------------------------------------------------------
GAM0(lambda,lambda)=1;
GAM0(lambda,R)=-1;
GAM0(lambda,elambda)=-1;
GAM0(lambda,ep)=1;
GAM0(lambda,z)=rhoz;


% eq 3b
% -------------------------------------------------------------------------
GAM0(lambdastar,lambdastar)=1;
GAM0(lambdastar,Rstar)=-1;
GAM0(lambdastar,elambdastar)=-1;
GAM0(lambdastar,z)=rhoz;


% eq 4, labor supply equation
% -------------------------------------------------------------------------
GAM0(w,w)=1;
GAM0(w,b)=-1;             % old specification with preference shock        
GAM0(w,y)=-niu;
GAM0(w,Z)=niu;
GAM0(w,lambda)=1;


% eq 4b, labor supply equation
% -------------------------------------------------------------------------
GAM0(wstar,wstar)=1;
GAM0(wstar,b)=-1;         % old specification with preference shock       
GAM0(wstar,ystar)=-niu;
GAM0(wstar,Z)=niu;
GAM0(wstar,lambdastar)=1;


% eq 5, MP rule
% -------------------------------------------------------------------------
GAM0(R,R)=1;
GAM1(R,R)=rhoR;
GAM0(R,p)=-(1-rhoR)*fp/4;
GAM0(R,p_1)=-(1-rhoR)*fp/4;
GAM0(R,p_2)=-(1-rhoR)*fp/4;
GAM1(R,p_2)=(1-rhoR)*fp/4;
GAM0(R,pit)=(1-rhoR)*fp;
%GAM0(R,pit)=(1-rhoR)*(fp);
%GAM0(R,y)=-(1-rhoR)*fy;
%GAM0(R,ystar)=(1-rhoR)*fy;

% GAM0(R,y)=-(1-rhoR)*fy - ExtraParam1;
% GAM0(R,ystar)=(1-rhoR)*fy + ExtraParam1;
% GAM1(R,y)=-ExtraParam1;
% GAM1(R,ystar)=ExtraParam1;

% GAM0(R,ExpGap)  = -(1-rhoR)*fy;

GAM0(R,ExpGap)  = -(1-rhoR)*fy - ExtraParam1;
GAM1(R,ExpGap)  = - ExtraParam1;

% GAM0(R,y)=-(1-rhoR)*fy/4;
% GAM1(R,y_3)=-(1-rhoR)*fy/4;
% GAM0(R,z)=-(1-rhoR)*fy/4;
% GAM0(R,z_1)=-(1-rhoR)*fy/4;
% GAM0(R,z_2)=-(1-rhoR)*fy/4;
% GAM1(R,z_2)=(1-rhoR)*fy/4;

GAM1(R,a1)=1;

PSI(R,Rs)=1;

%GAM0(R,p)=1; GAM0(R,pit)=1; GAM0(R,ExpGap)=.5;
%GAM0(R,y)=.1; GAM0(R,ystar)=-.1;
%GAM0(R,p_1)=1/4; GAM0(R,p_2)=1/4; GAM1(R,p_2)=-1/4;


% eq 6 - 9, exogenous shocks
% -------------------------------------------------------------------------
GAM0(z,z)=1; GAM1(z,z)=rhoz; PSI(z,zs)=1;
GAM0(lambdap,lambdap)=1; GAM1(lambdap,lambdap)=rholambdap; PSI(lambdap,lambdaps)=1;
GAM0(Z,Z)=1; GAM1(Z,Z)=rhoZ; PSI(Z,Zs)=1;
GAM0(b,b)=1; GAM1(b,b)=rhob; PSI(b,bs)=1;
GAM0(pit,pit)=1; GAM1(pit,pit)=rhopit; PSI(pit,pits)=1;


% eq 10 - 14, expectational terms
% -------------------------------------------------------------------------
GAM0(ep,p)=1; GAM1(ep,ep)=1; PPI(ep,pex)=1;
GAM0(ey,y)=1; GAM1(ey,ey)=1; PPI(ey,yex)=1;
GAM0(elambda,lambda)=1; GAM1(elambda,elambda)=1; PPI(elambda,lambdaex)=1;
GAM0(eystar,ystar)=1; GAM1(eystar,eystar)=1; PPI(eystar,ystarex)=1;
GAM0(elambdastar,lambdastar)=1; GAM1(elambdastar,elambdastar)=1; PPI(elambdastar,lambdastarex)=1;
GAM0(eR,R)=1; GAM1(eR,eR)=1; PPI(eR,Rex)=1;
GAM0(eR2,eR)=1; GAM1(eR2,eR2)=1; PPI(eR2,Rex2)=1; 
GAM0(eR3,eR2)=1; GAM1(eR3,eR3)=1; PPI(eR3,Rex3)=1; 


% eq 15 - 17, lagged variables
% -------------------------------------------------------------------------
GAM0(y_1,y_1)=1; GAM1(y_1,y)=1;
GAM0(p_1,p_1)=1; GAM1(p_1,p)=1;
GAM0(p_2,p_2)=1; GAM1(p_2,p_1)=1;
GAM0(y_2,y_2)=1; GAM1(y_2,y_1)=1;
GAM0(y_3,y_3)=1; GAM1(y_3,y_2)=1;
GAM0(z_1,z_1)=1; GAM1(z_1,z)=1;
GAM0(z_2,z_2)=1; GAM1(z_2,z_1)=1;


% eq 15 - 17, definition of tbr1
% -------------------------------------------------------------------------
GAM0(tbr1,tbr1)=1;
GAM0(tbr1,R)=-1/4;
GAM0(tbr1,eR)=-1/4;
GAM0(tbr1,eR2)=-1/4;
GAM0(tbr1,eR3)=-1/4;


% eq 15 - 17, definition of the empirical output gap
% -------------------------------------------------------------------------
GAM0(ExpGap,ExpGap)=1/.9; 
GAM1(ExpGap,ExpGap)=1; 
GAM0(ExpGap,y)=-1; 
GAM0(ExpGap,y_1)=1; 
GAM0(ExpGap,z)=-1; 


% eq 15 - 17, definition of anticipated shocks
% -------------------------------------------------------------------------
GAM0(a1,a1)=1; GAM1(a1,a2)=1; PSI(a1,mps1)=1;
GAM0(a2,a2)=1; GAM1(a2,a3)=1; PSI(a2,mps2)=1;
GAM0(a3,a3)=1; GAM1(a3,a4)=1; PSI(a3,mps3)=1;
GAM0(a4,a4)=1; PSI(a4,mps4)=1;


% Solution of the RE model using Gensys
% (calls the lowercase "gensys" -- this replication's own actively-
% maintained implementation of the same interface, not Chris Sims'
% original GENSYS.M, which isn't available here; MATLAB's function
% resolution is case-sensitive even though the filesystem may not be)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[G1,C,impact,fmat,fwt,ywt,gev,eu]=gensys(GAM0,GAM1,zeros(NY,1),PSI,PPI) ;


% Observation equations (obs = zmat * endog + C)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
zmat=zeros(4,NY); 
zmat(1,y)=1; zmat(1,y_1)=-1; zmat(1,z)=1; 
zmat(2,p)=4;
zmat(3,tbr1)=4; 
zmat(4,R)=4; 

C=zeros(3,1);
C(1)=gamma100;
C(2)=4*pss100;
C(3)=4*(pss100+rss100);
C(4)=4*(pss100+rss100);