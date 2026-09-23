% Figure5: opening the supply box (PQHT), prices ex energy. The two
% energy-supply shocks are summed into one bar.

close all
clear
addpath(genpath('aux'))

%US decomposition
rea = load(fullfile('draws', 'PQHTus_draws.mat'));
us = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%EA decomposition
rea = load(fullfile('draws', 'PQHTea_draws.mat'));
ea = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%Figure settings
BLUE = [44 127 184]/255;  RED = [.8941 .1020 .1098];
BARS = [0.9290 0.6940 0.1250;   % demand            (yellow)
        0.30   0.45   0.12;      % non-energy supply (dark green)
        0.64   0.79   0.38];     % energy supply     (light green)
NAMES = {'Demand','Non-energy supply','Energy supply'};
YLAB = '100 x log change relative to year ago';  v = 2;  PRICELIM = [0 8];
x0 = us.pdates(1) - calmonths(2);  x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

figure('Position',[0 0 1150 430])

subplot(1,2,1)                                    % (a) US CPI ex energy
c = squeeze(us.meanSDC(:,v,:)) - us.meanDC(:,v);
bars = [c(:,1) c(:,2) c(:,3)+c(:,4)]*100;         % sum the two energy shocks
BarGraph(us.actual(:,v)*100, us.meanDC(:,v)*100, bars, us.pdates, BLUE, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(a) US CPI ex energy'); ylabel(YLAB)
h = get(gca,'Children');
legend(h([2 1 end:-1:end-2]), [{'Actual','Model forecast as of 2019:Q4'} NAMES], ...
       'Location','NorthEast','FontSize',8); legend boxoff

subplot(1,2,2)                                    % (b) EA HICP ex energy
c = squeeze(ea.meanSDC(:,v,:)) - ea.meanDC(:,v);
bars = [c(:,1) c(:,2) c(:,3)+c(:,4)]*100;
BarGraph(ea.actual(:,v)*100, ea.meanDC(:,v)*100, bars, ea.pdates, RED, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(b) EA HICP ex energy'); ylabel(YLAB)

%export
exportgraphics(gcf, fullfile('results','Figure5.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
