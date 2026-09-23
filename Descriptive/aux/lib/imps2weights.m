function Weights =imps2weights(RelImp,Time);
%IMPS2WEIGHTS  Turn monthly relative importances into chaining weights.
%   Weights = imps2weights(RelImp,Time) sets every month of year y to the
%   relative importances observed in DECEMBER of year y-1, held constant
%   through the year. See the chain-linking subsection of text/ReplicationManual.tex: the fixed
%   prior-December weights the chain-linking convention uses. The first year is
%   returned as NaN (no prior December). Pairs with unchain.m / chainlink.m.

Years = unique(year(Time));

Weights = RelImp*NaN;

for jy = 2:length(Years)
    currYear = Years(jy);
    Index = (year(Time)==currYear);
    Weights(Index,:) =  ones(sum(Index),1)*RelImp(year(Time)==currYear-1&month(Time)==12,:);
end;

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
