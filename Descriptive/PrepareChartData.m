% PrepareChartData.m: build the DESCRIPTIVE-CHART dataset of the paper
%   (figure 1 and its energy companion, figure 4) from the raw series
%   GetChartData.m already fetched to data/raw/
%
%   US: constructed from BLS components with the same chain-linked machinery
%   as PrepareVARData (aux/lib), on the HICP concept of appendix A of the paper:
%     headline = all items less owners' equivalent rent (OER);
%     goods    = all items less "services less energy services" less "food
%                away from home"  (identically: commodities less food and
%                energy commodities, plus food at home, plus energy -- i.e.
%                energy, including energy services, is a GOOD, and
%                restaurants are a SERVICE, as in the HICP);
%     services = "services less energy services" plus "food away from home"
%                less OER.
%   Levels (SA; PCUFAN is NSA = CUUR0000SEFV, identical to the SA series
%   since Aug 1992):                      Relative importances:
%     PCU       all items                   RPCU
%     PCUSSLE   services less energy svcs   RUSXEGM
%     PCUFAN    food away from home         RPCUFA
%     PCUHSHA   owners' equivalent rent     RPCUHSHA
%     PCUSE     energy                      RUEGM
%     PCUHFF    household energy            RPCUHFF
%
%   EA: published Eurostat aggregates, changing composition (EA11-21), SA:
%     H023HICP  HICP all items              H023QG    HICP goods
%     H023QE    HICP energy                 H023QS    HICP services
%     H023HW5   electricity, gas and other fuels (04.5)
%     H023HN22  fuels and lubricants for personal transport (07.2.2)
%
%   Output:  data/DataChart.mat : TimeQ, CH (quarters x 12), MnemC, DescrC
%            columns: HEADus HEADea GOODus GOODea SERVus SERVea
%                     ENERus ENERea HHENus HHENea TRENus TRENea
%            plus CONTRIB (quarters x 8): the contribution accounting of
%            headline inflation, EXus HHus TRus HEADus, EXea HHea TRea HEADea

close all
clear
addpath('aux')
addpath('aux/lib')
addpath(fullfile('data','public'))   % BLSRelativeImportance.csv, for publicweights.m

% which vintage of the dual-source raw series to use
SOURCE = 'haver';   % 'haver' or 'public'
rawdir = fullfile('data','raw',SOURCE);

load(fullfile('..','VAR','data','VARData.mat'), 'TimeQ');

%% 1) US: components and chain-linked aggregates --------------------------------
[TimeM, LEV1] = readraw(rawdir, 'USCPI_AllItems');
[~,     LEV2] = readraw(rawdir, 'USCPI_ServicesLessEnergy');
[~,     LEV3] = readraw(rawdir, 'USCPI_FoodAwayHome');
[~,     LEV4] = readraw(rawdir, 'USCPI_OER');
[~,     LEV5] = readraw(rawdir, 'USCPI_Energy');
[~,     LEV6] = readraw(rawdir, 'USCPI_HouseholdEnergy');
LEV = [LEV1 LEV2 LEV3 LEV4 LEV5 LEV6];

if strcmp(SOURCE, 'haver')
    [~, W1] = readraw(rawdir, 'USWeight_AllItems');
    [~, W2] = readraw(rawdir, 'USWeight_ServicesLessEnergy');
    [~, W3] = readraw(rawdir, 'USWeight_FoodAwayHome');
    [~, W4] = readraw(rawdir, 'USWeight_OER');
    [~, W5] = readraw(rawdir, 'USWeight_Energy');
    [~, W6] = readraw(rawdir, 'USWeight_HouseholdEnergy');
    W = [W1 W2 W3 W4 W5 W6];
else
    % same shipped file PrepareVARData.m uses for its own weights
    W = publicweights(TimeM, {'AllItems','ServicesLessEnergyServices', ...
                             'FoodAwayFromHome','OER','Energy','HouseholdEnergy'});
end
LEV = fillgap(LEV);          % October 2025, the federal-shutdown month

