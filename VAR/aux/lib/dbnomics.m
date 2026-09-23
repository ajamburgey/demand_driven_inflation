function [x, t] = dbnomics(id)
%DBNOMICS  One series from the DBnomics open mirror (api.db.nomics.world).
%   [x, t] = dbnomics('BEA/NIPA-T10106/A191RX-Q') returns values and dates.
%   The id is provider/dataset/series. Quarterly BEA periods come as
%   '2019-Q4' (mapped to the first month of the quarter), monthly Fed H.15
%   periods as month-end dates (mapped to the first of the month).
%   Used by the PUBLIC data mode of GetData.m for the series whose official
%   portals require a key or refuse scripted access (BEA tables, the Fed
%   H.15 monthly averages); DBnomics republishes them verbatim.
url = sprintf('https://api.db.nomics.world/v22/series/%s?observations=1', id);
f   = [tempname '.json'];
fetchfile(f, url);   % retries a transient bad/error-page response
R = jsondecode(fileread(f));
d = R.series.docs(1);
p = string(d.period);
v = d.value;
if iscell(v)                                   % missing values arrive as 'NA'
    vn = NaN(numel(v),1);
    for i = 1:numel(v)
        if isnumeric(v{i}), vn(i) = v{i}; end
    end
    v = vn;
end
t = NaT(numel(p),1);
for i = 1:numel(p)
    if contains(p(i), '-Q')                    % quarterly: 2019-Q4
        yr = str2double(extractBefore(p(i), '-'));
        q  = str2double(extractAfter(p(i), '-Q'));
        t(i) = datetime(yr, 3*q-2, 1);
    else                                       % daily-stamped monthly: 2019-10-31
        t(i) = dateshift(datetime(p(i)), 'start', 'month');
    end
end
ok = isfinite(v) & ~isnat(t);
t = t(ok);
x = v(ok);
[t, ix] = sort(t);
x = x(ix);
fprintf('  %s: DBnomics, %d obs to %s\n', id, numel(x), string(t(end)));
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
