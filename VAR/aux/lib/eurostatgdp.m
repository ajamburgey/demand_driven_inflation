function [x, t] = eurostatgdp(unit)
%EUROSTATGDP  Euro-area quarterly GDP from the Eurostat SDMX API.
%   [x, t] = eurostatgdp('CLV10_MEUR') returns real GDP (chain linked
%   volumes, million euro) and eurostatgdp('CP_MEUR') nominal GDP, both
%   seasonally and calendar adjusted, geo EA: the CHANGING-COMPOSITION
%   euro area, the concept of the estimation panel (new members enter as
%   they join; the level reference year differs from Haver's, which only
%   shifts the log level by a constant).
%   Used by the PUBLIC data mode of GetData.m.
url = sprintf(['https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/' ...
               'namq_10_gdp/Q.%s.SCA.B1GQ.EA?format=SDMX-CSV&startPeriod=1995-Q1'], unit);
f   = [tempname '.csv'];
fetchfile(f, url);   % retries a transient bad/error-page response
T = readtable(f, 'Delimiter', ',', 'TextType', 'string', 'VariableNamingRule', 'preserve');
p = T.("TIME_PERIOD");
v = T.("OBS_VALUE");
if ~isnumeric(v), v = double(v); end
yr = str2double(extractBefore(p, '-Q'));
q  = str2double(extractAfter(p, '-Q'));
t  = datetime(yr, 3*q-2, 1);
ok = isfinite(v) & ~isnat(t);
t = t(ok);
x = v(ok);
[t, ix] = sort(t);
x = x(ix);
fprintf('  namq_10_gdp %s EA: Eurostat, %d obs to %s\n', unit, numel(x), string(t(end)));
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
