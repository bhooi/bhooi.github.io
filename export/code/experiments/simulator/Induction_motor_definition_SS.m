
%% The motor is divided into five sub-circuits.  

% The five state variable of interest in a n induction motor are:
% i) Ids -> Variable 1
% ii)Iqs -> Variable 2
% iii) Idr -> Variable 3
% iv) Iqr -> Variable 4
% v) omega_r -> Variable 5

% Primer on the element type
% i)        1 - Voltage Source
% ii)       2 -   Resistances/Conductances
% iii)      3/5 - Capacitor [ In transient companion model 3-Voltage Source | 5-Resistance]
% iv)       4/6 - Inductor  [ In transient companion model 4-Current Source | 6-Resistance]
% v)        7 - Current Source
% vi)       11- Dependent Voltage Sources
% vi)       22- Short Circuit

% The mutual coupling elements are a function of one the five, which is
% defined by the circuit description below

% Defining Gnd first
Gnd=0;

%----------Circuit 1 -------------
%%
% |***In the steady state the derivative inductor terms are converted into short-circuit***|
% d-axis stator circuit
% Vds = Rs.Ids + 0 + 0 - omega_e.Ls.Iqs - omega_e.Lm.Iqr ***
% Circuit topology of the d-axis stator circuit
% [Id | Node_From |  Node_To | Independent/Dependent | Magnitude | Element Type | Dependent Element]
Ckt_ds=   [1    1   2   0   Rs                  2   0; 
           2    2   3   0   Ls                  22  0;  % ***
           3    3   4   1   Lm                  22  0;  % *** The element is dependent of the Idr current
           4    4   5   1   -(omega_e_base*Ls)  11  2;  % The element is dependent of the Iqs current
           5    5   Gnd 1   -(omega_e_base*Lm)  11  4]; % The element is dependent of the Iqr current
% Number of nodes in d-axis stator circuit excluding common ground node
num_nodes_Ckt_ds=max(max(Ckt_ds(:,2:3)));

%----------Circuit 2 -------------
%%
% |***In the steady state the derivative inductor terms are converted into short-circuit***|
% q-axis stator circuit
% Vqs = Rs.Iqs + 0 + 0 + omega_e.Ls.Ids + omega_e.Lm.Idr ***
% Circuit topology of the q-axis stator circuit
% [Id | Node_From |  Node_To | Independent/Dependent | Magnitude | Element Type | Dependent Element]
n=num_nodes_Ckt_ds;
Ckt_qs=   [1    1+n   2+n   0   Rs                  2   0; 
           2    2+n   3+n   0   Ls                  22  0;   % ***
           3    3+n   4+n	1   Lm                  22  0;   % *** The element is dependent of the Iqr current
           4    4+n   5+n   1   (omega_e_base*Ls)   11  1;   % The element is dependent of the Ids current
           5    5+n   Gnd   1   (omega_e_base*Lm)   11  3];  % The element is dependent of the Idr current]; 
num_nodes_Ckt_qs=max(max(Ckt_qs(:,2:3)-n));
       
%----------Circuit 3 -------------  
% |***In the steady state the derivative inductor terms are converted into short-circuit***|
% d-axis rotor circuit
% 0 = Rr.Idr + 0 + 0 + omega_r.Lr.Iqr + omega_r.Lm.Iqs - omega_e.Lr.Iqr - omega_e.Lm.Iqs ***
% Circuit topology of the q-axis stator circuit
% [Id | Node_From |  Node_To | Independent/Dependent | Magnitude | Element Type | Dependent Element]
n=n+num_nodes_Ckt_qs;
[Vqs_hist,dVqs_f_omega_r,dVqs_f_Iqs] = Vqs_f_hist(Lm,Iqs,omega_r,1);
[Vqr_hist,dVqr_f_omega_r,dVqr_f_Iqr]=Vqr_f_hist(Lr,Iqr,omega_r,1);
Ckt_dr=   [1    1+n   2+n   0   Rr                                2    0; 
           2    2+n   3+n   0   Lr                                22   0; % ***
           3    3+n   4+n   1   Lm                                22   0; % *** This function is dependent on Ids current
           4    4+n   5+n   0   Vqs_hist                          1    0; % This element is a pseudo voltage source which consists of history terms for the speed voltage term 
           5    5+n   6+n   1   dVqs_f_omega_r                    11   5; % This element is a function of omega_r
           6    6+n   7+n   1   dVqs_f_Iqs-(omega_e_base*Lm)      11   2; % This element is a function of Iqs
           7    7+n   8+n   0   Vqr_hist                          1    0; % This element is a pseudo voltage source which consists of history terms for the speed voltage term
           8    8+n   9+n   1   dVqr_f_omega_r                    11   5; % The element is a function of omega_r
           9    9+n   Gnd   1   dVqr_f_Iqr-(omega_e_base*Lr)      11   4; % The element is a function of Iqr
           10   Gnd   1+n   0   0                                 22   0];% The element is short circuited
num_nodes_Ckt_dr=max(max(Ckt_dr(:,2:3)-n)); 
% ------- There are two elements to check for tolerences here-------------


