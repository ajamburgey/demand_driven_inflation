% Figure12: prior and posterior of the demand share of the cumulative
% forecast error of year-on-year inflation over the inflation surge
% (2021:Q1-2023:Q4 for the US, 2021:Q3-2024:Q2 for the EA, relative to a
% 2019:Q4 forecast origin). Four rows: the baseline model, a flat prior on
% the share, transitory demand, and the Baumeister and Hamilton (2015)
% model.
%
% The three perturbations:
%   flat prior      the induced prior of the share is replaced by a flat
%                   prior
%   transitory      only draws in which the response of GDP to a demand
%                   shock after 20 quarters is at most one tenth of its
%                   maximum response over the first two years are kept,
%                   prior and posterior alike.
%   BH              the Baumeister-Hamilton model estimated with their
%                   algorithm: Student t priors on the two elasticities
%                   (modes +1 supply and -1 demand, scale 0.6, 3 degrees
%                   of freedom, truncated to the sign)


close all
clear
addpath(genpath('aux'))
rng(5)

NPRIOR = 5000;                                 % prior draws, baseline and BH
NPRTRAN = 30000;                               % prior draws, transitory (few survive)
SR  = [1 1; 1 -1];
RF  = [-3 4];                                  % support of the flat prior
gg  = linspace(-1, 2, 600);                    % plotting window

%% United States
r  = load(fullfile('draws','PQus_draws.mat'));
T0 = find(r.dts=='01-oct-2019');
w1 = datetime(2021,1,1);                       % the US inflation surge
w2 = datetime(2023,10,1);

% baseline: the posterior shares from the saved draws, the prior shares
% from the prior sampler
basePostUS = Shares(r.y, r.lags, r.dts, r.BETA, r.G, T0, w1, w2);
[BETAp, Gp] = GetVARPriorDrawsPQ(r.y(1:T0,:), r.lags, NPRIOR, 10, SR);
basePriUS = Shares(r.y, r.lags, r.dts, BETAp, Gp, T0, w1, w2);

% flat prior on the share, by importance reweighting of the posterior
[flatPostUS, flatWUS] = FlatReweight(basePriUS, basePostUS, RF, 'United States');

% transitory demand: keep only the draws with a transitory GDP response,
% posterior and prior alike
keep = TransitoryDraws(r.BETA, r.G);
tranPostUS = Shares(r.y, r.lags, r.dts, r.BETA(:,:,keep), r.G(:,:,keep), T0, w1, w2);
[BETAp, Gp] = GetVARPriorDrawsPQ(r.y(1:T0,:), r.lags, NPRTRAN, 10, SR);
keepP = TransitoryDraws(BETAp, Gp);
tranPriUS = Shares(r.y, r.lags, r.dts, BETAp(:,:,keepP), Gp(:,:,keepP), T0, w1, w2);
fprintf('United States transitory: posterior keeps %d of %d, prior keeps %d of %d\n', ...
    sum(keep), numel(keep), sum(keepP), numel(keepP));

% the Baumeister-Hamilton model
[bhPostUS, bhPriUS] = BHShares(r.y, r.lags, r.dts, T0, w1, w2, NPRIOR, 'United States');

%% Euro area
r  = load(fullfile('draws','PQea_draws.mat'));
T0 = find(r.dts=='01-oct-2019');
w1 = datetime(2021,7,1);                       % the EA surge, two quarters later
w2 = datetime(2024,4,1);

%baseline
basePostEA = Shares(r.y, r.lags, r.dts, r.BETA, r.G, T0, w1, w2);
[BETAp, Gp] = GetVARPriorDrawsPQ(r.y(1:T0,:), r.lags, NPRIOR, 10, SR);
basePriEA = Shares(r.y, r.lags, r.dts, BETAp, Gp, T0, w1, w2);

%flat prior on share
[flatPostEA, flatWEA] = FlatReweight(basePriEA, basePostEA, RF, 'Euro area');

%transitory demand
keep = TransitoryDraws(r.BETA, r.G);
tranPostEA = Shares(r.y, r.lags, r.dts, r.BETA(:,:,keep), r.G(:,:,keep), T0, w1, w2);
[BETAp, Gp] = GetVARPriorDrawsPQ(r.y(1:T0,:), r.lags, NPRTRAN, 10, SR);
keepP = TransitoryDraws(BETAp, Gp);
tranPriEA = Shares(r.y, r.lags, r.dts, BETAp(:,:,keepP), Gp(:,:,keepP), T0, w1, w2);
fprintf('Euro area transitory: posterior keeps %d of %d, prior keeps %d of %d\n', ...
    sum(keep), numel(keep), sum(keepP), numel(keepP));

