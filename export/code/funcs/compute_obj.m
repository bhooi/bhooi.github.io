function [obj, sX] = compute_obj(sy, sXl, temp, tempcoef)
Tvec = max(0, temp - tempcoef(5));
Tvecd = [Tvec; Tvec];
sX = bsxfun(@times, sXl, Tvecd(:));
obj = sum((sy - sX * tempcoef(1:4)').^2);
end