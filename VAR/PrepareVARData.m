% PrepareVARData.m: Build the basic VAR dataset for the US and the euro
% area from the raw series GetVARData.m already fetched to data/raw/
%
%   The seven variables (two columns each, US and EA):
%     P  consumer prices excluding energy
%          US: CPI-U excluding energy AND excluding owners' equivalent rent
%              (OER), so that it matches the euro-area HICP concept, which
%              has no owner-occupied housing. Constructed from BLS components
%              by chain-linked aggregation (section 1).
%          EA: HICP excluding energy, the published Eurostat special
%              aggregate, changing-composition euro area, SA.
%     Q  real GDP.
%     H  HOUSEHOLD energy prices (electricity, gas and other household fuels).
%     T  TRANSPORT energy prices (motor fuels).
%          US: household energy is the published BLS component; transport
%              energy = energy less household energy, chain-linked (there is
%              no published SA "motor fuel" aggregate on our databases).
%          EA: both are published Eurostat components: 04.5 "electricity,
%              gas and other fuels" and 07.2.2 "fuels and lubricants for
%              personal transport equipment". By the Eurostat definition the
%              HICP special aggregate "energy" is exactly 04.5 + 07.2.2.
%     R  the 1-year interest rate, the monetary-policy indicator of the
%        paper (no shadow rates: the 1-year market rate reflects expected
%        policy also at the zero lower bound, and covers the whole sample):
%          US: 1-year Treasury constant-maturity yield.
%          EA: 12-month EURIBOR (the euro-area government yield only starts
%              in 2004; the EURIBOR covers the whole sample).
%     F  the PRIMARY DEFICIT ratio:
%          US: -(net government saving + government interest payments), NIPA general government,
%              the Smets-Wouters (2024) definition used by Mori (2026), in
%              percent of the CBO's NOMINAL POTENTIAL GDP.
%          EA: the definition of Mori / Ascari-Bonam-Mori-Smadu (2026): the
%              ESA-2010 general government primary balance in percent of GDP
%              (ECB), sign-flipped and rescaled from current to TREND nominal
%              GDP with a sixth-degree polynomial trend (Ramey-Zubairy 2018).
%              (No CBO-style official potential exists for the euro area.)
%
%   Known differences between the two SOURCE settings: the euro-area price
%   indexes come from the ECB's live HICP dataflow in 'public' mode (same
%   series, coarser published precision, well below 0.1 pp on year-on-year
%   rates); the two euro-area energy components 04.5 and 07.2.2 have no
%   official seasonally adjusted version anywhere, so 'public' mode adjusts
%   the published NSA indexes itself (aux/lib/seasadj.m); GDP levels sit on
%   different index bases (a constant scale, which drops out of logs up to a
%   constant).
%
%   Output (written next to this file):
%     data/VARData.mat : TimeQ (quarterly dates), Data (quarters x 16, US-odd / EA-even in
%                the order LoadData.m reads: 1 CPI(less OER, incl energy), 2 HICP,
%                3/4 GDP, 5/6 1y rate, 7/8 CPI ex energy, 9/10 all energy,
%                11/12 transport energy, 13/14 household energy, 15/16 primary
%                deficit), Mnem, Descr

close all
clear
addpath('aux')
addpath('aux/lib')
addpath(fullfile('data','public'))   % BLSRelativeImportance.csv, for publicweights.m

% which vintage of the dual-source raw series to use
SOURCE = 'haver';   % 'haver' or 'public'
rawdir = fullfile('data','raw',SOURCE);

%% 1) real GDP (US and EA) and EA nominal GDP; also anchors the quarterly grid
[tgus, gus] = readraw(rawdir, 'USRealGDP');
[tgea, gea] = readraw(rawdir, 'EARealGDP');
[tnea, nea] = readraw(rawdir, 'EANomGDP');

TimeQ = (datetime(1959,1,1) : calquarters(1) : dateshift(tgus(end),'start','quarter'))';
key   = year(TimeQ)*10 + quarter(TimeQ);          % 2021Q3 -> 20213

Qus  = aligndt(tgus, gus, key);
Qea  = aligndt(tgea, gea, key);
NGDPea = aligndt(tnea, nea, key);

%% 2) US consumer prices: P, H, T from BLS components -------------------------
[TimeM, PCU]     = readraw(rawdir, 'USCPI_AllItems');
[~,     PCUSE]   = readraw(rawdir, 'USCPI_Energy');
[~,     PCUHSHA] = readraw(rawdir, 'USCPI_OER');
[~,     PCUHFF]  = readraw(rawdir, 'USCPI_HouseholdEnergy');
LEV = [PCU PCUSE PCUHSHA PCUHFF];

