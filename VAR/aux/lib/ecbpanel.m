function [X, t] = ecbpanel(keys)
%ECBPANEL  Several monthly ECB Data Portal series, aligned on one grid.
%   [X, t] = ecbpanel({key1, key2, ...}) fetches each series with
%   ecbseries and aligns them on a common monthly grid spanning the union
%   of their samples, NaN where a series has no observation.
%   Used by the PUBLIC data mode of GetData.m / GetChartData.m.
n  = numel(keys);
xs = cell(n,1);
ts = cell(n,1);
t0 = datetime(2100,1,1);
t1 = datetime(1900,1,1);
for j = 1:n
    [xs{j}, ts{j}] = ecbseries(keys{j});
    t0 = min(t0, ts{j}(1));
    t1 = max(t1, ts{j}(end));
end
t = (t0 : calmonths(1) : t1)';
X = NaN(numel(t), n);
for j = 1:n
    [~, ia, ib] = intersect(t, ts{j});
    X(ia, j) = xs{j}(ib);
end
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
