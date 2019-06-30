function [x_fc] = forecast_ets_single(x, pred_len, alpha, beta, gamma, phi, m)

n = length(x);
theta = nan(1, m+n);
b = nan(1, m+n);
s = nan(1, m+n);

xm = conv(x, ones(1,m)/m, 'same');
xmm = conv(xm, ones(1,2)/2, 'same');
x_detrend = x(m+1 : 3*m) - xmm(m+1 : 3*m);
x_ave = mean(reshape(x_detrend, [m 2]), 2);

theta(m) = x(1) - x_ave(1);
b(m) = 0;
s(1:m) = x_ave;

for t = m+1 : m+n
    resid = x(t-m) - (theta(t-1) + b(t-1) + s(t-m));
    theta(t) = theta(t-1) + b(t-1) + alpha * resid;
    b(t) = (1-beta) * b(t-1) + beta * (theta(t) - theta(t-1));
    s(t) = s(:,t-m) + gamma * resid;
end
theta(:, 1:m) = [];
b(:, 1:m) = [];
s(:, 1:m) = [];

% forecast
% x_fc = theta(n) + b(n) * (1:pred_len) + s(end-m+1 : end);
x_fc = theta(n) + b(n) * phi.^(1:m) + s(end-m+1 : end);
end