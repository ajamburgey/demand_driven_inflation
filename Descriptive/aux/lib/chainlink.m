function Pchain = chainlink(Punch,Time)
%CHAINLINK  Re-chain within-year relatives into a continuous index.
%   Pchain = chainlink(Punch,Time) is the inverse of unchain.m: given within-
%   year price relatives Punch (e.g. the weighted relative of a sub-aggregate),
%   it rebuilds a level index by chaining each year onto the previous December,
%   Pchain(t) = Punch(t) * Pchain(Dec of year-1), anchored to 1 in the first
%   December where Punch is complete (see the chain-linking subsection of text/ReplicationManual.tex). Applied to
%   the weighted combination of components, it yields the US CPI sub-aggregates
%   (headline ex-OER, ex-energy, energy, transport/household energy).

t0 = min(find(sum(isnan(Punch),2)==0 & month(Time)==12));

Years = unique(year(Time(t0:end)));

Pchain = Punch*NaN;
Pchain(year(Time)==Years(1),:)=1;

for jy = 2:length(Years)
    currYear = Years(jy);
    Index = (year(Time)==currYear);
    Pchain(Index,:) = Punch(Index,:).*Pchain(year(Time)==currYear-1&month(Time)==12,:);
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
