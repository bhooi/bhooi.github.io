function [b, Irhat, Iihat, BIC_cost] = PQFitSegment(Vr, Vi, Ir, Ii, N, bic_param)

n = length(Vr);
Vn = sqrt(Vr.^2 + Vi.^2);
X = [Vr./Vn.^2 Vi./Vn.^2; Vi./Vn.^2 -Vr./Vn.^2];
y = [Ir; Ii];
b = X \ y;
yhat = X * b;
Irhat = yhat(1:n); 
Iihat = yhat(n+1:end);
error = y - yhat;
BIC_cost = BIC(error, length(b), N, bic_param);