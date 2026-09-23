% Figure9: plots the GDP and inflation nowcasts and projections for the US
% and EA along with the data from the latest vintage.

close all
clear
addpath('aux')

S = load(fullfile('data','Projections.mat'));
dates = S.dates;
T0 = S.T0;
nv = S.nv;

% add dates for projection fans
qdate = @(k) dates(T0) + calquarters(k - T0);

% one entry per panel: title, actual series, fan matrix (5 horizons x nv
% rounds), y limits, y label, fan legend label
panels = struct( ...
  'title',  {'(a) US GDP', '(b) EA GDP', '(c) US CPI', '(d) EA HICP'}, ...
  'actual', {S.USgdpActual(:), S.EAgdpActual(:), S.USinfActual(:), S.EAinfActual(:)}, ...
  'fan',    {S.USgdpProj, S.EAgdpProj, S.USinfProj, S.EAinfProj}, ...
  'ylim',   {[87 120], [82 109], [0 10], [-1 11]}, ...
  'ytick',  {90:5:115, 85:5:105, 0:2:10, 0:2:10}, ...
  'ylabel', {'index (2019:Q4 = 100)', 'index (2019:Q4 = 100)', ...
             'percent change from year ago', 'percent change from year ago'}, ...
  'label',  {'SPF projection', 'ECB projection', 'SPF projection', 'ECB projection'});

figure('Position',[0 0 1350 1000],'Visible','off') %visible off so monitor size doesn't squish image
% manual 2x2 grid: gapX/gapY set the space between panels (tune to taste,
% in between tiledlayout's 'compact' and default 'loose' spacing)
gapX = 0.1; gapY = 0.1;
marginL = 0.055; marginR = 0.015; marginB = 0.055; marginT = 0.035;
tileW = (1 - marginL - marginR - gapX) / 2;
tileH = (1 - marginB - marginT - gapY) / 2;
for pos = 1:4
  p = panels(pos);
  row = ceil(pos/2); col = mod(pos-1,2)+1;
  left   = marginL + (col-1)*(tileW+gapX);
  bottom = 1 - marginT - row*tileH - (row-1)*gapY;

  % one 2x2 panel: thick black latest line, dotted fans, filled diamond
  % nowcasts, parula colors trimmed to the warm end
  axes('Position',[left bottom tileW tileH]);
  hold on;
  grid on
  cmap = parula(round(1.5*nv)); cmap = cmap(end-nv+1:end,:);
  ok = isfinite(p.actual(1:numel(dates)));
  hl = plot(dates(ok & (1:numel(dates))'>=T0), p.actual(ok & (1:numel(dates))'>=T0), 'k','LineWidth',3.5);
  hp=[]; hn=[];
  for i = 1:nv
      seg = p.fan(1:5,i);
      if all(~isfinite(seg))
          continue;
      end
      hp = plot(qdate(T0+i:T0+i+4), seg, ':','LineWidth',2,'Color',cmap(i,:));
      hn = scatter(qdate(T0+i), seg(1), 60,'d','filled','MarkerFaceColor',cmap(i,:));
  end
  xlim([qdate(T0-1) qdate(T0+31)]);
  if ~isempty(p.ylim)
      ylim(p.ylim);
  end
  set(gca,'YTick',p.ytick);
  set(gca,'FontSize',16);
  ylabel(p.ylabel);
  title(p.title,'FontSize',20)
  if pos <= 2                                  % legend in the GDP row only, the
      legend([hl hn hp], {'latest','nowcast',p.label}, ...   % inflation row repeats it
             'Location','SouthEast','FontSize',18);
      legend boxoff
  end
end

%export
exportgraphics(gcf, fullfile('results','Figure9.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
