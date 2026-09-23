function out = ControlCovid(y, lags, dates, BETA, G, cov, nlag, regwin)
% ControlCovid: control the historical decomposition for the Stock-Watson covid
% factor, draw by draw, and split the post-2019 history into cleaned demand,
% cleaned supply and a covid component.
%
% METHOD (this is the important part).
%   We work DRAW BY DRAW and average the CONTRIBUTIONS, so the output is the
%   posterior mean of each contribution. This is the same object as the baseline
%   Figure 2 (which also reports posterior means), and it is the correct approach
%   for a sign-identified VAR: each accepted draw carries its own rotation, there
%   is no single "median rotation", and the map from parameters to contributions
%   is non-linear, so the average of the contributions is not the contribution at
%   the average parameters.
%
%   For each accepted draw i = 1..M:
%     (1) take that draw's reduced-form coefficients beta = BETA(:,:,i) and its
%         rotation Gi = G(:,:,i);
%     (2) form that draw's structural shocks   e = (y - x*beta) / Gi'  (demand, supply);
%     (3) build that draw's impulse responses and its 2019:Q4 forecast;
%     (4) regress each shock on the covid factor cov and its lags 0:nlag over the
%         window regwin, and keep the fitted part (no intercept) as the covid piece
%         of the shock. This is the Stock-Watson Theta_FC(L) step;
%     (5) the cleaned (the paper's purged) shock is the residual; contributions are the impulse responses
%         convolved with the cleaned shocks (demand, supply) and with the covid
%         piece (covid via the demand channel, covid via the supply channel).
%   The contributions are summed over draws and divided by M at the end.
%
% INPUT   y, lags, dates   the data as passed to PQ, and the quarterly dates
%         BETA, G          the accepted PQ draws from SignRestrict (. x . x M)
%         cov              the covid factor on the post-2019 grid (T-T0 x 1),
%                          already set to zero outside the covid window by the caller
%         nlag             lags 0:nlag of cov enter the projection
%         regwin           logical (T-T0 x 1), the window used to fit the projection
%
% OUTPUT  out.CDy, out.CSy      year-on-year contributions of cleaned demand, supply
%         out.CVdy, out.CVsy    year-on-year covid contribution, demand and supply channel
%         out.DCy, out.acty     the 2019:Q4 forecast and the actual, year-on-year
%         out.pdates           the post-2019 dates
%         out.BM, out.R2       across-draw mean projection coefficients and R2 (for info)

T0 = find(dates=='01-oct-2019');
[T, n] = size(y);
M = size(G, 3);
H = T - T0;                                          % number of post-2019 quarters

% regressors of the reduced-form VAR (constant and lags)
k = lags*n + 1;
x = zeros(T,k); x(:,1) = 1;
for i = 1:lags, x(:,1+(i-1)*n+1:1+i*n) = lag(y,i); end
x = x(lags+1:end,:);

% the covid factor and its lags 0:nlag, on the post-2019 grid
Z = zeros(H, nlag+1);
for j = 0:nlag
    Z(:,j+1) = [zeros(j,1); cov(1:end-j)];
end

CD = zeros(H,n); CS = zeros(H,n);                    % cleaned demand, cleaned supply
CVd = zeros(H,n); CVs = zeros(H,n);                  % covid via demand, covid via supply
DCm = zeros(H,n); SHm = zeros(H,n); REM = zeros(H,n);
BM = zeros(n,nlag+1); R2 = zeros(1,n);

for i = 1:M
    beta = BETA(:,:,i); Gi = G(:,:,i);
    e  = (y(lags+1:end,:) - x*beta) / (Gi');         % structural shocks [demand supply]
    ep = e(T0+1-lags:T-lags, :);                     % post-2019 shocks (H x n)

    % impulse responses from the reduced-form moving average, rotated by Gi
    B = cell(lags,1); for l=1:lags, B{l} = beta(1+(l-1)*n+1:1+l*n,:).'; end
    Psi = cell(H,1); Psi{1} = eye(n);
    for h = 2:H, S = zeros(n); for l=1:min(h-1,lags), S = S + B{l}*Psi{h-l}; end; Psi{h} = S; end
    IRF = zeros(n,n,H); for h=1:H, IRF(:,:,h) = Psi{h}*Gi; end

    % 2019:Q4 deterministic forecast (the VAR run forward with no shocks)
    DC = [y(T0-lags+1:T0,:); zeros(H,n)];
    for tau=1:H, DxT=[1; reshape(DC(lags+tau-1:-1:tau,:)',k-1,1)]'; DC(lags+tau,:)=DxT*beta; end
    DCm = DCm + DC(lags+1:end,:);

    % project each shock on the covid factor and its lags, keep the fitted covid piece
    rem = zeros(H,n);
    for is = 1:n
        b = [ones(sum(regwin),1) Z(regwin,:)] \ ep(regwin,is);
        rem(:,is) = Z*b(2:end);                      % covid piece of shock is (no intercept)
        BM(is,:)  = BM(is,:) + b(2:end)';
        R2(is)    = R2(is) + 1 - sum((ep(regwin,is)-[ones(sum(regwin),1) Z(regwin,:)]*b).^2) ...
                                 / sum((ep(regwin,is)-mean(ep(regwin,is))).^2);
    end
    cln = ep - rem;                                  % cleaned shocks
    SHm = SHm + ep; REM = REM + rem;

    % contributions: impulse responses convolved with the shock series
    for v = 1:n
        CD(:,v)  = CD(:,v)  + filter(squeeze(IRF(v,1,:)),1,cln(:,1));
        CS(:,v)  = CS(:,v)  + filter(squeeze(IRF(v,2,:)),1,cln(:,2));
        CVd(:,v) = CVd(:,v) + filter(squeeze(IRF(v,1,:)),1,rem(:,1));
        CVs(:,v) = CVs(:,v) + filter(squeeze(IRF(v,2,:)),1,rem(:,2));
    end
end
CD=CD/M; CS=CS/M; CVd=CVd/M; CVs=CVs/M; DCm=DCm/M; SHm=SHm/M; REM=REM/M; BM=BM/M; R2=R2/M;

% year-on-year display, as in Decomposition.m / Figure 2
yoy = @(c)[c(1:4,:); c(5:end,:)-c(1:end-4,:)];
out.CDy  = 100*yoy(CD);  out.CSy  = 100*yoy(CS);
out.CVdy = 100*yoy(CVd); out.CVsy = 100*yoy(CVs);
out.acty = 100*(y(T0+1:T,:) - y(T0-3:T-4,:));
out.DCy  = 100*(DCm - [y(T0-3:T0,:); DCm(1:end-4,:)]);
out.pdates = dates(T0+1:T);
out.SHm = SHm; out.cleaned = SHm - REM;
out.BM = BM; out.R2 = R2;
end

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
