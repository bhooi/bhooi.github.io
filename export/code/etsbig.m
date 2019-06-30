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
% X * param = y, where X and y are as below, and param = [G; B; alpha_R; alpha_I]


function [theta, b, s, param, Irhat, Iihat, tot_err, tot_err_f] = etsbig(model, Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef)

magn = max(Vr.^2 + Vi.^2 + 1);
p = 4;
n = length(Ir);
d = 4*(m+2)+1;
theta = zeros(d, p, m+n);
b = zeros(d, p, m+n);
s = zeros(d, p, m+n);
dummy = [zeros(d-1, 1); 1];

temp = max(0, temp - tempcoef(end));

% initialization
for i=1:p
    for j=1:m
        s((j-1)*p + i, i, j) = 1;
    end
    theta(p*m + i, i, m) = 1;
    if i <= 0 % only add trend terms for G and B
        b(p*(m+1) + i, i, m) = 1;
    end
end

all_err = nan(d, 2*n); % squared errors
all_err_f = nan(d, 2*n); % squared forecast errors
for t = m+1 : m+n
    if strcmp(model, 'BIG')
        Xt = [Vr(t-m) -Vi(t-m) 1 0; Vi(t-m) Vr(t-m) 0 1];
    elseif strcmp(model,'PQ')
        Vn = sqrt(Vr(t-m).^2 + Vi(t-m).^2);
        Xt = [Vr(t-m)/Vn^2 Vi(t-m)/Vn^2 0 0; Vi(t-m)/Vn^2 -Vr(t-m)/Vn^2 0 0];
    end
    yt = [Ir(t-m); Ii(t-m)] - temp(t-m) * Xt * tempcoef(1:p)';
    err_f = yt * dummy' - Xt * (theta(:, :, t-1) + phi * b(:, :, t-1) + s(:, :, t-m))';
    grad = -err_f' * Xt;
    theta(:, :, t) = theta(:, :, t-1) + phi * b(:, :, t-1) - alpha * grad / magn;
    b(:, :, t) = beta * (theta(:, :, t) - theta(:, :, t-1)) + phi * (1 - beta) * b(:, :, t-1);
    s(:, :, t) = s(:, :, t-m) - gamma * grad / magn;
    err = yt * dummy' - Xt * (theta(:, :, t) + s(:, :, t))';
    all_err(:, (t-m-1)*2+1 : (t-m)*2) = err';
    all_err_f(:, (t-m-1)*2+1 : (t-m)*2) = err_f';
end
theta(:, :, 1:m) = [];
b(:, :, 1:m) = [];
s(:, :, 1:m) = [];

seas_ridge = zeros(d, p*(m-1));
seas_ridge(1:p*m, :) = kron([eye(m-1); zeros(1,m-1)] - [zeros(1,m-1); eye(m-1)], eye(p));
ridge_err = [all_err lambda * seas_ridge lambda2 * eye(d)];

init_param = [ridge_err(1:d-1, :)' \ -ridge_err(d,:)'; 1];
theta = reshape(init_param' * reshape(theta, [d p*n]), [p n]);
b = reshape(init_param' * reshape(b, [d p*n]), p, n);
s = reshape(init_param' * reshape(s, [d p*n]), p, n);

param = theta + s + tempcoef(1:p)' * temp;
if strcmp(model, 'BIG')
    [Irhat, Iihat] = BIGPredict(Vr, Vi, param);
elseif strcmp(model, 'PQ')
    [Irhat, Iihat] = PQPredict(Vr, Vi, param);
end
    
tot_err = sqrt(mean((all_err' * init_param).^2)) / sqrt(mean(([Ir Ii]).^2));
tot_err_f = sqrt(mean((all_err_f' * init_param).^2)) / sqrt(mean(([Ir Ii]).^2));

% tot_err = sum((all_err' * init_param).^2);
% tot_err_f = sum((all_err_f' * init_param).^2);


end
