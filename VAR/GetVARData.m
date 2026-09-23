% GetVARData.m: fetch every raw series behind the VAR dataset (US/EA prices,
% GDP, rates, deficits) from the internet and save each one as a plain CSV
% under data/raw/haver/ or data/raw/public/
%
%   Sources: choose with the SOURCE setting below.
%     'haver' : Haver Analytics (needs HAVER_KEY below), the authors' setup,
%               except three US deficit-ratio series that aren't on Haver
%               and come from FRED's free CSV endpoint regardless of SOURCE.
%     'public': free public sources only: the BLS public API (needs no key,
%               or your own registered key below for higher rate limits),
%               DBnomics, the ECB and Eurostat data portals, and FRED.
%
%   US CPI relative-importance weights: in 'public' mode these are NOT
%   fetched at all.

close all
clear
addpath('aux')
addpath('aux/lib')

%% data source and API keys -- set these before running ---------------------
SOURCE = 'haver';   % 'public' or 'haver'

% Haver: REQUIRED if SOURCE='haver'.
HAVER_KEY = '';
if strcmp(SOURCE,'haver') && isempty(HAVER_KEY)
    error('Set HAVER_KEY at the top of this script to use SOURCE=''haver''.');
end

% BLS (SOURCE='public' only): optional. Put your own registered key here
% (https://data.bls.gov/registrationEngine/) for higher rate limits. Leave
% empty to use BLS's own public, unregistered tier automatically.
BLS_KEY = '';
if isempty(BLS_KEY)
    BLS_KEY = 'public';   % blspanel.m's own sentinel for the unregistered tier
end

rawdir = fullfile('data','raw',SOURCE);
if ~isfolder(rawdir), mkdir(rawdir); end

%% 1) real GDP (US and EA) and EA nominal GDP ---------------------------------
if strcmp(SOURCE, 'haver')
    [x, t] = haverseries('GDPH@USECON', HAVER_KEY);       writeraw(rawdir, 'USRealGDP', t, x);
    [x, t] = haverseries('J023GDPT@EUDATA', HAVER_KEY);   writeraw(rawdir, 'EARealGDP', t, x);
    [x, t] = haverseries('J023GDPN@EUDATA', HAVER_KEY);   writeraw(rawdir, 'EANomGDP',  t, x);
else
    [x, t] = dbnomics('BEA/NIPA-T10106/A191RX-Q');   writeraw(rawdir, 'USRealGDP', t, x);
    [x, t] = eurostatgdp('CLV10_MEUR');               writeraw(rawdir, 'EARealGDP', t, x);
    [x, t] = eurostatgdp('CP_MEUR');                  writeraw(rawdir, 'EANomGDP',  t, x);
end

%% 2) US consumer prices: components behind P, H, T ---------------------------
% Levels (SA indices):                       Weights (relative importances):
%   PCU      all items                         RPCU
%   PCUSE    energy                            RUEGM
%   PCUHSHA  owners' equivalent rent (OER)     RPCUHSHA
%   PCUHFF   household energy                  RPCUHFF
if strcmp(SOURCE, 'haver')
    [LEV, TimeM] = haverpanel({'PCU@USECON','PCUSE@USECON','PCUHSHA@USECON','PCUHFF@USECON'}, 'M', HAVER_KEY);
    W            = haverpanel({'RPCU@USECON','RUEGM@USECON','RPCUHSHA@USECON','RPCUHFF@USECON'}, 'M', HAVER_KEY, TimeM);
    writeraw(rawdir, 'USCPIWeight_AllItems',        TimeM, W(:,1));
    writeraw(rawdir, 'USCPIWeight_Energy',          TimeM, W(:,2));
    writeraw(rawdir, 'USCPIWeight_OER',             TimeM, W(:,3));
    writeraw(rawdir, 'USCPIWeight_HouseholdEnergy', TimeM, W(:,4));
else
    % same BLS series from the BLS public API; weights come from the
    % shipped data/public/BLSRelativeImportance.csv, not fetched here
    [LEV, TimeM] = blspanel({'CUSR0000SA0','CUSR0000SA0E','CUSR0000SEHC','CUSR0000SAH21'}, BLS_KEY);
end
writeraw(rawdir, 'USCPI_AllItems',        TimeM, LEV(:,1));
writeraw(rawdir, 'USCPI_Energy',          TimeM, LEV(:,2));
writeraw(rawdir, 'USCPI_OER',             TimeM, LEV(:,3));
writeraw(rawdir, 'USCPI_HouseholdEnergy', TimeM, LEV(:,4));

%% 3) EA consumer prices: components behind P, H, T, and the headline HICP ----
%   H023QOE   overall index excluding energy                      -> P ex energy
%   H023HW5   electricity, gas and other fuels (COICOP 04.5)      -> H
%   H023HN22  fuels and lubricants for personal transport (07.2.2)-> T
%   H023QE    energy = 04.5 + 07.2.2 exactly                      -> all-energy
%   H023HICP  overall HICP, all items                             -> headline P
if strcmp(SOURCE, 'haver')
    [EAP, TimeE]      = haverpanel({'H023QOE@EUDATA','H023HW5@EUDATA','H023HN22@EUDATA','H023QE@EUDATA'}, 'M', HAVER_KEY);
    [x, tEO]          = haverseries('H023HICP@EUDATA', HAVER_KEY);
