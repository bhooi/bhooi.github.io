cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util

% CMU1 dataset
Datacode = 'int3';
Dataname = 'int3_data.mat';
data_name = 'CMU';
start_pt = 14;
[Vr, Vi, Ir, Ii, temp, timestamp] = preprocess_CMU(Dataname, Datacode);

% CMU2 dataset
% Datacode = 'data_0725_all_2';
% Dataname = 'data_0725_all_2_data.mat';
% [Vr, Vi, Ir, Ii, temp, timestamp] = preprocess_CMU2(Dataname, Datacode);

% [Vr, Vi, Ir, Ii, temp, param] = simulate_data(false);
% [Vr, Vi, Ir, Ii, temp, param] = simulate_data2(false);

n = length(Ir);
% temp = smoothts(temp, 'e', .05);


%%

% alpha = .3;
% beta = 0;
% gamma = .01;
% phi = 1;
% m = 24;
% lambda = 5; % seasonal regularization
% lambda2 = 0; % overall regularization
% tempcoef = [4 1 .5 .2 73]; 

alpha = .6;
beta = 0.1;
gamma = .05;
phi = 1;
m = 24;
lambda = .02; % seasonal regularization
lambda2 = .02; % overall regularization
tempcoef = [[1 .25 .2 .1] 65];


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
rwid = 2;
tday = (1:length(Ir))/24;
figure('Position', [100 100 600 600]);
subplot(3,1,1); 
plot(tday, Ir, 'k-', 'LineWidth', 1.5); hold on; 
title('I_R'); ylabel('Amp.');
set(gcf, 'PaperPositionMode', 'auto');
set(findall(gcf,'Type','Axes'),'FontSize',22);
set(findall(gcf,'Type','Text'),'FontSize',24);
yl = ylim;
posx = [sort_idx(1)-rwid sort_idx(1)-rwid sort_idx(1)+rwid+1 sort_idx(1)+rwid+1];
posy = [yl(1) yl(2) yl(2) yl(1)];
r = patch(posx, posy, [1 0 0], 'facealpha', .6,'EdgeColor','none');
subplot(3,1,2);
plot(tday, Ii, 'k-', 'LineWidth', 1.5); hold on; 
title('I_I'); ylabel('Amp.');
set(gcf, 'PaperPositionMode', 'auto');
set(findall(gcf,'Type','Axes'),'FontSize',22);
set(findall(gcf,'Type','Text'),'FontSize',24);
yl = ylim;
posy = [yl(1) yl(2) yl(2) yl(1)];
r = patch(posx, posy, [1 0 0], 'facealpha', .6,'EdgeColor','none');
subplot(3,1,3);
plot(tday, anom_scores, 'r-', 'LineWidth', 1.5);
title('Anomalousness'); ylabel('No. of IQRs');
set(gcf, 'PaperPositionMode', 'auto');
set(findall(gcf,'Type','Axes'),'FontSize',22);
set(findall(gcf,'Type','Text'),'FontSize',24);
printpdf(gcf, sprintf('../plots/anomaly_%s.pdf', data_name));

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