function [BETA, G, acc] = SignRestrict(resGLP, SignRestrictions, Ndraws, ExtraRestrictions, Nr)
% SignRestrict: rotate and accept.
%
% Takes the posterior BVAR draws, draws random orthogonal rotations of each
% one, and keeps the rotations whose responses satisfy the sign restrictions.
% The loop is the SVARsign.m verbatim, so given the same random number
% stream the accepted draws are identical to the original implementation.
%
% INPUT   resGLP            output of bvarGLP (with mcmc.beta, mcmc.sigma)
%         SignRestrictions  n x n (impact) or n x n x h (horizons 1..h)
%                           matrix of 1 / -1 / 0 (0 = unrestricted);
%                           columns are shocks, rows are variables
%         Ndraws            number of posterior draws to rotate
%         ExtraRestrictions optional predicate for restrictions that a sign
%                           matrix cannot express (e.g. the energy
%                           or-conditions). It receives the impact matrix g
%                           (n x n) when SignRestrictions is impact-only, and
%                           the impulse-response array IRFs (n x n x h,
%                           variable x shock x horizon) when SignRestrictions
%                           spans horizons, so an or-condition can be checked
%                           over the same four quarters as the sign matrix
%
% OUTPUT  BETA, G, acc      accepted lag coefficients, impact matrices
%                           and their count
%

if nargin < 4 || isempty(ExtraRestrictions)
    ExtraRestrictions = @(g) true;
end

n = size(SignRestrictions, 1);
posNORM = 1;                                   % sign normalization: every shock is
                                               % expansionary (raises variable 1, GDP)
if nargin < 5 || isempty(Nr)
    if n <= 3; Nr = 10; else; Nr = 100; end    % rotations per posterior draw
end

k    = size(resGLP.mcmc.beta, 1);
G    = NaN(n, n, Ndraws*Nr*.01);               % preallocate for a 1 percent acceptance
BETA = NaN(k, n, Ndraws*Nr*.01);               % guess; the arrays grow past it if needed

acc = 0;
for i = 1:Ndraws
    sigma  = squeeze(resGLP.mcmc.sigma(:,:,i));
    beta   = squeeze(resGLP.mcmc.beta(:,:,i));
    Csigma = chol(sigma, 'lower');

    for j = 1:Nr
        X = randn(n, n);
        [Q, R] = qr(X); Q = Q*diag(sign(diag(R)));
        g = Csigma*Q;
        g = g*diag(sign(g(posNORM,:)));

        if size(SignRestrictions, 3) == 1
            if all(all(g.*SignRestrictions >= 0)) && ExtraRestrictions(g)
                acc = acc + 1;
                G(:,:,acc)    = g(1:n,:);
                BETA(:,:,acc) = beta;
            end
        else
            IRFs = NaN(n, n, size(SignRestrictions, 3));
            for jj = 1:n
                IRFs(:,jj,:) = computeIRFs(beta, g, jj, size(SignRestrictions,3))';
            end
            if all(all(all(IRFs.*SignRestrictions >= 0))) && ExtraRestrictions(IRFs)
                acc = acc + 1;
                G(:,:,acc)    = g(1:n,:);
                BETA(:,:,acc) = beta;
            end
        end
    end
end

BETA = BETA(:,:,1:acc);
G    = G(:,:,1:acc);

% -------------------------------------------------------------------------
% Part of the replication code for Domenico Giannone and Giorgio E.
% Primiceri (2026), "Demand Driven Inflation", Brookings Papers on
% Economic Activity.
%
% Feel free to use and adapt this code for your own research. If it
% contributes to your work, we kindly ask that you acknowledge it by
% citing the accompanying paper.
% -------------------------------------------------------------------------
