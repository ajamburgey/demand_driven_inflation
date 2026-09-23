% GetRealTimeData: fetch every real-time input directly from its official
% web source into data/raw/web/
%
% Sources (fetched from the web):
%   (i) routputQvQd.xlsx: Philadelphia Fed Real-Time Data Set (ROUTPUT vintages)
%   (ii) median_rgdp_level.xlsx: Philadelphia Fed SPF median real GDP projections in levels
%   (iii) median_cpi_level.xlsx: Philadelphia Fed SPF median CPI projections in levels
%   (iv) alfred_<date>.csv: 26 ALFRED vintages of CPIAUCSL (one per SPF round)
%   (v) GDPC1.csv: recent vintage of US real GDP (FRED)
%   (vi) CPIAUCSL.csv: recent vintage of US CPI (FRED)
%   (vii) RealGDP_EA.csv: recent vintage of euro-area real GDP in the CURRENT composition
%   (viii) HICP_ANR.csv: EA HICP annual rate
%   (ix) MPD/YER.P.<round>.csv and MPD/HIC.A.<round>.csv: ECB/Eurosystem staff
%        GDP growth and inflation projections, one file per round needed
%
% Not fetched here (see PrepareRealTimeData.m):
%   data/RawEA/Vintages_GDP_Eurostat_updated.xlsx: vintages of Euro area GDP
%   from the Eurostat flash releases. Only exist as pdf press releases.
%
% nv (number of rounds) and letters (round-code letters by quarter) must
% match PrepareRealTimeData.m's copies of the same constants.

close all
clear
addpath('aux')     % fetchfile

rawDir = fullfile('data','raw','web');
eaDir  = fullfile('data','RawEA');
if ~exist(rawDir,'dir'), mkdir(rawDir); end
if ~isfile(fullfile(eaDir,'Vintages_GDP_Eurostat_updated.xlsx'))
  warning('%s not found; copy it in by hand (no web source exists for it).', ...
          fullfile(eaDir,'Vintages_GDP_Eurostat_updated.xlsx'));
end

nv = 26;              % number of vintages (2020:Q1 .. 2026:Q2)
letters = 'WGSA';     % March/June/September/December round codes for ECB projections

%--------------------------------------------------------------------------
disp('Fetching Data...')

%Philadelphia Fed files
philly = { ...
 'routputQvQd.xlsx',      'https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/real-time-data/data-files/xlsx/routputQvQd.xlsx'; ...
 'median_rgdp_level.xlsx','https://www.philadelphiafed.org/-/media/frbp/assets/surveys-and-data/survey-of-professional-forecasters/data-files/files/median_rgdp_level.xlsx'; ...
 'median_cpi_level.xlsx', 'https://www.philadelphiafed.org/-/media/frbp/assets/surveys-and-data/survey-of-professional-forecasters/data-files/files/median_cpi_level.xlsx'};
for i = 1:size(philly,1)
    fetchfile(fullfile(rawDir,philly{i,1}), philly{i,2});
end

%ALFRED CPI vintages (the 26 SPF-deadline dates of rounds 1-26)
%Last available ALFRED CPI vintages that were available at each SPF
%deadline: https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/survey-of-professional-forecasters/spf-release-dates.txt?la=en&sc_lang=en&hash=673DDAC864F629E70FEF0DCB88934863
vd = {'2020-02-11','2020-05-12','2020-08-12','2020-10-13', ...
    '2021-02-08','2021-05-12', '2021-07-13','2021-10-13', ...
    '2022-01-12','2022-04-12','2022-07-13','2022-10-13', ...
    '2023-01-12','2023-04-12','2023-07-12','2023-10-12', ...
    '2024-01-11','2024-04-10','2024-07-11','2024-10-10', ...
    '2025-01-15','2025-05-13','2025-08-12','2025-10-24',...
    '2026-02-13','2026-05-12'};
for i = 1:numel(vd)
    f = fullfile(rawDir, sprintf('alfred_%s.csv', vd{i}));
    fetchfile(f, sprintf('https://alfred.stlouisfed.org/graph/alfredgraph.csv?id=CPIAUCSL&vintage_date=%s', vd{i}));
end

%Recent Vintages of US GDP and CPI
fetchfile(fullfile(rawDir,'GDPC1.csv'),    'https://fred.stlouisfed.org/graph/fredgraph.csv?id=GDPC1');
fetchfile(fullfile(rawDir,'CPIAUCSL.csv'), 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL');

%Recent Vintage of EA real GDP (Eurostat SDMX, current composition)
fetchfile(fullfile(rawDir,'RealGDP_EA_raw.csv'), ['https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/' ...
    'namq_10_gdp/Q.CLV10_MEUR.SCA.B1GQ.EA21?format=SDMX-CSV&startPeriod=1995-Q1']);
Tg = readtable(fullfile(rawDir,'RealGDP_EA_raw.csv'), 'Delimiter',',', 'TextType','string', 'VariableNamingRule','preserve');
mm = containers.Map({'1','2','3','4'}, {'01','04','07','10'});
fid = fopen(fullfile(rawDir,'RealGDP_EA.csv'),'w');
fprintf(fid, 'observation_date,RealGDP_EA21\n');
for i = 1:height(Tg)
    p = char(Tg.TIME_PERIOD(i));                     % e.g. 1995-Q1
    fprintf(fid, '%s-%s-01,%.1f\n', p(1:4), mm(p(end)), Tg.OBS_VALUE(i));
end
fclose(fid);

%Recent Vintage of EA HICP annual rate (ECB SDW)
fetchfile(fullfile(rawDir,'HICP_ANR_raw.csv'), 'https://data-api.ecb.europa.eu/service/data/HICP/M.U2.N.000000.4D0.ANR?format=csvdata');
Th = readtable(fullfile(rawDir,'HICP_ANR_raw.csv'), 'TextType','string');
fid = fopen(fullfile(rawDir,'HICP_ANR.csv'),'w');
fprintf(fid, 'observation_date,HICP_ANR\n');
for i = 1:height(Th)
    fprintf(fid, '%s-01,%.6g\n', Th.TIME_PERIOD(i), Th.OBS_VALUE(i));
end
fclose(fid);

%ECB/Eurosystem staff projection rounds (dataflow MPD)
for i = 1:nv
    yr = 2020 + floor((i-1)/4); rd = sprintf('%c%02d', letters(mod(i-1,4)+1), mod(yr,100));
    fetchfile(fullfile(rawDir,'MPD',sprintf('YER.P.%s.csv',rd)), ...
        sprintf('https://data-api.ecb.europa.eu/service/data/MPD/Q.U2.YER.P.%s.0000?format=csvdata',rd));
    fetchfile(fullfile(rawDir,'MPD',sprintf('HIC.A.%s.csv',rd)), ...
        sprintf('https://data-api.ecb.europa.eu/service/data/MPD/Q.U2.HIC.A.%s.0000?format=csvdata',rd));
end

fprintf('GetRealTimeData: raw files written to %s\n', rawDir);

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