[bhPostEA, bhPriEA] = BHShares(r.y, r.lags, r.dts, T0, w1, w2, NPRIOR, 'Euro area');

%save all draws
save(fullfile('draws','AppendixShares_draws.mat'), ...
     'basePostUS','basePriUS','flatPostUS','flatWUS','tranPostUS','tranPriUS','bhPostUS','bhPriUS', ...
     'basePostEA','basePriEA','flatPostEA','flatWEA','tranPostEA','tranPriEA','bhPostEA','bhPriEA');

%% Make figure
BLU = [44 127 184]/255;
RED = [.8941 .1020 .1098];

% densities on the plotting window, one per panel
basePriUSd  = ShareDensity(basePriUS,  [], gg);
basePostUSd = ShareDensity(basePostUS, [], gg);
basePriEAd  = ShareDensity(basePriEA,  [], gg);
basePostEAd = ShareDensity(basePostEA, [], gg);
flatPrid    = ones(size(gg))/(RF(2)-RF(1));    % the flat prior on [-3, 4]
flatPostUSd = ShareDensity(flatPostUS, flatWUS, gg);
flatPostEAd = ShareDensity(flatPostEA, flatWEA, gg);
tranPriUSd  = ShareDensity(tranPriUS,  [], gg);
tranPostUSd = ShareDensity(tranPostUS, [], gg);
tranPriEAd  = ShareDensity(tranPriEA,  [], gg);
tranPostEAd = ShareDensity(tranPostEA, [], gg);
bhPriUSd    = ShareDensity(bhPriUS,    [], gg);
bhPostUSd   = ShareDensity(bhPostUS,   [], gg);
bhPriEAd    = ShareDensity(bhPriEA,    [], gg);
bhPostEAd   = ShareDensity(bhPostEA,   [], gg);

% common y axis within each row
ymax1 = max([basePriUSd basePostUSd basePriEAd basePostEAd]);
ymax2 = max([flatPrid   flatPostUSd flatPrid   flatPostEAd]);
ymax3 = max([tranPriUSd tranPostUSd tranPriEAd tranPostEAd]);
ymax4 = max([bhPriUSd   bhPostUSd   bhPriEAd   bhPostEAd]);

figure('Position',[0 0 1150 1560], 'Visible','off') %visibility off to prevent monitor size from truncating

subplot(4,2,1)                                 % (a) US, baseline, with the legend
SharePanel(gg, basePriUSd, basePostUSd, BLU, ymax1, '(a) US baseline')
x0 = -0.9;  yl = ymax1*1.05;
plot([x0 x0+0.45], 0.945*yl*[1 1], '--', 'Color', 0.55*BLU, 'LineWidth', 2.0);
text(x0+0.55, 0.945*yl, 'prior', 'FontSize', 13);
patch([x0 x0+0.45 x0+0.45 x0], yl*[0.82 0.82 0.885 0.885], BLU, ...
      'FaceAlpha', 0.55, 'EdgeColor', 0.45*BLU);
text(x0+0.55, 0.8525*yl, 'posterior', 'FontSize', 13);

subplot(4,2,2)                                 % (b) EA, baseline
SharePanel(gg, basePriEAd, basePostEAd, RED, ymax1, '(b) EA baseline')

subplot(4,2,3)                                 % (c) US, flat prior
SharePanel(gg, flatPrid, flatPostUSd, BLU, ymax2, '(c) US flat prior on the share')

subplot(4,2,4)                                 % (d) EA, flat prior
SharePanel(gg, flatPrid, flatPostEAd, RED, ymax2, '(d) EA flat prior on the share')

subplot(4,2,5)                                 % (e) US, transitory demand
SharePanel(gg, tranPriUSd, tranPostUSd, BLU, ymax3, '(e) US transitory demand')

subplot(4,2,6)                                 % (f) EA, transitory demand
SharePanel(gg, tranPriEAd, tranPostEAd, RED, ymax3, '(f) EA transitory demand')

subplot(4,2,7)                                 % (g) US, Baumeister-Hamilton
SharePanel(gg, bhPriUSd, bhPostUSd, BLU, ymax4, '(g) US Baumeister-Hamilton')

subplot(4,2,8)                                 % (h) EA, Baumeister-Hamilton
SharePanel(gg, bhPriEAd, bhPostEAd, RED, ymax4, '(h) EA Baumeister-Hamilton')