%                              PCU  SSLE  FAN  OER  ENER  HHEN
HEADus_m = chainagg(LEV, W, [   1    0    0   -1    0     0 ], TimeM);
GOODus_m = chainagg(LEV, W, [   1   -1   -1    0    0     0 ], TimeM);
SERVus_m = chainagg(LEV, W, [   0    1    1   -1    0     0 ], TimeM);
ENERus_m = chainagg(LEV, W, [   0    0    0    0    1     0 ], TimeM);
HHENus_m = chainagg(LEV, W, [   0    0    0    0    0     1 ], TimeM);
TRENus_m = chainagg(LEV, W, [   0    0    0    0    1    -1 ], TimeM);
EXENus_m = chainagg(LEV, W, [   1    0    0   -1   -1     0 ], TimeM);

USm      = dropanchor([HEADus_m GOODus_m SERVus_m ENERus_m HHENus_m TRENus_m]);
EXENus_m = dropanchor(EXENus_m);

%% 2) EA: published aggregates ----------------------------------------------------
[TimeE, EA1] = readraw(rawdir, 'EAHICP_Headline');
[~,     EA2] = readraw(rawdir, 'EAHICP_Goods');
[~,     EA3] = readraw(rawdir, 'EAHICP_Services');
[~,     EA4] = readraw(rawdir, 'EAHICP_Energy');
[~,     EA5] = readraw(rawdir, 'EAHICP_HouseholdEnergy');
[~,     EA6] = readraw(rawdir, 'EAHICP_TransportEnergy');
[~,     EA7] = readraw(rawdir, 'EAHICP_ExEnergy');
EAm_m = [EA1 EA2 EA3 EA4 EA5 EA6 EA7];

if strcmp(SOURCE, 'public')
    EAm_m(:,5) = seasadj(EAm_m(:,5), TimeE);   % no official SA exists for 04.5
    EAm_m(:,6) = seasadj(EAm_m(:,6), TimeE);   % and 07.2.2: adjust here
end

%% 3) quarterly panel -------------------------------------------------------------
USq = toquarterly(USm,   TimeM, TimeQ);
EAq = toquarterly(EAm_m, TimeE, TimeQ);

CH = [USq(:,1) EAq(:,1) USq(:,2) EAq(:,2) USq(:,3) EAq(:,3) ...
      USq(:,4) EAq(:,4) USq(:,5) EAq(:,5) USq(:,6) EAq(:,6)];

MnemC  = {'HEADus';'HEADea';'GOODus';'GOODea';'SERVus';'SERVea'; ...
          'ENERus';'ENERea';'HHENus';'HHENea';'TRENus';'TRENea'};
DescrC = {'US CPI-U less OER, SA, chain-linked (HICP concept)'; ...
          'EA HICP all items, changing composition, SA (Haver H023HICP)'; ...
          'US CPI goods, HICP concept (= all items - services ex energy services - food away), chain-linked'; ...
          'EA HICP goods, changing composition, SA (Haver H023QG)'; ...
          'US CPI services, HICP concept (= services ex energy services + food away - OER), chain-linked'; ...
          'EA HICP services, changing composition, SA (Haver H023QS)'; ...
          'US CPI energy, SA (chain-linked, replicates the published aggregate)'; ...
          'EA HICP energy, SA (Haver H023QE)'; ...
          'US CPI household energy, SA (PCUHFF)'; ...
          'EA HICP electricity, gas and other fuels, 04.5, SA (Haver H023HW5)'; ...
          'US CPI transport energy = energy less household energy, chain-linked'; ...
          'EA HICP fuels and lubricants for personal transport, 07.2.2, SA (Haver H023HN22)'};

