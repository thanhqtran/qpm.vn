%%%%%%%%%%%%%%%%
%%% Forecast
%%%%%%%%%%%%%%%%

%% Housekeeping
clear all
close all

addpath utils
load pE.mat

%% Read the model
[m, p, mss] = readmodel_est(pE);

%% Set variances -- retaken from 'a03_kalmanfilter.m'
p.std_SHK_L_GDP_GAP   = 1;
p.std_SHK_DLA_GDP_BAR = 0.5;

p.std_SHK_DLA_CPI     = 0.75;
p.std_SHK_D4L_CPI_TAR = 2;

p.std_SHK_L_S = 3; 
p.std_SHK_RS  = 1;

p.std_SHK_RR_BAR    = 0.5;
p.std_SHK_DLA_Z_BAR = 0.5;

p.std_SHK_L_GDP_RW_GAP = 1;
p.std_SHK_RS_RW        = 1;
p.std_SHK_DLA_CPI_RW   = 2;
p.std_SHK_RR_RW_BAR    = 0.5;

% solve the model to load the initial condition at the steady state
m = assign(m, p);
m = solve(m);

%% Load results from Kalman filtration of the data
load('results/kalm_his_est.mat');
h = g;
%clear g

%% Define the time frame of the forecast
% Change the time frame depending on you data and forecast period!
startfcast = get(h.mean.L_GDP_GAP, 'last') + 1;
endfcast   = qq(2027,4);
fcastrange = startfcast:endfcast;

%% Example in video
% video example of hard tuning
% h.mean.RS_RW(qq(2014,1):qq(2014,4)) = [ 0.3  0.3  0.2  0.1];
% simplan = plan(m, fcastrange);
% simplan = exogenize(simplan, qq(2014,1):qq(2014,4), 'RS_RW');
% simplan = endogenize(simplan, qq(2014,1):qq(2014,4), 'SHK_RS_RW');

%% New Plan
simplan = plan(m, fcastrange); %plan command creates an object with the name simplan (in setting up the use of tunes below)

% US forecasts follow 
% https://www.conference-board.org/research/us-forecast
d2 = dbload('usdata_forecast.csv');
% compute the GDP_GAP and DLA_CPI
d2.L_GDP_RW_GAP = 100*(d2.GDP_RW_FORECAST-d2.GDP_RW_BAR)/d2.GDP_RW_BAR;
d2.L_CPI_RW = 100*log(d2.CPI_RW);
d2.DLA_CPI_RW = 4*diff(d2.L_CPI_RW);    %annualized so must multiply by 4.


% load the new values
%h.mean.RS_RW(qq(2025,4)) = d2.RS_RW_FORECAST(qq(2025,4));
h.mean.RS_RW(qq(2026,1):qq(2026,4)) = d2.RS_RW_FORECAST(qq(2026,1):qq(2026,4));
h.mean.RS_RW(qq(2027,1):qq(2027,4)) = d2.RS_RW_FORECAST(qq(2027,1):qq(2027,4));

%h.mean.DLA_CPI_RW(qq(2025,4)) = d2.DLA_CPI_RW(qq(2025,4));
h.mean.DLA_CPI_RW(qq(2026,1):qq(2026,4)) = d2.DLA_CPI_RW(qq(2026,1):qq(2026,4));
h.mean.DLA_CPI_RW(qq(2027,1):qq(2027,4)) = d2.DLA_CPI_RW(qq(2027,1):qq(2027,4));

%h.mean.L_GDP_RW_GAP(qq(2025,4)) = d2.L_GDP_RW_GAP(qq(2025,4));
h.mean.L_GDP_RW_GAP(qq(2026,1):qq(2026,4)) = d2.L_GDP_RW_GAP(qq(2026,1):qq(2026,4));
h.mean.L_GDP_RW_GAP(qq(2027,1):qq(2027,4)) = d2.L_GDP_RW_GAP(qq(2027,1):qq(2027,4));

simplan = exogenize(simplan, qq(2026,1):qq(2027,4), {'RS_RW', 'DLA_CPI_RW', 'L_GDP_RW_GAP'});
simplan = endogenize(simplan, qq(2026,1):qq(2027,4), {'SHK_RS_RW', 'SHK_DLA_CPI_RW', 'SHK_L_GDP_RW_GAP'});

