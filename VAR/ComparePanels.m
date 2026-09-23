% ComparePanels.m: diagnostic workbook comparing the haver vs public
% vintages of every EA HICP series used across the VAR and Descriptive
% folders -- headline, ex energy, goods, services, energy, household
% energy and transport energy
%
% For household and transport energy (COICOP 04.5 and 07.2.2), the public
% vintage is NSA (no official seasonally adjusted version exists anywhere
% for these two); this script seasonally adjusts it with the package's
% own aux/lib/seasadj.m before comparing, the same treatment
% PrepareVARData.m applies. The raw NSA public level is also shown for
% reference. Every other series is already seasonally adjusted on both
% sides.
%
% Note: Goods and Services HICP come from ../Descriptive/data/raw instead.
%
% Output: data/HaverPublicComparison_EAEnergy.xlsx (one sheet per series)

close all
clear
addpath('aux')
addpath('aux/lib')

VARraw  = fullfile('data','raw');
DESCraw = fullfile('..','Descriptive','data','raw');

series = struct( ...
    'sheet',        {'EAHICP_Headline','EAHICP_ExEnergy','EAHICP_Goods','EAHICP_Services', ...
                      'EAHICP_Energy','EAHICP_HouseholdEnergy','EAHICP_TransportEnergy'}, ...
    'rawdirbase',   {VARraw, VARraw, DESCraw, DESCraw, VARraw, VARraw, VARraw}, ...
    'srclabel',     {'VAR/data/raw','VAR/data/raw','Descriptive/data/raw','Descriptive/data/raw', ...
                      'VAR/data/raw','VAR/data/raw','VAR/data/raw'}, ...
    'title',        {'EA HICP Headline (all items) -- both sides already seasonally adjusted', ...
                      'EA HICP ex Energy -- both sides already seasonally adjusted', ...
                      'EA HICP Goods -- both sides already seasonally adjusted', ...
                      'EA HICP Services -- both sides already seasonally adjusted', ...
                      'EA HICP Energy (04.5+07.2.2) -- both sides already seasonally adjusted', ...
                      'EA HICP Household Energy (COICOP 04.5) -- public side is NSA; we seasonally adjust it (seasadj.m)', ...
                      'EA HICP Transport Energy (COICOP 07.2.2) -- public side is NSA; we seasonally adjust it (seasadj.m)'}, ...
    'needsSeasadj', {false, false, false, false, false, true, true} ...
);

outfile = fullfile('data','HaverPublicComparison_EAEnergy.xlsx');
if isfile(outfile), delete(outfile); end   % start clean -- writecell appends sheets to an existing file otherwise

for k = 1:numel(series)
    s = series(k);
    hdir = fullfile(s.rawdirbase, 'haver');
    pdir = fullfile(s.rawdirbase, 'public');
    [th, xh] = readraw(hdir, s.sheet, 'haver');
    [tp, xp] = readraw(pdir, s.sheet, 'public');

    if s.needsSeasadj
        xpSA = seasadj(xp, tp);
    else
        xpSA = xp;
    end

    tgrid = union(th, tp);
    hc   = aligngrid(th, xh,   tgrid);
    pcSA = aligngrid(tp, xpSA, tgrid);

    hyoy     = yoygrowth(hc);
    pyoy     = yoygrowth(pcSA);
    leveldiff = hc - pcSA;
    yoydiff   = hyoy - pyoy;

    if s.needsSeasadj
        pcRaw = aligngrid(tp, xp, tgrid);
        headers = {'Date','Haver Level (SA)','Public Level (NSA raw)','Public Level (SA, adjusted)', ...
                   'Level Diff (Haver - Public SA)','Haver YoY %','Public YoY % (SA)','YoY Diff (pp)'};
        datacols = [hc, pcRaw, pcSA, leveldiff, hyoy, pyoy, yoydiff];
        note = 'Public level shown below is AFTER our own seasonal adjustment (ratio-to-moving-average, aux/lib/seasadj.m). Raw NSA public level is included for reference.';
    else
        headers = {'Date','Haver Level (SA)','Public Level (SA)','Level Diff (Haver - Public)', ...
                   'Haver YoY %','Public YoY %','YoY Diff (pp)'};
        datacols = [hc, pcSA, leveldiff, hyoy, pyoy, yoydiff];
        note = 'Both sides are already published seasonally adjusted -- no adjustment applied.';
    end

    dateCol = cellstr(datestr(tgrid, 'yyyy-mm-dd'));
    body = [dateCol, numcell(datacols)];

    C = cell(4 + numel(tgrid), numel(headers));
    C{1,1} = s.title;
    C{2,1} = [note '  [source: ' s.srclabel ']'];
    C(4, 1:numel(headers)) = headers;
    C(5:end, :) = body;
    writecell(C, outfile, 'Sheet', s.sheet);

    % summary block, a couple of columns to the right of the data
    commonBoth = isfinite(hc) & isfinite(pcSA);
    ld = leveldiff(commonBoth);
    yd = yoydiff(commonBoth & isfinite(yoydiff));
    summary = { ...
        'Summary (common obs)', []; ...
        'N common obs (level)', sum(commonBoth); ...
        'Max |level diff|',     max(abs(ld)); ...
        'Mean |level diff|',    mean(abs(ld)); ...
        'N common obs (YoY)',   numel(yd); ...
        'Max |YoY diff| (pp)',  max(abs(yd)); ...
        'Mean |YoY diff| (pp)', mean(abs(yd)) ...
    };
    sumCol = numel(headers) + 2;
    writecell(summary, outfile, 'Sheet', s.sheet, 'Range', [colletter(sumCol) '4']);

    fprintf('%s: %d common obs, max|YoY diff| = %.4f pp, mean|YoY diff| = %.4f pp\n', ...
            s.sheet, numel(yd), max(abs(yd)), mean(abs(yd)));
end

fprintf('ComparePanels: wrote %s\n', outfile);

% -------------------------------------------------------------------------
%% Functions

function [t, x] = readraw(rawdir, name, sfx)
% readraw  Load one (Date,Value) CSV written by GetVARData.m or GetChartData.m.
f = fullfile(rawdir, [name '_' sfx '.csv']);
if ~isfile(f)
    error('ComparePanels: %s not found -- run the matching GetXData.m (with SOURCE=''%s'') first.', f, sfx);
end
tb = readtable(f);
t = tb.Date;
x = tb.Value;
end

function v = aligngrid(t, x, tgrid)
% aligngrid  Reindex a dated series onto a shared date grid, NaN where missing.
v = NaN(size(tgrid));
[~, ia, ib] = intersect(tgrid, t);
v(ia) = x(ib);
end

function g = yoygrowth(x)
% yoygrowth  Year-on-year percent change of a monthly series (12-row lag).
g = NaN(size(x));
if numel(x) > 12
    g(13:end) = 100*(x(13:end)./x(1:end-12) - 1);
end
end

function C = numcell(M)
% numcell  Numeric matrix -> cell array, with NaN written as a blank cell.
C = num2cell(M);
for i = 1:numel(C)
    if isnan(C{i}), C{i} = []; end
end
end

function s = colletter(n)
% colletter  1-based column index -> Excel column letter(s).
s = '';
while n > 0
    r = mod(n-1,26);
    s = [char('A'+r) s]; %#ok<AGROW>
    n = floor((n-1)/26);
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
