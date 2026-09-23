function logpriorCPS = logpriorCPS (param);

loprior = zeros(length(param));

%prior(1)  = log(normpdf(param(1),0.475,0.025));     % gamma100
prior(1)  = log(normpdf(param(1),0.45,0.05));     % gamma100
prior(2)  = log(normpdf(param(2),0.5,0.1));         % pss100
prior(3)  = logGammapdf(param(3),0.25,0.1);         % Fbeta
prior(4)  = logBetapdf(param(4),0.5,0.1);           % h
prior(5)  = logBetapdf(param(5),0.66,0.1);          % xip
%prior(6)  = log(normpdf(param(6),1.7,0.3));         % fp
prior(6)  = log(normpdf(param(6),1.5,0.5));         % fp
%prior(7) = logGammapdf(param(7),0.4,0.2);           % fy
prior(7) = log(normpdf(param(7),.125,0.075));       % fy
prior(8) = logBetapdf(param(8),0.6,0.2);            % rhoR
prior(9) = logBetapdf(param(9),0.4,0.2);            % rhoz 
prior(10) = logBetapdf(param(10),0.6,0.2);          % rholambdap
prior(11) = logBetapdf(param(11),0.6,0.2);          % rhob 
prior(12) = logIG1pdf(param(12),0.15,1);            % sdR 
prior(13) = logIG1pdf(param(13),1,1);               % sdz 
prior(14) = logIG1pdf(param(14),0.15,1);            % sdlambdap 
%prior(15) = logUnifpdf(param(15),0,0.15);           % sdpit --- for the uniform distribution use lower and upper bound instead of mean and variance
prior(15) = logIG1pdf(param(15),0.025,1);          % sdpit --- for the uniform distribution use lower and upper bound instead of mean and variance
prior(16) = logIG1pdf(param(16),1,1);               % sdb 
prior(17) = logBetapdf(param(17),0.5,0.1);          % iotap
prior(18) = log(normpdf(param(18),.125,0.075));     % fdY
prior(19) = logIG1pdf(param(19),0.15,1);            % sdmps1
prior(20) = log(normpdf(param(20),1,0.25));         % decay
prior(21) = logBetapdf(param(21),0.6,0.2);          % rhoZ
prior(22) = logIG1pdf(param(22),1,1);               % sdZ



if all(isfinite(prior))==0 | all(isreal(prior))==0;
    logpriorCPS=-1e10;
else
    logpriorCPS=sum(prior);
end