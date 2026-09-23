function W = publicweights(TimeM, names)
%PUBLICWEIGHTS  BLS December relative importances from the shipped file.
%   W = publicweights(TimeM, {'AllItems','Energy','OER','HouseholdEnergy'})
%   returns a matrix on the monthly grid TimeM with the December values of
%   the requested components filled in and NaN elsewhere, exactly the
%   shape the chain-linking (imps2weights) expects.
%
%   The file data/public/BLSRelativeImportance.csv ships with the package.
%   Its values equal the published BLS relative importance tables
%   (https://www.bls.gov/cpi/tables/relative-importance/, one table per
%   year), which the BLS site serves only to browsers; see data/SOURCES.md
%   for the verification. To extend it, append one row per new December
%   from the published table.
root = fileparts(fileparts(mfilename('fullpath')));    % data/
T = readtable('BLSRelativeImportance.csv', 'CommentStyle', '#');
W = NaN(numel(TimeM), numel(names));
for j = 1:numel(names)
    v = T.(names{j});
    for i = 1:height(T)
        k = find(year(TimeM) == T.december(i) & month(TimeM) == 12, 1);
        if ~isempty(k)
            W(k, j) = v(i);
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
