% Figure6: opening the demand box (PQRF), prices.

close all
clear
addpath(genpath('aux'))

%US decomposition
rea = load(fullfile('draws', 'PQRFus_draws.mat'));
us = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%EA decomposition
rea = load(fullfile('draws', 'PQRFea_draws.mat'));
ea = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%Figure settings
BLUE = [44 127 184]/255;  RED = [.8941 .1020 .1098];
BARS = [0.80   0.52   0.04;    % monetary     (dark gold)
        0.9290 0.6940 0.1250;  % fiscal       (yellow)
        0.99   0.86   0.49;    % other demand (light yellow)
        0.4660 0.6740 0.1880]; % supply       (green)
NAMES = {'Monetary policy','Fiscal policy','Other demand','Supply'};
YLAB = '100 x log change relative to year ago';  v = 2;  PRICELIM = [-8 12];
x0 = us.pdates(1) - calmonths(2);  x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

figure('Position',[0 0 1150 430])

subplot(1,2,1)                                    % (a) US CPI
bars = (squeeze(us.meanSDC(:,v,:)) - us.meanDC(:,v))*100;
BarGraph(us.actual(:,v)*100, us.meanDC(:,v)*100, bars, us.pdates, BLUE, BARS);
[tq, av] = ActualTail('CPIus', 'yoy', us.pdates(end));     % actual already observed
plot([us.pdates(end); tq], [us.actual(end,v); av]*100, '-d', 'LineWidth', 3, ...
     'Color', BLUE, 'HandleVisibility', 'off');            % beyond the fiscal data
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(a) US CPI'); ylabel(YLAB)
h = get(gca,'Children');
legend(h([2 1 end:-1:end-3]), [{'Actual','Model forecast as of 2019:Q4'} NAMES], ...
       'Location','NorthEast','FontSize',8); legend boxoff

subplot(1,2,2)                                    % (b) EA HICP
bars = (squeeze(ea.meanSDC(:,v,:)) - ea.meanDC(:,v))*100;
BarGraph(ea.actual(:,v)*100, ea.meanDC(:,v)*100, bars, ea.pdates, RED, BARS);
[tq, av] = ActualTail('HICPea', 'yoy', ea.pdates(end));    % actual already observed
plot([ea.pdates(end); tq], [ea.actual(end,v); av]*100, '-d', 'LineWidth', 3, ...
     'Color', RED, 'HandleVisibility', 'off');             % beyond the fiscal data
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(b) EA HICP'); ylabel(YLAB)

%export
exportgraphics(gcf, fullfile('results','Figure6.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
