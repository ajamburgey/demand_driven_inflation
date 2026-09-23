% LoadData: load the dataset and name the series used by the models.
% Run from the VAR/ folder. The full column list, with sources, is in
% Mnem and Descr inside data/VARData.mat.

load(fullfile('data','VARData.mat'))

% paper sample convention: the analysis uses data through 2026:Q1, even
% when the dataset on disk extends further
Data = Data(TimeQ <= datetime(2026,1,1), :);

% United States
UScpi      = log(Data(:,1));                   % CPI (less OER)
USgdp      = log(Data(:,3));                   % real GDP
UStb1      =     Data(:,5)/100;                % 1-year Treasury rate
UScpiexen  = log(Data(:,7));                   % CPI ex energy
UScpitren  = log(Data(:,11));                  % CPI transportation energy
UScpihhen  = log(Data(:,13));                  % CPI household energy
USdef      =     Data(:,15)/100;               % primary deficit, % of potential GDP

% Euro area
EAhicp     = log(Data(:,2));                   % HICP
EAgdp      = log(Data(:,4));                   % real GDP
EAeuribor1 =     Data(:,6)/100;                % 12-month EURIBOR
EAhicpexen = log(Data(:,8));                   % HICP ex energy
EAhicptren = log(Data(:,12));                  % HICP transportation energy
EAhicphhen = log(Data(:,14));                  % HICP household energy
EAdef      =     Data(:,16)/100;               % primary deficit, % of trend GDP

% quarterly dates
dates=[];
for year=[1959:2026]
    dates=[dates datetime(year,[1:3:12],1)];
end
clear year
dates = dates(1:size(Data,1));                 % align with the truncated data

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
