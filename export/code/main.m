
dataset = 'CMU'; % change this to 'LBNL' for the LBNL dataset
% dataset = 'LBNL';


load(['../data/' dataset '.mat']);

if strcmp(dataset,'CMU')
    m = 24; % CMU data has hourly samples
else
    m = 288; % LBNL dataset has samples every 5 minutes
end

n = 5 * m; % train using the first 5 days 
pred_len = m; % and forecast the next day

temp = smoothts(temp, 'e', .4); % smooth temperature data
alpha = .6;
beta = .01;
gamma = .2;
phi = 1;
lambda = 0; % seasonal regularization
lambda2 = 0; % overall regularization
tempcoef = [0 0 0 0 0]; % initialization point for temperature vector
n_init = 10*m;

% Forecast currents (Ir_fc, Ii_fc) and also fit currents (Irhat, Iihat)
[Vr_fc, Vi_fc, Ir_fc, Ii_fc, Irhat, Iihat] = etsbig_forecast(Ir(1:n), Ii(1:n), Vr(1:n), Vi(1:n), temp, m, pred_len, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, []);

%% Plot fitted against true values, and plot forecasts
figure;
subplot(2,1,1);
plot(Ir, 'kx'); title('I_R'); hold on;
plot(Irhat, 'r-', 'LineWidth', 2); 
plot(n+1 : n+pred_len, Ir_fc, 'b-', 'LineWidth', 2);
subplot(2,1,2);
plot(Ii, 'kx'); title('I_I'); hold on;
plot(Iihat, 'r-', 'LineWidth', 2); 
plot(n+1 : n+pred_len, Ii_fc, 'b-', 'LineWidth', 2);
legend({'Actual', 'Fitted', 'Forecast'});
suptitle(sprintf('MSE: %.2f%%\n', err*100));