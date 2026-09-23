function [X, Time, Meta] = haverpanel(codes, freq, key, Time)
%HAVERPANEL  Download several Haver series onto one common time grid.
%
%   [X, Time, Meta] = haverpanel({'PCU@USECON','PCUSE@USECON'}, 'M', key)
%
%   downloads each series with haverseries and aligns them as the columns of X
%   on a common MONTHLY grid ('Q' for quarterly), running from the earliest to
%   the latest observation over all the series. Missing months are NaN.
%   Meta{j} holds all the metadata the API reports for series j (haverseries
%   also prints a one-line report per series while downloading).
%
%   haverpanel(codes, freq, key, Time) aligns on a grid you supply instead.
%
%   key is your Haver API key (see the calling script's own HAVER_KEY
%   setting), passed straight through to haverseries.

nser = numel(codes);
xs = cell(nser, 1);
ts = cell(nser, 1);
Meta = cell(nser, 1);
for j = 1:nser
    [xs{j}, ts{j}, Meta{j}] = haverseries(codes{j}, key);
end

% --- the common grid ------------------------------------------------------
if nargin < 4
    t0 = ts{1}(1);  t1 = ts{1}(end);
    for j = 2:nser
        t0 = min(t0, ts{j}(1));
        t1 = max(t1, ts{j}(end));
    end
    if upper(freq) == 'M'
        Time = (dateshift(t0,'start','month')   : calmonths(1)   : dateshift(t1,'start','month'))';
    else
        Time = (dateshift(t0,'start','quarter') : calquarters(1) : dateshift(t1,'start','quarter'))';
    end
end

% --- put every series on the grid (match by year+month / year+quarter) ----
X = nan(numel(Time), nser);
for j = 1:nser
    for i = 1:numel(Time)
        if upper(freq) == 'M'
            k = find(year(ts{j})==year(Time(i)) & month(ts{j})==month(Time(i)), 1);
        else
            k = find(year(ts{j})==year(Time(i)) & quarter(ts{j})==quarter(Time(i)), 1);
        end
        if ~isempty(k), X(i,j) = xs{j}(k); end
    end
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
