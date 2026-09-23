% Figure10: plots the GDP nowcasts and projections for the US
% and EA along with the preliminary data releases for each series.

close all
clear
addpath('aux')

S = load(fullfile('data','Projections.mat'));
dates = S.dates;
T0 = S.T0;
nv = S.nv;

% add dates for projection fans
qdate = @(k) dates(T0) + calquarters(k - T0);

%first-release diagonals
USgdpFirst = NaN(size(dates));
for i = 0:nv-1
    for j = i+1:nv
        if isfinite(S.USgdpRT(T0+i,j))
            USgdpFirst(T0+i) = S.USgdpRT(T0+i,j);
            break   % stop at the first (earliest) vintage that has this quarter
        end
    end
end

EAgdpFirst = NaN(size(dates));
for i = 0:size(S.EAgdpRT,2)-1
    EAgdpFirst(T0+i) = S.EAgdpRT(T0+i, i+1);
end

% one entry per panel: title, first-release series, fan matrix (5 horizons
% x nv rounds), fan legend label
panels = struct( ...
  'title',  {'(a) US GDP', '(b) EA GDP'}, ...
  'first',  {USgdpFirst, EAgdpFirst}, ...
  'fan',    {S.USgdpProj, S.EAgdpProj}, ...
  'ylim',   {[87 120], [82 109]}, ...
  'ytick',  {90:5:115, 85:5:105}, ...
  'label',  {'SPF projection', 'ECB projection'});

figure('Position', [0, 0, 1500, 500]);
for pos = 1:2
  p = panels(pos);
  subplot(1,2,pos); hold on; grid on
  cmap = parula(round(1.5*nv)); cmap = cmap(end-nv+1:end,:);
  ok = isfinite(p.first);
  hl = plot(dates(ok), p.first(ok), 'k-o','LineWidth',2.5,'MarkerSize',5,'MarkerFaceColor','k');
  hp=[]; hn=[];
  for i = 1:nv
      seg = p.fan(1:5,i);
      if all(~isfinite(seg)), continue; end
      hp = plot(qdate(T0+i:T0+i+4), seg, ':','LineWidth',2,'Color',cmap(i,:));
      hn = scatter(qdate(T0+i), seg(1), 45,'d','filled','MarkerFaceColor',cmap(i,:));
  end
  xlim([qdate(T0-1) qdate(T0+31)]); ylim(p.ylim); set(gca,'YTick',p.ytick);
  set(gca,'FontSize',14); ylabel('index (2019:Q4 = 100)'); title(p.title,'FontSize',16)
  legend([hl hn hp], {'preliminary release','nowcast',p.label}, ...
         'Location','SouthEast','FontSize',16); legend boxoff
end

%export
exportgraphics(gcf, fullfile('results','Figure10.pdf'), 'ContentType','vector')


% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
