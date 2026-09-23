% PrepareRealTimeData: build the real-time projection dataset entirely from
% the locally stored raw files -- reformats the ALFRED CPI vintages, Philly
% Fed real-time/SPF files, FRED "latest vintage" series, the Eurostat
% flash-release archive, and the ECB MPD staff-projection rounds into
% condensed projection matrices and actuals (SPF for the US, ECB staff
% projections for the euro area).
%
% nv (number of rounds) and letters (round-code letters by quarter) must
% match GetRealTimeData.m's copies of the same constants.

close all
clear
addpath('aux')     % readMPDround

rawDir = fullfile('data','raw','web');
eaDir  = fullfile('data','RawEA');

% Grid and conventions
dates = datetime(1995,2,15):calquarters(1):datetime(2032,12,15);
dates.Format = 'yyyy:QQ';
key   = year(dates)*4 + quarter(dates);
T0 = find(dates=='15-Nov-2019'); %first date (2019:Q4)
nv = 26; %number of vintages (2020:Q1 .. 2026:Q2)
T1 = T0 + nv; %last date
KCUT = 2026*4 + 1; %cutoff for projection data
RB = 11320.0/10550.3; %base-year splice factor (due to change from 2012 to 2017 chain dollars)
letters = 'WGSA'; % March/June/September/December round codes for ECB projections

%--------------------------------------------------------------------------
disp('Formatting Data...')

%US DATA

% Build CPIvintM from the 26 raw ALFRED vintages (one column per SPF round)
vd = {'2020-02-11','2020-05-12','2020-08-12','2020-10-13', ...
    '2021-02-08','2021-05-12', '2021-07-13','2021-10-13', ...
    '2022-01-12','2022-04-12','2022-07-13','2022-10-13', ...
    '2023-01-12','2023-04-12','2023-07-12','2023-10-12', ...
    '2024-01-11','2024-04-10','2024-07-11','2024-10-10', ...
    '2025-01-15','2025-05-13','2025-08-12','2025-10-24',...
    '2026-02-13','2026-05-12'};
mdates = (datetime(1995,1,1):calmonths(1):datetime(2026,3,1))';   % monthly grid
CPIvintM = NaN(numel(mdates), numel(vd));
for i = 1:numel(vd)
    f = fullfile(rawDir, sprintf('alfred_%s.csv', vd{i}));
    opts = detectImportOptions(f); opts = setvartype(opts, 1, 'string');
    Tv = readtable(f, opts);
    d = datetime(Tv.(1), 'InputFormat', 'yyyy-MM-dd'); v = Tv.(2);
    for j = 1:numel(d)
        k = find(mdates == d(j), 1);
        if ~isempty(k)
            CPIvintM(k,i) = v(j);
        end
    end
end
CPIvintM(370, 25) = mean([CPIvintM(369, 25) CPIvintM(371, 25)]); %one month missing on recent vintage (take average of surrounding months)
CPIvintM(370, 26) = mean([CPIvintM(369, 26) CPIvintM(371, 26)]);
save(fullfile('data','CPIvintages.mat'), 'CPIvintM', 'mdates', 'vd');

% US real-time GDP vintages (Philly Fed ROUTPUT)
USgdpRT = load_routput(fullfile(rawDir,'routputQvQd.xlsx'), nv, key); % grid x nv real-output vintages
USgdpRT(:,1:15) = USgdpRT(:,1:15)*RB;                                 % rebase pre-2023 vintages
GDP201904 = USgdpRT(T0,nv);
USgdpRT = 100*USgdpRT/GDP201904;                                      % index, 2019:Q4=100

% US median GDP projections in levels (SPF)
Pgdpus = readmatrix(fullfile(rawDir,'median_rgdp_level.xlsx'));
GDPpro = align_rounds(Pgdpus, 4:8, key);
USgdpProj = GDPpro(T0+1:T1,:)';
USgdpProj(:,1:15) = USgdpProj(:,1:15)*RB; %account for change in dollar index
USgdpProj = 100*USgdpProj/GDP201904; %rescale to 2019Q4 = 100

