function [Vr_fc, Vi_fc, Ir_fc, Ii_fc, Irhat, Iihat] = etsbig_forecast(Ir, Ii, Vr, Vi, temp, m, pred_len, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, whatif_mod)

if length(temp) < length(Ir) + pred_len
    error('Temperature vector not long enough to cover the forecast period');
end

if isempty(whatif_mod)
    whatif_mod = [1 1 0];
end
temp = smoothts(temp, 'e', .4);

n = length(Ir);
p = 4;
n_init = m * 10; % days used for initialization
% tail_idx = max(1, n - m * 100) : n;
% [Vr_fc, Vi_fc] = forecast_R(Vr(tail_idx), Vi(tail_idx), 'ets', pred_len);

[Vr_fc, Vi_fc] = forecast_ets(Vr, Vi, pred_len, alpha, beta, gamma, phi, m);

% [theta, b, s, ~, Irhat, Iihat, ~, ~] = etsbig_alternating(Ir, Ii, Vr, Vi, temp(1:n), m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, 10);
[theta, b, s, ~, Irhat, Iihat, ~, ~, tempcoef] = etsbig_outer(Ir, Ii, Vr, Vi, temp(1:n), m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, 5, n_init);

temp(n+1:end) = temp(n+1:end) + whatif_mod(3);
% disp(tempcoef);
% disp(tempcoef(1:4)' * max(0, temp(n+1:n+m) - tempcoef(end)));

param_fc = s(:, n-m+1:end) + theta(:, end) * ones(1, m) + b(:, end) * phi.^(1:m) + ...
    tempcoef(1:4)' * max(0, temp(n+1:n+m) - tempcoef(end));
param_fc(1,:) = param_fc(1,:) * whatif_mod(1);
param_fc(2,:) = param_fc(2,:) * whatif_mod(2);

% disp(param_fc);


[Ir_fc, Ii_fc] = BIGPredict(Vr_fc, Vi_fc, param_fc);



end