if strcmp(SOURCE, 'haver')
    [~, RPCU]     = readraw(rawdir, 'USCPIWeight_AllItems');
    [~, RUEGM]    = readraw(rawdir, 'USCPIWeight_Energy');
    [~, RPCUHSHA] = readraw(rawdir, 'USCPIWeight_OER');
    [~, RPCUHFF]  = readraw(rawdir, 'USCPIWeight_HouseholdEnergy');
    W = [RPCU RUEGM RPCUHSHA RPCUHFF];
else
    % the December relative importances as shipped (equal to the published
    % bls.gov tables; the tables are served only to browsers, not the API)
    W = publicweights(TimeM, {'AllItems','Energy','OER','HouseholdEnergy'});
end

% October 2025 is a single missing month (US federal shutdown; the BLS resumed
% publication in November) - fill it so 2025Q4 exists:
LEV = fillgap(LEV);

% chainagg combines the components into one chain-linked index following the
% BLS convention (within-year relatives weighted by the previous December's
% relative importances): +1 add the component, -1 remove it, 0 not involved.
%                                 PCU  PCUSE  PCUHSHA  PCUHFF
Cus_m    = chainagg(LEV, W, [      1     0      -1       0 ], TimeM);  % all items less OER, incl energy (col1)
Pus_m    = chainagg(LEV, W, [      1    -1      -1       0 ], TimeM);  % less energy, less OER (col7)
Hus_m    = chainagg(LEV, W, [      0     0       0       1 ], TimeM);  % household energy (col13)
Tus_m    = chainagg(LEV, W, [      0     1       0      -1 ], TimeM);  % transport = energy - household (col11)
ENus_m   = chainagg(LEV, W, [      0     1       0       0 ], TimeM);  % all energy (col9)

% chainlink sets the whole anchor year flat = 1 (here 1984, since OER exists
% from 1983), so the first 24 months of a constructed series are an artifact,
% not data. Remove them:
Cus_m  = dropanchor(Cus_m);
Pus_m  = dropanchor(Pus_m);
Hus_m  = dropanchor(Hus_m);
Tus_m  = dropanchor(Tus_m);
ENus_m = dropanchor(ENus_m);

%% 3) EA consumer prices: P, H, T are published Eurostat aggregates -----------
[TimeE, QOE]  = readraw(rawdir, 'EAHICP_ExEnergy');
[~,     HW5]  = readraw(rawdir, 'EAHICP_HouseholdEnergy');
[~,     HN22] = readraw(rawdir, 'EAHICP_TransportEnergy');
[~,     QE]   = readraw(rawdir, 'EAHICP_Energy');
[TimeEO, EAhicpO] = readraw(rawdir, 'EAHICP_Headline');
EAP = [QOE HW5 HN22 QE];
if strcmp(SOURCE, 'public')
    % 04.5 and 07.2.2 exist only NSA anywhere; ex energy and energy have
    % official SA versions already (see the header note)
    EAP(:,2) = seasadj(EAP(:,2), TimeE);
    EAP(:,3) = seasadj(EAP(:,3), TimeE);
end

%% 4) R: the 1-year interest rate, monthly averaged to quarters ---------------
[tRus, IRus] = readraw(rawdir, 'USRate1Y');
[tRea, IRea] = readraw(rawdir, 'EARate1Y');
Rus = toquarterly(IRus, tRus, TimeQ);
Rea = toquarterly(IRea, tRea, TimeQ);

%% 5) F: the primary deficit ratio ---------------------------------------------
% --- US ---
[tsav, sav] = readraw(rawdir, 'USGovSaving');
[tgin, gin] = readraw(rawdir, 'USGovInterest');
[tpot, pot] = readraw(rawdir, 'USPotentialGDP');
if strcmp(SOURCE, 'public')
    % the BEA lines are in millions of dollars on DBnomics, billions on
    % Haver/FRED
    sav = sav/1000;
    gin = gin/1000;
end
defUS  = -(aligndt(tsav, sav, key) + aligndt(tgin, gin, key));   % bn $, SAAR
POTus  = aligndt(tpot, pot, key);
Fus    = 100 * defUS ./ POTus;                    % percent of CBO potential GDP

% --- EA ---
% Sign-flipped to a deficit, and rescaled from current to TREND nominal GDP
% as in Mori / Ascari-Bonam-Mori-Smadu (2026)
[tEA, pbEA] = readraw(rawdir, 'EAPrimaryBalance');
DEFGDPea = -aligndt(tEA, pbEA, key);              % deficit, % of current GDP
GDPNea   = NGDPea;
TRea     = NaN(size(GDPNea));
ok       = isfinite(GDPNea);
TRea(ok) = gdptrend(GDPNea(ok));
Fea      = DEFGDPea .* GDPNea ./ TRea;            % percent of trend GDP

