function [Vqr_hist,dVqr_f_omega_r,dVqr_f_Iqr] = Vqr_f_hist(Lr,Iqr,omega_r,Damping_factor)
% Calculates the history elements of first function  Vqr_f i.e.
% (-omega_r*Lr*Iqr)
dVqr_f_omega_r=Damping_factor*Lr*Iqr;
dVqr_f_Iqr=Damping_factor*Lr*omega_r;
Vqr_hist=(omega_r*Lr*Iqr)-(omega_r*dVqr_f_omega_r)-(Iqr*dVqr_f_Iqr);
end