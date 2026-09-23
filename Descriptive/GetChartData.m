% GetChartData.m: fetch every raw series behind the descriptive-chart
% dataset (figure 1 and its energy companion, figure 4): headline, goods,
% services, energy, household energy and transport energy price index
% components for the US and the EA, plus the EA HICP item weights used in
% figure 4's contribution accounting. Saves each one as a plain CSV under
% data/raw/haver/ or data/raw/public/
%
%   Sources: choose with the SOURCE setting below.
%     'haver' : Haver Analytics (needs HAVER_KEY below), the authors' setup.
%     'public': free public sources only: the BLS public API for the US
%               levels (needs no key, or your own registered key below for
%               higher rate limits), the shipped BLS December relative
%               importances for the US weights (not fetched here), and the
%               ECB Data Portal for the EA levels.
%
%   The EA HICP item weights (Eurostat prc_hicp_inw) are public in both
%   modes and always fetched, unsuffixed, regardless of SOURCE.
%
%   US: BLS series concepts (HICP concept of appendix A of the paper):
%     PCU       all items                     PCUSSLE  services less energy svcs
%     PCUFAN    food away from home           PCUHSHA  owners' equivalent rent (OER)
%     PCUSE     energy                        PCUHFF   household energy
%   US relative-importance weights (haver mode only; public mode uses the
%   shipped data/public/BLSRelativeImportance.csv, not fetched here):
%     RPCU, RUSXEGM, RPCUFA, RPCUHSHA, RUEGM, RPCUHFF
%
%   EA: published Eurostat aggregates, changing composition (EA11-21), SA
%   (haver mode) or ECB Data Portal (public mode, HW5/HN22 NSA -- seasonal
%   adjustment happens in PrepareChartData.m, not here):
%     H023HICP  HICP all items                H023QG    HICP goods
%     H023QE    HICP energy                    H023QS    HICP services
%     H023HW5   electricity, gas and other fuels (04.5)
%     H023HN22  fuels and lubricants for personal transport (07.2.2)
%     H023QOE   HICP ex energy

close all
clear
addpath('aux')          % fetchfile
addpath('aux/lib')

%% data source and API keys -- set these before running ---------------------
SOURCE = 'haver';   % 'public' or 'haver'

% Haver: REQUIRED if SOURCE='haver'.
HAVER_KEY = '7bCtsOfwsIGhNIkzqtHOqvjtoOpyX79gTgIXolH_vQk';
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

%% 1) US: CPI level components -------------------------------------------------
if strcmp(SOURCE, 'haver')
    [LEV, TimeM] = haverpanel({'PCU@USECON','PCUSSLE@USECON','PCUFAN@USECON', ...
                               'PCUHSHA@USECON','PCUSE@USECON','PCUHFF@USECON'}, 'M', HAVER_KEY);
else
    [LEV, TimeM] = blspanel({'CUSR0000SA0','CUSR0000SASLE','CUUR0000SEFV', ...
                             'CUSR0000SEHC','CUSR0000SA0E','CUSR0000SAH21'}, BLS_KEY);
end
writeraw(rawdir, 'USCPI_AllItems',           TimeM, LEV(:,1));
writeraw(rawdir, 'USCPI_ServicesLessEnergy', TimeM, LEV(:,2));
writeraw(rawdir, 'USCPI_FoodAwayHome',       TimeM, LEV(:,3));
writeraw(rawdir, 'USCPI_OER',                TimeM, LEV(:,4));
writeraw(rawdir, 'USCPI_Energy',             TimeM, LEV(:,5));
writeraw(rawdir, 'USCPI_HouseholdEnergy',    TimeM, LEV(:,6));