% h.mean.L_CPI(qq(2025,3)) = log(exp(h.mean.L_CPI(qq(2024,3))/100)*(1+3.4/100))*100;
% h.mean.DLA_CPI(qq(2025,3)) = 4 * (h.mean.L_CPI(qq(2025,3)) - h.mean.L_CPI(qq(2025,2)));
% 
% simplan = exogenize(simplan, qq(2025,3), {'DLA_CPI'} );
% simplan = endogenize(simplan, qq(2025,3), {'SHK_DLA_CPI'});
% 
% h.mean.L_S(qq(2025,3)) = log(exp(h.mean.L_S(qq(2024,3))/100)*(1+6.64/100))*100;
% %h.mean.DLA_CPI(qq(2025,3)) = 4 * (h.mean.L_S(qq(2025,3)) - h.mean.L_CPI(qq(2025,2)));
% 
% simplan = exogenize(simplan, qq(2025,3), {'L_S'} );
% simplan = endogenize(simplan, qq(2025,3), {'SHK_L_S'});
% 

%% make a forecast
% baseline: jforecast
% s: the model object
s = jforecast(m, h, fcastrange, 'plan', simplan, 'anticipate', true);

s.mean = dbextend(h.mean, s.mean);
s.std = dbextend(h.std, s.std);

%%
dbsave(s.mean,'results/baseline_hardtuning.csv');

%% Graphs and Tables
Tablerng = startfcast-4:endfcast;
Plotrng = startfcast-4:endfcast;
Histrng = startfcast-4:startfcast-1;

% Specify country and units for exchange rate
country = 'Vietnam';
exchange = 'VND/USD';

% Report
x = report.new('Adjusted for US Forecasts');

% Figures
sty = struct();
sty.line.linewidth = 1.5;
sty.line.linestyle = {'-';'--';':'};
sty.axes.box = 'off';
sty.legend.location = 'Best';
sty.legend.Box = 'off';

band_probs = [0.9 0.6 0.3];
x.figure('Forecast - Main Indicators', 'subplot', [2,2], 'style', sty, 'range', Plotrng, 'dateformat', 'YYYY:PP');
% subplots
x.graph('Inflation, yoy in %');
x.fanchart('', s.mean.D4L_CPI, s.std.D4L_CPI, band_probs);
x.highlight('', Histrng);
x.graph('Real GDP, yoy in %');
x.fanchart('', s.mean.D4L_GDP, s.std.D4L_GDP, band_probs);
x.highlight('', Histrng);
x.graph('Nominal exchange rate depreciation, yoy %');
x.fanchart('', s.mean.D4L_S, s.std.D4L_S, band_probs);
x.highlight('', Histrng);
x.graph('Policy rate (3-month Interbank), %');
x.fanchart('', s.mean.RS , s.std.RS, band_probs);
x.highlight('', Histrng);
% x.graph('Real Marginal Costs, yoy %');
% x.fanchart('', s.mean.RMC, s.std.RMC,  band_probs);
% x.highlight('', Histrng);
% x.graph('Real interest rate, %');
% x.fanchart('', s.mean.RR , s.std.RR, band_probs);
% x.highlight('', Histrng);




x.figure('Forecast - Main Indicators', 'subplot', [3,2], 'style', sty, 'range', Plotrng, 'dateformat', 'YYYY:P');

x.graph('Inflation, %', 'legend', true);
x.series('q-o-q', s.mean.DLA_CPI);
x.series('y-o-y', s.mean.D4L_CPI);
x.series('Target', s.mean.D4L_CPI_TAR);
x.vline('', startfcast-1);

x.graph('Output Gap, %', 'legend', false, 'zeroline', true);
x.series('', s.mean.L_GDP_GAP);
x.vline('', startfcast-1);

x.graph('Nominal Interest Rate, % p.a.', 'legend', false);
x.series('', s.mean.RS);
x.vline('', startfcast-1);

x.graph('Nominal Exchange Rate Deprec., %', 'legend', true);
x.series('q-o-q', s.mean.DLA_S);
x.series('y-o-y', (s.mean.L_S - s.mean.L_S{-4}));
x.vline('', startfcast-1);

% x.graph('Real exchange rate gap, %', 'legend', false);
% x.series('', s.mean.L_Z_GAP);
% x.vline('', startfcast-1);


