function [x, t] = ecbseries(key)
%ECBSERIES  One monthly (or quarterly) series from the ECB Data Portal SDMX API.
%   [x, t] = ecbseries('HICP.M.U2.Y.000000.4F0.INX') returns the values and
%   their dates (first of the month, or first month of the quarter for
%   quarterly keys such as the GFS primary balance). The dataflow is the
%   part of the key before the first dot, the rest is the series key.
%   Used by the PUBLIC data mode of GetData.m / GetChartData.m.
dot  = find(key == '.', 1);
flow = key(1:dot-1);
rest = key(dot+1:end);
url  = sprintf('https://data-api.ecb.europa.eu/service/data/%s/%s?format=csvdata', flow, rest);
f    = [tempname '.csv'];
fetchfile(f, url);   % retries a transient bad/error-page response
T = readtable(f, 'Delimiter', ',', 'TextType', 'string', 'VariableNamingRule', 'preserve');
p = T.("TIME_PERIOD");
v = T.("OBS_VALUE");
if ~isnumeric(v), v = double(v); end
if any(contains(p, '-Q'))                      % quarterly key (e.g. the GFS balance)
    yr = str2double(extractBefore(p, '-Q'));
    q  = str2double(extractAfter(p, '-Q'));
    t  = datetime(yr, 3*q-2, 1);
else                                           % monthly key: 1997-01
    t = datetime(p + "-01", 'InputFormat', 'yyyy-MM-dd');
end
ok = ~isnan(v) & ~isnat(t);
t = t(ok);
x = v(ok);
[t, ix] = sort(t);
x = x(ix);
fprintf('  %s: ECB Data Portal, %d obs to %s\n', key, numel(x), string(t(end)));
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
