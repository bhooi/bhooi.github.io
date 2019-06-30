function [dTeIdr, dTeIqs, dTeIds, dTeIqr]=derivative_Te(Idr,Iqs,Ids,Iqr,omega_e_base,Lm,poles,Damping_factor,k)
% k is an arbritary constant and is a function of synchrounous speed
% (omega_b) and mutual inductance between the stator and rotor coil (Lm)
% Te=(1.5*poles*Lm/2)*(Idr*Iqs-Ids*Iqr)
dTeIds=-k*Iqr;
dTeIqs=k*Idr;
dTeIdr=k*Iqs;
dTeIqr=-k*Ids;
end
