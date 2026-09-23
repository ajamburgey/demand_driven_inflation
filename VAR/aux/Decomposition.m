function res = Decomposition(y, lags, dates, BETA, G, fd, fT0, series, labelY, shocks, ColorBars)
% Decomposition: historical decomposition with the accepted draws.
%
% Decomposes the post-2019 behavior of the variables into the contributions
% of the identified shocks, draw by draw, and averages. Plots the paper's
% bar chart (actuals, the 2019:Q4 unconditional forecast, and the stacked
% shock contributions). the SVARsign.m decomposition block, factored.
%
% INPUT   y, lags, dates    the data as passed to the estimation (trimmed
%                           to the estimation start), and their dates
%         BETA, G           the accepted draws from SignRestrict
%         fd                1 = display the variable in year-on-year terms
%         fT0               1 = subtract the 2019:Q4 level in the display
%         series, labelY, shocks, ColorBars   labels and colors
%
% OUTPUT  res               posterior means: meanSDC, meanDC, actual,
%                           pdates, and the level objects meanSDClev,
%                           meanDClev, yact, ypre, yT0v
%

T0 = find(dates=='01-oct-2019');
[T, n] = size(y);
acc = size(G, 3);

SDC = NaN(T-T0, n, acc, n);
for jj = 1:n
    hd = HD(y(T0+1-lags:end,:), lags, BETA, G, jj*ones(acc,1));
    SDC(:,:,:,jj) = hd.SDC;
end
DC = hd.DC;                        % the no-shock forecast, identical for every jj

dSDC   = SDC - cat(1, repmat(y(T0+1-4:T0,:),1,1,acc,n), SDC(1:end-4,:,:,:)).*repmat(fd,T-T0,1,acc,n);
dDC    = DC  - cat(1, repmat(y(T0+1-4:T0,:),1,1,acc),   DC(1:end-4,:,:)).*repmat(fd,T-T0,1,acc);
actual = y(T0+1:end,:) - y(T0+1-4:end-4,:).*repmat(fd,T-T0,1);

% the bar chart
BaseColor = [44,127,184]./255;
figure('Position',[0,0,1200,400*min([n-1,2])])
for pos = 1:n
    subplot(ceil(n/2), 2, pos);
    yT0 = y(T0,pos)*fT0(pos)*100;
    BarGraph(actual(:,pos)*100-yT0, mean(dDC(:,pos,:),3)*100-yT0, ...
        [squeeze(mean(dSDC(:,pos,:,:),3))-mean(dDC(:,pos,:),3)]*100, ...
        dates(T0+1:T), BaseColor, ColorBars);
    grid on
    ylabel(labelY(pos))
    title(series(pos))
    set(gca,'fontsize',13)
end
ax = gca;
lines = ax.Children;
legend([lines([2 1 end:-1:end-n+1])], [{'Actual','Model forecast as of 2019:Q4'} shocks], ...
    'Location','SouthEast'); legend boxoff

% posterior means, in display units and in levels
res = struct;
res.meanSDC    = squeeze(mean(dSDC, 3));
res.meanDC     = mean(dDC, 3);
res.actual     = actual;
res.pdates     = dates(T0+1:T);
res.meanSDClev = squeeze(mean(SDC, 3));
res.meanDClev  = mean(DC, 3);
res.yact       = y(T0+1:T,:);
res.ypre       = y(T0+1-4:T0,:);
res.yT0v       = y(T0,:);

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
