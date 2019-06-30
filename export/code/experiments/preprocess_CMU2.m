function [Vr, Vi, Ir, Ii, temp, timestamp] = preprocess_CMU2(Dataname, Datacode)

Dir = '../data/CMU_data/';
tempfname1 = 'KPAPITTS56_2017-04-28_2017-07-24.csv';
tempfname2 = 'KPAPITTS52_2017-04-28_2017-07-24.csv';

load([Dir Dataname]);

Data_time_name = sprintf('%s_dates.mat', Datacode);
load([Dir Data_time_name]); % timestamp
n = length(I_real);
start_pt = 10;
end_pt = start_pt - 1 + floor((n - start_pt + 1) / 24) * 24;
Vr = V_real(start_pt:end_pt)';
Ir = I_real(start_pt:end_pt)';
Vi = V_imag(start_pt:end_pt)';
Ii = I_imag(start_pt:end_pt)';
% temp = load_temp_wu(tempfname1, tempfname2, timestamp);
% save([Dir sprintf('temp/%s_temp.mat', Datacode)], 'temp');
load([Dir sprintf('temp/%s_temp.mat', Datacode)]);
temp = temp(start_pt:end_pt);
timestamp = timestamp(start_pt:end_pt)';

