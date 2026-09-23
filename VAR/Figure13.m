% Figure13: full decomposition of every variable of the supply model (PQHT:
% GDP, prices ex energy, transport energy, household energy).

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
BARS = [0.9290 0.6940 0.1250; 0.30 0.45 0.12; 0.64 0.79 0.38];   % demand, non-en supply, energy
NAMES = {'Demand','Non-energy supply','Energy supply'};
titUS = {'(a) US GDP','(c) US CPI ex energy','(e) US CPI transportation energy','(g) US CPI household energy'};
titEA = {'(b) EA GDP','(d) EA HICP ex energy','(f) EA HICP transportation energy','(h) EA HICP household energy'};
YLAB = '100 x log change relative to year ago';
x0 = us.pdates(1) - calmonths(2);  x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

% contributions per variable (energy pair summed) and each row's y range
BU = cell(4,1);  BE = cell(4,1);  YL = cell(4,1);
for v = 1:4
    cu = squeeze(us.meanSDC(:,v,:)) - us.meanDC(:,v);  BU{v} = [cu(:,1) cu(:,2) cu(:,3)+cu(:,4)]*100;
    ce = squeeze(ea.meanSDC(:,v,:)) - ea.meanDC(:,v);  BE{v} = [ce(:,1) ce(:,2) ce(:,3)+ce(:,4)]*100;
    lo = min([us.actual(:,v)*100; ea.actual(:,v)*100; us.meanDC(:,v)*100+sum(min(BU{v},0),2); ea.meanDC(:,v)*100+sum(min(BE{v},0),2)]);
    hi = max([us.actual(:,v)*100; ea.actual(:,v)*100; us.meanDC(:,v)*100+sum(max(BU{v},0),2); ea.meanDC(:,v)*100+sum(max(BE{v},0),2)]);
    YL{v} = [floor(lo)-1 ceil(hi)+1];
end
YL{2} = [0 8];                                                  % CPI ex energy fixed
en = [min(YL{3}(1),YL{4}(1)) max(YL{3}(2),YL{4}(2))];  YL{3} = en;  YL{4} = en;   % energy rows share

figure('Position',[0 0 1150 1560], 'Visible','off')
for v = 1:4
    subplot(4,2,2*v-1)                                          % US
    BarGraph(us.actual(:,v)*100, us.meanDC(:,v)*100, BU{v}, us.pdates, BLUE, BARS);
    xlim([x0 x1]); ylim(YL{v}); grid on; set(gca,'fontsize',12); title(titUS{v}); ylabel(YLAB)
    if v == 1
        h = get(gca,'Children');
        legend(h([2 1 end:-1:end-3]), [{'Actual','Model forecast as of 2019:Q4'} NAMES], 'Location','NorthEast','FontSize',8); legend boxoff
    end
    subplot(4,2,2*v)                                            % EA
    BarGraph(ea.actual(:,v)*100, ea.meanDC(:,v)*100, BE{v}, ea.pdates, RED, BARS);
    xlim([x0 x1]); ylim(YL{v}); grid on; set(gca,'fontsize',12); title(titEA{v}); ylabel(YLAB)
end

%export
exportgraphics(gcf, fullfile('results','Figure13.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
