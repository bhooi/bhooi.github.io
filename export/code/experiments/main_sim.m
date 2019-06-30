cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util
addpath util/distinguishable_colors
[Vr, Vi, Ir, Ii, temp, param] = simulate_data(false);
paramhat = {};
Irhat = {};
IiIhat = {};
window_choices = [2 4 8 16];
method_names = [{'ETS-BIG'}, arrayfun(@(x)sprintf('Window (%d)', x), window_choices, 'UniformOutput', false)];
num_methods = length(method_names);

%%
n = length(Ir);

figure;
subplot(4,1,1);
plot(Ir); title('I real');
subplot(4,1,2);
plot(Ii); title('I imag');
subplot(4,1,3);
plot(Vr); title('V real');
subplot(4,1,4);
plot(temp); title('Temperature');

%%
alpha = .3;
beta = 0;
gamma = .01;
phi = 1;
m = 24;
lambda = 5; % seasonal regularization
lambda2 = 0; % overall regularization
tempcoef = [4 1 .5 .2 73]; 

% [theta, b, s, G, B, alpha_R, alpha_I, Irhat, Iihat, err, err_f, tempcoef] = ets_outer(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);
[theta, b, s, paramhat{1}, Irhat{1}, Iihat{1}, err, err_f] = ...
    ets_big(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);

fprintf('MSE: %.4f%%     Forecast MSE: %.4f%% \n', err*100, err_f*100);
fprintf('Temperature coefficients:\n');
disp(tempcoef);

for i=2:num_methods
    [paramhat{i}, Irhat{i}, Iihat{i}] = windowed_big(Ir, Ii, Vr, Vi, window_choices(i-1));
end


%% plot parameter time series

paramnames = {'G','B','alpha_R','alpha_I'};
seriesnames ={'Level', 'Seasonality', 'Temperature'};

figure;
cols = distinguishable_colors(num_methods);
ylims = {[-.5 1.5],[-.5 .5],[-200 200],[-200 200]};
for i=1:4
    subplot(4,1,i);
    plot(param(i,:), 'kx'); title(paramnames{i},'LineWidth', 1); hold on;
    for method_idx=1:num_methods
        plot(paramhat{method_idx}(i,:), '-', 'Color', cols(method_idx,:), 'LineWidth', 1); title(paramnames{i});
    end
    ylim(ylims{i});
end
legend(['Truth', method_names], 'Location', 'southeast');

%% plot decomposed parameter time series
allseries = {theta, s, tempcoef' * temp'};
figure;
for i=1:4
    for j=1:3
        subplot(4,3,(i-1)*3+j);
        plot(allseries{j}(i,:));
        title(sprintf('%s for %s\n', seriesnames{j}, paramnames{i}));
    end
end

%% plot actual vs fitted currents
figure;
subplot(2,1,1);
plot(Ir, 'kx'); title('I_R'); hold on;
for method_idx=1:num_methods
    plot(Irhat{method_idx}, '-', 'Color', cols(method_idx,:), 'LineWidth', 1); 
end
subplot(2,1,2);
plot(Ii, 'kx'); title('I_I'); hold on;
for method_idx=1:num_methods
    plot(Iihat{method_idx}, '-', 'Color', cols(method_idx,:), 'LineWidth', 1); 
end
legend(['Truth', method_names], 'Location', 'southeast');
% suptitle(sprintf('MSE: %.2f%%     Forecast MSE: %.2f%% \n', err*100, err_f*100));

%% plot residuals
figure;
subplot(2,1,1);
title('I_R - I_R hat'); hold on;
for method_idx=1:num_methods
    plot(Irhat{method_idx} - Ir, '-', 'Color', cols(method_idx,:), 'LineWidth', 1); 
end
subplot(2,1,2);
title('I_I - I_I hat'); hold on;
for method_idx=1:num_methods
    plot(Iihat{method_idx} - Ii, '-', 'Color', cols(method_idx,:), 'LineWidth', 1); 
end
legend(method_names, 'Location', 'southeast');

%% plot differences
% figure;
% subplot(3,1,1);
% plot(diff(Vr), 'k-'); title('V_R'); hold on;
% subplot(3,1,2);
% plot(diff(Ir), 'kx'); title('I_R'); hold on;
% plot(Irhat, 'r-', 'LineWidth', 2); 
% subplot(3,1,3);
% plot(diff(Ii), 'kx'); title('I_I'); hold on;
% plot(Iihat, 'r-', 'LineWidth', 2); legend({'Actual', 'Fitted'});
% suptitle(sprintf('MSE: %.2f%%     Forecast MSE: %.2f%% \n', err*100, err_f*100));

