function [C, g] = chaincontrib(LEV, WD, Time)
%CHAINCONTRIB  Exact contributions to the 12-month change of a chain-linked
%   aggregate (the BLS / HICP convention: annual links at December, weights
%   fixed within each link period).
%
%   [C, g] = chaincontrib(LEV, WD, Time)
%
%   LEV   T x n  component index levels (monthly, SA)
%   WD    T x n  the APPLICABLE link weights in each month: for a month of
%                calendar year y, the weight vector of year y's link period
%                (for the US CPI, the output of imps2weights; for the HICP,
%                the official weights of year y)
%   Time  T x 1  monthly dates
%
%   C     T x n  contributions, which sum EXACTLY to g
%   g     T x 1  the 12-month growth of the implied chain-linked aggregate
%
%   The 12-month change spans two link periods, so it is decomposed over two
%   legs -- (t-12) -> December, with the old period's current-price shares,
%   and December -> t, with the new period's weights -- and the legs are
%   compounded:
%       g = r1 + (1+r1) r2 ,   C_j = s1_j g1_j + (1+r1) s2_j g2_j ,
%   where g1_j, g2_j are the component growth rates over the two legs,
%   s1_j the current-price share of j at t-12 (link weights times the
%   within-period relative, normalized) and s2_j the link weight share of
%   the new period. Within a link period a chain-linked aggregate is a
%   weighted average of the component relatives, so each leg is exactly
%   additive; compounding the two preserves additivity.

[T, n] = size(LEV);
C = NaN(T, n);
g = NaN(T, 1);

for t = 13:T
    if month(Time(t)) == 12
        % a December-to-December change is exactly one link period: one leg
        x = LEV(t,:) ./ LEV(t-12,:) - 1;
        w = WD(t,:);
        if any(~isfinite([x w])), continue; end
        s      = w / sum(w);
        C(t,:) = s .* x;
        g(t)   = sum(C(t,:));
        continue
    end
    y  = year(Time(t));
    D1 = find(year(Time) == y-1 & month(Time) == 12);      % December, year y-1
    D2 = find(year(Time) == y-2 & month(Time) == 12);      % December, year y-2
    if isempty(D1) || isempty(D2), continue; end
    lev = [LEV(t-12,:); LEV(D1,:); LEV(t,:)];
    w1  = WD(t-12,:);  w2 = WD(t,:);
    if any(~isfinite([lev(:)' w1 w2])), continue; end

    R1 = LEV(t-12,:) ./ LEV(D2,:);                 % relatives in period y-1
    s1 = (w1 .* R1) / sum(w1 .* R1);               % current-price shares, t-12
    g1 = LEV(D1,:) ./ LEV(t-12,:) - 1;
    r1 = sum(s1 .* g1);

    s2 = w2 / sum(w2);                             % link-weight shares, year y
    g2 = LEV(t,:) ./ LEV(D1,:) - 1;
    r2 = sum(s2 .* g2);

    C(t,:) = s1 .* g1 + (1 + r1) * (s2 .* g2);
    g(t)   = r1 + (1 + r1) * r2;
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
