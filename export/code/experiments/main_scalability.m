cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util
addpath util/distinguishable_colors
addpath util/terrorbar

% == CMU DATASET 1
Datacode = 'int3';
data_name = 'CMU';
Dataname = 'int3_data.mat';
[Vr, Vi, Ir, Ii, temp, ~] = preprocess_CMU(Dataname, Datacode);
D = [Vr; Vi; Ir; Ii; temp];
n = length(Vr);
m = 24;
alpha = .9;
beta = 0.01;
gamma = .2;
phi = 1;
m = 24;
lambda = .02; % seasonal regularization
lambda2 = .02; % overall regularization
tempcoef = [[1 .25 .2 .1] 70];
n_init = m * 10;
pred_len = 24;

trial_sizes = round(500000 * 1.5.^(1:11));
% trial_sizes = trial_sizes(1);
num_trials = length(trial_sizes);
num_reps = 1;
runtime = nan(num_trials, num_reps);

D_ext = repmat(D, [1 m + ceil(trial_sizes(end) / n)]);
temp_ext = D_ext(5,:);

%%
for trial_idx = 1:num_trials
    fprintf('==== size: %d\n', trial_sizes(trial_idx));
    Dcur = D_ext(:, 1:trial_sizes(trial_idx));
    Vr_cur = Dcur(1,:);
    Vi_cur = Dcur(2,:);
    Ir_cur = Dcur(3,:);
    Ii_cur = Dcur(4,:);
    for rep_idx = 1:num_reps
        tic;
        etsbig_forecast(Ir_cur, Ii_cur, Vr_cur, Vi_cur, temp_ext, m, pred_len, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, [], []);
        runtime(trial_idx, rep_idx) = toc;
    end
end

% save('../output/scalability.mat', 'runtime');
load('../output/scalability.mat');
mean_times = mean(runtime, 2);

%%
figure('Position', [0 0 500 500]);
colors = distinguishable_colors(3);
loglog(trial_sizes(2:end), mean_times(2:end),'-x', 'LineWidth',3, 'Color', colors(1, :), 'MarkerSize', 12); hold on;

% x1 = trial_sizes(end);
% x2 = trial_sizes(1);
% y1 = .7 * mean_times(end);
% y2 = y1 * x2 / x1;
x1 = 10^6; x2 = 10^8; y1=2; y2=y1 * x2 / x1;
loglog([x1 x2], [y1 y2], 'k--', 'LineWidth',3); hold on;
xlabel('Time series length');
ylabel('Time taken (s)');
set(findall(gcf,'Type','Axes'),'FontSize',26);
set(findall(gcf,'Type','Text'),'FontSize',26);

set(gcf, 'PaperPositionMode', 'auto');
printpdf(gcf, '../plots/scalability.pdf');
hold off;