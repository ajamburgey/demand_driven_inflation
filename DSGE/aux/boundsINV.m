function theta = boundsINV (param);


gamma100=   param(1);
pss100=     param(2);
Fbeta=      bound0INV(param(3));
h=          bound01INV(param(4));
xip=        bound01INV(param(5));
fp=         param(6);
fy=         param(7);
rhoR=       bound01INV(param(8));
rhoz=       bound01INV(param(9)); 
rholambdap= bound01INV(param(10));
rhob=       bound01INV(param(11)); 
sdR=        bound0INV(param(12)); 
sdz=        bound0INV(param(13)); 
sdlambdap=  bound0INV(param(14)); 
sdpit=      bound0INV(param(15)); 
sdb=        bound0INV(param(16)); 
iotap=      bound01INV(param(17));
ExtraParam1=param(18);
sdmps1=     bound0INV(param(19)); 
decay=      bound0INV(param(20)); 
rhoZ=       bound01INV(param(21)); 
sdZ=        bound0INV(param(22)); 

theta = [gamma100 pss100 Fbeta h xip fp fy rhoR rhoz rholambdap rhob sdR sdz sdlambdap sdpit sdb iotap ExtraParam1 sdmps1 decay rhoZ sdZ];



function rho = bound01INV(param);
rho = log(param/(1-param));

function sigma = bound0INV(param);
sigma = log(param);