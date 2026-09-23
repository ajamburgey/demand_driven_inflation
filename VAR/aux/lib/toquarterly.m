function Xq = toquarterly(Xm, TimeM, TimeQ)
%TOQUARTERLY  Quarterly averages of monthly series.
%
%   Xq = toquarterly(Xm, TimeM, TimeQ)
%
%   averages the monthly data (columns of Xm, dated TimeM) into quarters
%   (dated TimeQ). A quarter needs all three months, otherwise it is NaN.

Xq = nan(numel(TimeQ), size(Xm,2));
for i = 1:numel(TimeQ)
    rows = year(TimeM)==year(TimeQ(i)) & quarter(TimeM)==quarter(TimeQ(i));
    for j = 1:size(Xm,2)
        v = Xm(rows, j);
        if numel(v) == 3 && all(isfinite(v))
            Xq(i,j) = mean(v);
        end
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
