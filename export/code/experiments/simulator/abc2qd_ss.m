function [Vd,Vq,Vo] = abc2qd_ss(Vbase, theta, omega_e_base)
    lamda=pi/2;
    t = 0;
    Va=Vbase*cos(omega_e_base*t+lamda);
    Vb=Vbase*cos(omega_e_base*t+lamda-(2*pi/3));
    Vc=Vbase*cos(omega_e_base*t+lamda+(2*pi/3));

    theta=theta*t;

    Vq=(2/3)*(Va*cos(theta)+Vb*cos(theta-2*pi/3)+Vc*cos(theta+(2*pi/3)));
    Vd=(2/3)*(Va*sin(theta)+Vb*sin(theta-2*pi/3)+Vc*sin(theta+(2*pi/3)));
    Vo=(1/3)*(Va+Vb+Vc);
    
    Vd = -Vd;
    Vq = 0;
    Vo = 0;
    
end

