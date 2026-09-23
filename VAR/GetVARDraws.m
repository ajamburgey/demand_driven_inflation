% GetVARDraws: GDP (Q) and CPI (P) -- demand and supply.
%
% Demand shocks move GDP and prices in the same direction, supply shocks in
% opposite directions, signs on impact. United States first, then the euro
% area.

close all
clear
addpath(genpath('aux'))
addpath(genpath('GLP_PrePostCovid_ConstantCoeff'))
LoadData

lags   = 4;
Ndraws = 10000;
initialT = find(dates=='01-jan-1997');           % estimation starts 1997 (the euro-area
                                             % price detail begins) and ends 2019:Q4
                                               % (pre covid), in both economies
% variable order: GDP, consumer prices
shocks = ["Demand","Supply"];
SignRestrictions = [[1 1]' [1 -1]'];           % columns: shocks; rows: GDP, CPI
fd  = [1 1];                                   % display flag: 1 = year-on-year change
fT0 = [0 0];                                   % 1 = level relative to the origin (unused here)
ColorBars = [[0.9290 0.6940 0.1250];[0.4660 0.6740 0.1880]];

%% United States
y      = [USgdp UScpi];
series = ["US GDP","US CPI"];
labelY = ["100 x log change relative to year ago","100 x log change relative to year ago"];

y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

rng(5) %Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',3.5);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws);
save(fullfile('draws','PQus_draws.mat'), 'BETA','G','acc','y','dts', ...
     'lags','fd','fT0','series','labelY','shocks','ColorBars');

fprintf('%s: %d accepted draws saved\n', mfilename, acc);

%% Euro area
y      = [EAgdp EAhicp];
series = ["EA GDP","EA HICP"];
labelY = ["100 x log change relative to year ago","100 x log change relative to year ago"];

y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

rng(5) %Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',1.5);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws);
save(fullfile('draws','PQea_draws.mat'), 'BETA','G','acc','y','dts', ...
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
