% Figure 1: year-on-year consumer price inflation, US (blue) and EA
% (red), for the headline, goods, services and energy indexes.

close all
clear
load(fullfile('data','DataChart.mat'))          % CH (price indexes), TimeQ; columns:
% HEADus HEADea GOODus GOODea SERVus SERVea ENERus ENERea HHENus HHENea TRENus TRENea
keep  = TimeQ <= datetime(2026,1,1);             % paper sample convention
CH    = CH(keep,:);  TimeQ = TimeQ(keep);
PI = 100*(CH(5:end,:)./CH(1:end-4,:) - 1);       % year-on-year inflation
PI = [NaN(4,size(CH,2)); PI];
t0 = find(year(TimeQ)==2018, 1);

BLUE = [44 127 184]/255;  RED = [.8941 .1020 .1098];
cc = PI(t0:end,1:6);   clim = [floor(min(cc(:)))-1 ceil(max(cc(:)))+1];  % non-energy
ee = PI(t0:end,7:12);  elim = [floor(min(ee(:)))-2 ceil(max(ee(:)))+2];  % energy axis sized on all six
                                                                         % energy series, though only
                                                                         % the two totals are plotted

TIT = {'CPI / HICP','CPI / HICP goods','CPI / HICP services','CPI / HICP energy'};
usc = [1 3 5 7];  eac = [2 4 6 8];  YL = {clim,clim,clim,elim};  L = 'abcd';

figure('Position',[0 0 1150 780])
for i = 1:4
    subplot(2,2,i)
    plot(TimeQ, PI(:,usc(i)), 'Color', BLUE, 'LineWidth', 3); hold on
    plot(TimeQ, PI(:,eac(i)), 'Color', RED,  'LineWidth', 3); hold off
    xlim([TimeQ(t0) TimeQ(end)+calmonths(2)]); ylim(YL{i}); grid on
    xticks(datetime(2018:2027,1,1))               % year-start gridlines, as in the
    xtickformat('yyyy')                           % other charts
    ylabel('percent change from year ago'); set(gca,'fontsize',13)
    title(sprintf('(%s) %s', L(i), TIT{i}))
    if i == 1
        legend({'US','EA'}, 'Location','northwest','FontSize',9); legend boxoff
    end
end
exportgraphics(gcf, fullfile('results','Figure1.pdf'), 'ContentType','vector'); close

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
