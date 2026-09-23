function P = chainagg(Levels, RelImps, signs, Time)
%CHAINAGG  Chain-linked aggregate of CPI components (wraps the lib/ routines).
%
%   P = chainagg(Levels, RelImps, signs, Time)
%
%   combines the component price indices (columns of Levels, monthly, SA) into
%   one chain-linked index, weighting with the relative importances (columns of
%   RelImps, same order). signs says what to do with each component:
%       +1  add it        -1  remove it        0  not involved
%   e.g. with components [all-items, energy, OER, household-energy]:
%       chainagg(L, W, [1  0 -1  0], Time)   = all items less OER
%       chainagg(L, W, [1 -1 -1  0], Time)   = all items less energy less OER
%
%   It is exactly the BLS / HICP convention, done by three routines:
%       unchain      : within-year price relatives to the previous December
%       imps2weights : each year weighted by the previous December's
%                      relative importances
%       chainlink    : re-chain the weighted relatives into an index
%
%   NOTES.  (1) The sample starts at the first December where ALL components in
%   Levels are available (unchain's anchor), whatever the signs.  (2) chainlink
%   sets the whole anchor year flat = 1, so the first 24 months of P are an
%   artifact, not data; GetData.m and GetChartData.m drop them.  GetData.m
%   prints checks that this machinery reproduces already-published BLS
%   aggregates.

r = unchain(Levels, Time);                    % price relatives
w = imps2weights(RelImps, Time);              % prior-December weights
a = ones(size(w,1),1) * signs;                % +1 / -1 / 0 per component
P = chainlink( sum(r.*w.*a, 2) ./ sum(w.*a, 2), Time );
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
