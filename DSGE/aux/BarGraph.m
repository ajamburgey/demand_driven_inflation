% -------------------------------------------------------------------------
% Part of the replication codes for:
% Giannone, Domenico, and Giorgio Primiceri (2024),
% "The Drivers of Post-Pandemic Inflation", NBER Working Paper No. 32859.
% Available at: https://urldefense.com/v3/__https://www.nber.org/papers/w32859__;!!Dq0X2DkFhyF93HkjWTBQKhk!TfQ0n7X2BNZobmQNVQSvqf9JC7Dm9vp-XYxBocAEpqbHAO_jtrufJazBqn6aqqlwo5o8qYAU9WonnHoRUTzNjffQbzg$
%
% If you use these codes in your research—-either in their original form 
% or with modifications—-please cite the above-referenced paper.
% -------------------------------------------------------------------------

function BarGraph(y,dc,sc,dates,colory,colorbars)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% y: data (T x 1)
% dc: deterministic component (T x 1)
% sc: stochastic components (T x n)
% dates: dates (T x 1)
% colory: color for plotting data (1 x 3)
% colorbars: colors for plotting bars (n x 3); can be empty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(colorbars)
    colorbars=[[0.9290 0.6940 0.1250];[0.8500 0.3250 0.0980];[0.4940 0.1840 0.5560];[.5 .5 .5]];
end

[T,n]=size(sc);

for t=1:T
    
    levelUP=dc(t);
    levelDOWN=dc(t);
    
    dateblock=[dates(t)-calmonths(1) dates(t)+calmonths(1) dates(t)+calmonths(1) dates(t)-calmonths(1)];
    
    fill(dateblock,dc(t)+[0 0 sc(t,1) sc(t,1)],colorbars(1,:),'EdgeColor',colorbars(1,:)); hold on
    if sc(t,1)>0; levelUP=sc(t,1)+dc(t); else; levelDOWN=sc(t,1)+dc(t); end    
    
    for i=2:n
        if sc(t,i)>0
            fill(dateblock,levelUP+[0 0 sc(t,i) sc(t,i)],colorbars(i,:),'EdgeColor',colorbars(i,:));
            levelUP=levelUP+sc(t,i);
        else
            fill(dateblock,levelDOWN+[0 0 sc(t,i) sc(t,i)],colorbars(i,:),'EdgeColor',colorbars(i,:));
            levelDOWN=levelDOWN+sc(t,i);
        end        
    end
end
plot(dates,y,'-d','LineWidth',3,'Color',colory);
plot(dates,dc,'LineWidth',3,'Color',colory,'LineStyle','-.');
grid on;