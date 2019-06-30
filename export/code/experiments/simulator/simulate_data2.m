function [Ir_final, Ii_final] = simulate_data2(V, show_display)


% Choose the maximum resistance during the day
R = 50; % In ohms
I_noise_factor = .2;
% Choose the maximum capacitance/inductance during the data
% Xl = 2*pi*f*L
% Xc = 1/(2*pi*f*C)
% X = Xl - Xc
% Choose positive value for inductive and negative for capacitive
X = 2;
t = 1:length(V);
% Choose a voltage (Constant - Change V later)
% Add NOISE to system voltage here . Choose 460 for the motor
%% 
Vrating = V;
V = V * 100;
Vr = V;
Vi = zeros(size(V));
Vrated=Vrating/sqrt(3); %Single Phase Voltage
Vmotor=Vrated*sqrt(2); % Voltage

% Some motor calculation goes here
% Choose a vector of Tload here for the motor
T = 10.*ones(length(t),1);
Vinput = V;

% Find the motor currents here
Ir_motor = nan(1,length(t)); 
Ii_motor = nan(1,length(t));
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

G = Gmax * abs(sin(2*pi*t/48));
B = Bmax * abs(sin(2*pi*t/48));
% Let's also some add some constanc current alpha_r (We can probably add
% some variation to this later even
alphaR = 15;
alphaI = -10;
% Calculate noiseless Ir and Ii
Ir = G.*V + alphaR;
Ii = B.*V + alphaI;
% Add some noise to the currents (Decrease the noise if required)
Ir_noise = I_noise_factor * wgn(length(Ir),1,0);
Ii_noise = I_noise_factor * wgn(length(Ii),1,0);

Ir_final = (Ir+Ir_noise'+Ir_motor_net);
Ii_final = (Ii+Ii_noise'+Ii_motor_net);

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