x.graph('Monetary Conditions, %', 'legend', true, 'zeroline', true);
x.series('MCI', s.mean.MCI);
x.series('RIR gap', s.mean.RR_GAP );
x.series('RER gap', s.mean.L_Z_GAP);
x.vline('', startfcast-1);

x.graph(['Nominal Exchange Rate - ' exchange], 'legend', false);
x.series('', exp(s.mean.L_S/100));
x.vline('', startfcast-1);
% 
x.pagebreak();

%% Tables
TableOptions = {'range', Tablerng, 'vline', startfcast-1, 'decimal', 2, 'dateformat', 'YY:PP',...
    'long', true, 'longfoot', '---continued', 'longfootposition', 'right'};

x.table('Forecast - Main Indicators', TableOptions{:});

x.subheading('');
x.subheading('Prices');
  x.series('CPI ', s.mean.D4L_CPI, 'units', '% (y-o-y)');
  x.series('', s.mean.DLA_CPI, 'units', '% (q-o-q)');
  x.series('Target', s.mean.D4L_CPI_TAR, 'units', '%');
  
x.subheading('');  
  x.series('Ex. Rate', exp(s.mean.L_S/100)/1000, 'units', '1000VND');
  x.series('', (s.mean.L_S-s.mean.L_S{-4}), 'units', '% (y-o-y)');
x.subheading('');
  x.series('Policy Rate', s.mean.RS, 'units', '% p.a.');
  x.series('Real Rate', s.mean.RR, 'units', '% p.a.');

x.subheading('');
x.subheading('Real Economy');
  x.series('Output Gap', s.mean.L_GDP_GAP, 'units', '%');
  x.series('Real GDP', s.mean.DLA_GDP, 'units', '% (q-o-q)');
  x.series('', s.mean.D4L_GDP, 'units', '% (y-o-y)');
  x.series('Potential GDP', s.mean.DLA_GDP_BAR, 'units', '% (q-o-q)');
  x.series('Marginal Cost', s.mean.RMC, 'units', '% (q-o-q)');
  x.series('RMC - Domestic', s.mean.a2*s.mean.a3*s.mean.L_GDP_GAP, 'units', 'p.p.');
  x.series('RMC - Imported', s.mean.a2*(1-s.mean.a3)*s.mean.L_Z_GAP, 'units', 'p.p.');
  
x.subheading('');
x.subheading('Monetary Conditions');
  x.series('MC Index', s.mean.MCI, 'units', '%');
  x.series('RIR Gap', s.mean.RR_GAP, 'units', 'p.p.');
  x.series('RER Gap', s.mean.L_Z_GAP, 'units', '%');

x.subheading('');
x.subheading('Foreign Counterpart: USA');
  x.series('Inflation', s.mean.DLA_CPI_RW, 'units', '% (y-o-y)');
  x.series('Interest Rate', s.mean.RS_RW, 'units', '% p.a.');
  x.series('Output Gap', s.mean.L_GDP_RW_GAP, 'units', '%');
  

x.pagebreak();
%% MORE TABLES
x.table('Forecast - Decompositions', TableOptions{:});

 
x.subheading('');
x.subheading('Headline Inflation');
  x.series('Headline Inflation', s.mean.DLA_CPI, 'units', '%');
  x.series('Lag', s.mean.a1*s.mean.DLA_CPI{-1}, 'units', 'p.p.');
  x.series('Expectations', (1-s.mean.a1)*s.mean.E_DLA_CPI, 'units', 'p.p.');
  x.series('RMC', s.mean.a2*s.mean.RMC, 'units', 'p.p.');
  x.series('RMC - Domestic', s.mean.a2*s.mean.a3*s.mean.L_GDP_GAP, 'units', 'p.p.');
  x.series('RMC - Imported', s.mean.a2*(1-s.mean.a3)*s.mean.L_Z_GAP, 'units', 'p.p.');
  x.series('Shock', s.mean.SHK_DLA_CPI, 'units', 'p.p.');

