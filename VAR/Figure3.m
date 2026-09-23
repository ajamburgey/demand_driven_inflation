% Figure3: US demand-supply-covid decomposition of GDP growth and inflation
% using the Stock-Watson covid factor, two ways -- purging the identified
% shocks (top row) and purging the variables' growth rates themselves
% before decomposing (bottom row).

close all
clear
addpath(genpath('aux'))
addpath(genpath('GLP_PrePostCovid_ConstantCoeff'))   % lag.m, used by ControlCovid.m and HD.m

load(fullfile('draws','PQus_draws.mat'), 'BETA','G','y','dts','lags');
M = size(G,3); idx = round(linspace(1,M,min(3000,M))); BETA = BETA(:,:,idx); G = G(:,:,idx);

% Stock-Watson covid factor
T0 = find(dts=='01-oct-2019'); T = size(y,1);
pk = year(dts)*4 + quarter(dts); pk = pk(:);
Cm = load(fullfile('data','SWcovid_quarterly.mat')); Tc = Cm.T;
COVfull = zeros(T,1);                               % rep = quarterly average of cfac
for t = 1:T
    COVfull(t) = pickq(Tc.qk, Tc.rep, pk(t));
end
inwin = pk>=2020*4+1 & pk<=2023*4+1; COVfull(~inwin) = 0;   % covid window 2020Q1-2023Q1
nlag  = 4;                                          % contemporaneous + 4 lags

% (top row) purge the identified shocks
r  = ControlCovid(y, lags, dts, BETA, G, COVfull(T0+1:T), nlag, inwin(T0+1:T));
CV = r.CVdy + r.CVsy;                               % single covid contribution

% (bottom row) purge the variables' growth rates and use the residuals
dy = diff(y);                                       % row t is growth into quarter t+1
X  = ones(T-1, 1+nlag+1);
for l = 0:nlag
    z = zeros(T,1);
    z(1+l:end) = COVfull(1:end-l);
    X(:,2+l) = z(2:end);
end
fitted = NaN(T-1,2);
for i = 1:2
    b = X \ dy(:,i);
    fitted(:,i) = X(:,2:end)*b(2:end);               % the covid part only
end
yc = y;
yc(T0+1:end,:) = y(T0,:) + cumsum(dy(T0:end,:) - fitted(T0:end,:), 1);

acc = size(G,3);
SDC = NaN(T-T0, 2, acc, 2);
for jj = 1:2
    hd = HD(yc(T0+1-lags:end,:), lags, BETA, G, jj*ones(acc,1));
    SDC(:,:,:,jj) = hd.SDC;
end
DC   = hd.DC;                                        % no-shock forecast, identical for every jj
dSDC = SDC - cat(1, repmat(yc(T0+1-4:T0,:),1,1,acc,2), SDC(1:end-4,:,:,:));
dDC  = DC  - cat(1, repmat(yc(T0+1-4:T0,:),1,1,acc),   DC(1:end-4,:,:));
dem  = [mean(squeeze(dSDC(:,1,:,1) - dDC(:,1,:)), 2), ...
        mean(squeeze(dSDC(:,2,:,1) - dDC(:,2,:)), 2)];
sup  = [mean(squeeze(dSDC(:,1,:,2) - dDC(:,1,:)), 2), ...
        mean(squeeze(dSDC(:,2,:,2) - dDC(:,2,:)), 2)];
fc   = [mean(squeeze(dDC(:,1,:)), 2), mean(squeeze(dDC(:,2,:)), 2)];
actR = y(T0+1:end,:)  - y(T0+1-4:end-4,:);           % raw year-on-year change
actC = yc(T0+1:end,:) - yc(T0+1-4:end-4,:);          % cleaned year-on-year change
covB = actR - actC;                                  % the covid bar, deterministic
pdq  = dts(T0+1:T);

% ---- check numbers: shares of cumulative excess US CPI inflation, both ways ----
win  = pdq>=datetime(2021,1,1) & pdq<=datetime(2023,10,1);
totP = sum(r.acty(win,2) - r.DCy(win,2));
totK = sum(actR(win,2) - fc(win,2));
fprintf('shares of cumulative excess US CPI inflation 2021Q1-2023Q4:\n');
fprintf('                    covid    demand   supply   demand share ex covid\n');
fprintf('purged shocks     %7.3f %8.3f %8.3f %10.3f\n', ...
    sum(CV(win,2))/totP, sum(r.CDy(win,2))/totP, sum(r.CSy(win,2))/totP, ...
    sum(r.CDy(win,2))/(sum(r.CDy(win,2))+sum(r.CSy(win,2))));
fprintf('purged variables  %7.3f %8.3f %8.3f %10.3f\n', ...
    sum(covB(win,2))/totK, sum(dem(win,2))/totK, sum(sup(win,2))/totK, ...
    sum(dem(win,2))/(sum(dem(win,2))+sum(sup(win,2))));

% ---- draw ----
BLUE = [44 127 184]/255;
BARS = [0.9290 0.6940 0.1250;    % demand (yellow)
        0.4660 0.6740 0.1880;    % supply (green)
        0        0        0    ]; % covid (black)
YLAB = '100 x log change relative to year ago';
GDPLIM = [-16 16];  PRICELIM = [-5 11];
x0 = r.pdates(1) - calmonths(2);
x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

figure('Position',[0 0 1150 860])

subplot(2,2,1)                                       % (a) US GDP, purged shocks
BarGraph(r.acty(:,1), r.DCy(:,1), [r.CDy(:,1) r.CSy(:,1) CV(:,1)], r.pdates, BLUE, BARS);
xlim([x0 x1]); ylim(GDPLIM); grid on; set(gca,'fontsize',13)
title('(a) US GDP, purged shocks'); ylabel(YLAB)
h = get(gca,'Children');
legend(h([2 1 end:-1:end-2]), {'Actual','Model forecast as of 2019:Q4','Demand','Supply','Covid'}, ...
       'Location','NorthEast','FontSize',9); legend boxoff

subplot(2,2,2)                                       % (b) US CPI, purged shocks
BarGraph(r.acty(:,2), r.DCy(:,2), [r.CDy(:,2) r.CSy(:,2) CV(:,2)], r.pdates, BLUE, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(b) US CPI, purged shocks'); ylabel(YLAB)

subplot(2,2,3)                                       % (c) US GDP, purged variables
BarGraph(100*actR(:,1), 100*fc(:,1), 100*[dem(:,1) sup(:,1) covB(:,1)], pdq, BLUE, BARS);
xlim([x0 x1]); ylim(GDPLIM); grid on; set(gca,'fontsize',13)
title('(c) US GDP, purged variables'); ylabel(YLAB)

subplot(2,2,4)                                       % (d) US CPI, purged variables
BarGraph(100*actR(:,2), 100*fc(:,2), 100*[dem(:,2) sup(:,2) covB(:,2)], pdq, BLUE, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(d) US CPI, purged variables'); ylabel(YLAB)

%export
exportgraphics(gcf, fullfile('results','Figure3.pdf'), 'ContentType','vector');

% -------------------------------------------------------------------------
%% Functions
function v = pickq(keys, vals, kk)
  j = find(keys==kk,1); if isempty(j)||~isfinite(vals(j)), v = 0; else, v = vals(j); end
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
