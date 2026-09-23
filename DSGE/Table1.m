% Table1: the demand-supply decomposition and the systematic conduct of
% monetary policy (table 1 of the paper). Reports the share of the
% cumulative forecast error in year-on-year US GDP-deflator inflation
% over 2021:Q1-2023:Q4, relative to the 2019:Q4 forecast, attributed to
% demand disturbances (monetary policy, monetary policy news,
% inflation-target and preference shocks) under counterfactual monetary
% policy rules -- Panel A varies the response to inflation (phi_pi),
% Panel B the response to the output gap (phi_Y), one at a time, holding
% every other parameter (including the other policy coefficient) at its
% posterior mode.

close all
clear
addpath(genpath('aux'))    % modCPSbase, SmoothedStates

S = load(fullfile('draws','DSGE_draws.mat'));
n = size(S.y,2);

% the deterministic (no-shock) path from the 2019:Q4 state
DC = NaN(S.TTT, n);
S0 = S.SS_SD19(end,:)';
for t = 1:S.TTT
    S0 = S.G1*S0;
    DC(t,:) = S.zmat*S0 + S.C;
end

Tzlb_2026 = 0;
dates  = (datetime(2020,1,1):calquarters(1):datetime(2026,1,1))';
window = find(dates=='01-Jan-2021'):find(dates=='01-Oct-2023');

phiPgrid = [1.05 1.50 2.00 S.POSTMODE(6) 3.00 5.00];
phiYgrid = [0.00 S.POSTMODE(7) 0.40 0.60 0.80 1.00];

fprintf('Table1: Panel A (varying phi_pi)...\n');
sharePanelA = NaN(1, numel(phiPgrid));
for k = 1:numel(phiPgrid)
    sharePanelA(k) = demandshare(S, DC, phiPgrid(k), S.POSTMODE(7), Tzlb_2026, window);
    fprintf('  phi_pi = %.2f: demand share = %.2f\n', phiPgrid(k), sharePanelA(k));
end

fprintf('Table1: Panel B (varying phi_Y)...\n');
sharePanelB = NaN(1, numel(phiYgrid));
for k = 1:numel(phiYgrid)
    sharePanelB(k) = demandshare(S, DC, S.POSTMODE(6), phiYgrid(k), Tzlb_2026, window);
    fprintf('  phi_Y = %.2f: demand share = %.2f\n', phiYgrid(k), sharePanelB(k));
end

%% write the .csv
outfile = fullfile('results','Table1.csv');
fid = fopen(outfile, 'w');
fprintf(fid, 'Panel A. Varying the response to inflation\n');
fprintf(fid, 'phi_pi,%s\n', strjoin(compose('%.2f', phiPgrid), ','));
fprintf(fid, 'Demand share,%s\n', strjoin(compose('%.2f', sharePanelA), ','));
fprintf(fid, '\n');
fprintf(fid, 'Panel B. Varying the response to the output gap\n');
fprintf(fid, 'phi_Y,%s\n', strjoin(compose('%.2f', phiYgrid), ','));
fprintf(fid, 'Demand share,%s\n', strjoin(compose('%.2f', sharePanelB), ','));
fclose(fid);

% -------------------------------------------------------------------------
%% Functions

function share = demandshare(S, DC, phiP, phiY, Tzlb_2026, window)
% the demand share of the inflation forecast error under a counterfactual
% policy rule with response-to-inflation phiP and response-to-output-gap
% phiY, all other parameters at S.POSTMODE
NewParam = S.POSTMODE;
NewParam(6) = phiP;
NewParam(7) = phiY;
[G1new,~,impactnew,~,SDXnew,zmatnew,NY,NX] = modCPSbase(NewParam);

SS_new = SmoothedStates(S.DATAnony - DC, G1new, impactnew, SDXnew, zmatnew, ...
                         zeros(size(S.y,2),1), Tzlb_2026, S.pos0, zeros(NY,1), zeros(NY,NY));
shocks_new = (SS_new(2:end,:) - SS_new(1:end-1,:)*G1new') * pinv(impactnew*SDXnew)';

i = 2;   % GDP deflator inflation
HD = NaN(S.TTT, 1, NX);
for is = 1:NX
    SDX_single = zeros(NX);
    SDX_single(is,is) = SDXnew(is,is);
    X = NaN(S.TTT+1, NY); X(1,:) = zeros(1,NY);
    for t = 1:S.TTT
        X(t+1,:) = (G1new*X(t,:)' + impactnew*SDX_single*shocks_new(t,:)')';
        HD(t,1,is) = zmatnew(i,:)*X(t+1,:)';
    end
end

% year-on-year (trailing 4-quarter) inflation, its pre-pandemic-model
% forecast, and each shock's own contribution to it. Prepending the last
% 3 quarters of the estimation sample (2019:Q2-Q4) lets movsum compute a
% proper trailing 4-quarter sum for every quarter from 2020:Q1 onward;
% 'Endpoints','discard' then trims the output back down to S.TTT
% elements, aligned 1:1 with `window` (which is built off `dates`,
% starting 2020:Q1).
Pplus  = [S.y(S.T-2:S.T,i); S.DATA(S.T+1:end,i)];
DCplus = [S.y(S.T-2:S.T,i); DC(:,i)];
HDplus = [zeros(3,NX); squeeze(HD(:,1,:))];

Pyoy  = movsum(Pplus,  [3 0], 'Endpoints', 'discard') / 4;
DCyoy = movsum(DCplus, [3 0], 'Endpoints', 'discard') / 4;
HDyoy = movsum(HDplus, [3 0], 'Endpoints', 'discard') / 4;

FEyoy    = Pyoy - DCyoy;
HDdemand = sum(HDyoy(:,[1 5:end]), 2);   % monetary policy, preference, anticipated MP news, inflation target

share = sum(HDdemand(window)) / sum(FEyoy(window));
end

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
