cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util
addpath util/distinguishable_colors
addpath simulator

% CMU1 dataset
Datacode = 'int3';
Dataname = 'int3_data.mat';
start_pt = 14;
[Vr, Vi, ~, ~, ~, ~] = preprocess_CMU(Dataname, Datacode);
n = length(Vr);

num_trials = 2;

% Vr_trials = arrayfun(@(x)(4 + .6*abs(sin(2*pi*(1:n)/48)) + .05*wgn(1,n,0)),1:num_trials, 'UniformOutput', false); 
% INCREASE TRIAL
% trial_type = 'increase';
% Vr_trials{1} = Vr + normrnd(0, std(Vr), size(Vr));
% Vr_trials{2} = Vr_trials{1} * 1.05;

% DECREASE TRIAL
% trial_type = 'decrease';
% Vr_trials{1} = Vr + normrnd(0, std(Vr), size(Vr));
% Vr_trials{2} = Vr_trials{1} * .95;

% RESAMPLE TRIAL
case_types = {'increase', 'decrease'};
window_choices = [2 4 8 16];
% method_names = [{'StreamCast', 'PQ', 'PowerCast'}, arrayfun(@(x)sprintf('Window%d', x), window_choices, 'UniformOutput', false)];
method_names = {'StreamCast', 'PQ', 'Window4'};
num_methods = length(method_names);
cols = distinguishable_colors(num_methods);
cols(1:2,:) = cols([2 1],:);
errs = nan(length(case_types), num_methods);

for case_idx = 1:length(case_types)
% for case_idx=1:1
    case_type = case_types{case_idx};
    % Vr_trials{1} = Vr + normrnd(0, std(Vr), size(Vr));
    % Vr_trials{2} = Vr + normrnd(0, std(Vr), size(Vr));
    % 
    % Ir_trials = cell(1, num_trials); 
    % Ii_trials = cell(1, num_trials);
    load_fname = sprintf('../output/%s_trial.mat', case_type);

    % ----
    % for i=1:num_trials
    %     [Ir_trials{i}, Ii_trials{i}] = simulate_data2(Vr_trials{i}, false);
    % end
    % save(load_fname, 'Vr_trials', 'Ir_trials', 'Ii_trials');
    load(load_fname);
    % ----


    paramhat = cell(1, num_methods);
    Irhat = cell(1, num_methods);
    Iihat = cell(1, num_methods);
    trial_names = {'Train', 'Test'};

    series_names = {'V_R [Volts]', 'I_R [Amp.]', 'I_I [Amp.]'};
    nseries = length(series_names);
    % figure('Position', [0 0 800 800]);
    % for i=1:nseries
    %     for j=1:num_trials
    %         ser = {Vr_trials{j}, Ir_trials{j}, Ii_trials{j}};
    %         subplot(nseries,num_trials,(i-1)*num_trials+j);
    %         plot(ser{i}); ylabel(series_names{i}); hold on;
    %         title([trial_type ': ' series_names{i}]);
    %     end
    % end
    % xlabel('Hours');
    % set(gcf, 'PaperPositionMode', 'auto');
    % set(findall(gcf,'Type','Axes'),'FontSize',16);
    % set(findall(gcf,'Type','Text'),'FontSize',18);
    % set(findall(gcf,'Type','Legend'),'FontSize',16);
    % printpdf(gcf, sprintf('../plots/sim2/sim2_%s_data.pdf', trial_type));
    % hold off;

    %%
    alpha = .1;
    beta = .01;
    gamma = .01;
    phi = 1;
    m = 24;
    lambda = .05; % seasonal regularization
    lambda2 = 0.01; % overall regularization
    tempcoef = [0 0 0 0 0]; 

    [theta, b, s, paramhat{1}, ~, ~, err, err_f] = ...
        etsbig('BIG', Ir_trials{1}, Ii_trials{1}, Vr_trials{1}, zeros(1,n), zeros(1,n), m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);
    fprintf('MSE: %.4f%%     Forecast MSE: %.4f%% \n', err*100, err_f*100);

    [~, ~, ~, paramhat{2}, ~, ~, ~, ~] = ...
        etsbig('PQ', Ir_trials{1}, Ii_trials{1}, Vr_trials{1}, zeros(1,n), zeros(1,n), m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);