%% 3b) the CONTRIBUTION accounting of headline inflation ---------------------------
% Headline year-on-year inflation decomposed EXACTLY into the contributions
% of prices ex energy, household energy and transportation energy, with the
% chain-linking machinery of the two indexes (lib/chaincontrib: annual links
% at December, within-period weights fixed; the contributions add up to the
% implied aggregate's 12-month change without residual).
%   US weights: BLS relative importances (previous December's), so the
%       three components partition the ex-OER basket:
%       ex energy = RPCU-RUEGM-RPCUHSHA, household = RPCUHFF,
%       transport = RUEGM-RPCUHFF.
%   EA weights: official HICP item weights (Eurostat prc_hicp_inw, annual,
%       per mille; not on Haver), CP045 and CP0722; ex energy = the rest.
WD    = imps2weights(W, TimeM);
WDus  = [WD(:,1)-WD(:,5)-WD(:,4)  WD(:,6)  WD(:,5)-WD(:,6)];
[Cus, gus] = chaincontrib([EXENus_m HHENus_m TRENus_m], WDus, TimeM);

[whhEA, wtrEA] = eurostatweights(fullfile('data','raw','EAItemWeights.csv'), TimeE);
WDea  = [1-whhEA-wtrEA  whhEA  wtrEA];
[Cea, gea] = chaincontrib(EAm_m(:,[7 5 6]), WDea, TimeE);

% checks: additivity is exact by construction; the implied aggregates must
% match the headline series (US: identical construction; EA: published).
% The EA gap concentrates in 1997-2000 (up to 0.6 pp), where the ex-energy
% input is a Haver back-extension that runs about 0.4 pp per year below the
% ECB back-calculated rate (see data/SOURCES.md); from 2001 the two series
% agree closely, and the contribution figure starts in 2018.
gUShead = 100*(HEADus_m(13:end)./HEADus_m(1:end-12) - 1);
dUS = max(abs(100*gus(13:end) - gUShead), [], 'omitnan');
gEAhead = 100*(EAm_m(13:end,1)./EAm_m(1:end-12,1) - 1);
dEA = max(abs(100*gea(13:end) - gEAhead), [], 'omitnan');
i01 = find(TimeE >= datetime(2001,1,1), 1) - 12;       % months from 2001 in the yoy vectors
dEA01 = max(abs(100*gea(i01+12:end) - gEAhead(i01:end)), [], 'omitnan');
fprintf('contribution check: implied vs headline yoy, max|diff| US %.4f pp, EA %.3f pp (from 2001: %.3f pp)\n', dUS, dEA, dEA01);

CONTRIB = [toquarterly(100*[Cus gus], TimeM, TimeQ) toquarterly(100*[Cea gea], TimeE, TimeQ)];
save(fullfile('data', 'DataChart.mat'), 'TimeQ', 'CH', 'MnemC', 'DescrC', 'CONTRIB');

% -------------------------------------------------------------------------
%% Functions

function [t, x] = readraw(rawdir, name)
% readraw  Read one (Date,Value) CSV written by GetChartData.m, named
% <name>_<source>.csv (see writeraw in GetChartData.m).
[~, sfx] = fileparts(rawdir);
tb = readtable(fullfile(rawdir, [name '_' sfx '.csv']));
t  = tb.Date;
x  = tb.Value;
end

function x = dropanchor(x)
% remove the flat anchor year: the first 24 months of each chain-linked column
for j = 1:size(x,2)
    i = find(isfinite(x(:,j)), 1);
    if ~isempty(i), x(i : min(i+23, size(x,1)), j) = NaN; end
end
end

function [whh, wtr] = eurostatweights(file, TimeGrid)
% EA HICP item weights (annual, per mille) from the shipped, pre-fetched
% data/raw/EAItemWeights.csv (see GetChartData.m), expanded to the given
% time grid as shares of the total basket
tb  = readtable(file);
whh = NaN(size(TimeGrid));  wtr = NaN(size(TimeGrid));
for j = 1:height(tb)
    sel = (year(TimeGrid) == tb.Year(j));
    whh(sel) = tb.CP045(j)/1000;
    wtr(sel) = tb.CP0722(j)/1000;
end
fprintf('EA HICP weights: Eurostat prc_hicp_inw, %d-%d\n', min(tb.Year), max(tb.Year));
% the weights of the current year appear on the portals only with a lag
% (as of July 2026 both Eurostat and the ECB stop at 2025), so the last
% published weights carry forward until the official ones arrive
lastyr = max(tb.Year);
sel = year(TimeGrid) > lastyr;
if any(sel)
    whh(sel) = tb.CP045(tb.Year==lastyr)/1000;
    wtr(sel) = tb.CP0722(tb.Year==lastyr)/1000;
    fprintf('EA HICP weights: %d+ not yet published, carrying the %d weights forward\n', ...
            lastyr+1, lastyr);
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