% Recent vintage of US GDP (FRED GDPC1)
gdp = quarterly_from_fred(fullfile(rawDir,'GDPC1.csv'), key);
USgdpActual = 100*gdp/gdp(T0); %rescale to 2019Q4 = 100
USgdpActual(key > KCUT) = NaN; %remove values after 2026Q1


% US CPI median projection levels (SPF)
Pcpius = readmatrix(fullfile(rawDir,'median_cpi_level.xlsx'));
infpro = align_rounds(Pcpius, 3:8, key);    % CPI1..CPI6 on the grid

% Make CPIvintM quarterly (take monthly averages)
CPIvint = NaN(ceil(size(CPIvintM,1)/3), size(CPIvintM,2));
for i=1:size(CPIvintM,2)
    for j=3:3:size(CPIvintM,1) %March, June, September, December
        CPIvint(j/3,i)=mean(CPIvintM(j-2:j,i)); %3 month trailing average of last month in each quarter to get quarterly average
    end
end

%Recent Vintage of CPI (FRED CPIAUCSL)
Qcpi = quarterly_from_fred(fullfile(rawDir,'CPIAUCSL.csv'), key);

%Inflation projections in YoY terms
USinfProj = NaN(5,nv);
c = 0;
for t = T0+1:T1
    c = c+1;
    v = t-T0;
    if v<=numel(vd) && size(CPIvint,2)>=v %for earlier origins use correct vintage date to make YoY projections
        cp = @(k) CPIvint(t-k,v);
    else
        cp = @(k) Qcpi(t-k); %for recent origins use recent vintage to simplify (haven't read in older vintages)
    end
    %Approach: Get 1+growth rate for projection horizon as well as its 3 lags and multiply them to get YoY growth
    %Note: At each origin first value is (CPI1) is previous quarter, second value (CPI2) is nowcast, and so on.
    USinfProj(1,c) = cp(3)/cp(4)*cp(2)/cp(3)*(1+infpro(t,1)/100)^.25*(1+infpro(t,2)/100)^.25; %(yoy nowcast at t): cp(3)/cp(4) * cp(2)/cp(3) * (1+g(1)) * (1+g(2)) (use past values where projections aren't provided)
    USinfProj(2,c) = cp(2)/cp(3)*(1+infpro(t,1)/100)^.25*(1+infpro(t,2)/100)^.25*(1+infpro(t,3)/100)^.25; %(yoy at t+1):  cp(2)/cp(3) * (1+g(1)) * (1+g(2)) * (1+g(3))
    USinfProj(3,c) = (1+infpro(t,1)/100)^.25*(1+infpro(t,2)/100)^.25*(1+infpro(t,3)/100)^.25*(1+infpro(t,4)/100)^.25; %(yoy at t+2):  (1+g(1)) * (1+g(2)) * (1+g(3)) * (1+g(4)) (all four from the SPF)
    USinfProj(4,c) = (1+infpro(t,2)/100)^.25*(1+infpro(t,3)/100)^.25*(1+infpro(t,4)/100)^.25*(1+infpro(t,5)/100)^.25; %(yoy at t+3):  g(2) * g(3) * g(4) * g(5)
    USinfProj(5,c) = (1+infpro(t,3)/100)^.25*(1+infpro(t,4)/100)^.25*(1+infpro(t,5)/100)^.25*(1+infpro(t,6)/100)^.25; %(yoy at t+4):  g(3) * g(4) * g(5) * g(6)
end
USinfProj = 100*(USinfProj-1);

%Actual inflation in YoY
USinfActual = 100*(Qcpi./[nan(4,1);Qcpi(1:end-4)] - 1);
USinfActual(key > KCUT) = NaN; %remove values after 2026Q1


%--------------------------------------------------------------------------
%EURO AREA DATA

% Euro area GDP Projections (ECB)
% Read flash vintages archive
GDPvintE = xlsread(fullfile(eaDir,'Vintages_GDP_Eurostat.xlsx'),'Sheet1','B4:AA64');
GDPvintE = [NaN(16*4,nv); GDPvintE]; %append with 16 years of missing data at front (going back to 1995 like US).
datesgdpea = datetime(1995, 1, 1):calquarters(1):datetime(2026, 1, 1);
GDP201904ea = xlsread(fullfile(eaDir,'Vintages_GDP_Eurostat.xlsx'),'levels','D227:BH227');
GDP201904ea = GDP201904ea(T0-16*4); %starts in 2011Q1 (rather than 1995Q1) so adjust by 16 years to get 2019Q4 date
EAgdpRT = 100*GDPvintE/GDP201904ea;   % t+45 flash vintages, index 2019:Q4=100

% anchor for each round (flash diagonal for rounds covered by the archive,
% extended afterwards); EAgdpRT may lag nv if the hand-updated flash
% archive hasn't been refreshed with the newest round yet
anchorEA = nan(nv,1);
for i=1:nv
  if size(EAgdpRT,2)>=i
      anchorEA(i) = EAgdpRT(T0-1+i,i);
  end
end

% Euro area series (current composition) and EAgdpActual
eagdp = quarterly_from_fred(fullfile(rawDir,'RealGDP_EA.csv'), key);
EAgdpActual = 100*eagdp/eagdp(T0);
EAgdpActual(key > KCUT) = NaN;

% Euro area GDP Projections
Pgdpea = NaN(numel(key),nv);
for i = 1:nv
    yr = 2020 + floor((i-1)/4); rd = sprintf('%c%02d', letters(mod(i-1,4)+1), mod(yr,100));
    f = fullfile(rawDir,'MPD',sprintf('YER.P.%s.csv',rd)); if ~isfile(f), continue; end
    Pgdpea(:,i) = readMPDround(f, key);
end
EAgdpProj = NaN(5,nv);
for i = 1:nv
  if ~isnan(anchorEA(i))
    EAgdpProj(:,i) = anchorEA(i)*cumprod(1+Pgdpea(T0+i:T0+i+4,i)/100);
  end
end

% Euro area HICP projections (ECB)
EAinfActual = quarterly_from_fred(fullfile(rawDir,'HICP_ANR.csv'), key); EAinfActual(key > KCUT) = NaN;
Pinfea = NaN(numel(key),nv);
for i = 1:nv
    yr = 2020 + floor((i-1)/4); rd = sprintf('%c%02d', letters(mod(i-1,4)+1), mod(yr,100));
    f = fullfile(rawDir,'MPD',sprintf('HIC.A.%s.csv',rd));
    if ~isfile(f)
        continue;
    end
    v = readMPDround(f, key);
    Pinfea(1:numel(key)-T0, i) = v(T0+1:end);
end

% Get diagonal of EAPi for projections in same format as USinfProj
EAinfProj = NaN(5,nv);
for i = 1:nv
    EAinfProj(:,i) = Pinfea(i:i+4,i);
end

%--------------------------------------------------------------------------
%% EXPORT

disp('Exporting Data...')

% Trim every full-grid series to a common window, 1995:Q1 - 2026:Q1
TEND = find(key==KCUT,1);
dates       = dates(1:TEND);
key         = key(1:TEND);
USgdpActual = USgdpActual(1:TEND);
EAgdpActual = EAgdpActual(1:TEND);
USinfActual = USinfActual(1:TEND);
EAinfActual = EAinfActual(1:TEND);
USgdpRT     = USgdpRT(1:TEND,:);
EAgdpRT     = EAgdpRT(1:TEND,:);

outdir = fullfile('data');

%Save .mat with all constructed series
outmat = fullfile(outdir,'Projections.mat');
save(outmat, 'dates','key','T0','nv','vd', 'USgdpActual','USgdpProj','USinfActual','USinfProj','EAgdpActual','EAgdpProj','EAinfActual','EAinfProj','USgdpRT','EAgdpRT');

%Write CSVs (for ease of viewing)

% Get round labels and codes
round_labels = cell(nv,1);
round_codes = cell(nv,1);
for i=1:nv
    yr = 2020 + floor((i-1)/4);
    q = mod(i-1,4)+1;
    round_labels{i} = sprintf('%dQ%d',yr,q);
    round_codes{i} = sprintf('%c%02d', letters(mod(i-1,4)+1), mod(yr,100));
end

% 1) US GDP projections: rows = rounds, cols = horizon0..4
T = table((1:nv)', round_labels, round_codes, 'VariableNames', {'round_index','round_label','round_code'});
for h = 1:5
    T.(['h',num2str(h-1)]) = USgdpProj(h,:)';
end
writetable(T, fullfile(outdir,'Projections_US_GDP.csv'));

% 2) EA GDP projections
T = table((1:nv)', round_labels, round_codes, 'VariableNames', {'round_index','round_label','round_code'});
for h = 1:5
    T.(['h',num2str(h-1)]) = EAgdpProj(h,:)';
end
writetable(T, fullfile(outdir,'Projections_EA_GDP.csv'));

% 3) US Inflation projections
T = table((1:nv)', round_labels, round_codes, 'VariableNames', {'round_index','round_label','round_code'});
for h = 1:5
    T.(['h',num2str(h-1)]) = USinfProj(h,:)';
end
writetable(T, fullfile(outdir,'Projections_US_Inflation.csv'));

% 4) EA Inflation projections
T = table((1:nv)', round_labels, round_codes, 'VariableNames', {'round_index','round_label','round_code'});
for h = 1:5
    T.(['h',num2str(h-1)]) = EAinfProj(h,:)';
end
writetable(T, fullfile(outdir,'Projections_EA_Inflation.csv'));

% 5) Actuals latest vintage: date + four series
Tact = table(dates', USgdpActual, USinfActual, EAgdpActual, EAinfActual, 'VariableNames', {'date','US_GDP_index_latest','US_CPI_yoy_latest','EA_GDP_index_latest','EA_HICP_yoy_latest'});
writetable(Tact, fullfile(outdir,'Actuals_latest_vintage.csv'));

disp('Done.')


%--------------------------------------------------------------------------
%% Functions

function V = load_routput(file, nv, key)
  [num,~,raw] = xlsread(file);
  vlab = string(raw(1,2:end)); rq = string(raw(2:end,1));
  rkey = zeros(numel(rq),1);
  for i = 1:numel(rq), rkey(i) = double(extractBefore(rq(i),':'))*4 + double(extractAfter(rq(i),'Q')); end
  V = nan(numel(key), nv);
  for j = 1:nv
    y = 2020 + floor((j-1)/4); q = mod(j-1,4)+1;
    lab = sprintf('ROUTPUT%02dQ%d', mod(y,100), q);
    cc = find(vlab==lab,1); if isempty(cc), continue; end
    for i = 1:numel(rkey), g = find(key==rkey(i),1); if ~isempty(g), V(g,j) = num(i,cc); end, end
  end
end

function G = align_rounds(M, cols, key)
  G = nan(numel(key), numel(cols));
  if isempty(M), return; end
  for r = 1:size(M,1)
    if ~isfinite(M(r,1))||~isfinite(M(r,2)), continue; end
    g = find(key==M(r,1)*4+M(r,2),1); if ~isempty(g), G(g,:) = M(r,cols); end
  end
end

function v = quarterly_from_fred(file, key)
  T = readtable(file,'TextType','string'); d = datetime(T.(1)); x = T.(2);
  qk = year(d)*4 + quarter(d); v = nan(numel(key),1);
  for g = 1:numel(key), m = x(qk==key(g)); if ~isempty(m), v(g) = mean(m,'omitnan'); end, end
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
