function param = fit_PowerCast(Ir, Ii, Vr, Vi, t_d, data_name)

Vr = Vr'; Vi = Vi'; Ir = Ir'; Ii = Ii';
n_ds = 1;
sigma = .5;
window_size = 5;
% rank
r = 2;
% AR(p)
ar_window = 1;
t_tot = length(Vr);
n_d = t_tot/t_d; % hourly basis
data_proc_method = 1;
n_d_pred = 1;

% myTensor = construct_tensor(Vr,Ir,Vi,Ii,n_d,t_d,data_proc_method,window_size,sigma, data_name);

[fit_G, fit_B, fit_alpha_r, fit_alpha_i] = construct_tensor_tmp(Vr,Ir,Vi,Ii,window_size,sigma, data_name);

param = [fit_G fit_B fit_alpha_r fit_alpha_i]';
