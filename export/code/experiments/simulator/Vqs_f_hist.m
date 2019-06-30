function [Vqs_hist,dVqs_f_omega_r,dVqs_f_Iqs] = Vqs_f_hist(Lm,Iqs,omega_r,Damping_factor)
% Calculates the history elements of first function  Vqs_f i.e.
% (-omega_r*Lm*Iqs)
dVqs_f_omega_r=Damping_factor*Lm*Iqs;
dVqs_f_Iqs=Damping_factor*Lm*omega_r;
Vqs_hist=(omega_r*Lm*Iqs)-(omega_r*dVqs_f_omega_r)-(Iqs*dVqs_f_Iqs);
end

