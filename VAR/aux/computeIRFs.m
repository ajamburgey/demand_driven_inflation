function irf = computeIRFs(beta,G,nshock,hmax);
% computes IRFs up to horizon hmax based on beta and G (structural, uses G directly).
% NB: an earlier version of this function was called bvarIrfs, the same name as
% the Cholesky-based GLP subroutine elsewhere on the path; it is renamed to the
% filename so the two can never shadow each other.

[k,n] = size(beta);
lags = (k-1)/n;

% computation of IRFs 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y=zeros(lags+hmax,n);
in=lags;
vecshock=zeros(n,1); vecshock(nshock)=1;
for tau=1:hmax
    xT=[reshape(Y([in+tau-1:-1:in+tau-lags],:)',k-1,1)]';
    Y(in+tau,:)=xT*beta(2:end,:)+(tau==1)*(G*vecshock)';
end
irf = Y(in+1:end,:);
% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