else
    % the same aggregates from the ECB Data Portal, live HICP dataflow. Ex
    % energy and energy have official SA versions; the two energy
    % components (04.5, 07.2.2) exist only NSA anywhere -- seasonal
    % adjustment happens in PrepareVARData.m, not here
    [EAP, TimeE] = ecbpanel({'HICP.M.U2.Y.XE0000.4F0.INX', ...    % ex energy, official SA
                             'HICP.M.U2.N.045000.4D0.INX', ...    % 04.5, NSA
                             'HICP.M.U2.N.072200.4D0.INX', ...    % 07.2.2, NSA
                             'HICP.M.U2.Y.NRGY00.4F0.INX'});      % energy, official SA
    [x, tEO]     = ecbseries('HICP.M.U2.Y.000000.4F0.INX');       % overall HICP, SA
end
writeraw(rawdir, 'EAHICP_ExEnergy',         TimeE, EAP(:,1));
writeraw(rawdir, 'EAHICP_HouseholdEnergy',  TimeE, EAP(:,2));
writeraw(rawdir, 'EAHICP_TransportEnergy',  TimeE, EAP(:,3));
writeraw(rawdir, 'EAHICP_Energy',           TimeE, EAP(:,4));
writeraw(rawdir, 'EAHICP_Headline',         tEO,   x);

%% 4) R: the 1-year interest rate ---------------------------------------------
%   FCM1      US 1-year Treasury constant-maturity yield, % p.a.
%   I023IB12  12-month EURIBOR, % p.a.
if strcmp(SOURCE, 'haver')
    [x, t] = haverseries('FCM1@USECON', HAVER_KEY);      writeraw(rawdir, 'USRate1Y', t, x);
    [x, t] = haverseries('I023IB12@EUDATA', HAVER_KEY);  writeraw(rawdir, 'EARate1Y', t, x);
else
    [x, t] = dbnomics('FED/H15/RIFLGFCY01_N.M');                             writeraw(rawdir, 'USRate1Y', t, x);
    [x, t] = ecbseries('FM.M.U2.EUR.RT.MM.EURIBOR1YD_.HSTA');                 writeraw(rawdir, 'EARate1Y', t, x);
end

%% 5) F: the primary deficit ratio --------------------------------------------
% --- US: the NIPA general government detail is not on Haver, so these three
% always come from FRED's free CSV endpoint (SOURCE='haver') or the
% equivalent DBnomics/CBO series (SOURCE='public') -- neither needs a key.
%   TGDEF            net government saving (general government, NIPA 3.1 line 31), bn $ SAAR
%   A180RC1Q027SBEA  government interest payments (general government, NIPA 3.1 line 27), bn $ SAAR
%   NGDPPOT          nominal potential GDP (CBO), bn $ SAAR
if strcmp(SOURCE, 'haver')
    [x, t] = fredcsv('TGDEF');                writeraw(rawdir, 'USGovSaving',     t, x);
    [x, t] = fredcsv('A180RC1Q027SBEA');      writeraw(rawdir, 'USGovInterest',   t, x);
    [x, t] = fredcsv('NGDPPOT');              writeraw(rawdir, 'USPotentialGDP',  t, x);
else
    [x, t] = dbnomics('BEA/NIPA-T30100/A922RC-Q');   writeraw(rawdir, 'USGovSaving',    t, x);
    [x, t] = dbnomics('BEA/NIPA-T30100/A180RC-Q');   writeraw(rawdir, 'USGovInterest',  t, x);
    [x, t] = cbopotential();                          writeraw(rawdir, 'USPotentialGDP', t, x);
end

% --- EA: the quarterly ESA-2010 general government primary balance, % of GDP
if strcmp(SOURCE, 'haver')
    [x, t] = haverseries('G025PBPQ@EUDATA', HAVER_KEY);
else
    [x, t] = ecbseries('GFS.Q.N.I9.W0.S13.S1._Z.B.B9P._Z._Z._Z.XDC_R_B1GQ_CY._Z.S.V.CY._T');
end
writeraw(rawdir, 'EAPrimaryBalance', t, x);

fprintf('GetVARData: raw series written to %s (SOURCE=''%s'')\n', rawdir, SOURCE);

% -------------------------------------------------------------------------
%% Functions

function writeraw(rawdir, name, t, x)
% writeraw  Save one dated series as a plain (Date,Value) CSV, named
% <name>_<source>.csv (the source suffix comes from rawdir's own
% subfolder name, data/raw/haver or data/raw/public) so the haver and
% public vintages can be opened side by side without ambiguity.
[~, sfx] = fileparts(rawdir);
fname = [name '_' sfx '.csv'];
t = t(:);  x = x(:);
tb = table(t, x, 'VariableNames', {'Date','Value'});
writetable(tb, fullfile(rawdir, fname));
fprintf('  wrote %s (%d obs, %s to %s)\n', fname, numel(x), string(t(1)), string(t(end)));
end

function [x, t] = fredcsv(id)
% one series from FRED's public csv endpoint
f = [tempname '.csv'];
fetchfile(f, ['https://fred.stlouisfed.org/graph/fredgraph.csv?id=' id]);
tb = readtable(f);
t = tb.observation_date;
x = tb.(id);
fprintf('%s: FRED, %d obs to %s\n', id, numel(x), string(t(end)));
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
