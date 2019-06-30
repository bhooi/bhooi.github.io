function [Vdr_hist,dVdr_f_omega_r,dVdr_f_Idr] = Vdr_f_hist(Lr,Idr,omega_r,Damping_factor)
% Calculates the history elements of first function  Vdr_f i.e.
% f(x)=omega_r*Lr*Idr
dVdr_f_omega_r=Damping_factor*Lr*Idr;
dVdr_f_Idr=Damping_factor*Lr*omega_r;
Vdr_hist=(omega_r*Lr*Idr)-(omega_r*dVdr_f_omega_r)-(Idr*dVdr_f_Idr);
end