% Figure14: full decomposition of every variable of the demand model (PQRF:
% GDP, prices, one-year rate, primary deficit).

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
BARS = [0.80 0.52 0.04; 0.9290 0.6940 0.1250; 0.99 0.86 0.49; 0.4660 0.6740 0.1880];
NAMES = {'Monetary policy','Fiscal policy','Other demand','Supply'};
titUS = {'(a) US GDP','(c) US CPI','(e) US 1-year interest rate','(g) US primary deficit'};
titEA = {'(b) EA GDP','(d) EA HICP','(f) EA 1-year interest rate','(h) EA primary deficit'};
YLABS = {'100 x log change relative to year ago','100 x log change relative to year ago', ...
         'percentage points','percent of GDP'};
x0 = us.pdates(1) - calmonths(2);  x1 = DataEdge() + calmonths(2);   % right edge just past the last observed quarter

MNus = {'GDPus','CPIus','TB1Yus','Fus'};             % the observed tails past the
MNea = {'GDPea','HICPea','IB1Yea','Fea'};            % sample end (the deficits
TR   = {'yoy','yoy','rate','rate'};                  % have none until released)

BU = cell(4,1);  BE = cell(4,1);  YL = cell(4,1);
for v = 1:4
    BU{v} = (squeeze(us.meanSDC(:,v,:)) - us.meanDC(:,v))*100;
    BE{v} = (squeeze(ea.meanSDC(:,v,:)) - ea.meanDC(:,v))*100;
    lo = min([us.actual(:,v)*100; ea.actual(:,v)*100; us.meanDC(:,v)*100+sum(min(BU{v},0),2); ea.meanDC(:,v)*100+sum(min(BE{v},0),2)]);
    hi = max([us.actual(:,v)*100; ea.actual(:,v)*100; us.meanDC(:,v)*100+sum(max(BU{v},0),2); ea.meanDC(:,v)*100+sum(max(BE{v},0),2)]);
    YL{v} = [floor(lo)-1 ceil(hi)+1];
end
YL{2} = [-8 12];                                               % prices fixed

figure('Position',[0 0 1150 1560], 'Visible', 'off')
for v = 1:4
    subplot(4,2,2*v-1)                                         % US
    BarGraph(us.actual(:,v)*100, us.meanDC(:,v)*100, BU{v}, us.pdates, BLUE, BARS);
    [tq, av] = ActualTail(MNus{v}, TR{v}, us.pdates(end));
    if ~isempty(tq), plot([us.pdates(end); tq], [us.actual(end,v); av]*100, '-d', ...
            'LineWidth', 3, 'Color', BLUE, 'HandleVisibility', 'off'); end
    xlim([x0 x1]); ylim(YL{v}); grid on; set(gca,'fontsize',12); title(titUS{v}); ylabel(YLABS{v})
    if v == 1
        h = get(gca,'Children');
        legend(h([2 1 end:-1:end-4]), [{'Actual','Model forecast as of 2019:Q4'} NAMES], 'Location','NorthEast','FontSize',7); legend boxoff
    end
    subplot(4,2,2*v)                                           % EA
    BarGraph(ea.actual(:,v)*100, ea.meanDC(:,v)*100, BE{v}, ea.pdates, RED, BARS);
    [tq, av] = ActualTail(MNea{v}, TR{v}, ea.pdates(end));
    if ~isempty(tq), plot([ea.pdates(end); tq], [ea.actual(end,v); av]*100, '-d', ...
            'LineWidth', 3, 'Color', RED, 'HandleVisibility', 'off'); end
    xlim([x0 x1]); ylim(YL{v}); grid on; set(gca,'fontsize',12); title(titEA{v}); ylabel(YLABS{v})
end

%export
exportgraphics(gcf, fullfile('results','Figure14.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
