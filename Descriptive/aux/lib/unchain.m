function Punch = unchain(Plev,Time);
%UNCHAIN  Within-year price relatives of monthly index levels.
%   Punch = unchain(Plev,Time) returns, for each column of the level matrix
%   Plev (monthly, dates Time), the ratio of the level to the PREVIOUS
%   December's level:  Punch(t) = Plev(t) / Plev(Dec of year-1).
%   This strips out the index base so the series can be re-weighted and
%   re-chained (see imps2weights.m, chainlink.m, and the chain-linking
%   subsection of text/ReplicationManual.tex).
%   The chain is anchored at t0 = the first December in which every column is
%   non-NaN; months before t0 are returned as NaN.
%   Used by chainagg.m / chaincontrib.m to build US CPI sub-aggregates.

t0 = min(find(sum(isnan(Plev),2)==0 & month(Time)==12));

Years = unique(year(Time(t0:end)));
Punch = Plev*NaN;

for jy = 2:length(Years)
    currYear = Years(jy);
    Index = (year(Time)==currYear);
    Punch(Index,:) = Plev(Index,:)./(ones(sum(Index),1)*Plev(year(Time)==currYear-1&month(Time)==12,:));
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
