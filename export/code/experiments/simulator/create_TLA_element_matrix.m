function [V_matrix,I_matrix,R_matrix,G_matrix,Beta_matrix,Alpha_matrix]=create_TLA_element_matrix(IM_Ckt,IF_Echelon_index,V_tree,V_link,I_tree,I_link,num_twigs,num_links,delta_t,omega_index,Idq_index)


% Setting the dimensions of the tree link analysis element matrices.
V_matrix=zeros(num_twigs,1);
R_matrix=zeros(num_twigs,num_twigs); % R_matrix is a square matrix with mutually coupled elements in the off-diagonal term.
G_matrix=zeros(num_links,num_links); % G_matrix is a square matrix with mutually coupled elements in the off-diagonal term
I_matrix=zeros(num_links,1);
Alpha_matrix=zeros(num_twigs,num_links);
Beta_matrix=zeros(num_links,num_twigs);

for i=1:size(IF_Echelon_index,1)
    % Define the element term in the IM_Ckt table
    k=IF_Echelon_index(i,4);
    % Finding the dependent element of the circuit element if any
    m=IM_Ckt(IF_Echelon_index(i,4),7);
    
    
%-------------------Independent Vsource Matrix Elements------------------
    if(IF_Echelon_index(i,2)==1)
        V_matrix(i)=IM_Ckt(k,5);
        
        
%-------------------Short Circuit Elements-------------------------------
    elseif(IF_Echelon_index(i,2)==22)
        R_matrix(i,i)=0;
        
        
%-------------------Independent Resistive Elements----------------------
%                     Twig or a Link Location
    elseif(IF_Echelon_index(i,2)==2)
        if(i<=num_twigs)
            R_matrix(i,i)=IM_Ckt(k,5);
        else
            G_matrix(i-num_twigs,i-num_twigs)=1/IM_Ckt(k,5);
        end
        
 %%%%%%%%%%%%%%% Important the speed here is negative so this has to be multiplied to negative voltage ----------------------------       
%---------------Dependent Voltage Sources in Off Diagonal Terms----------       
    elseif(IF_Echelon_index(i,2)==11)
        if(m==5) % Check if the element is dependent on speed
            % The omega dependent term is a function of speed which is a
            % voltage of a link element
            Alpha_matrix(i,(omega_index-num_twigs))=-IM_Ckt(k,5); 
        else
            % The Id and Iq dependent elements is a function of one of the
            % tree currents and thus are in off-diagonal term of the matrix
            R_matrix(i,Idq_index(m))=IM_Ckt(k,5);    
        end
        
        
%-----------------Companion Voltage Sources of the Capcitor Elements-------   
    elseif(IF_Echelon_index(i,2)==3)
        % Find the capcitor equivalent resistane index
        j=find(IF_Echelon_index(:,1)==(IF_Echelon_index(i,1)+1));
        % Require the capacitor eq resistance to calculate the net voltage
        % across the capacitor
        if j>num_twigs    
        V_matrix(i)=(delta_t/(2*IM_Ckt(k,5)))*I_tree(i)+(V_tree(i)+V_link(j-num_twigs));
        else
        V_matrix(i)=(delta_t/(2*IM_Ckt(k,5)))*I_tree(i)+(V_tree(i)+V_tree(j));
        end
        
        
%-----------------Companion Current Sources of the Inductor Elements-------
%--------------Includes Self and Mutual Inductances------------------------
    elseif(IF_Echelon_index(i,2)==4)
            % Find the inductor equivalent resistance index
            j=find(IF_Echelon_index(:,1)==(IF_Echelon_index(i,1)-1));
            if j>num_twigs  
            I_matrix(i-num_twigs)=(delta_t/(2*IM_Ckt(k,5)))*(V_link(i-num_twigs))+(I_link(i-num_twigs)+I_link(j-num_twigs));
            else
            I_matrix(i-num_twigs)=(delta_t/(2*IM_Ckt(k,5)))*(V_link(i-num_twigs))+(I_link(i-num_twigs)+I_tree(j));   
            end
        
%--------------Companion Equivalent Resistances of the Capacitors Elements--    
    elseif(IF_Echelon_index(i,2)==5)
        % Find the capcitor element in the net matrix
        if(i<=num_twigs)
            R_matrix(i,i)=delta_t/(2*IM_Ckt(k,5));
        else
            G_matrix(i-num_twigs,i-num_twigs)=(2*IM_Ckt(k,5))/delta_t;
        end
        
%--------------Independent Voltage Source of the Mutual Inductor Elements--          
    elseif(IF_Echelon_index(i,2)==44)
        % Find the dependent voltage source index
        j=find(IF_Echelon_index(:,1)==(IF_Echelon_index(i,1)+1));
        % Require the capacitor eq resistance to calculate the net voltage
        % across the capacitor
        if j>num_twigs    
        V_matrix(i)=-(((2*IM_Ckt(k,5))/delta_t)*I_tree(Idq_index(m))+(V_tree(i)+V_link(j-num_twigs)));
        else
        V_matrix(i)=-(((2*IM_Ckt(k,5))/delta_t)*I_tree(Idq_index(m))+(V_tree(i)+V_tree(j)));
        end
        
%--------------Dependent Voltage Source of the Mutual Inductor Elements--          
    elseif(IF_Echelon_index(i,2)==46)
        R_matrix(i,Idq_index(m))=((2*IM_Ckt(k,5))/delta_t);
        
    
%--------------Companion Equivalent Resistances of the Inductor Elements-- 
    elseif(IF_Echelon_index(i,2)==6)
        if(i<=num_twigs)
             R_matrix(i,i)=(2*IM_Ckt(k,5))/delta_t;
        else
             G_matrix(i-num_twigs,i-num_twigs)=delta_t/(2*IM_Ckt(k,5));
        end
        
        
%---------------Independent and Dependent Current Sources - Torque Model--
    elseif(IF_Echelon_index(i,2)==7)
        if(IM_Ckt(k,4)==1)
            Beta_matrix(i-num_twigs,Idq_index(m))=IM_Ckt(k,5);
        else
            I_matrix(i-num_twigs)=IM_Ckt(k,5);
        end
    end
end




        