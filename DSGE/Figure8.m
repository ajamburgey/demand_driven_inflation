% Figure8: post-pandemic historical decomposition of US GDP and the GDP
% deflator (2020:Q1-2026:Q1) implied by the DSGE model, at its posterior
% mode.

close all
clear
addpath('aux')    % BarGraph, SmoothedStates

S = load(fullfile('draws','DSGE_draws.mat'));

Tzlb_2026 = 0;
SS_2026 = SmoothedStates(S.DATAnony, S.G1, S.impact, S.SDX, S.zmat, S.C, ...
                          Tzlb_2026, S.pos0, S.SS_SD19(end,:)', zeros(S.NY,S.NY));
shocks_2026 = (SS_2026(2:end,:) - SS_2026(1:end-1,:)*S.G1') * pinv(S.impact*S.SDX)';

HD = NaN(S.TTT, size(S.y,2), S.NX);
DC = NaN(S.TTT, size(S.y,2));
for is = 0:S.NX
    SDX_single = zeros(S.NX);
    if is > 0, SDX_single(is,is) = S.SDX(is,is); end
    X = NaN(S.TTT+1, S.NY); X(1,:) = S.SS_SD19(end,:);
    for t = 1:S.TTT
        X(t+1,:) = (S.G1*X(t,:)' + S.impact*SDX_single*shocks_2026(t,:)')';
        if is == 0
            DC(t,:) = S.zmat*X(t+1,:)' + S.C;
        else
            HD(t,:,is) = S.zmat*X(t+1,:)' + S.C;
        end
    end
end
HD = HD - repmat(DC,1,1,S.NX);

dates = (datetime(2020,1,1):calquarters(1):datetime(2026,1,1))';

% shocks reordered for the legend: MP, MP news x4 (3 blank), inflation
% target, preference, technology, transitory technology (blank), cost-push
HDgrouped = HD(:,:,[1 6 7 8 9 10 5 2 4 3]);
colorbars = [[0.6350 0.0780 0.1840];[0.85 0.45 0.2];[0.85 0.45 0.2];[0.85 0.45 0.2]; ...
             [0.85 0.45 0.2];[0.8895 0.5720 0.1625];[0.9290 0.6940 0.1250]; ...
             [0.4660 0.6740 0.1880];[0.4660 0.6740 0.1880];[0.4940 0.1840 0.5560]];

figure('Position', [0 0 1400 450]);
for i = 1:2
    Pplus     = [S.y(S.T-2:S.T,i); S.DATA(S.T+1:end,i)];
    INFLcovid = movsum(Pplus, [0 3], 'Endpoints','discard')/4;
    DCplus    = [S.y(S.T-2:S.T,i); DC(:,i)];
    DCcovid   = movsum(DCplus, [0 3], 'Endpoints','discard')/4;
    HDplus    = [repmat(zeros(3,1),1,size(HD,3)); squeeze(HDgrouped(:,i,:))];
    HDcovid   = movsum(HDplus, [0 3], 'Endpoints','discard')/4;

    subplot(1,2,i); BarGraph(INFLcovid, DCcovid, HDcovid, dates, [0 0.4470 0.7410], colorbars);
    set(gca,'FontSize',13)
    ylabel('100 x log change relative to year ago','FontSize',13);
    if i == 1, title('(a) US GDP','FontSize',13); else, title('(b) US GDP deflator','FontSize',13); end
end
legend('monetary policy','monetary policy news','','','','inflation target', ...
       'preference','technology','','cost-push' , 'FontSize', 10); legend boxoff

%export
exportgraphics(gcf, fullfile('results','Figure8.pdf'), 'ContentType','vector')

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
