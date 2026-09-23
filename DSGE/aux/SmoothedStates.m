function [SmoothedStates,SmoothedVar]=SmoothedStates(y,G1,M,SDX,H,C,Tzlb,pos0,shat0,sig0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Date: July 7, 2026
% This function computes the smoothed states for a DSGE model solved with 
% Gensys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% dimensions
T=size(y,1);
[NY,NX]=size(M);


% initializing the Kalman filter
Q=M*SDX*SDX'*M';  if Tzlb>0; sss=diag(SDX); sss(pos0)=0; SSS=diag(sss); Q=M*SSS*SSS'*M'; end
if nargin<9
    shat0=zeros(NY,1); 
    sig0=disclyap_fast(G1,Q);
end
shat=shat0;
sig=sig0;
SHAT=zeros(NY,T);
SIG=zeros(NY,NY,T);


% Kalman filter recursion, also delivering the log-likelihood
for t=1:T
    if t<Tzlb; sss=diag(SDX); sss(pos0)=0; SSS=diag(sss); Q=M*SSS*SSS'*M'; else; Q=M*SDX*SDX'*M'; end
    if t<Tzlb && size(y,2)>2; yy=y(t,[1 2 4])'; HH=H([1 2 4],:); CC=C([1 2 4]); else; yy=y(t,:)'; HH=H; CC=C; end
    [shat,sig,loglh]=kfilter(yy,HH,CC,G1,shat,sig,0,Q);
    %[shat,sig,loglh]=kfilter(y(t,:)',H,C,G1,shat,sig,0,Q);
    SHAT(:,t)=shat;
    SIG(:,:,t)=sig;
end


% Kalman smoother
SmoothedStates=zeros(NY,T); SmoothedStates(:,T)=shat;
SmoothedVar=zeros(NY,NY,T); SmoothedVar(:,:,T)=sig;
bnT=shat';
SnT=sig;
for t=T-1:-1:1
    if t<Tzlb; sss=diag(SDX); sss(pos0)=0; SSS=diag(sss); Q=M*SSS*SSS'*M'; else; Q=M*SDX*SDX'*M'; end
    [bnT,SnT]=ksmooth_const_pseudo(SHAT(:,t)',squeeze(SIG(:,:,t)),bnT,SnT,G1,zeros(NY,1),Q);
    SmoothedStates(:,t)=bnT;
    SmoothedVar(:,:,t)=SnT;
end
[bnT,~]=ksmooth_const_pseudo(shat0',sig0,bnT,SnT,G1,zeros(length(G1),1),Q);
SmoothedStates=[bnT' SmoothedStates]';
SmoothedVar = cat(3, SnT, SmoothedVar);

 


function [btT,StT]=ksmooth_const_pseudo(btt,Stt,bnT,SnT,A,C,omega)
%[btT StT]=ksmooth(btt,Stt,bnT,SnT,A,omega)
% Smoothing recursion.  State evolution equation is
%    bn=A*bt+e,  Var(e)=omega
%    bt|t ~ N(btt,Stt) -- from Kalman Filter
%    bn|T ~ N(bnT,SnT) -- distribution of bn given full sample. From 
%                         KF if n=T, otherwise from this recursion
%    bt|T ~ N(btT,StT)
AS=A*Stt;
G=AS*A'+omega;
[u,d,v]=svd(G);
first0=min(find(diag(d)<1e-5));
if isempty(first0),first0=min(size(G))+1;end
u=u(:,1:first0-1);
v=v(:,1:first0-1);
d=diag(d);d=diag(1./d(1:first0-1)); 
pseudoinvG=v*d*u';
SAGI=AS'*pseudoinvG;
btT=(SAGI*(bnT'-A*btt'-C))'+btt;
StT=Stt-SAGI*AS+SAGI*SnT*SAGI';