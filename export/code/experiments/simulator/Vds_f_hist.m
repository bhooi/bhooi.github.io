function [Vds_hist,dVds_f_omega_r,dVds_f_Ids] = Vds_f_hist(Lm,Ids,omega_r,Damping_factor)
% Calculates the history elements of first function  Vds_f i.e.
% (-omega_r*Lm*Ids)
dVds_f_omega_r=Damping_factor*Lm*Ids;
dVds_f_Ids=Damping_factor*Lm*omega_r;
Vds_hist=(omega_r*Lm*Ids)-(omega_r*dVds_f_omega_r)-(Ids*dVds_f_Ids);
end