%export
exportgraphics(gcf, fullfile('results','Figure12.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
%% Functions

function s = Shares(y, lags, dts, BETA, G, T0, w1, w2)
% Shares  The demand share of the cumulative forecast error of
% year-on-year inflation over the surge window, one share per draw.
% INPUT   y, lags, dts    the data, lag order and dates of the model
%         BETA, G         accepted lag coefficients and impact matrices
%         T0              position of the forecast origin (2019:Q4)
%         w1, w2          first and last quarter of the surge window
% OUTPUT  s               1 x draws vector of demand shares
[T, n] = size(y);
acc = size(G,3);
SDC = NaN(T-T0, n, acc, n);
for jj = 1:n
    hd = HD(y(T0+1-lags:end,:), lags, BETA, G, jj*ones(acc,1));
    SDC(:,:,:,jj) = hd.SDC;
end
DC   = hd.DC;                              % no-shock forecast, identical for every jj
fd   = ones(1,n);
dSDC = SDC - cat(1, repmat(y(T0+1-4:T0,:),1,1,acc,n), SDC(1:end-4,:,:,:)).*repmat(fd,T-T0,1,acc,n);
dDC  = DC  - cat(1, repmat(y(T0+1-4:T0,:),1,1,acc),   DC(1:end-4,:,:)).*repmat(fd,T-T0,1,acc);
v    = 2;                                      % prices are the second variable
dem  = squeeze(dSDC(:,v,:,1) - dDC(:,v,:));
sup  = squeeze(dSDC(:,v,:,2) - dDC(:,v,:));
pd   = dts(T0+1:T).';
win  = pd >= w1 & pd <= w2;
s    = sum(dem(win,:),1) ./ (sum(dem(win,:),1) + sum(sup(win,:),1));
end

function keep = TransitoryDraws(BETA, G)
% TransitoryDraws  The draws in which the response of GDP to a demand
% shock after 20 quarters is at most one tenth of its maximum response
% over the first two years.
keep = false(1, size(G,3));
for m = 1:size(G,3)
    Rd = computeIRFs(BETA(:,:,m), G(:,:,m), 1, 20);
    keep(m) = abs(Rd(20,1)) <= 0.1*max(Rd(1:8,1));
end
end

function [sPost, w] = FlatReweight(sPri, sPost, RF, name)
% FlatReweight  Importance weights that turn the induced prior of the
% share into a flat prior on RF = [-3, 4]: one over a kernel estimate of
% the induced prior density at each posterior draw, with the density
% floored at its 2nd percentile so no single draw dominates.
% OUTPUT  sPost   the posterior draws inside RF
%         w       their importance weights
sPri  = sPri(:);
sPost = sPost(:);
pts = linspace(RF(1), RF(2), 280);
f   = ksdensity(sPri(sPri>=RF(1) & sPri<=RF(2)), pts, 'Bandwidth', 0.08);
fl  = quantile(f, 0.02);
inR = sPost >= RF(1) & sPost <= RF(2);
sPost = sPost(inR);
w   = 1./max(interp1(pts, f, sPost, 'linear'), fl);
fprintf('%s flat: weighted median %.2f, P(>1/2) %.3f, ESS %.0f of %d\n', ...
    name, WeightedQuantile(sPost, w, .5), sum(w(sPost>.5))/sum(w), ...
    sum(w)^2/sum(w.^2), numel(w));
end

function m = WeightedQuantile(s, w, p)
% WeightedQuantile  Quantile p of draws s under importance weights w.
[ss, ix] = sort(s(:));
ww = w(ix)/sum(w);
cw = cumsum(ww);
m = ss(find(cw >= p, 1));
end

function f = ShareDensity(v, w, gg)
% ShareDensity  Kernel density on the plotting window: draws outside are
% dropped and the curve is not rescaled, so the plotted area equals the
% probability mass inside the window. A weighted version when importance
% weights are supplied.
v = v(:);
in = v >= gg(1) & v <= gg(end);
if isempty(w)
    f = ksdensity(v(in), gg, 'Support', [gg(1)-1e-9 gg(end)+1e-9], ...
                  'BoundaryCorrection', 'reflection');
    f = f*(sum(in)/numel(v));
else
    w = w(:);
    f = ksdensity(v(in), gg, 'Support', [gg(1)-1e-9 gg(end)+1e-9], ...
                  'BoundaryCorrection', 'reflection', 'Weights', w(in));
    f = f*(sum(w(in))/sum(w));
end
end

function SharePanel(gg, dPri, dPost, col, ymax, ttl)
% SharePanel  One panel: posterior as the filled area, prior as the
% dashed line, in the economy's color.
hold on; grid on
fill([gg fliplr(gg)], [dPost zeros(size(gg))], col, ...
     'FaceAlpha', 0.55, 'EdgeColor', 0.45*col, 'LineWidth', 1.2);
plot(gg, dPri, '--', 'Color', 0.55*col, 'LineWidth', 1.6);
xlim([gg(1) gg(end)]); ylim([0 ymax*1.05]); set(gca,'fontsize',13)
title(ttl)
end

function [post, pri] = BHShares(y, lags, dts, T0, w1, w2, NPRIOR, name)
% BHShares  The Baumeister-Hamilton (2015) model estimated on the same
% data and sample as the baseline: demand and supply elasticities with
% truncated Student t priors, their Minnesota prior on the lag
% coefficients, Gamma priors on the inverse structural variances, and a
% random walk Metropolis chain on the elasticities (their equation (59)
% as the target, in the local function BHTarget). Posterior and prior
% share draws come out on the same definition as the baseline.
% INPUT   y, lags, dts, T0, w1, w2   as in Shares
%         NPRIOR                     number of prior draws
%         name                       economy label for printing
% OUTPUT  post, pri                  1 x draws vectors of demand shares
CA = 1;  CB = -1;  SIGT = 0.6;  NUT = 3;       % t priors on the elasticities
KAP = 2;  LAM0 = 0.2;  LAM1 = 1;  LAM3 = 100;  % variance and Minnesota priors
NMH = 2e5;  NBURN = 5e4;  THIN = 10;           % the Metropolis chain

% the regression matrices on the estimation sample
yE = y(1:T0,:);
[TT, n] = size(yE);
k = 1 + n*lags;
x = zeros(TT, k);
x(:,1) = 1;
for i = 1:lags
    x(lags+1:end, 1+(i-1)*n+1:1+i*n) = yE(lags+1-i:end-i, :);
end
X = x(lags+1:end,:);
Y = yE(lags+1:end,:);
T = size(Y,1);

% AR(8) residual variances scale the priors, as in BH
res = NaN(TT-8, n);
for i = 1:n
    xa = ones(TT-8, 9);
    for j = 1:8
        xa(:,1+j) = yE(9-j:end-j,i);
    end
    ar = ols1(yE(9:end,i), xa);
    res(:,i) = ar.resols;
end
Sh = (res'*res)/size(res,1);
s  = diag(Sh);
Bols = (X'*X)\(X'*Y);
U    = Y - X*Bols;
Om   = (U'*U)/T;

% the Minnesota prior as dummy observations appended to X
Mdiag = NaN(k,1);
Mdiag(1) = LAM0^2*LAM3^2;
for j = 1:lags
    for kv = 1:n
        Mdiag(1+(j-1)*n+kv) = LAM0^2/(j^(2*LAM1)*s(kv));
    end
end
Xd = [X; diag(1./sqrt(Mdiag))];
XX = Xd'*Xd;
cXXi = chol(XX\eye(k), 'lower');

% the mode of the target and a proposal scale from its Hessian
a0 = fminsearch(@(al) -BHTarget(al, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP), ...
                [-1; 1], optimset('Display','off'));
a0 = fminsearch(@(al) -BHTarget(al, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP), ...
                a0, optimset('Display','off'));
H  = zeros(2);
h  = 1e-3;
for i = 1:2
    for j = 1:2
        ei = zeros(2,1); ei(i) = h;
        ej = zeros(2,1); ej(j) = h;
        H(i,j) = (BHTarget(a0+ei+ej, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP) ...
                - BHTarget(a0+ei-ej, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP) ...
                - BHTarget(a0-ei+ej, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP) ...
                + BHTarget(a0-ei-ej, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP))/(4*h^2);
    end
end
if all(isfinite(H(:)))
    [Vh, Dh] = eig(-(H+H')/2);
    dh = abs(diag(Dh));
    dh = max(dh, max(dh)*1e-6);
    PL = chol(Vh*diag(dh)*Vh', 'lower');
else
    PL = diag([5 5]);
end

% the random walk Metropolis chain on the elasticities
xi = 1.3;
accMH = 0;
al  = a0;
qal = BHTarget(al, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP);
ALS = NaN(2, (NMH-NBURN)/THIN);
na  = 0;
for it = 1:NMH
    cand = al + xi*(PL'\trnd(2,2,1));
    qc = BHTarget(cand, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP);
    if log(rand) < qc - qal
        al = cand;  qal = qc;  accMH = accMH + 1;
    end
    if it <= NBURN && mod(it,1000)==0          % tune the scale during burn in
        rate = accMH/it;
        if rate < 0.2
            xi = xi*0.9;
        elseif rate > 0.4
            xi = xi*1.1;
        end
    end
    if it > NBURN && mod(it-NBURN,THIN)==0
        na = na + 1;
        ALS(:,na) = al;
    end
end
ALS = ALS(:,1:na);
fprintf('%s BH: MH acceptance %.2f, %d kept draws\n', name, accMH/NMH, na);

% reduced form posterior draws given the elasticities, then the shares
BETAb = NaN(k, n, na);
Gb    = NaN(n, n, na);
for m = 1:na
    [BETAb(:,:,m), Gb(:,:,m)] = BHDraw(ALS(:,m), Y, Xd, XX, cXXi, Sh, T, k, n, KAP);
end
post = Shares(y, lags, dts, BETAb, Gb, T0, w1, w2);

% prior draws: elasticities from the truncated t priors, the rest from
% the conjugate priors
BETAp = NaN(k, n, NPRIOR);
Gp    = NaN(n, n, NPRIOR);
np = 0;
while np < NPRIOR
    as = CA + SIGT*trnd(NUT);
    if as < 0; continue; end
    ad = CB + SIGT*trnd(NUT);
    if ad > 0; continue; end
    np = np + 1;
    [BETAp(:,:,np), Gp(:,:,np)] = BHPriorDraw([ad; as], Sh, Mdiag, k, n, KAP);
end
pri = Shares(y, lags, dts, BETAp, Gp, T0, w1, w2);
end

function qv = BHTarget(al, Y, Xd, XX, Sh, Om, T, k, n, CA, CB, SIGT, NUT, KAP)
% BHTarget  The BH (2015) target, their equation (59), up to additive
% constants, for al = (demand elasticity, supply elasticity).
ad = al(1);
as = al(2);
if ad > 0 || as < 0
    qv = -inf;
    return
end
Amat = [1 -ad; 1 -as];
lp = -((NUT+1)/2)*(log(1+((ad-CB)/SIGT)^2/NUT) + log(1+((as-CA)/SIGT)^2/NUT));
qv = lp + T*log(abs(det(Amat))) + (T/2)*log(det(Om));
for i = 1:n
    ai  = Amat(i,:)';
    tau = KAP*(ai'*Sh*ai);
    mi  = zeros(k,1);
    mi(2:1+n) = ai;                            % random walk mean
    Yd  = [Y*ai; (Xd(T+1:end,:))*mi];
    bh  = XX\(Xd'*Yd);
    zst = Yd'*Yd - Yd'*Xd*bh;
    qv  = qv + KAP*log(tau) - (KAP+T/2)*log(tau + zst/2);
end
end

function [BETA, G] = BHDraw(al, Y, Xd, XX, cXXi, Sh, T, k, n, KAP)
% BHDraw  One posterior draw of the lag coefficients and variances given
% the elasticities, mapped to reduced form.
Amat = [1 -al(1); 1 -al(2)];
Bs = NaN(n, k);
d  = NaN(n,1);
for i = 1:n
    ai  = Amat(i,:)';
    tau = KAP*(ai'*Sh*ai);
    mi  = zeros(k,1);
    mi(2:1+n) = ai;
    Yd  = [Y*ai; (Xd(T+1:end,:))*mi];
    bh  = XX\(Xd'*Yd);
    zst = Yd'*Yd - Yd'*Xd*bh;
    del = gamrnd(KAP + T/2, 1/(tau + zst/2));
    d(i) = 1/del;
    Bs(i,:) = (bh + sqrt(d(i))*(cXXi*randn(k,1)))';
end
BETA = (Amat\Bs)';
G    = Amat\diag(sqrt(d));
end

function [BETA, G] = BHPriorDraw(al, Sh, Mdiag, k, n, KAP)
% BHPriorDraw  One draw from the BH prior given the elasticities, mapped
% to reduced form.
Amat = [1 -al(1); 1 -al(2)];
Bs = NaN(n, k);
d  = NaN(n,1);
for i = 1:n
    ai  = Amat(i,:)';
    tau = KAP*(ai'*Sh*ai);
    del = gamrnd(KAP, 1/tau);
    d(i) = 1/del;
    mi  = zeros(k,1);
    mi(2:1+n) = ai;
    Bs(i,:) = (mi + sqrt(d(i))*(sqrt(Mdiag).*randn(k,1)))';
end
BETA = (Amat\Bs)';
G    = Amat\diag(sqrt(d));
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
