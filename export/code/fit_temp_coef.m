function tempcoef = fit_temp_coef(Ir, Ii, Vr, Vi, temp, theta, s, tempcoef)

n = length(Ir);

sy = nan(2*n, 1);
sXl = nan(4, 2*n);

for t = 1:n
    Xt = [Vr(t) -Vi(t) 1 0; Vi(t) Vr(t) 0 1];
    yt = [Ir(t); Ii(t)];
    rt = yt - Xt * (theta(:,t) + s(:,t));
    cur_idx = (t-1)*2 + (1:2);
    sy(cur_idx) = rt;
    sXl(:, cur_idx) = Xt';
end
sXl = sXl';
[objval, sX] = compute_obj(sy, sXl, temp, tempcoef);
% fprintf('obj = %.3f\n', objval);
tempcoef(1:4) = sX \ sy;
% fprintf('adjust weights: obj = %.3f\n', compute_obj(sy, sXl, temp, tempcoef));

% optimize over threshold

[~,sort_idx] = sort(temp, 'descend');
cand = unique(temp);

wt = nan(n,1);
sT = nan(n,1);
for t = 1:n
    Xt = [Vr(t) -Vi(t) 1 0; Vi(t) Vr(t) 0 1];
%     rt = sy((t-1)*2 + (1:2));
    yt = [Ir(t); Ii(t)];
    rt = yt - Xt * (theta(:,t) + s(:,t));
    w = tempcoef(1:4)';
    wt(t) = w' * Xt' * Xt * w;
    sT(t) = wt(t) * temp(t) - rt' * Xt * w;
end


for i = 1:n-1
    if temp(sort_idx(i)) ~= temp(sort_idx(i+1))
        good = sort_idx(1:i);
        T0 = sum(sT(good)) / sum(wt(good));
        if T0 < temp(sort_idx(i)) && T0 > temp(sort_idx(i+1))
            fprintf('at index %d: found T0 = %.3f\n', i, T0);
            cand = [cand T0];
        end
    end
end

% gradt=[];
% for t=1:n
%     Xt = [Vr(t) -Vi(t) 1 0; Vi(t) Vr(t) 0 1];
% %     rt = sy((t-1)*2 + (1:2));
%     yt = [Ir(t); Ii(t)];
%     rt = yt - Xt * (theta(:,t) + s(:,t));
%     w = tempcoef(1:4)';
%     gradt(t) = (rt - Xt * (temp(t)-cc) * w)' * Xt * w;
% end

obj = arrayfun(@(x)compute_obj(sy, sXl, temp, [tempcoef(1:4) x]), cand);
[best_obj, best_idx] = min(obj);
fprintf('adjusting threshold to %.3f: obj = %.3f\n', cand(best_idx), best_obj);
tempcoef(5) = cand(best_idx);

end