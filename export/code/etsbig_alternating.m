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

function [theta, b, s, param, Irhat, Iihat, err, err_f, tempcoef] = etsbig_alternating(Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef, niters)

err = nan(niters, 1);
err_f = nan(niters, 1);
for iter=1:niters
%     fprintf('======== ITER %d\n', iter);
    [theta, b, s, param, Irhat, Iihat, err(iter), err_f(iter)] = etsbig('BIG', Ir, Ii, Vr, Vi, temp, m, alpha, beta, gamma, phi, lambda, lambda2, tempcoef);
%     fprintf('err=%.5f, err_f=%.5f\n', err(iter), err_f(iter));
    tempcoef = fit_temp_coef(Ir, Ii, Vr, Vi, temp, theta, s, tempcoef);
%     fprintf('tempcoef='); fprintf('%.3f ', tempcoef); fprintf('\n');
    if (iter > 1) && (err_f(iter) > err_f(iter-1)*.999)
%         fprintf('converged, stopping\n');
        break
    end
%     param = theta + s + tempcoef(1:4)' * max(0,temp-tempcoef(5));
end
err = err(iter);
err_f = err_f(iter);
end
