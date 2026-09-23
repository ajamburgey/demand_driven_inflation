% PrepareDSGEData.m: build the DSGE dataset from the raw series
% GetDSGEData.m already fetched to data/raw/
%
%   Output:
%     DSGEData.mat : TimeQ (quarterly dates, 1997:Q1-2026:Q1), GDPgr (real
%                     GDP per capita, percent change, SAAR, FRED
%                     A939RX0Q048SBEA), infl (GDP implicit price deflator,
%                     percent change, FRED GDPDEF -- NOT annualized here;
%                     GetDSGEDraws.m does infl*4, matching data.xlsx), ffr
%                     (federal funds effective rate, FRED FEDFUNDS, FRED's
%                     own quarterly average), tbill (1-year Treasury
%                     constant-maturity yield, FRED GS1, monthly average
%                     to quarters), Mnem, Descr.

close all
clear
addpath('aux')          
addpath('aux/lib')      % toquarterly

rawdir = fullfile('data','raw');

TimeQ = (datetime(1997,1,1) : calquarters(1) : datetime(2026,1,1))';
key   = year(TimeQ)*10 + quarter(TimeQ);

%% 1) GDPgr: real GDP per capita, percent change, SAAR ------------------------
[t, x] = readraw(rawdir, 'USRealGDPpc_growth');
GDPgr  = aligndt(t, x, key);

%% 2) infl: GDP implicit price deflator, percent change -----------------------
% left un-annualized here, exactly like data.xlsx; GetDSGEDraws.m does infl*4
[t, x] = readraw(rawdir, 'USGDPDeflator_growth');
infl   = aligndt(t, x, key);

%% 3) ffr: federal funds effective rate ----------------------------------------
[t, x] = readraw(rawdir, 'USFedFundsRate');
ffr    = aligndt(t, x, key);

%% 4) tbill: 1-year Treasury constant-maturity yield ---------------------------
% monthly GS1, equally averaged to quarters (see GetDSGEData.m's header note)
[t, x] = readraw(rawdir, 'USTBill1Y');
tbill  = toquarterly(x, t, TimeQ);

%% 5) save and report -----------------------------------------------------------
Mnem  = {'GDPgr';'infl';'ffr';'tbill'};
Descr = {'US real GDP per capita, percent change, SAAR (FRED A939RX0Q048SBEA, transformation pch)'; ...
         'US GDP implicit price deflator, percent change, not annualized (FRED GDPDEF, transformation pch)'; ...
         'US federal funds effective rate, percent, FRED quarterly average (FRED FEDFUNDS)'; ...
         'US 1-year Treasury constant-maturity yield, percent, monthly average to quarters (FRED GS1)'};

save(fullfile('data','DSGEData.mat'), 'TimeQ', 'GDPgr', 'infl', 'ffr', 'tbill', 'Mnem', 'Descr');

fprintf('PrepareDSGEData: wrote %s\n', fullfile('data','DSGEData.mat'));

% -------------------------------------------------------------------------
%% Functions

function [t, x] = readraw(rawdir, name)
% readraw  Read one (Date,Value) CSV written by GetDSGEData.m.
tb = readtable(fullfile(rawdir, [name '.csv']));
t  = tb.Date;
x  = tb.Value;
end

function v = aligndt(t, x, key)
% align a dated series onto the quarterly grid
k = year(t)*10 + quarter(t);
v = NaN(numel(key), 1);
[~, ia, ib] = intersect(key, k);
v(ia) = x(ib);
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
