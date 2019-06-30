cd ~/Desktop/bryan-papers/etsbig/code
clearvars; close all; clc; warning off;
addpath util

Datacode = 'int3';
Dataname = 'int3_data.mat';
[V, ~, ~, ~, ~, ~] = preprocess_CMU(Dataname, Datacode);
V = V' * 100;
t = 1:length(V);
show_display = true;


% Choose the maximum resistance during the day
R = 50; % In ohms
% Choose the maximum capacitance/inductance during the data
% Xl = 2*pi*f*L
% Xc = 1/(2*pi*f*C)
% X = Xl - Xc
% Choose positive value for inductive and negative for capacitive
X = 2;
% Choose a voltage (Constant - Change V later)
% V = 0 * V + 460; % Three-phase motor voltage rating
%%
% Add NOISE to system voltage here . Choose 460 for the motor
%% 
Vrating = V;
Vrated=Vrating/sqrt(3); %Single Phase Voltage
Vmotor=Vrated*sqrt(2); % Voltage

% Some motor calculation goes here
% Choose a vector of Tload here for the motor
T = 10.*ones(length(t),1);
Vinput = V.*ones(length(t),1);

% Find the motor currents here
Ir_motor = []; Ii_motor = [];
for i = 1: length(t)
    [Ir_motor(i), Ii_motor(i)] = InductionMotorCurrent(Vinput(i), T(i));
end

%%

% Multiply the motor currents with what believe is the true number of
% motors in the system

numMotors = 10;
Ir_motor_net = numMotors.*Ir_motor;
Ii_motor_net = numMotors.*Ii_motor;

% calculate maximum G and B for the system
Gmax = R/(R^2 + X^2);
Bmax = -X/(R^2 + X^2);
% Create time varying G and B % We can make changes here to make accurate G
% and B
G = Gmax*abs(sin(2*pi*1.1574e-5*t));
B = Bmax*abs(sin(2*pi*1.1574e-5*t));
% Lets make sure G and B have a min value value thats not 0
G = max(G,0.2*Gmax);
B = sign(B).*max(abs(B),0.2*abs(Bmax));
% Let's also some add some constanc current alpha_r (We can probably add
% some variation to this later even
alphaR = 15;
alphaI = -10;
% Calculate noiseless Ir and Ii
Ir = G*V;
Ii = B*V;
% Add some noise to the currents (Decrease the noise if required)
Ir_noise = wgn(length(Ir),1,0);
Ii_noise = wgn(length(Ii),1,0);

Ir_final = Ir+Ir_noise'+Ir_motor_net;
Ii_final = Ii+Ii_noise'+Ii_motor_net;

%%

if show_display
    series = {V, Ir_final, Ii_final};
    nseries = length(series);
    seriesnames = {'V_R [V]', 'I_R [A]', 'I_I [A]'};
    figure;
    for i=1:nseries
        subplot(nseries,1,i);
        plot(series{i}); ylabel(seriesnames{i});
    end
    xlabel('Hours');
end

