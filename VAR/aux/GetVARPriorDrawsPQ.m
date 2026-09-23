function [BETAp, Gp] = PriorDrawsPQ(yE, lags, NPRIOR, NR, SR)
% PriorDrawsPQ  Draws from the proper prior of the baseline PQ model,
% with the sign restrictions applied exactly as in estimation.
%
% A prior draw samples the two hyperparameters from their Gamma
% hyperpriors (lambda mode 0.2 sd 0.4, miu mode 1 sd 1, truncated to the
% GLP bounds), forms the Minnesota and sum-of-coefficients prior exactly
% as bvarGLP (random walk mean, AR residual scales, Vc = 10e6, lag decay
% 2), draws (Sigma, B) from the normal-inverse-Wishart conditional on
% the dummy observations only, and accepts rotations by the SignRestrict
% rule (NR Haar rotations per parameter draw, R-diagonal sign fix,
% output-positive normalization, signs on impact).
%
% INPUT   yE      estimation sample (levels), T x n
%         lags    number of lags
%         NPRIOR  accepted draws to return
%         NR      rotations per parameter draw
%         SR      n x n sign pattern (columns shocks, rows variables)
% OUTPUT  BETAp, Gp   accepted lag coefficients and impact matrices
% -------------------------------------------------------------------------
[TT, n] = size(yE);  k = 1 + n*lags;
x  = zeros(TT, k);  x(:,1) = 1;
for i = 1:lags
    x(lags+1:end, 1+(i-1)*n+1:1+i*n) = yE(lags+1-i:end-i, :);
end
x  = x(lags+1:end,:);
y0 = mean(yE(1:lags,:), 1);
yR = yE(lags+1:end,:);  T = size(yR,1);
SS = zeros(n,1);
for i = 1:n
    ar = ols1(yR(:,i), [ones(T,1), x(:,1+i)]);
    SS(i) = ar.sig2hatols;
end
b = zeros(k, n);  b(2:n+1,:) = eye(n);
d = n + 2;  psi = SS*(d-n-1);  Vc = 10e6;  alpha = 2;
gl = gcoef(0.2, 0.4);  gm = gcoef(1, 1);

BETAp = NaN(k, n, NPRIOR);  Gp = NaN(n, n, NPRIOR);
accP = 0;  tried = 0;
while accP < NPRIOR && tried < 4e6
    tried = tried + 1;
    lam = gamrnd(gl.k, gl.theta);  if lam < 1e-4 || lam > 5;  continue; end
    miu = gamrnd(gm.k, gm.theta);  if miu < 1e-4 || miu > 50; continue; end
    omega = zeros(k,1);  omega(1) = Vc;
    for i = 1:lags
        omega(1+(i-1)*n+1 : 1+i*n) = (d-n-1)*(lam^2)*(1/(i^alpha))./psi;
    end
    yd = (1/miu)*diag(y0);
    xd = [zeros(n,1) (1/miu)*repmat(diag(y0),1,lags)];
    bh   = (xd'*xd + diag(1./omega)) \ (xd'*yd + diag(1./omega)*b);
    eps  = yd - xd*bh;
    S    = diag(psi) + eps'*eps + (bh-b)'*diag(1./omega)*(bh-b);
    [V,E] = eig(S);  Sinv = V*diag(1./abs(diag(E)))*V';
    eta   = mvnrnd(zeros(1,n), Sinv, d);
    SIG   = (eta'*eta) \ eye(n);
    cholSIG   = cholred((SIG+SIG')/2);
    cholZZinv = cholred((xd'*xd + diag(1./omega)) \ eye(k));
    B = bh + cholZZinv'*randn(k,n)*cholSIG;
    Cs = chol((SIG+SIG')/2, 'lower');
    for j = 1:NR
        Xr = randn(n);  [Q, Rq] = qr(Xr);  Q = Q*diag(sign(diag(Rq)));
        g = Cs*Q;  g = g*diag(sign(g(1,:)));
        if all(all(g.*SR >= 0))
            accP = accP + 1;
            Gp(:,:,accP) = g;  BETAp(:,:,accP) = B;
            if accP >= NPRIOR; break; end
        end
    end
end
BETAp = BETAp(:,:,1:accP);  Gp = Gp(:,:,1:accP);
end

function r = gcoef(mode, sd)
% GammaCoef of the GLP package
r.k = (2 + mode^2/sd^2 + sqrt((4 + mode^2/sd^2)*mode^2/sd^2))/2;
r.theta = sqrt(sd^2/r.k);
end

function C = cholred(S)
% reduced-rank Cholesky of the GLP package
[v, dd] = eig((S+S')/2);
dd = diag(real(dd));
scale = mean(diag(S))*1e-12;
J = (dd > scale);
C = zeros(size(S));
C(J,:) = (v(:,J)*(diag(dd(J)))^(1/2))';
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
