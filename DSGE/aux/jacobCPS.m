function J=jacobCPS(param);

J=zeros(length(param),1);
J(1)=1;
J(2)=1;
J(3)=bound0prime(param(3));
J(4)=bound01prime(param(4));
J(5)=bound01prime(param(5));
J(6)=1;
J(7)=1;
J(8)=bound01prime(param(8));
J(9)=bound01prime(param(9));
J(10)=bound01prime(param(10));
J(11)=bound01prime(param(11));
J(12)=bound0prime(param(12));
J(13)=bound0prime(param(13));
J(14)=bound0prime(param(14));
J(15)=bound0prime(param(15));
J(16)=bound0prime(param(16));
J(17)=bound01prime(param(17));
J(18)=1;
J(19)=bound0prime(param(19));
J(20)=bound0prime(param(20));
J(21)=bound01prime(param(21));
J(22)=bound0prime(param(22));

J=diag(J);

function y = bound01prime(x);
y = exp(x)/(1+exp(x))^2;

function y = bound0prime(x);
y = exp(x);
