function r=HD(y,lags,BETA,GG,S)
% HD  Historical decomposition, draw by draw, from a forecast origin.
% INPUT   y      data whose first `lags` rows are the initial conditions,
%                so the forecast origin is row `lags` and the decomposition
%                starts at row lags+1
%         lags   lag order
%         BETA   k x n x M lag coefficients, one page per accepted draw
%         GG     n x n x M structural impact matrices
%         S      M x 1 shock selector: for draw i, SDC feeds back only the
%                realized shock S(i), so column j of a call with S = j*ones
%                isolates shock j
% OUTPUT  r.DC      horizons x n x M unconditional forecast (no shocks)
%         r.SDC     horizons x n x M forecast plus the selected shock alone
%         r.SHOCKS  horizons x n x M realized structural shocks
% The contribution of shock j is SDC - DC; DC is identical across S.

[T,n]=size(y);
M=size(BETA,3);

k=lags*n+1;
T0=lags;
hz=1:T-T0;

x=zeros(T,k);
x(:,1)=1;
for i=1:lags
    x(:,1+(i-1)*n+1:1+i*n)=lag(y,i);
end
x=x(lags+1:end,:);


store_DC=NaN(max(hz),n,M);
store_SDC=NaN(max(hz),n,M);
store_SHOCKS=NaN(max(hz),n,M);
for i=1:M
    beta=squeeze(BETA(:,:,i));
    G=squeeze(GG(:,:,i));
    s=S(i);
    shocks=(y(lags+1:end,:)-x*beta)*inv(G');
    store_SHOCKS(:,:,i)=shocks;
    
    DC=[y(T0-lags+1:T0,:);zeros(hz(end),n)];
    SDC=[y(T0-lags+1:T0,:);zeros(hz(end),n)];
    for tau=1:max(hz)
        DxT=[1;reshape(DC([lags+tau-1:-1:lags+tau-lags],:)',k-1,1)]';
        SDxT=[1;reshape(SDC([lags+tau-1:-1:lags+tau-lags],:)',k-1,1)]';
        DC(lags+tau,:)=DxT*beta;
        SDC(lags+tau,:)=SDxT*beta+shocks(tau,s)*G(:,s)';
    end
    store_DC(:,:,i)=DC(lags+1:end,:);
    store_SDC(:,:,i)=SDC(lags+1:end,:);
end
r.DC=store_DC;
r.SDC=store_SDC;
r.SHOCKS=store_SHOCKS;

    
% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
