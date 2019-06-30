cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util

Datacode = 'lbnl';
data_name = 'LBNL';
interval = 300; % time interval between data points
[Vr, Vi, Ir, Ii, temp] = preprocess_LBNL(interval);
n = length(Ir);
initial_days = 3;
num_trials = 5;
m = 86400 / interval;
alpha = .6;
beta = .1;
gamma = .02;
phi = 1;
lambda = .1; % seasonal regularization
lambda2 = .001; % overall regularization
tempcoef = [[0 0 0 0] 68];


%%

% [theta, b, s, paramhat, Irhat, Iihat, err, err_f] = ...
%     etsbig(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);

[theta, b, s, paramhat, Irhat, Iihat, err, err_f, tempcoef] = ...
    etsbig_alternating(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, 10);
% 
fprintf('MSE: %.4f%%     Forecast MSE: %.4f%% \n', err*100, err_f*100);
fprintf('Temperature coefficients:\n');
disp(tempcoef);



% %% plot parameter time series
% 
% paramnames = {'G','B','alpha_r','alpha_i'};
% seriesnames ={'Level', 'Seasonality', 'Temperature', 'Total'};
% 
% figure;
% for i=1:4
%     subplot(4,1,i);
%     plot(paramhat(i,:), 'b-'); title(paramnames{i}); hold on;
%     if exist('param','var') % if this is simulation, plot ground truth params
%         plot(param(i,:), 'r-'); title(paramnames{i});
%     end
% end
% legend({'Fitted', 'Truth'}, 'Location', 'southeast');
% 
% %% plot decomposed parameter time series
% allseries = {theta, s, tempcoef' * temp};
% mycols = {'b','g','r','k'};
% for i=1:4
%     figure('Position', [0 0 600 600]); 
%     energ = nan(1, 3);
%     for j=1:3
%         energ(j) = var(allseries{j}(i,:));
%     end
%     energ = energ / sum(energ);
%     for j=1:3
%         subplot(4,1,j);
%         series = allseries{j}(i,:);
%         plot(series, 'LineWidth', 2, 'Color', mycols{j}); hold on;
%         title(sprintf('%s for %s (energy = %.1f%%)', seriesnames{j}, paramnames{i}, energ(j)*100));
%     end
%     subplot(4,1,4);
%     plot(paramhat(i,:), 'LineWidth', 2, 'Color', mycols{4}); hold on;
%     title(sprintf('Total for %s', paramnames{i}));
%     set(gcf, 'PaperPositionMode', 'auto');
%     set(findall(gcf,'Type','Axes'),'FontSize',18);
%     set(findall(gcf,'Type','Text'),'FontSize',18);
%     set(findall(gcf,'Type','Legend'),'FontSize',18);
%     printpdf(gcf, sprintf('../plots/param_breakdown_%s.pdf', paramnames{i}));
% end


%%
resid_r = Ir - Irhat; 
resid_i = Ii - Iihat;
med_r = median(resid_r);
med_i = median(resid_i);
anom_scores = abs(resid_r - med_r) / iqr(resid_r) + abs(resid_i - med_i) / iqr(resid_i);
[~, sort_idx] = sort(anom_scores, 'descend');

%%

times = (1:length(Ir)) / m;
rwid = 50;
figure('Position', [100 100 600 600]);
subplot(3,1,1); 
plot(times, Ir, 'k-', 'LineWidth', 1.5); hold on; 
title('I_R'); ylabel('Amp.');
subplot(3,1,2);
plot(times, Ii, 'k-', 'LineWidth', 1.5); hold on; 
title('I_I'); ylabel('Amp.');
subplot(3,1,3);
plot(times, anom_scores, 'r-', 'LineWidth', 1.5);
title('Anomalousness'); ylabel('No. of IQRs');
set(gcf, 'PaperPositionMode', 'auto');
xlabel('Days');
set(findall(gcf,'Type','Axes'),'FontSize',18);
set(findall(gcf,'Type','Text'),'FontSize',22);
set(findall(gcf,'Type','Legend'),'FontSize',20);
subplot(3,1,1); 
yl = ylim;
add_anomaly_patch((sort_idx(1)-rwid)/m, (sort_idx(1)+rwid+1)/m, yl(1), yl(2));
subplot(3,1,2);
yl = ylim;
add_anomaly_patch((sort_idx(1)-rwid)/m, (sort_idx(1)+rwid+1)/m, yl(1), yl(2));
printpdf(gcf, sprintf('../plots/anomaly1_%s.pdf', data_name));

%%
figure('Position', [100 100 600 600]);
subplot(2,1,1);
plot(times, 100*Vr, 'k-', 'LineWidth', 1.5); hold on;
title('V_R'); ylabel('Volts');
subplot(2,1,2);
plot(times, 100*Vi, 'k-', 'LineWidth', 1.5); hold on;
title('V_I'); ylabel('Volts');
xlabel('Days');
set(gcf, 'PaperPositionMode', 'auto');
set(findall(gcf,'Type','Axes'),'FontSize',18);
set(findall(gcf,'Type','Text'),'FontSize',22);
set(findall(gcf,'Type','Legend'),'FontSize',20);
subplot(2,1,1); yl = ylim;
add_anomaly_patch((sort_idx(1)-rwid)/m, (sort_idx(1)+rwid+1)/m, yl(1), yl(2));
subplot(2,1,2); yl = ylim;
add_anomaly_patch((sort_idx(1)-rwid)/m, (sort_idx(1)+rwid+1)/m, yl(1), yl(2));
printpdf(gcf, sprintf('../plots/anomaly2_%s.pdf', data_name));
%%

[Vr_full, Vi_full] = preprocess_LBNL_full();
tfull = (1:length(Vr_full)) / (120 * 86400);

%%
zoom = (2.493692 < tfull & tfull < 2.493737);
Vr_sub = Vr_full(zoom); 
Vi_sub = Vi_full(zoom);
save('../output/LBNL_anomaly_sub', 'Vr_sub', 'Vi_sub');
% load('../output/LBNL_anomaly_sub');
t_sub = (1:length(Vr_sub))/120;
figure('Position', [100 100 600 600]);
subplot(2,1,1);
plot(t_sub, Vr_sub, 'k-', 'LineWidth', 1.5); hold on;
title('V_R'); ylabel('Volts');
subplot(2,1,2);
plot(t_sub, Vi_sub, 'k-', 'LineWidth', 1.5); hold on;
title('V_I'); ylabel('Volts');
xlabel('Seconds');
set(gcf, 'PaperPositionMode', 'auto');
set(findall(gcf,'Type','Axes'),'FontSize',18);
set(findall(gcf,'Type','Text'),'FontSize',22);
set(findall(gcf,'Type','Legend'),'FontSize',20);
subplot(2,1,1);
yl = ylim; add_anomaly_patch(.9, 3.1, -400, 400);
subplot(2,1,2);
yl = ylim; add_anomaly_patch(.9, 3.1, -200, 200);
printpdf(gcf, sprintf('../plots/anomaly3_%s.pdf', data_name));





%%

% if strcmp(data_name, 'CMU')
%     plot_names = {'Ir', 'Ii', 'Anomalousness'};
%     plot_series = {Ir, Ii, anom_scores};
% elseif strcmp(data_name, 'LBNL')    
%     plot_names = {'Ir', 'Ii', 'Vr', 'Vi', 'Anomalousness'};
%     plot_series = {Ir, Ii, Vr, Vi, anom_scores};
% end
% plot_series2 = {Irhat, Iihat, [], [], []};
%         
% nseries = length(plot_series);
% figure('Position', [100 100 600 600]);
% for i=1:nseries
%     subplot(nseries,1,i);
%     plot(plot_series{i}); title(plot_names{i}); hold on;
%     if ~isempty(plot_series2{i})
%         plot(plot_series2{i}, 'r-');
%     end
% end