%% 6) assemble the quarterly panel (16 columns, US-odd / EA-even, LoadData order)
Cus_q    = toquarterly(Cus_m,   TimeM,  TimeQ);      % col1  CPIus (less OER, incl energy)
HICPea_q = toquarterly(EAhicpO, TimeEO, TimeQ);      % col2  HICPea (overall HICP)
USm = toquarterly([Pus_m Hus_m Tus_m ENus_m], TimeM, TimeQ);   % [ex-energy, household, transport, all-energy]
EAm = toquarterly(EAP,  TimeE, TimeQ);                          % [ex-energy, household, transport, all-energy]

Data = [Cus_q      HICPea_q   Qus        Qea       ...   %  1- 4  CPI, HICP, real GDP US/EA
        Rus        Rea        USm(:,1)   EAm(:,1)  ...   %  5- 8  1y rates, CPI/HICP ex energy
        USm(:,4)   EAm(:,4)   USm(:,3)   EAm(:,3)  ...   %  9-12  all-energy, transport energy
        USm(:,2)   EAm(:,2)   Fus        Fea];           % 13-16  household energy, primary deficit

Mnem  = {'CPIus';'HICPea';'GDPus';'GDPea';'TB1Yus';'IB1Yea'; ...
         'CPIus_exene';'HICPea_exene';'CPIus_ener';'HICPea_ener'; ...
         'CPIus_trene';'HICPea_trene';'CPIus_hhene';'HICPea_hhene'; ...
         'Fus';'Fea'};
Descr = {'US CPI-U less owners equivalent rent, incl energy, SA, chain-linked from BLS components'; ...
         'EA HICP all items, changing composition, SA'; ...
         'US real GDP, SAAR, bn chained dollars'; ...
         'EA real GDP, changing composition, SA, mn chained euros'; ...
         'US 1-year Treasury constant-maturity yield, % p.a.'; ...
         '12-month EURIBOR, % p.a.'; ...
         'US CPI less energy less OER, SA, chain-linked (PCU,PCUSE,PCUHSHA + weights)'; ...
         'EA HICP excluding energy, changing composition, SA'; ...
         'US CPI energy, SA, chain-linked (reproduces published CPIENGSL)'; ...
         'EA HICP energy = COICOP 04.5 + 07.2.2, SA'; ...
         'US CPI transport energy = energy less household energy, SA, chain-linked'; ...
         'EA HICP fuels and lubricants for personal transport, COICOP 07.2.2, SA'; ...
         'US CPI household energy, SA (BLS component PCUHFF, chain-linked)'; ...
         'EA HICP electricity, gas and other fuels, COICOP 04.5, SA'; ...
         'US primary deficit -(net government saving + interest payments), % of CBO nominal potential GDP'; ...
         'EA primary deficit (ECB primary balance sign-flipped), % of trend nominal GDP (Ramey-Zubairy polynomial), as in Mori/ABMS 2026'};

%% 7) save and report --------------------------------------------------------
save(fullfile('data','VARData.mat'), 'TimeQ', 'Data', 'Mnem', 'Descr');
fprintf('PrepareVARData: data/VARData.mat written (SOURCE=''%s'', %d quarters)\n', SOURCE, numel(TimeQ));

% -------------------------------------------------------------------------
%% Functions

function [t, x] = readraw(rawdir, name)
% readraw  Load one (Date,Value) CSV written by GetVARData.m, named
% <name>_<source>.csv (see writeraw in GetVARData.m).
[~, sfx] = fileparts(rawdir);
f = fullfile(rawdir, [name '_' sfx '.csv']);
if ~isfile(f)
    error('PrepareVARData: %s not found -- run GetVARData.m first (with the matching SOURCE) to create it.', f);
end
tb = readtable(f);
t = tb.Date;
x = tb.Value;
end

function x = dropanchor(x)
% remove the flat anchor year: the first 24 months of a chain-linked series
i = find(isfinite(x), 1);
if ~isempty(i), x(i : min(i+23, numel(x))) = NaN; end
end

function v = aligndt(t, x, key)
% align a dated series onto the quarterly grid
k = year(t)*10 + quarter(t);
v = NaN(numel(key), 1);
[~, ia, ib] = intersect(key, k);
v(ia) = x(ib);
end

function tr = gdptrend(g)
% sixth-degree polynomial trend of log GDP (Ramey and Zubairy 2018)
x = (1:numel(g))';
[p, ~, mu] = polyfit(x, log(g), 6);
tr = exp(polyval(p, x, [], mu));
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
