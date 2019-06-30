function [param, Irhat, Iihat] = windowed_big(Ir, Ii, Vr, Vi, width)

n = length(Ir);
param = nan(4, n);
for i=1:n
    idx = i-width/2 : i+width/2;
    idx = idx(idx >= 1 & idx <= n);
    [b, ~, ~] = BIGFitSegment(Vr(idx), Vi(idx), Ir(idx), Ii(idx));
    param(:, i) = b;
end
[Irhat, Iihat] = BIGPredict(Vr, Vi, param);

end