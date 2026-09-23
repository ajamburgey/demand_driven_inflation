function [x, t, meta] = haverseries(code, key)
%HAVERSERIES  Download one series from Haver (HaverView REST API).
%
%   [x, t, meta] = haverseries('PCU@USECON', key)
%
%   returns the observations x and their dates t (datetime) of series PCU in
%   database USECON. Codes are written exactly as in Haver DLX:
%   'H023HICP@EUDATA', 'GDPH@USECON', 'S023MD@MKTPMI', ...
%
%   meta holds ALL the metadata the API reports (description, source,
%   frequency, data type, geography, when the series was last modified, ...);
%   each observation itself carries only its date and value, so nothing is
%   discarded. A one-line report of what was downloaded is printed:
%     PCU@USECON: CPI-U: All Items (SA, 1982-84=100) | Bureau of Labor
%     Statistics | 953 obs to 2026-05, last modified 2026-06-11
%
%   The API key is passed in by the caller (see the calling script's own
%   HAVER_KEY setting) rather than read from a file here.

if isempty(key)
    error('haverseries: pass your Haver API key (see the calling script''s HAVER_KEY setting).');
end

% --- download the series as JSON -----------------------------------------
parts = split(string(code), '@');                            % 'PCU@USECON' -> PCU, USECON
url   = "https://api.haverview.com/v4/database/" + upper(parts(2)) + ...
        "/series/" + upper(parts(1));
opts  = weboptions('HeaderFields', {'X-API-Key', key}, ...
                   'Timeout', 60, 'ContentType', 'json');
d     = webread(url, opts);

% --- unpack date/value pairs ----------------------------------------------
n = numel(d.dataPoints);
t = NaT(n, 1);
x = nan(n, 1);
for i = 1:n
    if iscell(d.dataPoints), obs = d.dataPoints{i}; else, obs = d.dataPoints(i); end
    t(i) = datetime(obs.date, 'InputFormat', 'yyyy-MM-dd');
    if isfield(obs, 'nSeriesData') && ~isempty(obs.nSeriesData)
        x(i) = obs.nSeriesData;                              % missing stays NaN
    end
end

% --- keep all the metadata and report what was downloaded ------------------
meta = rmfield(d, 'dataPoints');
if isfield(d, 'datetimeLastModified')
    meta.lastModified = datetime(d.datetimeLastModified, 'ConvertFrom', 'posixtime');
end
descr = '';  if isfield(d, 'description'), descr = d.description; end
src   = '';  if isfield(d, 'sourceName'),  src   = d.sourceName;  end
lastm = '';  if isfield(meta, 'lastModified'), lastm = string(meta.lastModified, 'yyyy-MM-dd'); end
fprintf('  %s: %s | %s | %d obs to %s, last modified %s\n', ...
        code, descr, src, n, string(t(end), 'yyyy-MM'), lastm);
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
