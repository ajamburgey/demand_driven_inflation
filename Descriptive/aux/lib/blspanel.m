function [X, TimeM] = blspanel(ids, apikey)
%BLSPANEL  Monthly BLS series from the official BLS public API (v2).
%   [X, TimeM] = blspanel({'CUSR0000SA0', ...}) fetches each series over
%   1947 to the present in ten-year windows (the API limit without a
%   registered key), batching all the series into one request per window,
%   and returns them aligned on a common monthly grid.
%
%   [X, TimeM] = blspanel(ids, apikey) uses a registered BLS key instead
%   of the unregistered API: 500 queries/day instead of 25, and 20-year
%   windows instead of 10 (so a full build takes four requests, not
%   eight). Register a free key at https://data.bls.gov/registrationEngine/
%   Omit apikey, or pass 'public', for the unregistered API.
%
%   The unregistered API allows 25 queries per day; a full build uses
%   eight. Used by the PUBLIC data mode of GetData.m / GetChartData.m.
%   The API host (api.bls.gov) accepts scripted access; the bls.gov table
%   pages do not.
if nargin < 2, apikey = 'public'; end
keyed = ~strcmp(apikey, 'public');
y0 = 1947;
y1 = year(datetime('today'));
TimeM = (datetime(y0,1,1) : calmonths(1) : datetime(y1,12,1))';
X = NaN(numel(TimeM), numel(ids));
idlist = strjoin(cellfun(@(s) ['"' s '"'], ids, 'UniformOutput', false), ',');
windowYears = 10 + 10*keyed;   % 10 unregistered, 20 with a registered key
for w0 = y0:windowYears:y1
    w1 = min(w0+windowYears-1, y1);
    if keyed
        body = sprintf('{"seriesid":[%s],"startyear":"%d","endyear":"%d","registrationkey":"%s"}', idlist, w0, w1, apikey);
    else
        body = sprintf('{"seriesid":[%s],"startyear":"%d","endyear":"%d"}', idlist, w0, w1);
    end
    bf = [tempname '.json'];                   % body via a file: portable quoting
    fid = fopen(bf, 'w');                      % (single quotes break on Windows)
    fprintf(fid, '%s', body);
    fclose(fid);
    f  = [tempname '.json'];
    st = system(sprintf(['curl -s --max-time 120 -H "Content-Type: application/json" ' ...
                         '-d @"%s" -o "%s" "https://api.bls.gov/publicAPI/v2/timeseries/data/"'], bf, f));
    assert(st == 0, 'BLS API request failed for %d-%d', w0, w1);
    R = jsondecode(fileread(f));
    assert(strcmp(R.status, 'REQUEST_SUCCEEDED'), 'BLS API: %s', strjoin(string(R.message), '; '));
    for k = 1:numel(R.Results.series)
        s = R.Results.series(k);
        j = find(strcmp(ids, s.seriesID));
        for i = 1:numel(s.data)
            d = s.data(i);
            if iscell(s.data), d = s.data{i}; end
            if d.period(1) ~= 'M' || strcmp(d.period, 'M13')
                continue                       % skip annual averages
            end
            m = str2double(d.period(2:3));
            r = find(year(TimeM) == str2double(d.year) & month(TimeM) == m, 1);
            X(r, j) = str2double(strrep(d.value, ',', ''));
        end
    end
end
last = find(any(isfinite(X), 2), 1, 'last');   % trim unused tail months
X = X(1:last, :);
TimeM = TimeM(1:last);
for j = 1:numel(ids)
    b = find(isfinite(X(:,j)), 1, 'last');
    fprintf('  %s: BLS API, %d obs to %s\n', ids{j}, sum(isfinite(X(:,j))), string(TimeM(b)));
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