%----------Circuit 4 ------------- 
% |***In the steady state the derivative inductor terms are converted into short-circuit***|
% q-axis rotor circuit
% 0 = Rr.Iqr + 0 + 0 - omega_r.Lr.Idr - omega_r.Lm.Ids + omega_e.Lr.Idr + omega_e.Lm.Ids *** 
% Circuit topology of the q-axis stator circuit
% [Id | Node_From |  Node_To | Independent/Dependent | Magnitude | Element Type | Dependent Element]
n=n+num_nodes_Ckt_dr;
[Vds_hist,dVds_f_omega_r,dVds_f_Ids]=Vds_f_hist(Lm,Ids,omega_r,1);
[Vdr_hist,dVdr_f_omega_r,dVdr_f_Idr]=Vdr_f_hist(Lr,Idr,omega_r,1);
Ckt_qr=   [1    1+n   2+n   0   Rr                                2    0; 
           2    2+n   3+n   0   Lr                                22   0;
           3    3+n   4+n   1   Lm                                22   0; % The element is dependent on the current Iqs
           4    4+n   5+n   0   -Vds_hist                         1    0; % This element is a pseudo voltage source which consists of history terms for the speed voltage term
           5    5+n   6+n   1   -dVds_f_omega_r                   11   5; % This function is dependent on the speed omega_r
           6    6+n   7+n   1   (omega_e_base*Lm)-dVds_f_Ids      11   1; % The element is dependent on the current Ids]
           7    7+n   8+n   0   -Vdr_hist                         1    0; % This element is a pseudo voltage source which consists of history terms for the speed voltage term
           8    8+n   9+n   1   -dVdr_f_omega_r                   11   5; % The function is dependent on the rotor speed omega_r
           9    9+n   Gnd   1   (omega_e_base*Lr)-dVdr_f_Idr      11   3; % This function is dependent on rotor current Idr
           10   Gnd   1+n   0   0                                 22   0];% The element is short circuited
num_nodes_Ckt_qr=max(max(Ckt_qr(:,2:3)-n));          
       
%----------Circuit 5 ------------- 
% |***In the steady state the derivative capacitor terms are converted into open-circuit***|
% Mechanical Circuit     
% Cj.p(omega_r)=Te_p-Te_n-Tl
% Te_p(k+1)= Te_p(k)
% Circuit topology of the q-axis stator circuit
% [Id | Node_From |  Node_To | Independent/Dependent | Magnitude | Element Type | Dependent Element]
k=(3/4)*Lm*poles*1;
[dTeIdr, dTeIqs, dTeIds, dTeIqr]=derivative_Te(Idr,Iqs,Ids,Iqr,omega_e_base,Lm,poles,1,k);
Te_hist_val=Te_hist(Idr,Iqr,Ids,Iqs,dTeIdr,dTeIds,dTeIqr,dTeIqs,omega_e_base,Lm,0,poles);
Te_old=k*(Idr*Iqs-Iqr*Ids);
n=n+num_nodes_Ckt_qr;
Ckt_mech= [1    1+n   Gnd    0    (Cj)                       33  0; % *** Converted into open circuit
           2    Gnd   1+n    0    (Te_old+Te_hist_val-Tl)    7   0;
           3    Gnd   1+n    1    (dTeIds)                   7   1;
           4    Gnd   1+n    1    (dTeIqs)                   7   2;
           5    Gnd   1+n    1    (dTeIdr)                   7   3;
           6    Gnd   1+n    1    (dTeIqr)                   7   4;
           7    Gnd   1+n    0    (D^-1)                     2   0]; % The current direction is negative in this case
num_nodes_Ckt_mech=max(max(Ckt_mech(:,2:3)-n));          
clear n;

%----------Voltage Source for the motor ***
if(strcmp(option,'transient'))
[Vd,Vq,Vo]=abc2qd(Vbase, theta, t, omega_e_base);
else
[Vd,Vq,Vo]=abc2qd_ss(Vbase, theta,omega_e_base);  
end

Ckt_Vs= [1    1   Gnd    0    Vd	1   0;
         2    6   Gnd    0    Vq	1   0];

% Total Circuit 
IM_Ckt=[Ckt_ds;Ckt_qs;Ckt_dr;Ckt_qr;Ckt_mech;Ckt_Vs];

% Calculating number of elements
num_V=numel(find(IM_Ckt(:,6)==1));
num_R=numel(find(IM_Ckt(:,6)==2));
num_C=numel(find(IM_Ckt(:,6)==3));
num_L=numel(find(IM_Ckt(:,6)==4));
num_I=numel(find(IM_Ckt(:,6)==7));
num_R_dependent=numel(find(IM_Ckt(:,6)==11));
num_SC=numel(find(IM_Ckt(:,6)==22));
num_ML=numel(find(IM_Ckt(:,6)==44));
num_elements=[num_V num_R num_C num_L num_I num_R_dependent num_SC num_ML];
       
% Calculating the total number of nodes.
num_nodes=num_nodes_Ckt_ds+num_nodes_Ckt_qs+num_nodes_Ckt_dr+num_nodes_Ckt_qr+num_nodes_Ckt_mech+1; % Add nodes for capacitances and mutual inductances

% Making the ground node as the last node
gnd_elements_node_from=find(IM_Ckt(:,2)==0);
gnd_elements_node_to=find(IM_Ckt(:,3)==0);
IM_Ckt(gnd_elements_node_from,2)=num_nodes;
IM_Ckt(gnd_elements_node_to,3)=num_nodes;