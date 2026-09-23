% GetVARDrawsRF: GDP, CPI, the one-year interest rate and the primary
% deficit -- monetary, fiscal and other demand shocks, and supply.
%
% All three demand shocks move GDP and prices in the same direction, supply
% in opposite directions. The signs of the two policy instruments identify
% the demand shocks: monetary policy shocks LOWER the rate with the deficit
% falling; the remaining demand shocks RAISE the rate, reflecting the
% systematic response of monetary policy; fiscal shocks RAISE the deficit,
% other demand shocks lower it through the automatic stabilizers.

close all
clear
addpath(genpath('aux'))
addpath(genpath('GLP_PrePostCovid_ConstantCoeff'))
LoadData

lags   = 4;
Ndraws = 10000;
initialT = find(dates=='01-jan-1997');           % US: 1997 to 2019:Q4

% variable order: GDP, consumer prices, one-year rate, primary deficit
shocks = ["Monetary policy","Fiscal policy","Other demand","Supply"];
SignRestrictions = [[1 1 -1 -1]' [1 1 1 1]' [1 1 1 -1]' [1 -1 0 0]'];
SignRestrictions = repmat(SignRestrictions, [1 1 4]);   % all signs held, quarters 1 to 4
fd  = [1 1 0 0];                               % display flag: 1 = year-on-year change (rates in levels)
fT0 = [0 0 0 0];                               % 1 = level relative to the origin (unused here)
ColorBars = [[0.80 0.52 0.04];[0.9290 0.6940 0.1250];[0.99 0.86 0.49];[0.4660 0.6740 0.1880]];   % paper palette: monetary, fiscal, other demand, supply

%% United States
y      = [USgdp UScpi UStb1 USdef];
series = ["US GDP","US CPI","US interest rate","US primary deficit"];
labelY = ["100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "percentage points","percent of potential GDP"];

y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

rng(5) % Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',50);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws, [], 1000);
save(fullfile('draws','PQRFus_draws.mat'), 'BETA','G','acc','y','dts', ...
     'lags','fd','fT0','series','labelY','shocks','ColorBars');

fprintf('%s: %d accepted draws saved\n', mfilename, acc);

%% Euro area
y      = [EAgdp EAhicp EAeuribor1 EAdef];
series = ["EA GDP","EA HICP","EA interest rate","EA primary deficit"];
labelY = ["100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "percentage points","percent of trend GDP"];

% the EA deficit starts in 2002:Q4 and lags the other series at the end:
% cut the trailing quarters without it and start the estimation in 2002:Q4
% (not 1997 as in the other exercises)
T2  = find(all(isfinite(y),2),1,'last');
y   = y(find(dates=='01-oct-2002'):T2,:);
dts = dates(find(dates=='01-oct-2002'):T2);
T0  = find(dts=='01-oct-2019');

rng(5) % Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',60);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws, [], 1000);
save(fullfile('draws','PQRFea_draws.mat'), 'BETA','G','acc','y','dts', ...
     'lags','fd','fT0','series','labelY','shocks','ColorBars');

fprintf('%s: %d accepted draws saved\n', mfilename, acc);

% the hyperparameter optimizer (csminwel, inside bvarGLP) leaves scratch
% files in the working directory; remove them
for f = {'g1.mat','g2.mat','g3.mat','H.dat'}
    if isfile(f{1}); delete(f{1}); end
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
