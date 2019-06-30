function [Ids, Iqs] = Run_Induction_Motor_SI_SS(V, T)

    %% Simulation Parameters

    % Simulation Start Time
    t_start=0;
    % Simulation time step
    delta_t=1e-5;
    % Simulation end time
    t_end=1.5;
    % Tolerence for each time step for  NR iterations
    abstol=0.5e-1;
    % Total number of time steps
    time_steps=length(t_start:delta_t:t_end); 
    % Initial Damping Factor for Damped Newton Raphson
    Damping_factor=1;
    % Maximum number of Newton Raphson Iterations
    NR_limit=100000;
    % Config Helper On or Off
    config_helper=0 ;
    % Transient or steady state solver
    option='ss';

    if(strcmp(option,'ss'))
        time_steps=1;
        t_start=1;
        delta_t=1;
        t_end=1;
    end

    %% Newton Raphson Initialization Variables
    t=0; 
    iteration_count_NF_Store=zeros(time_steps,1);
    iteration_count=0;
    iteration_count_NF=0;
    count_low_step_size=0;
    tol_Store=[];

    % Initialization of motor state variables.
    Iqs=0; Iqr=0; Ids=0; Idr=0; omega_r=0; Te=0;

    % Initialization of motor non-linear functions
    NF1_old=0; NF2_old=0; NF3_old=0; NF4_old=0; NF5_old=0;
    
    %% Motor Parameters
    %% Load Motor Parameters - SI Units
    Motor_Choice=8;
    [Vbase_check,Rr,Rs,Ls,Lr,Lm,Cj,poles,fbase,omega_e_base,~]=Motor_Parameters_SI(Motor_Choice);

    % Define Load Torque Again
    Tl = T;
    Vbase = V;
    
    %%
    D=0.01771;

    % Synchronous frame motor
    theta=2*pi*fbase;

    %% Calculate the circuit file for system initialization
    Induction_motor_definition_SS

    %% Creating the incidence matrix with voltage sources in the left most columns and current sources in the right most.

    [A,Initial_Echelon_index,Num_nodes,Num_branches,Sorted_Echelon_index]=create_sorted_Amatrix(IM_Ckt);
    num_twigs=Num_nodes(2)-1;
    num_links=Num_branches(2)-num_twigs;

    %% Re-arranging the incidence matrix to form [I|F]

    % Getting the row echelon incidence
    [F,IF_Echelon_index,check,A_ech_standard]=convertAtoIF(A,Num_nodes,Sorted_Echelon_index);
    if(check==1)
        sprintf('Formatting of the A matrix is successful');
    else
        sprintf('Error in formatting of A matrix to format I|F')
    end 

    %% Initializaton of the variables


    % Storing state variables for each time step
    omega_r_Store=zeros(time_steps,1); Te_Store=zeros(time_steps,1); vd_Store=zeros(time_steps,1); Iqs_Store=zeros(time_steps,1);

    % Initialization of the tree and link voltage and currents
    I_tree=zeros(num_twigs,1);
    I_link=zeros(num_links,1);
    V_tree=zeros(num_twigs,1);
    V_link=zeros(num_links,1);


    %% Indexing of the state variables in the system

    Idq_index(1)=find(IF_Echelon_index(:,4)==2); % Find the index for Ids *** SC Element
    Idq_index(2)=find(IF_Echelon_index(:,4)==7); % Find the index for Iqs *** SC Element
    Idq_index(3)=find(IF_Echelon_index(:,4)==12); % Find the index for Idr *** SC Element
    Idq_index(4)=find(IF_Echelon_index(:,4)==22);% Find the index for Iqr *** SC Element
    omega_index=find(IF_Echelon_index(:,4)==35); % Find the index for speed
    Te_index=find(IF_Echelon_index(:,4)==31);

    %% Start the moving forward in time loop
    for t=t_start:delta_t:t_end

    % Increasing the iteration count for each time step
    iteration_count=iteration_count+1;

    % Initializing the tolerence matrix for each non-linear functions for each
    % time step
    tol=5.*ones(5,1);

    % Storing the iteration count for each N-R iteration
    iteration_count_NF_Store(iteration_count)=iteration_count_NF;
    iteration_count_NF=0; 
    count_bad_step=0;

    V_tree_old=V_tree;
    I_tree_old=I_tree;
    V_link_old=V_link;
    I_link_old=I_link;


        while max(abs(tol))>abstol

            %% Evaluate the transient setting based on results    
            if(config_helper==1)
                if(iteration_count_NF>10)
                    delta_t=delta_t/10;
                    count_low_step_size=0;
                    iteration_count_NF=0;
                    V_tree=V_tree_old;
                    V_link=V_link_old;
                    I_link=I_link_old;
                    I_tree=I_tree_old;
                    Damping_factor=Damping_factor/10;
                    count_bad_step=count_bad_step+1
                end
                if(iteration_count_NF<5)
                    count_low_step_size=count_low_step_size+1;
                end
                if(count_low_step_size>5)
                    delta_t=delta_t*10;
                    count_low_step_size=0;
                    Damping_factor=Damping_factor*10;
                end
                delta_t=min(delta_t,1e-6);
                if delta_t<=1e-6  
                    delta_t=max(delta_t,1e-10);
                end
                Damping_factor=min(1,Damping_factor);
                if(Damping_factor<1)
                    Damping_factor=max(1e-4,Damping_factor);
                end
            end


            iteration_count_NF=iteration_count_NF+1;

            if iteration_count_NF>NR_limit
                sprintf('The NR_Solver has reached its iteration limit');
                break
            end

            %% Re-evaluate the NR elements

            Induction_motor_definition_SS

            %% Creating Element Matrices V_matrix | I_matrix | R_matrix | G_matrix | Beta_matrix | Alpha_matrix

            [V_matrix,I_matrix,R_matrix,G_matrix,Beta_matrix,Alpha_matrix]=create_TLA_element_matrix(IM_Ckt,IF_Echelon_index,V_tree,V_link,I_tree,I_link,num_twigs,num_links,delta_t,omega_index,Idq_index);


            %% Calculation of tree voltages and link currents

            AlphaF=Alpha_matrix*F';
            BetaF=Beta_matrix*F;
            RF=R_matrix*F;
            GF=-G_matrix*F';
            S=[(eye(num_twigs)-AlphaF) RF;GF (eye(num_links)+BetaF)];
            Source_matrix=[V_matrix;I_matrix];

            Tree_link_results=S\Source_matrix;

            % Calculation of tree voltages is given by the formula
            V_tree= Tree_link_results(1:num_twigs);
            V_link= F'*V_tree;

            % Calculation of link 
            I_link= Tree_link_results(num_twigs+1:end);
            I_tree= -F*I_link;


            %%  The five non linear functions and the check
            % 1. omega_r.Lr.Idr | 2. - omega_r.Lm.Iqs | 3. omega_r.Lr.Idr | 4.
            % omega_r.Lm.Ids 5. Te

            %% Updating parameters and non-linear state variables

            NF1=Lr*Idq_index(3)*(-V_link(omega_index-num_twigs));
            NF2=Lm*Idq_index(1)*(-V_link(omega_index-num_twigs));
            NF3=Lr*Idq_index(4)*(-V_link(omega_index-num_twigs));
            NF4=Lm*Idq_index(2)*(-V_link(omega_index-num_twigs));
            NF5=I_tree(Idq_index(3))*I_tree(Idq_index(2))-I_tree(Idq_index(1))*I_tree(Idq_index(4));

            tol=[NF1-NF1_old;NF2-NF2_old;NF3-NF3_old;NF4-NF4_old;NF5-NF5_old];

            NF1_old=NF1;
            NF2_old=NF2;
            NF3_old=NF3;
            NF4_old=NF4;
            NF5_old=NF5;

            % tol=[I_tree(Idq_index(1))-Ids;I_tree(Idq_index(3))-Idr;I_tree(Idq_index(4))-Iqr...
            %     ;I_tree(Idq_index(2))-Iqs;-V_link(omega_index-num_twigs)-omega_r];

            if(max(abs(tol))>abstol)
                Ids=I_tree(Idq_index(1))-(1-Damping_factor)*tol(1);
                Idr=I_tree(Idq_index(3))-(1-Damping_factor)*tol(2);
                Iqr=I_tree(Idq_index(4))-(1-Damping_factor)*tol(3);
                Iqs=I_tree(Idq_index(2))-(1-Damping_factor)*tol(4);
                omega_r=-V_link(omega_index-num_twigs)-(1-Damping_factor)*tol(5); 

                % Applying linear damping to all variables
                if(iteration_count>1)
                V_tree=V_tree-(1-Damping_factor).*(V_tree-V_tree_old);
                V_link=V_link-(1-Damping_factor).*(V_link-V_link_old);
                I_tree=I_tree-(1-Damping_factor).*(I_tree-I_tree_old);
                I_link=I_link-(1-Damping_factor).*(I_link-I_link_old);
                end
            else
                Ids=I_tree(Idq_index(1));
                Idr=I_tree(Idq_index(3));
                Iqr=I_tree(Idq_index(4));
                Iqs=I_tree(Idq_index(2));
                omega_r=-V_link(omega_index-num_twigs); 
            end

            Te=(3/4)*poles*(Lm)*(Idr*Iqs-Ids*Iqr);
        end

    t_mod=mod(t,0.1);
    if(t_mod==0)
        t;
    end

    % % Storing the systems voltages and currents for each time step
    % V_tree_T=[V_tree_T V_tree];
    % V_link_T=[V_link_T V_link];
    % I_link_T=[I_link_T I_link];
    % I_tree_T=[I_tree_T I_tree];

    % Storing the motor variables to plot
    % omega_r_T=[omega_r_T omega_r];
    % vd_T=[vd_T Vd];
    % vq_T=[vq_T Vq];
    % Ids_T=[Ids_T Ids];
    % Idr_T=[Idr_T Idr];
    % Iqs_T=[Iqs_T Iqs];
    % Iqr_T=[Iqr_T Iqr];
    % Te_T=[Te_T Te];

    omega_r_Store(iteration_count)=omega_r;
    Te_Store(iteration_count)=Te;
    vd_Store(iteration_count)=Vd;
    Iqs_Store(iteration_count)=Iqs;

end
