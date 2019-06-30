function [Vr, Vi, Ir, Ii, temp, timestamp] = preprocess_CMU(Dataname, Datacode)

Dir = '../data/CMU_data/';
load([Dir Dataname]);

Data_time_name = sprintf('%s_dates.mat', Datacode);
load([Dir Data_time_name]); % timestamp
start_pt = 13;
end_pt = start_pt - 1 + floor((length(timestamp) - start_pt + 1) / 24) * 24;
Vr = V_real(start_pt:end_pt)';
Ir = I_real(start_pt:end_pt)';
Vi = V_imag(start_pt:end_pt)';
Ii = I_imag(start_pt:end_pt)';
timestamp = timestamp(start_pt:end_pt)';
n = length(Ir);

[temp, ~] = load_temp_data(n);
% temp = load_temp_wu('KPAPITTS56_2016-07-28_2016-08-25.csv', [], timestamp);


