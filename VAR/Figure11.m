% Figure11: prior and posterior of the slopes of the demand and supply
% curves at the one year horizon.

close all
clear
addpath(genpath('aux'))
addpath(genpath('GLP_PrePostCovid_ConstantCoeff'))
rng(5)

LoadData
lags   = 4;
Ndraws = 10000;
NRPOST = 120;                                  % rotations per posterior draw
NRPRI  = 40;                                   % rotations per prior draw
NPRIOR = 100000;
HH     = 4;                                    % one year horizon
initialT = find(dates=='01-jan-1997');
SR = [1 1; 1 -1];

%% United States
y   = [USgdp UScpi];
y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',1.0);
[BETA, G, acc] = SignRestrict(resGLP, SR, Ndraws, [], NRPOST);
fprintf('US: %d accepted posterior draws\n', acc);
[demPostUS, supPostUS] = Slopes(BETA, G, HH);
clear BETA G

[BETAp, Gp] = GetVARPriorDrawsPQ(y(1:T0,:), lags, NPRIOR, NRPRI, SR);
fprintf('US: %d accepted prior draws\n', size(Gp,3));
[demPriUS, supPriUS] = Slopes(BETAp, Gp, HH);
clear BETAp Gp

%% Euro area
% no reseeding here: as in PQ.m, the EA chain continues the script's stream
% (do not reseed mid-script; see the note in PQ.m)
y   = [EAgdp EAhicp];
y   = y(initialT:end,:);
dts = dates(initialT:end);
T0  = find(dts=='01-oct-2019');

resGLP = bvarGLP(y(1:T0,:), lags, 'MNalpha',0, 'MNpsi',0, 'sur',0, 'noc',1, ...
                 'mcmc',1, 'Ndraws',2*Ndraws, 'MCMCconst',7.0);
[BETA, G, acc] = SignRestrict(resGLP, SR, Ndraws, [], NRPOST);
fprintf('EA: %d accepted posterior draws\n', acc);
[demPostEA, supPostEA] = Slopes(BETA, G, HH);
clear BETA G

[BETAp, Gp] = GetVARPriorDrawsPQ(y(1:T0,:), lags, NPRIOR, NRPRI, SR);
fprintf('EA: %d accepted prior draws\n', size(Gp,3));
[demPriEA, supPriEA] = Slopes(BETAp, Gp, HH);
clear BETAp Gp

save(fullfile('draws','AppendixSlopes_draws.mat'), ...
     'demPostUS','supPostUS','demPriUS','supPriUS', ...
     'demPostEA','supPostEA','demPriEA','supPriEA');

%% The figure
YEL = [0.9290 0.6940 0.1250];
GRN = [0.4660 0.6740 0.1880];
g4  = linspace(0, 4, 600);

priUS     = SlopeDensity([demPriUS supPriUS], g4);   % pooled prior, identical curves in population
demPostUSd = SlopeDensity(demPostUS, g4);
supPostUSd = SlopeDensity(supPostUS, g4);
priEA     = SlopeDensity([demPriEA supPriEA], g4);
demPostEAd = SlopeDensity(demPostEA, g4);
supPostEAd = SlopeDensity(supPostEA, g4);
ymax = max([priUS demPostUSd supPostUSd priEA demPostEAd supPostEAd]);

figure('Position',[0 0 1150 390])

subplot(1,2,1)                                            % (a) United States
hold on; grid on
fill([g4 fliplr(g4)], [demPostUSd zeros(size(g4))], YEL, ...
     'FaceAlpha', 0.55, 'EdgeColor', 0.45*YEL, 'LineWidth', 1.2);
fill([g4 fliplr(g4)], [supPostUSd zeros(size(g4))], GRN, ...
     'FaceAlpha', 0.55, 'EdgeColor', 0.45*GRN, 'LineWidth', 1.2);
