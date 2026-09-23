function d = DataEdge()
% DataEdge  The last quarter with any observed data in the panel. The
% figure scripts put the right edge of every x axis just past this
% quarter, so all decomposition charts end together at the data frontier
% (the demand model's bars stop earlier, at the last quarter with fiscal
% data, while its actual lines run to the edge).
S = load(fullfile('data','VARData.mat'));
d = max(S.TimeQ(any(~isnan(S.Data), 2)));
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
