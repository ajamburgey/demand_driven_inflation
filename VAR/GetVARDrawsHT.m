% GetVARDrawsHT: GDP, prices ex energy and the two energy prices --
% demand, non-energy supply and two energy supply shocks.
%
% Demand moves GDP and all prices in the same direction. Non-energy supply
% moves GDP and core prices in opposite directions with energy prices up.
% Each energy shock raises GDP and lowers AT LEAST ONE of the two energy
% prices, and the two energy shocks must move at least one energy price in
% opposite directions, so they are not the same shock.

close all
clear
addpath(genpath('aux'))
addpath(genpath('GLP_PrePostCovid_ConstantCoeff'))
LoadData

lags   = 4;
Ndraws = 10000;
initialT = find(dates=='01-jan-1997');           % 1997 to 2019:Q4, as in PQ.m

% variable order: GDP, prices ex energy, TRANSPORT energy, HOUSEHOLD energy
shocks = ["Demand","Non-energy supply","Energy supply 1","Energy supply 2"];
SignRestrictions = [[1 1 1 1]' [1 -1 1 1]' [1 0 0 0]' [1 0 0 0]'];
SignRestrictions = repmat(SignRestrictions, [1 1 4]);   
ExtraRestrictions = @EnergySigns;
fd  = [1 1 1 1];                               % display flag: 1 = year-on-year change
fT0 = [0 0 0 0];                               % 1 = level relative to the origin (unused here)
ColorBars = [[0.9290 0.6940 0.1250];[0.30 0.45 0.12];[0.64 0.79 0.38];[0.64 0.79 0.38]];   % paper palette: demand, non-energy supply, energy supply (x2, exchangeable)

%% United States
y      = [USgdp UScpiexen UScpitren UScpihhen];
series = ["US GDP","US CPI ex energy","US CPI tr energy","US CPI hh energy"];
labelY = ["100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "100 x log change relative to year ago"];

y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

rng(5) %Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',25);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws, ExtraRestrictions);
save(fullfile('draws','PQHTus_draws.mat'), 'BETA','G','acc','y','dts', ...
     'lags','fd','fT0','series','labelY','shocks','ColorBars');   % the expensive object: charts rerun from this

fprintf('%s: %d accepted draws saved\n', mfilename, acc);

%% Euro area
y      = [EAgdp EAhicpexen EAhicptren EAhicphhen];
series = ["EA GDP","EA HICP ex energy","EA HICP tr energy","EA HICP hh energy"];
labelY = ["100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "100 x log change relative to year ago", ...
          "100 x log change relative to year ago"];

y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

rng(5) %Note: changing seeds may require retuning MCMCconst to get a reasonable acceptance rate due to a new starting point.

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',5);
fprintf('  MH acceptance rate %.3f\n', resGLP.mcmc.ACCrate);
[BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws, ExtraRestrictions);
save(fullfile('draws','PQHTea_draws.mat'), 'BETA','G','acc','y','dts', ...
     'lags','fd','fT0','series','labelY','shocks','ColorBars');   % the expensive object: charts rerun from this

fprintf('%s: %d accepted draws saved\n', mfilename, acc);

% the hyperparameter optimizer (csminwel, inside bvarGLP) leaves scratch
% files in the working directory; remove them
for f = {'g1.mat','g2.mat','g3.mat','H.dat'}
    if isfile(f{1}); delete(f{1}); end
end

% -------------------------------------------------------------------------
%% Functions

function tf = EnergySigns(IRFs)
% each energy shock (columns 3,4) lowers at least one energy price (rows 3,4)
% in every restricted quarter, and the two shocks differ in at least one
% energy-price sign on impact so neither is a relabeling of the other
  tf = any(sign(IRFs(3:4,3,1)) ~= sign(IRFs(3:4,4,1)));
  for h = 1:size(IRFs,3)
      ok3 = IRFs(3,3,h) < 0 || IRFs(4,3,h) < 0;      % energy shock 1
      ok4 = IRFs(3,4,h) < 0 || IRFs(4,4,h) < 0;      % energy shock 2
      tf  = tf && ok3 && ok4;
  end
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
