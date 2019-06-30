function [Ir_fc, Ii_fc] = forecast_PowerCast(Ir, Ii, Vr, Vi, Vr_fc, Vi_fc, t_d, data_name)

Vr = Vr'; Vi = Vi'; Ir = Ir'; Ii = Ii'; Vr_fc = Vr_fc'; Vi_fc = Vi_fc';
n_ds = 1;
sigma = 0.5;
window_size = 5;
% rank
r = 2;
% AR(p)
ar_window = 1;
t_tot = length(Vr);
n_d = t_tot/t_d; % hourly basis
data_proc_method = 1;
n_d_pred = 1;

myTensor = construct_tensor(Vr,Ir,Vi,Ii,n_d,t_d,data_proc_method,window_size,sigma, data_name);

    X = tensor(myTensor);
    M = parafac_als(X, r);

[Ir2, Ii2, ~] = myforecast_fn('tensor_AR', M, ar_window, n_d_pred, n_d, [Vr; Vr_fc], [Vi; Vi_fc], data_name);
Ir_fc = Ir2(length(Vr)+1:end)';
Ii_fc = Ii2(length(Vr)+1:end)';