x.subheading('');
x.subheading('Ouptut Gap Decomposition');
  x.series('Output Gap', s.mean.L_GDP_GAP, 'units', '%');
  x.series('Lead', s.mean.b0*s.mean.L_GDP_GAP{+1}, 'units', 'p.p.');
  x.series('Lag', s.mean.b1*s.mean.L_GDP_GAP{-1}, 'units', 'p.p.');
  x.series('Monetary Conditions', -s.mean.b2*s.mean.MCI, 'units', 'p.p.');
  x.series('Real Interest Rate', -s.mean.b2*s.mean.b4*s.mean.RR_GAP, 'units', 'p.p.');
  x.series('Real Exchange Rate', -s.mean.b2*(1-s.mean.b4)*(-s.mean.L_Z_GAP), 'units', 'p.p.');
  x.series('Foreign Output Gap', s.mean.b3*s.mean.L_GDP_RW_GAP, 'units', 'p.p.');
  x.series('Shock', s.mean.SHK_L_GDP_GAP, 'units', 'p.p.');
  
x.subheading('');
x.subheading('Supply Side Assumptions');
  x.series('Potential Output', s.mean.DLA_GDP_BAR, 'units', '% (q-o-q)');
  x.series('', (s.mean.L_GDP_BAR-s.mean.L_GDP_BAR{-4}), 'units', '% (y-o-y)');
  x.subheading('');
  x.series('Eq. Real Interest Rate', s.mean.RR_BAR, 'units', '%');
  x.subheading('');
  x.series('Eq. Real Exchange Rate', s.mean.DLA_Z_BAR, 'units', '% (q-o-q)');
  x.series('', (s.mean.L_Z_BAR-s.mean.L_Z_BAR{-4}), 'units', '% (y-o-y)'); 
  
x.pagebreak();
x.table('Forecast - Policy Decomposition', TableOptions{:});

x.subheading('Interest Rate Decomposition');
  x.series('Interest Rate', s.mean.RS, 'units', '% p.a.');
  x.series('Lag', s.mean.g1*s.mean.RS{-1}, 'units', 'p.p.');
  x.series('Neutral Rate', (1-s.mean.g1)*s.mean.RSNEUTRAL, 'units', 'p.p.');
  x.series('Expected Inflation DEv.', (1-s.mean.g1)*s.mean.g2*(s.mean.D4L_CPI{+1} - s.mean.D4L_CPI_TAR{+4}), 'units', 'p.p.');
  x.series('Output Gap', (1-s.mean.g1)*s.mean.g3*s.mean.L_GDP_GAP, 'units', 'p.p.');
  x.series('Residual', s.mean.SHK_RS, 'units', 'p.p.');

x.subheading('');
x.subheading('Monetary Conditions Decomposition');
  x.series('Monetary Conditions', s.mean.MCI, 'units', '%');
  x.series('Real Interest Rate Gap', s.mean.b4*s.mean.RR_GAP, 'units', 'p.p.');
  x.series('Real Exchange Rate Gap', (1-s.mean.b4)*(-s.mean.L_Z_GAP), 'units', 'p.p');
  
x.table('Forecast - Foreign Variables', TableOptions{:});

x.subheading('USA');
  x.series('Inflation', s.mean.DLA_CPI_RW, 'units', '% (q-o-q)');
  x.series('Interest Rate', s.mean.RS_RW, 'units', '% p.a.');
  x.series('Output Gap', s.mean.L_GDP_RW_GAP, 'units', '%');

x.pagebreak();
x.table('Structural shocks', TableOptions{:});
x.series('Shock: Output gap (demand)', s.mean.SHK_L_GDP_GAP);
x.series('Shock: CPI inflation (cost-push)', s.mean.SHK_DLA_CPI);
x.series('Shock: Exchange rate (UIP)', s.mean.SHK_L_S);
x.series('Shock: Interest rate (monetary policy)', s.mean.SHK_RS);
x.series('Shock: Inflation target', s.mean.SHK_D4L_CPI_TAR);
x.series('Shock: Real interest rate', s.mean.SHK_RR_BAR);
x.series('Shock: Real exchange rate depreciation', s.mean.SHK_DLA_Z_BAR);
x.series('Shock: Potential GDP growth', s.mean.SHK_DLA_GDP_BAR);
x.series('Shock: Foreign output gap', s.mean.SHK_L_GDP_RW_GAP );
x.series('Shock: Foreign nominal interest rate', s.mean.SHK_RS_RW);
x.series('Shock: Foreign inflation', s.mean.SHK_DLA_CPI_RW);
x.series('Shock: Foreign real interest rate', s.mean.SHK_RR_RW_BAR);

x.publish('results/Forecast_Hardtuning3D', 'display', false,'cleanup=',false);
disp('Done!');
    

