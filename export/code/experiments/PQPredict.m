% Linear system based on PQ model:
% Ir = (P*Vr + Q*Vi)/|V|2
% Ii = (P*Vi - Q*Vr)/|V|2
% param = [P;Q]

function [Ir, Ii] = PQPredict(Vr, Vi, param)

Vn = sqrt(Vr.^2 + Vi.^2);
Ir = (param(1,:) .* Vr + param(2,:) .* Vi) ./ Vn.^2;
Ii = (param(1,:) .* Vi - param(2,:) .* Vr) ./ Vn.^2;

end