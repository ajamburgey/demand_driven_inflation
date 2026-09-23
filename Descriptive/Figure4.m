% Figure4: accounting decomposition of headline inflation

close all
clear
load(fullfile('data','DataChart.mat'))           % CONTRIB, TimeQ

keep    = TimeQ <= datetime(2026,1,1);           % paper sample convention
CONTRIB = CONTRIB(keep,:);  TimeQ = TimeQ(keep);
t0 = find(year(TimeQ)==2018, 1);

ORA  = [0.9500 0.5800 0.2600];   % ex energy
PURD = [0.4940 0.1840 0.5560];   % household energy
PURL = [0.76   0.62   0.86  ];   % transportation energy
LC   = {[44 127 184]/255, [.8941 .1020 .1098]};   % headline line: US, EA
TIT  = {'(a) US CPI','(b) EA HICP'};  COLS = {1:4, 5:8};  PRICELIM = [-5 11];

figure('Position',[0 0 1150 430])
for k = 1:2
    c = CONTRIB(:, COLS{k});
    subplot(1,2,k)
    b = bar(TimeQ, [c(:,1) c(:,2) c(:,3)], 'stacked', 'BarWidth', .8, 'EdgeColor','none');
    b(1).FaceColor = ORA;  b(2).FaceColor = PURD;  b(3).FaceColor = PURL;  hold on
    plot(TimeQ, c(:,4), '-d', 'Color', LC{k}, 'LineWidth', 2, 'MarkerSize', 4); hold off
    xlim([TimeQ(t0)-calmonths(2) TimeQ(end)+calmonths(2)]); ylim(PRICELIM); grid on
    ylabel('percent change from year ago; contributions'); set(gca,'fontsize',13)
    title(TIT{k})
    if k == 1
        h = get(gca,'Children');
        legend(h([1 end end-1 end-2]), {'Headline','Ex energy','Household energy','Transportation energy'}, ...
               'Location','NorthWest','FontSize',9); legend boxoff
    end
end

%export
exportgraphics(gcf, fullfile('results','Figure4.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
