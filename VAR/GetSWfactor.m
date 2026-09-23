% GetSWfactor: fetch the two FRED series behind the Stock-Watson covid
% factor measures used to clean the demand and supply shocks in Figure3.m,
% and save each as a plain CSV under data/raw/ 

close all
clear
addpath('aux')                                   % fetchfile

rawdir = fullfile('data','raw');
if ~isfolder(rawdir), mkdir(rawdir); end

[x, t] = fredmonthly('DGDSRA3M086SBEA');  writeraw(rawdir, 'USRealPCEGoods', t, x);
[x, t] = fredmonthly('DSERRA3M086SBEA');  writeraw(rawdir, 'USRealPCEServices', t, x);

fprintf('GetSWfactor: raw series written to %s\n', rawdir);

% -------------------------------------------------------------------------
%% Functions

function writeraw(rawdir, name, t, x)
% writeraw  Save one dated series as a plain (Date,Value) CSV.
t = t(:);  x = x(:);
tb = table(t, x, 'VariableNames', {'Date','Value'});
writetable(tb, fullfile(rawdir, [name '.csv']));
fprintf('  wrote %s (%d obs, %s to %s)\n', [name '.csv'], numel(x), string(t(1)), string(t(end)));
end

function [x, t] = fredmonthly(id)
% fredmonthly: one series from FRED's public csv endpoint, via fetchfile
% (retries a transient bad response, same as every other web fetch here).
  f = [tempname '.csv'];
  fetchfile(f, ['https://fred.stlouisfed.org/graph/fredgraph.csv?id=' id]);
  T = readtable(f);
  t = T.observation_date;
  x = T.(id);
  fprintf('  %s: FRED, %d obs to %s\n', id, numel(x), string(t(end)));
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
