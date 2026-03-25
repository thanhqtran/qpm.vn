% initiate IRIS
start;

% make data
a02_makedata;
% estimate with Bayesian
a07_estimate_bayesian;
% Kalman filter
a03_kalmanfilter_est;

% in sample testing
a04_insample;

% forecast with hard tuning
a05_forecast_hardtuning;
