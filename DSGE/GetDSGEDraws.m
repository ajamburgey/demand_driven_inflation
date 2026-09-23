% GetDSGEDraws: estimate the posterior mode of the DSGE model and get draws
% using MCMC
%
% Run GetDSGEData.m then PrepareDSGEData.m first if data/DSGEData.mat doesn't exist.

close all
clear
addpath(genpath('aux'))
addpath('gensys')
addpath('csminwel')

%% data (sample: 1997:I - 2026:I)
S = load(fullfile('data','DSGEData.mat'));
GDPgr = S.GDPgr;                    % real GDP
infl  = S.infl*4;                   % GDP deflator, annualized
ffr   = S.ffr;
tbill = S.tbill;
DATA  = [GDPgr infl tbill ffr];

StartDate = 1998;
DATA = DATA(5:end,:);
y    = DATA(1:88,:);
Tzlb = 44;                 % last ZLB quarter within the estimation sample
pos0 = 6:9;                % anticipated MP shocks shut off at the ZLB
[T,n]    = size(y);
DATAnony = DATA(T+1:end,:);
TT       = size(DATA,1);
TTT      = TT-T;

rng(5)   % the whole script is seeded once, as in the VAR draws scripts

%% posterior mode
np = 22;
GUESS = [0.519070181  0.4662545159 0.271414785  0.5359543726 0.6105952746 ...
          2.305867881  0.3812823847 0.8736600593 0.2609570501 0.4637052593 ...
          0.6249127632 0.1476849055 0.5404545995 0.1074951617 0.04257181447 ...
          0.8202025839 0.249610232  0.07778299134 0.1200048424 1.099401461 ...
          0.4177139865 0.4597356762];

x0 = boundsINV(GUESS);
fprintf('%s: refining the initial guess with csminwel...\n', mfilename);
[~,xh,~,hes] = csminwel('logpostCPS',x0,.1*eye(np),[],10e-5,1000,T,y,Tzlb,pos0);
POSTMODE = bounds(xh);
JJ = jacobCPS(xh);
HH = JJ*hes*JJ';

% csminwel leaves scratch files in the working directory; remove them
for f = {'g1.mat','g2.mat','g3.mat','H.dat'}
    if isfile(f{1}), delete(f{1}); end
end

%% MCMC draws
MCMCconst = .5;      % scaling constant for the inverse-Hessian proposal
M         = 100000;  % chain length
N         = 20000;   % burn-in discarded from the beginning

P1 = zeros(M,np);
P1(1,:) = mvnrnd(POSTMODE, 4*HH*MCMCconst^2, 1);
logpostOLD = logpostCPS_MCMC(P1(1,:),T,y,Tzlb,pos0);

count = 0;
fprintf('%s: running the %d-draw MCMC chain...\n', mfilename, M);
for i = 2:M
    if mod(i,10000) == 0
        fprintf('%s: MCMC draw %d/%d\n', mfilename, i, M);
    end
    P1(i,:) = mvnrnd(P1(i-1,:), HH*MCMCconst^2, 1);
    logpostNEW = logpostCPS_MCMC(P1(i,:),T,y,Tzlb,pos0);
    if logpostNEW > logpostOLD
        logpostOLD = logpostNEW;
        count = count+1;
    elseif rand(1) < exp(logpostNEW-logpostOLD)
        logpostOLD = logpostNEW;
        count = count+1;
    else
        P1(i,:) = P1(i-1,:);
    end
end
ACCrate = count/M;
fprintf('%s: MH acceptance rate %.3f\n', mfilename, ACCrate);

%% solve the model at the mode and get the pre-2019 smoothed states
[G1,C,impact,eu,SDX,zmat,NY,NX] = modCPSbase(POSTMODE);
SS_SD19 = SmoothedStates(y,G1,impact,SDX,zmat,C,Tzlb,pos0);

outdir = fullfile('draws');
save(fullfile(outdir,'DSGE_draws.mat'), ...
     'G1','C','impact','eu','SDX','zmat','NY','NX','POSTMODE','HH', ...
     'P1','N','M','MCMCconst','ACCrate', ...
     'SS_SD19','y','DATA','DATAnony','T','TT','TTT','Tzlb','pos0','StartDate');

fprintf('GetDSGEDraws: eu = [%d %d] (existence,uniqueness; both 1 = unique stable solution), saved %s\n', ...
        eu(1), eu(2), fullfile(outdir,'DSGE_draws.mat'));

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
