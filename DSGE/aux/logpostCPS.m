function logpost=logpostCPS(param,T,y,Tzlb,pos0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Date: March 6, 2009
% this function computes the value of the posterior density for the model
% in Cogley, Primiceri and Sargent (2009)
% To be used in the minimization algorithm
%
% Uses disclyap_fast (Pearlman-Justiniano doubling algorithm, already in
% this aux/ folder for SmoothedStates.m) in place of the original
% dlyapgio.m, which is not available here; both solve the same equation
% X = G1*X*G1' + Q.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% re-defining the parameter to transform the unconstrained into a
% constrained minimization
param=bounds(param);


% prior density
logprior=logpriorCPS(param);


% posterior calculation
if logprior==-1e10
    logpost=1e10;
    return    
else
    % Solution of the model
    [G1,C,M,eu,SDX,H,NY,NX]=modCPSbase(param);
    if eu ~=[1 1]';
        logpost=1e10;
        return
    else
        % initializing the Kalman filter
        shat=zeros(NY,1);
        Q=M*SDX*SDX'*M';  if Tzlb>0; sss=diag(SDX); sss(pos0)=0; SSS=diag(sss); Q=M*SSS*SSS'*M'; end
        sig=disclyap_fast(G1,Q);
        LOGLH=0;

        % Kalman filter recursion delivering log-likelihood
        for t=1:T
            if t<Tzlb; sss=diag(SDX); sss(pos0)=0; SSS=diag(sss); Q=M*SSS*SSS'*M'; else; Q=M*SDX*SDX'*M'; end
            if t<Tzlb; yy=y(t,[1 2 4])'; HH=H([1 2 4],:); CC=C([1 2 4]); else; yy=y(t,:)'; HH=H; CC=C; end
            [shat,sig,loglh]=kfilter(yy,HH,CC,G1,shat,sig,0,Q);
            %[shat,sig,loglh]=kfilter(y(t,:)',H,C,G1,shat,sig,0,Q);
            LOGLH=LOGLH+loglh;
        end
        logpost=-(LOGLH+logprior);      % logpost = -logpost because use a minimization algorithm (as opposed to maximization)
    end
end