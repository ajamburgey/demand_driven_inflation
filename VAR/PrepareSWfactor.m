% PrepareSWfactor: build the three quarterly Stock-Watson covid measures
% used to clean the demand and supply shocks in Figure3.m, from the raw
% series GetSWfactor.m already fetched to data/raw/ and the shipped
% data/swcovid/Factors_Monthly.xlsx
%
% Data: Stock and Watson's own replication file ('Factors_Monthly.xlsx',
% shipped locally) and the two FRED real-PCE series GetSWfactor.m fetched:
%   DGDSRA3M086SBEA  real PCE, goods (chain-type quantity index, SA)
%   DSERRA3M086SBEA  real PCE, services (chain-type quantity index, SA)
%
% From cfac and ffac1-3, and from real PCE goods and services, we build three
%     covid measures at quarterly frequency:
%        rep  the covid factor        = quarterly average of cfac
%        eta  the covid shock         = residual of cfac on one lag of [cfac,ffac],
%                                       fit 2020:M7-2023:M2, zero outside 2020:M3-2023:M2
%        fit  the proxy covid factor  = fit of cfac on real PCE goods/services growth

close all
clear
addpath(fullfile('data','swcovid'))         % Factors_Monthly.xlsx

rawdir = fullfile('data','raw');

%the monthly factors (taken directly from the SW replication files)
F = readtable('Factors_Monthly.xlsx');
C = F.cfac; Ff = [F.ffac1 F.ffac2 F.ffac3];

% -- covid shock eta: residual of cfac on a single lag of [cfac, ffac] --------
Xl   = [ [NaN;C(1:end-1)] , [NaN(1,3);Ff(1:end-1,:)] ];        % one lag of [C,F]
fitw = (F.Year==2020 & F.Month>=7) | (F.Year>=2021 & F.Year<=2022) | (F.Year==2023 & F.Month<=2);
b    = Xl(fitw,:) \ C(fitw);                                   % fit 2020:M7 - 2023:M2
eta  = C - Xl*b;
keep = (F.Year==2020 & F.Month>=3) | (F.Year>=2021 & F.Year<=2022) | (F.Year==2023 & F.Month<=2);
eta(~keep) = 0;                                                % zero outside 2020:M3 - 2023:M2

% -- real PCE goods and services (FRED), monthly, then quarterly growth --------
[gt, gx] = readraw(rawdir, 'USRealPCEGoods');
[st, sx] = readraw(rawdir, 'USRealPCEServices');
qkey = @(y,m) y*4 + ceil(m/3);
qg = qkey(year(gt),month(gt));
qs = qkey(year(st),month(st));
gQ = accumarray(qg-min(qg)+1, gx, [], @mean); gQk = (min(qg):max(qg))';
sQ = accumarray(qs-min(qs)+1, sx, [], @mean); sQk = (min(qs):max(qs))';

% -- aggregate the monthly factor and shock to quarters -----------------------
qkm  = F.Year*4 + ceil(F.Month/3); uq = unique(qkm);
repQ = zeros(size(uq)); etaQ = zeros(size(uq));
for i = 1:numel(uq)
    repQ(i) = mean(C(qkm==uq(i)));
    etaQ(i) = mean(eta(qkm==uq(i)));
end

% -- common quarterly grid 2019Q1 .. latest, and the growth spreads -----------
q0 = qkey(2019,1); q1 = max([uq;gQk;sQk]); qk = (q0:q1)';
pick = @(v,kk) local_pick(v,kk,qk);
rep = pick(repQ,uq); etaq = pick(etaQ,uq);
g   = pick(gQ,gQk);  s = pick(sQ,sQk);
dg  = [NaN;100*diff(log(g))]; ds = [NaN;100*diff(log(s))];     % quarterly real growth

% -- proxy: least-squares fit of cfac on quarterly goods/services growth -------
win = qk>=qkey(2020,1) & qk<=qkey(2024,9) & isfinite(rep) & isfinite(dg) & isfinite(ds);
Xf  = [dg ds ones(size(dg))]; bfit = Xf(win,:)\rep(win); fit = Xf*bfit;

% -- save the quarterly measures, keyed by quarter ----------------------------
rep(~isfinite(rep))=0; etaq(~isfinite(etaq))=0; fit(~isfinite(fit))=0;
T = table(qk, floor((qk-1)/4), qk-floor((qk-1)/4)*4, rep, etaq, fit, ...
    'VariableNames',{'qk','Year','Q','rep','eta','fit'});
save(fullfile('data', 'SWcovid_quarterly.mat'),'T','bfit');
fprintf('PrepareSWfactor: data/SWcovid_quarterly.mat written\n');

% -------------------------------------------------------------------------
%% Functions

function [t, x] = readraw(rawdir, name)
% readraw  Load one (Date,Value) CSV written by GetSWfactor.m.
f = fullfile(rawdir, [name '.csv']);
if ~isfile(f)
    error('PrepareSWfactor: %s not found -- run GetSWfactor.m first to create it.', f);
end
tb = readtable(f);
t = tb.Date;
x = tb.Value;
end

function out = local_pick(vals,keys,qk)
  out = nan(size(qk)); [tf,loc]=ismember(qk,keys); out(tf)=vals(loc(tf));
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
