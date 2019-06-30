% m = period size
% alpha, beta, gamma are smoothing parameters for theta, b, s resp.
% phi is damping parameter for additive trend
% lambda is ridge penalty for initial seasonal pattern
% theta = level estimate for [B, G, alpha_R, alpha_I]
% b = trend estimate
% s = seasonal estimate 
%
% we use smoothed SGD to minimize f(x,y,theta,s) = 1/2(y-x^T(theta+s))^2
%
% Linear system based on BIG model:
% Ir = GVr - BVi + alpha_r
% Ii = BVr + GVi + alpha_i
% in matrix form: 
% X * b = y, where X and y are as below, and b = [G; B; alpha_R; alpha_I]

function [theta, b, s, param, Irhat, Iihat, tot_err, tot_err_f, tempcoef] = etsbig_outer(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, niters, n_init)

magn = max(Vr.^2 + Vi.^2 + 1);
p = 4;
n = length(Ir);
n_init = min(n_init, n);
theta = nan(p, n);
b = nan(p, n);
s = nan(p, n);
[theta(:,1:n_init), b(:,1:n_init), s(:,1:n_init), ~, ~, ~, ~, ~, tempcoef] = ...
    etsbig_alternating(Ir(1:n_init), Ii(1:n_init), Vr(1:n_init), Vi(1:n_init), ...
    temp(1:n_init), m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, niters);

temp_adj = max(0, temp - tempcoef(5));

inv_idx = reshape(reshape(1:2*n, [n 2])', [1 2*n]);
Xall = [Vr' -Vi' ones(n,1) zeros(n,1); Vi' Vr' zeros(n,1) ones(n,1)]';
Xall = Xall(:, inv_idx);
tc = tempcoef(1:p)';
all_err_f = nan(1, 2*n);
for t = n_init+1 : n
    cur_idx = (t-1)*2 + (1:2);
    Xtp = Xall(:, cur_idx);
    Xt = Xtp';
    yt = [Ir(t); Ii(t)] - temp_adj(t) * (Xt(:,1) * tc(1) + Xt(:,2) * tc(2) + Xt(:,3) * tc(3) + Xt(:,4) * tc(4));
    cparam = (theta(:,t-1) + phi * b(:, t-1) + s(:, t-m));
    err_f = yt - (Xt(:,1) * cparam(1) + Xt(:,2) * cparam(2) + Xt(:,3) * cparam(3) + Xt(:,4) * cparam(4)); % Xt * cparam
    all_err_f(cur_idx) = err_f;
    grad = -Xtp(:,1) * err_f(1) - Xtp(:,2) * err_f(2);
    theta(:,t) = theta(:,t-1) + phi * b(:, t-1) - alpha * grad / magn;
    b(:,t) = beta * (theta(:,t) - theta(:,t-1)) + phi * (1-beta) * b(:, t-1);
    s(:,t) = s(:,t-m) - gamma * grad / magn;
end

all_err_f(1:n_init) = [];
param = theta + s;
param = param + tempcoef(1:4)' * temp_adj;
[Irhat, Iihat] = BIGPredict(Vr, Vi, param);
tot_err = sqrt(mean(([Irhat Iihat] - [Ir Ii]).^2)) / sqrt(mean(([Ir Ii]).^2));
tot_err_f = sqrt(mean(all_err_f.^2)) / sqrt(mean(([Ir Ii]).^2));

end