%     paramhat{3} = fit_PowerCast(Ir_trials{1}, Ii_trials{1}, Vr_trials{1}, zeros(1,n), 3, 'CMU');
    [paramhat{3}, ~, ~] = windowed_big(Ir_trials{1}, Ii_trials{1}, Vr_trials{1}, zeros(1,n), 4);

%     for i=4:num_methods
%         [paramhat{i}, ~, ~] = windowed_big(Ir_trials{1}, Ii_trials{1}, Vr_trials{1}, zeros(1,n), window_choices(i-3));
%     end

    for j=1:num_methods
        if j == 2
            [Irhat{j}, Iihat{j}] = PQPredict(Vr_trials{2}, zeros(1,n), paramhat{j});
        else
            [Irhat{j}, Iihat{j}] = BIGPredict(Vr_trials{2}, zeros(1,n), paramhat{j});
        end
    end

    for method_idx=1:num_methods
        errs(case_idx,method_idx) = mse_ratio(Irhat{method_idx}, Iihat{method_idx}, Ir_trials{2}, Ii_trials{2});
    end

    %% plot actual vs fitted currents
    titlestr = case_type;
    titlestr(1) = char(titlestr(1)-32);
    times = (1:n)/24;
    figure('Position',[100 100 800 600]);
    plot_idx = 1:100;
    subplot(2,1,1); 
    plot(times(plot_idx), Ir_trials{2}(plot_idx), 'kx', 'MarkerSize', 16, 'LineWidth', 4); title(sprintf('%s: I_R', titlestr)); hold on;
    ylabel('I_r [Amp.]');
    vcent = round(mean(Ir_trials{2})/10)*10;
    ylim([vcent-20 vcent+20]);
    for method_idx=1:num_methods
        plot(times(plot_idx), Irhat{method_idx}(plot_idx), '-', 'Color', cols(method_idx,:), 'LineWidth', 4); hold on;
    end
    subplot(2,1,2);
    plot(times(plot_idx), Ii_trials{2}(plot_idx), 'kx', 'MarkerSize', 16, 'LineWidth', 4); title(sprintf('%s: I_I', titlestr)); hold on;
    vcent = round(mean(Ii_trials{2})/10)*10;
    ylabel('I_i [Amp.]');
%     ylim([vcent-10 vcent+20]); 
    for method_idx=1:num_methods
        plot(times(plot_idx), Iihat{method_idx}(plot_idx), '-', 'Color', cols(method_idx,:), 'LineWidth', 4); hold on;
    end
    xlabel('Days');
%     legend(['Truth', method_names], 'Location', 'southeast');
    set(gcf, 'PaperPositionMode', 'auto');
    set(findall(gcf,'Type','Axes'),'FontSize',18);
    set(findall(gcf,'Type','Text'),'FontSize',34);
    set(findall(gcf,'Type','Legend'),'FontSize',20);
    printpdf(gcf, sprintf('../plots/sim2/sim2_%s_fit.pdf', case_type));
    hold off;


    %% plot bar graphs

%     figure('Position', [0 0 800 600]); hold on;
%     for i=1:num_methods
%         bar(i, errs(case_idx,i), 'FaceColor', cols(i,:));
%     end
%     ylabel('MSE'); 
%     set(gca,'XTick', 1:num_methods, 'XTickLabel', method_names);
%     set(gcf, 'PaperPositionMode', 'auto');
%     set(findall(gcf,'Type','Axes'),'FontSize',16);
%     set(findall(gcf,'Type','Text'),'FontSize',18);
%     set(findall(gcf,'Type','Legend'),'FontSize',16);
%     printpdf(gcf, sprintf('../plots/sim2/sim2_%s_bar.pdf', case_type));
%     hold off;
end
%%
fprintf('Errors: \n');
array2table(100*errs, 'RowNames', case_types, 'VariableNames', method_names)
input.data = 100*errs;
input.tableColLabels = method_names;
input.tableRowLabels = case_types;
input.dataFormat = {'%.2f',length(input.tableColLabels)};
input.booktabs = 1;
input.transposeTable = 0;
latex = latexTable(input);

%%

