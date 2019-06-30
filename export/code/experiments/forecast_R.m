function [Ir_fc, Ii_fc] = forecast_R(Ir, Ii, method, pred_len)

dlmwrite('../temp/X_in.txt',Ir');
cmd = sprintf('/usr/local/bin/R CMD BATCH "--args %d" %s.R ../temp/%s.out', pred_len, method, method);
system(cmd);
Ir_fc = dlmread('../temp/X_out.txt')';

dlmwrite('../temp/X_in.txt',Ii');
cmd = sprintf('/usr/local/bin/R CMD BATCH "--args %d" %s.R ../temp/%s.out', pred_len, method, method);
system(cmd);
Ii_fc = dlmread('../temp/X_out.txt')';

assert(length(Ir_fc) == pred_len);
delete ../temp/*.txt