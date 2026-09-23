function [x, t] = cbopotential()
%CBOPOTENTIAL  CBO nominal potential GDP from the US-CBO/cbo-data mirror.
%   [x, t] = cbopotential() returns the quarterly nominal potential GDP
%   (billions of dollars, = FRED NGDPPOT) from the Congressional Budget
%   Office's own GitHub data repository (cbo.gov refuses scripted access;
%   the repository is the CBO's scriptable channel). The newest
%   quarterly_*.csv in data/economic/historical_economic is used, located
%   through the GitHub directory listing, with the February 2026 vintage
%   as the fallback name.
%   Used by the PUBLIC data mode of GetData.m.
base = 'https://raw.githubusercontent.com/US-CBO/cbo-data/main/data/economic/historical_economic/';
name = 'quarterly_2026-02.csv';
fl = [tempname '.json'];
try
    fetchfile(fl, 'https://api.github.com/repos/US-CBO/cbo-data/contents/data/economic/historical_economic');
    L = jsondecode(fileread(fl));
    nm = sort(string({L.name}));
    nm = nm(startsWith(nm, 'quarterly_'));
    if ~isempty(nm), name = char(nm(end)); end
catch
    fprintf('  (CBO directory listing unavailable, using the pinned vintage)\n');
end
f  = [tempname '.csv'];
fetchfile(f, [base name]);   % retries a transient bad/error-page response
T = readtable(f, 'TextType', 'string');
T = T(T.variable == "potential_gdp", :);
yr = str2double(extractBefore(T.date, 'q'));
q  = str2double(extractAfter(T.date, 'q'));
t  = datetime(yr, 3*q-2, 1);
x  = T.value;
[t, ix] = sort(t);
x = x(ix);
fprintf('  potential_gdp: CBO (%s), %d obs to %s\n', name, numel(x), string(t(end)));
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
