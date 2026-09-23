% Figure 2: baseline historical decomposition (the PQ model).

close all
clear
addpath(genpath('aux'))

%US decomposition
rea = load(fullfile('draws', 'PQus_draws.mat'));
us = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%EA decomposition
rea = load(fullfile('draws', 'PQea_draws.mat'));
ea = Decomposition(rea.y, rea.lags, rea.dts, rea.BETA, rea.G, rea.fd, rea.fT0, ...
                    rea.series, rea.labelY, rea.shocks, rea.ColorBars);

%Figure settings
BLUE = [44 127 184]/255;      % US line
RED  = [.8941 .1020 .1098];   % EA line
BARS = [0.9290 0.6940 0.1250;   % demand (yellow)
        0.4660 0.6740 0.1880];  % supply (green)
YLAB = '100 x log change relative to year ago';
GDPLIM = [-16 16];  PRICELIM = [-5 11];
x0 = us.pdates(1) - calmonths(2);  x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

figure('Position',[0 0 1150 780])

%US GDP plot
subplot(2,2,1)                                            % (a) US GDP
bars = (squeeze(us.meanSDC(:,1,:)) - us.meanDC(:,1))*100;
BarGraph(us.actual(:,1)*100, us.meanDC(:,1)*100, bars, us.pdates, BLUE, BARS);
xlim([x0 x1]); ylim(GDPLIM); grid on; set(gca,'fontsize',13)
title('(a) US GDP'); ylabel(YLAB)
h = get(gca,'Children');
legend(h([2 1 end:-1:end-1]), {'Actual','Model forecast as of 2019:Q4','Demand','Supply'}, ...
       'Location','NorthEast','FontSize',9); legend boxoff

%EA GDP plot
subplot(2,2,2)                                            % (b) EA GDP
bars = (squeeze(ea.meanSDC(:,1,:)) - ea.meanDC(:,1))*100;
BarGraph(ea.actual(:,1)*100, ea.meanDC(:,1)*100, bars, ea.pdates, RED, BARS);
xlim([x0 x1]); ylim(GDPLIM); grid on; set(gca,'fontsize',13)
title('(b) EA GDP'); ylabel(YLAB)

%US CPI plot
subplot(2,2,3)                                            % (c) US CPI
bars = (squeeze(us.meanSDC(:,2,:)) - us.meanDC(:,2))*100;
BarGraph(us.actual(:,2)*100, us.meanDC(:,2)*100, bars, us.pdates, BLUE, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(c) US CPI'); ylabel(YLAB)

%EA HICP plot
subplot(2,2,4)                                            % (d) EA HICP
bars = (squeeze(ea.meanSDC(:,2,:)) - ea.meanDC(:,2))*100;
BarGraph(ea.actual(:,2)*100, ea.meanDC(:,2)*100, bars, ea.pdates, RED, BARS);
xlim([x0 x1]); ylim(PRICELIM); grid on; set(gca,'fontsize',13)
title('(d) EA HICP'); ylabel(YLAB)

%export
exportgraphics(gcf, fullfile('results','Figure2.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
