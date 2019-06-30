function [b, Irhat, Iihat] = BIGFitSegment(Vr, Vi, Ir, Ii)

% Linear system based on BIG model:
% Ir = GVr - BVi + alpha_r
% Ii = BVr + GVi + alpha_i
% in matrix form: 
% X * b = y, where X and y are as below, and b = [G; B; alpha_R; alpha_I]
%
n = length(Vr); % length of this segment only (N is entire data)
X = [Vr' -Vi' ones(n,1) zeros(n,1); Vi' Vr' zeros(n,1) ones(n,1)];
y = [Ir'; Ii'];
b = X \ y;
yhat = X * b;
Irhat = yhat(1:n); 
Iihat = yhat(n+1:end);