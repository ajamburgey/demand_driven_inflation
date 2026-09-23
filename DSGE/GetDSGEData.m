% GetDSGEData.m: fetch the four raw series behind the DSGE dataset (US real
% GDP per capita growth, GDP deflator inflation, the effective federal
% funds rate, and the 1-year Treasury yield) from FRED and save each one as
% a plain CSV under data/raw/

close all
clear
addpath('aux')       % fetchfile

rawdir = fullfile('data','raw');
if ~isfolder(rawdir), mkdir(rawdir); end

%% US real GDP per capita, percent change, SAAR (FRED's own pch transform)
[x, t] = fredcsv('A939RX0Q048SBEA', '&transformation=pch');
writeraw(rawdir, 'USRealGDPpc_growth', t, x);

%% US GDP implicit price deflator, percent change (FRED's own pch transform,
%  left un-annualized here, exactly like data.xlsx; PrepareDSGEData.m does infl*4)
[x, t] = fredcsv('GDPDEF', '&transformation=pch');
writeraw(rawdir, 'USGDPDeflator_growth', t, x);

%% US federal funds effective rate, percent (FRED's own quarterly, day-weighted average)
[x, t] = fredcsv('FEDFUNDS', '&fq=Quarterly&fam=avg');
writeraw(rawdir, 'USFedFundsRate', t, x);

%% US 1-year Treasury constant-maturity yield, percent, monthly (averaged to quarters in PrepareDSGEData.m)
[x, t] = fredcsv('GS1');
writeraw(rawdir, 'USTBill1Y', t, x);

fprintf('GetDSGEData: raw series written to %s\n', rawdir);

% -------------------------------------------------------------------------
%% Functions

function writeraw(rawdir, name, t, x)
% writeraw  Save one dated series as a plain (Date,Value) CSV.
t = t(:);  x = x(:);
tb = table(t, x, 'VariableNames', {'Date','Value'});
writetable(tb, fullfile(rawdir, [name '.csv']));
fprintf('  wrote %s (%d obs, %s to %s)\n', [name '.csv'], numel(x), string(t(1)), string(t(end)));
end

function [x, t] = fredcsv(id, extra)
% one series from FRED's public csv endpoint, with an optional query
% string (transformation and/or frequency/aggregation) appended
if nargin < 2, extra = ''; end
f = [tempname '.csv'];
fetchfile(f, ['https://fred.stlouisfed.org/graph/fredgraph.csv?id=' id extra]);
tb = readtable(f);
t  = tb.observation_date;
x  = tb{:,2};
fprintf('%s: FRED, %d obs to %s\n', id, numel(x), string(t(end)));
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
