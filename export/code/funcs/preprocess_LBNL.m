% NOTE: LBNL dataset starts at timestamp 1443657600 (Wednesday 30th September 2015 05:00:00 PM Berkeley time)
% and ends at timestamp 1444657599.991666666 (Monday 12th October 2015 06:46:39 AM)

function [Vr, Vi, Ir, Ii, temp] = preprocess_LBNL(interval)

Dir = '~/Desktop/others-papers/PowerGrid/data/LBNL/';

load([Dir 'bank120.mat']);
% skip 7 hours: we want from start of 1 Oct to end of 11 Oct
good = 3600 * 7 + 1 : 3600 * 7 + 86400 * 11;
meanreduce = @(X, d) mean(reshape(X, [d length(X)/d]), 1);
Ir = meanreduce(I_real(good)', interval); clear('I_real');
Ii = meanreduce(I_imag(good)', interval); clear('I_imag');
Vr = meanreduce(V_real(good)', interval) / 100; clear('V_real');
Vi = meanreduce(V_imag(good)', interval) / 100; clear('V_imag');
time_1oct = 1443657600;
datatimes = time_1oct : time_1oct + 86400 * 11 - 1;
temp = meanreduce(load_temp_wu_lbnl(datatimes), interval);
save_fname = sprintf('bank%dp.mat', 120*interval);
save([Dir save_fname], 'Vr','Vi','Ir','Ii','temp');
% load([Dir save_fname]);
end
