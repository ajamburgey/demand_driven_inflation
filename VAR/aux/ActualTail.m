function [dts, val] = ActualTail(mnem, trans, lastdate)
% ActualTail  The observed tail of a series after the model sample ends:
% the quarters beyond lastdate where the data already exist, on the
% model's transformation ('yoy' = log change from four quarters earlier,
% 'rate' = level over 100). The demand-model figures use it to draw the
% actual lines through the quarters where the decomposition bars must
% wait for the fiscal data release. When a series has no observations
% beyond the sample (the two deficits), the tail comes back empty and
% the figure is unchanged.
S = load(fullfile('data','VARData.mat'));
x = S.Data(:, strcmp(S.Mnem, mnem));
switch trans
    case 'yoy',  v = [NaN(4,1); log(x(5:end) ./ x(1:end-4))];
    case 'rate', v = x/100;
end
sel = S.TimeQ > lastdate & S.TimeQ <= datetime(2026,1,1) & ~isnan(v);   % paper sample convention
dts = S.TimeQ(sel);  val = v(sel);
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