%% 2) US: CPI relative-importance weights (haver mode only) -------------------
% public mode reads the shipped data/public/BLSRelativeImportance.csv instead
% (PrepareChartData.m); nothing to fetch here in that case.
if strcmp(SOURCE, 'haver')
    W = haverpanel({'RPCU@USECON','RUSXEGM@USECON','RPCUFA@USECON', ...
                    'RPCUHSHA@USECON','RUEGM@USECON','RPCUHFF@USECON'}, 'M', HAVER_KEY, TimeM);
    writeraw(rawdir, 'USWeight_AllItems',           TimeM, W(:,1));
    writeraw(rawdir, 'USWeight_ServicesLessEnergy', TimeM, W(:,2));
    writeraw(rawdir, 'USWeight_FoodAwayHome',       TimeM, W(:,3));
    writeraw(rawdir, 'USWeight_OER',                TimeM, W(:,4));
    writeraw(rawdir, 'USWeight_Energy',             TimeM, W(:,5));
    writeraw(rawdir, 'USWeight_HouseholdEnergy',    TimeM, W(:,6));
end

%% 3) EA: published HICP aggregates --------------------------------------------
if strcmp(SOURCE, 'haver')
    [EA, TimeE] = haverpanel({'H023HICP@EUDATA','H023QG@EUDATA','H023QS@EUDATA', ...
                              'H023QE@EUDATA','H023HW5@EUDATA','H023HN22@EUDATA', ...
                              'H023QOE@EUDATA'}, 'M', HAVER_KEY);
else
    % HW5/HN22 (04.5, 07.2.2) exist only NSA anywhere -- seasonal adjustment
    % happens in PrepareChartData.m, not here
    [EA, TimeE] = ecbpanel({'HICP.M.U2.Y.000000.4F0.INX', ...   % all items, SA
                            'HICP.M.U2.Y.GOODS0.4F0.INX', ...   % goods, SA
                            'HICP.M.U2.Y.SERV00.4F0.INX', ...   % services, SA
                            'HICP.M.U2.Y.NRGY00.4F0.INX', ...   % energy, SA
                            'HICP.M.U2.N.045000.4D0.INX', ...   % 04.5, NSA
                            'HICP.M.U2.N.072200.4D0.INX', ...   % 07.2.2, NSA
                            'HICP.M.U2.Y.XE0000.4F0.INX'});     % ex energy, SA
end
writeraw(rawdir, 'EAHICP_Headline',        TimeE, EA(:,1));
writeraw(rawdir, 'EAHICP_Goods',           TimeE, EA(:,2));
writeraw(rawdir, 'EAHICP_Services',        TimeE, EA(:,3));
writeraw(rawdir, 'EAHICP_Energy',          TimeE, EA(:,4));
writeraw(rawdir, 'EAHICP_HouseholdEnergy', TimeE, EA(:,5));
writeraw(rawdir, 'EAHICP_TransportEnergy', TimeE, EA(:,6));
writeraw(rawdir, 'EAHICP_ExEnergy',        TimeE, EA(:,7));

%% 4) EA HICP item weights (Eurostat, public, always fetched) -----------------
fetchfile(fullfile('data','raw','EAItemWeights_raw.csv'), ['https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/' ...
    'prc_hicp_inw/A.CP045+CP0722.EA?format=SDMX-CSV']);
Tw = readtable(fullfile('data','raw','EAItemWeights_raw.csv'), 'TextType','string');
years = unique(Tw.TIME_PERIOD);
fid = fopen(fullfile('data','raw','EAItemWeights.csv'),'w');
fprintf(fid, 'Year,CP045,CP0722\n');
for y = years'
    cp045 = Tw.OBS_VALUE(Tw.TIME_PERIOD==y & strcmp(Tw.coicop,'CP045'));
    cp0722 = Tw.OBS_VALUE(Tw.TIME_PERIOD==y & strcmp(Tw.coicop,'CP0722'));
    fprintf(fid, '%d,%.6g,%.6g\n', y, cp045, cp0722);
end
fclose(fid);
fprintf('EA HICP weights: Eurostat prc_hicp_inw, %d-%d\n', min(years), max(years));

fprintf('GetChartData: raw series written to %s (SOURCE=''%s'')\n', rawdir, SOURCE);

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

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
