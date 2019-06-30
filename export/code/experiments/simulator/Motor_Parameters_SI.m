%% Motor SI Parameters 
%---------------------------------------------------------------------------
function [Vbase,Rr,Rs,Ls,Lr,Lm,Cj,poles,fbase,omega_e_base,Tl]=Motor_Parameters_SI(Motor_Choice)

    if Motor_Choice==1

        %% Motor Model 1 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=220; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.905; % Rated power factor of the motor
        kWbase=(25*0.745)*1e3; % Motor Rating in kW
        kVAbase=3*746; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.816; % Rotor resistance of the motor (Ohms)
        Rs = 0.435; % Stator resistance of the motor (Ohms)
        Lls = 2*2.0e-3; % Stator winding leakage inductance(Henry)
        Lm = 69.31e-3; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 2e-3; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.089; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles= 4; % Number of poles

    end

    %% Motor Model 2 - SPICE Paper - Stan

    if Motor_Choice==2

        % Motor Name Plate Data
        Vrating=575; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.780; % Rated power factor of the motor
        kWbase=1.1*1e3; % Motor Rating in Watts
        kVAbase=kWbase/pf; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrating);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.03281; % Rotor resistance of the motor (Ohms)
        Rs = 0.05963; % Stator resistance of the motor (Ohms)
        Lls = 0.000633; % Stator winding leakage inductance(Henry)
        Lm = 0.02742; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 0.000633; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=1.3; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles= 4; % Number of poles

    end
    %% Motor Model 3 - Simulink 06: 150 HP 460 V 60 Hz 1785 rpm

    if Motor_Choice==3

        % Motor Name Plate Data
        Vrating=460; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        % pf=0.905; % Rated power factor of the motor
        % kWbase=1.119*1e3; % Motor Rating in Watts
        kVAbase=1.119e5; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrating);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.01721; % Rotor resistance of the motor (Ohms)
        Rs = 0.0302; % Stator resistance of the motor (Ohms)
        Lls = 0.000283; % Stator winding leakage inductance(Henry)
        Lm = 0.01905; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 0.000283; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=2; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0.3;  % Load Torque - Usually a function of speed
        poles= 4; % Number of poles

    end

    if Motor_Choice==4

        %% Motor Model 4 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=220; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.905; % Rated power factor of the motor
        kWbase=(25*0.745)*1e3; % Motor Rating in kW
        kVAbase=3*746; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=50; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.754; % Rotor resistance of the motor (Ohms)
        Rs = 1.05; % Stator resistance of the motor (Ohms)
        Lls = 3.6e-3; % Stator winding leakage inductance(Henry)
        Lm = 253e-3; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 7.3e-3; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.015; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles= 4; % Number of poles

    end

    if Motor_Choice==5

        %% Motor Model 5 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=220; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        % pf=0.905; % Rated power factor of the motor
        % kWbase=(25*0.745)*1e3; % Motor Rating in kW
        % kVAbase=3*746; % Motor rated kVA
        % Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        % Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.158*(3/2); % Rotor resistance of the motor (Ohms)
        Rs = 0.288*(3/2); % Stator resistance of the motor (Ohms)
        % Lls = 0.0425*(3/2); % Stator winding leakage inductance(Henry)
        Lm = 0.0412*(3/2); % Mutual inductance between the stator and rotor windings (Henry)
        % Llr = 7.3e-3; % Rotor winding leakage inductance(Henry)
        Ls=0.0425*(3/2); % Self Inductance of the stator
        Lr=0.0418*(3/2); % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.8; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles= 6; % Number of poles

    end

        if Motor_Choice==6

        %% Motor Model 1 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=200*sqrt(3); % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.905; % Rated power factor of the motor
        kWbase=(25*0.745)*1e3; % Motor Rating in kW
        kVAbase=3*746; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=50; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 6.085; % Rotor resistance of the motor (Ohms)
        Rs = 6.03; % Stator resistance of the motor (Ohms)
        Lls = 39.3e-3; % Stator winding leakage inductance(Henry)
        Lm = 450e-3; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 39.3e-3; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.00488; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles= 4; % Number of poles

    end

    if Motor_Choice==7

        %% Motor Model 7 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=460; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.905; % Rated power factor of the motor
        kWbase=(25*0.745)*1e3; % Motor Rating in kW
        kVAbase=3*746; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.451; % Rotor resistance of the motor (Ohms)
        Rs = 0.6837; % Stator resistance of the motor (Ohms)
        Lls = 0.004152; % Stator winding leakage inductance(Henry)
        Lm = 0.1486; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 0.004152; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.05; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0;  % Load Torque - Usually a function of speed
        poles=2; % Number of poles

    end

    if Motor_Choice==8

        %% Motor Model 8 - Simulink Model Parameters

        % Motor Name Plate Data
        Vrating=460; % Three-phase motor voltage rating
        Vrated=Vrating/sqrt(3); %Single Phase Voltage
        pf=0.905; % Rated power factor of the motor
        kWbase=(25*0.745)*1e3; % Motor Rating in kW
        kVAbase=3*746; % Motor rated kVA
        Irated=kVAbase/(sqrt(3)*Vrated);
        Vbase=Vrated*sqrt(2); % Volts
        Ibase=Irated*sqrt(2); % Amps
        fbase=60; % Rated Frequency in Hz
        omega_e_base=2*pi*fbase;

        % Equivalent Circuit Parameter (500 hp motor)
        Rr = 0.1645; % Rotor resistance of the motor (Ohms)
        Rs = 0.2761; % Stator resistance of the motor (Ohms)
        Lls = 0.002191; % Stator winding leakage inductance(Henry)
        Lm = 0.07614; % Mutual inductance between the stator and rotor windings (Henry)
        Llr = 0.002191; % Rotor winding leakage inductance(Henry)
        Ls=Lls+Lm; % Self Inductance of the stator
        Lr=Llr+Lm; % Self Inductance of the rotor

        % Mechanical System Circuit Parameters
        Cj=0.1; % Moment of inertia of the machine (In Kg.m^2)
        Tl=0.0;  % Load Torque - Usually a function of speed
        poles=2; % Number of poles

    end
end