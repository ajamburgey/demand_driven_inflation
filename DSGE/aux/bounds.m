function theta = bounds (param);

gamma100=   param(1);
pss100=     param(2);
Fbeta=      bound0(param(3));
h=          bound01(param(4));
xip=        bound01(param(5));
fp=         param(6);
fy=         param(7);
rhoR=       bound01(param(8));
rhoz=       bound01(param(9)); 
rholambdap= bound01(param(10));
rhob=       bound01(param(11)); 
sdR=        bound0(param(12)); 
sdz=        bound0(param(13)); 
sdlambdap=  bound0(param(14)); 
sdpit=      bound0(param(15)); 
sdb=        bound0(param(16)); 
iotap=      bound01(param(17));
ExtraParam1=param(18);
sdmps1=     bound0(param(19)); 
decay=      bound0(param(20)); 
rhoZ=       bound01(param(21)); 
sdZ=        bound0(param(22)); 

theta = [gamma100 pss100 Fbeta h xip fp fy rhoR rhoz rholambdap rhob sdR sdz sdlambdap sdpit sdb iotap ExtraParam1 sdmps1 decay rhoZ sdZ];



function rho = bound01(param);
rho = 1-1/(1+exp(param));

function sigma = bound0(param);
sigma = exp(param);