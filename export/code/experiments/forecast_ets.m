function [Ir_fc, Ii_fc] = forecast_ets(Ir, Ii, pred_len, alpha, beta, gamma, phi, m)
Ir_fc = forecast_ets_single(Ir, pred_len, alpha, beta, gamma, phi, m);
Ii_fc = forecast_ets_single(Ii, pred_len, alpha, beta, gamma, phi, m);