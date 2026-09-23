function L = fillgap(L)
%FILLGAP  Fill isolated single missing months in monthly index LEVELS.
%
%   L = fillgap(L) replaces, in each column, any month that is NaN while both
%   neighbours are present with the geometric mean
%
%       L(m) = sqrt( L(m-1) * L(m+1) ),
%
%   i.e. the known two-month change is split into two equal monthly steps.
%   Longer gaps and endpoints are left NaN.
%
%   Used for October 2025: the US federal shutdown meant BLS published no
%   October 2025 CPI; the index resumed in November, so October is a single
%   interior gap bracketed by known values. The back-test of this fill, and of
%   its (negligible) effect through the chain-linking, is in the authors'
%   companion archive.

for j = 1:size(L,2)
    for m = 2:size(L,1)-1
        if isnan(L(m,j)) && ~isnan(L(m-1,j)) && ~isnan(L(m+1,j))
            L(m,j) = sqrt( L(m-1,j) * L(m+1,j) );
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