TwoColorLine(g4, priUS, ymax*1.05, 0.75*YEL, 0.60*GRN, 0.035, 2.0);
xlim([0 4]); ylim([0 ymax*1.05]); set(gca,'fontsize',13)
title('(a) US')
x0 = 1.45;  yl = ymax*1.05;                               % the legend, drawn by hand
TwoColorLine(linspace(x0, x0+0.35, 30), 0.935*yl*ones(1,30), yl, ...
             0.75*YEL, 0.60*GRN, 0.035, 2.0);
text(x0+0.44, 0.935*yl, 'prior, demand and supply', 'FontSize', 9);
patch([x0 x0+0.35 x0+0.35 x0], yl*[0.845 0.845 0.895 0.895], YEL, ...
      'FaceAlpha', 0.55, 'EdgeColor', 0.45*YEL);
text(x0+0.44, 0.87*yl, 'posterior, demand', 'FontSize', 9);
patch([x0 x0+0.35 x0+0.35 x0], yl*[0.76 0.76 0.81 0.81], GRN, ...
      'FaceAlpha', 0.55, 'EdgeColor', 0.45*GRN);
text(x0+0.44, 0.785*yl, 'posterior, supply', 'FontSize', 9);

subplot(1,2,2)                                            % (b) Euro area
hold on; grid on
fill([g4 fliplr(g4)], [demPostEAd zeros(size(g4))], YEL, ...
     'FaceAlpha', 0.55, 'EdgeColor', 0.45*YEL, 'LineWidth', 1.2);
fill([g4 fliplr(g4)], [supPostEAd zeros(size(g4))], GRN, ...
     'FaceAlpha', 0.55, 'EdgeColor', 0.45*GRN, 'LineWidth', 1.2);
TwoColorLine(g4, priEA, ymax*1.05, 0.75*YEL, 0.60*GRN, 0.035, 2.0);
xlim([0 4]); ylim([0 ymax*1.05]); set(gca,'fontsize',13)
title('(b) EA')

exportgraphics(gcf, fullfile('results','Figure11.pdf'), 'ContentType','vector')

% the hyperparameter optimizer (csminwel, inside bvarGLP) leaves scratch
% files in the working directory; remove them
for f = {'g1.mat','g2.mat','g3.mat','H.dat'}
    if isfile(f{1}); delete(f{1}); end
end

% -------------------------------------------------------------------------
%% Functions

function [dem, sup] = Slopes(BETA, G, HH)
% Slopes  The demand (sign changed) and supply curve slopes at horizon
% HH for every accepted draw.
% INPUT   BETA, G   accepted lag coefficients and impact matrices
%         HH        the horizon (4 = one year)
% OUTPUT  dem, sup  1 x draws vectors of slopes
acc = size(G,3);
dem = NaN(1,acc);
sup = NaN(1,acc);
for m = 1:acc
    Rd = computeIRFs(BETA(:,:,m), G(:,:,m), 1, HH);   % responses to demand
    Rs = computeIRFs(BETA(:,:,m), G(:,:,m), 2, HH);   % responses to supply
    sup(m) =  Rd(HH,2)/Rd(HH,1);
    dem(m) = -Rs(HH,2)/Rs(HH,1);
end
end

function f = SlopeDensity(v, g4)
% SlopeDensity  Kernel density on the window [0, 4]: draws outside are
% dropped and the curve is not rescaled, so the plotted area equals the
% probability mass inside the window.
vin = v(v > 0);
f = ksdensity(vin, g4, 'Support', 'positive', 'BoundaryCorrection', 'reflection');
f = f*(numel(vin)/numel(v));
end

function TwoColorLine(x, y, yscale, colA, colB, dashlen, lw)
% TwoColorLine  One curve drawn as segments of alternating colors,
% chunked by arc length in axis normalized units so the dashes look
% even.
xn = x/max(x);
yn = y/yscale;
s  = [0 cumsum(sqrt(diff(xn).^2 + diff(yn).^2))];
grp = floor(s/dashlen);
for gval = unique(grp)
    idx = find(grp == gval);
    if idx(end) < numel(x)
        idx = [idx idx(end)+1];
    end
    if mod(gval,2) == 0
        cc = colA;
    else
        cc = colB;
    end
    plot(x(idx), y(idx), '-', 'Color', cc, 'LineWidth', lw);
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
