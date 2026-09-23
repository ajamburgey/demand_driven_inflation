function xa = seasadj(x, TimeM)
%SEASADJ  Simple multiplicative seasonal adjustment (ratio to moving average, in logs).
%   xa = seasadj(x, TimeM) removes a fixed multiplicative seasonal pattern
%   from the monthly index x: the seasonal factor of each calendar month is
%   the average deviation of log x from its centered twelve-month moving
%   average, renormalized to sum to zero over the twelve months.
%
%   The PUBLIC data mode uses it only for the two euro-area energy
%   components (COICOP 04.5 and 07.2.2), for which no official seasonally
%   adjusted series exists (see data/SOURCES.md); every other euro-area
%   aggregate comes seasonally adjusted from the ECB. The classical
%   ratio-to-moving-average method is deliberately simple; the wedge
%   against the Haver-adjusted versions of the same components is reported
%   by ComparePanels.m.
lx = log(x(:));
n  = numel(lx);

% centered twelve-month moving average (half weights on the end months)
ma = NaN(n,1);
for t = 7:n-6
    ma(t) = (lx(t-6)/2 + sum(lx(t-5:t+5)) + lx(t+6)/2) / 12;
end

% average deviation by calendar month, renormalized to sum to zero
dev = lx - ma;
mo  = month(TimeM(:));
s   = NaN(12,1);
for m = 1:12
    s(m) = mean(dev(mo == m), 'omitnan');
end
s = s - mean(s);

xa = exp(lx - s(mo));
xa(~isfinite(x(:))) = NaN;
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
