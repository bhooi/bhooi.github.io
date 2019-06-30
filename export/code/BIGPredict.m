% Linear system based on BIG model:
% Ir = GVr - BVi + alpha_r
% Ii = BVr + GVi + alpha_i
% param = [G; B; alpha_R; alpha_I]

function [Ir, Ii] = BIGPredict(Vr, Vi, param)
Ir = param(1,:) .* Vr - param(2,:) .* Vi + param(3,:);
Ii = param(2,:) .* Vr + param(1,:) .* Vi + param(4,:);
end