function [A_TLA,Initial_Echelon_index,Num_nodes,Num_branches,Sorted_Echelon_index]=create_sorted_Amatrix(net_Ckt)

%% Warning the ground is the last node in the net_Ckt imported into this function

% Calculating number of elements
num_V=numel(find(net_Ckt(:,6)==1)); % Count number of voltage sources
num_R=numel(find(net_Ckt(:,6)==2)); % Count number of resistances and conductances
num_C=numel(find(net_Ckt(:,6)==3)); % Count number of capacitances
num_L=numel(find(net_Ckt(:,6)==4)); % Count number of self inductances
num_I=numel(find(net_Ckt(:,6)==7)); % Count number of current sources
num_R_dependent=numel(find(net_Ckt(:,6)==11)); % Count number of current dependent voltage sources or voltage dependent current sources
num_SC=numel(find(net_Ckt(:,6)==22)); % Count number of short circuit elements
num_ML=numel(find(net_Ckt(:,6)==44)); % Count number of mutual inductances
num_elements=[num_V num_R num_C num_L num_I num_R_dependent num_SC num_ML];

% Calculate the number of elements
total_elements=size(net_Ckt,1);

% Number of nodes in the input netlist and actual circuit
num_nodes_net_Ckt=max(max(net_Ckt(:,2:3)));

% Number of nodes in the equivalent circuit of the actual circuit with
% companion models of capacitors and inductors
num_nodes_eq_circ=max(max(net_Ckt(:,2:3)))+num_C+num_ML; 

% Number of branches in the input netlist and actual circuit
num_branches_net_Ckt=total_elements;

% Number of branches in the equivalent circuit of the actual circuit with
% companion models of capacitors and inductors
num_branches_eq_circ=sum(num_elements)+num_C+num_L+num_ML; % Add number of inductors and capacitors to get equivalent branch numbers
A=zeros(num_nodes_eq_circ,num_branches_eq_circ);

% ----- Indexing Methodology

%----- Element Weight ----- Adds a weight to each element --> 1 - Voltage
%Source 2-> Short Circuit  5--> Resistances/Conductances 999--> Current
%Source 3-> Dependent Voltage Source

%----- Element type ----- Adds a type to each element --> 1 - Voltage
%Source 22-> Short Circuit  3 -> Capacitance Companion Voltage Source 4 -> Inductance
%Companion Current Source 5-> Capacitance Companion Resistance 6 -> Inductor Companion Resistance

%----- Element Branch ----- Adds the branch number of the variable in the
%orginal IM circuit to the matrix

%Initilizing the total number of elements including companion models.
count_eq_circ=0;

% Initializing the physical number of nodes prior to adding any adding any
% additional nodes due to thevenin circuits of inductors and capacitors
num_node_add=num_nodes_net_Ckt;


for i=1:total_elements
    
%--------- Stamping voltage sources into the incidence matrix--------------
    if(net_Ckt(i,6)==1)
        count_eq_circ=count_eq_circ+1; % Add 1 element to total for each Vsource
        Element_weight(count_eq_circ)=1; % Add weight 1 for Vsource
        Element_type(count_eq_circ)=net_Ckt(i,6); % Vsource element code -1
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
        
        
%-----Stamping short-circuit elements into the incidence matrix------------
    elseif(net_Ckt(i,6)==22) 
        count_eq_circ=count_eq_circ+1; % Add 1 element to total for each Vsource
        Element_weight(count_eq_circ)=1; % Add weight 1 for SC
        Element_type(count_eq_circ)=net_Ckt(i,6); % SC elemtent code -22
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;

%-----Stamping short-circuit elements into the incidence matrix------------
   elseif(net_Ckt(i,6)==3)
        % Thevenin equivalent companion model of the capacitor is used
        count_eq_circ=count_eq_circ+2; % Add two element for each cap
        Element_weight(count_eq_circ-1)=1; % Weight of V_c_source is 1
        Element_weight(count_eq_circ)=5; % Weight of R_c is 5
        Element_type(count_eq_circ-1)=net_Ckt(i,6); % V_c_source element code -3
        Element_type(count_eq_circ)=net_Ckt(i,6)+2; % R_c element code - 5
        Element_branch(count_eq_circ-1)=i;
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        % Additional node and branch is added due to thevenin circuit
        num_node_add=num_node_add+1;
        % Element 1 - Voltage element of the capacitor
        A(net_Ckt(i,2),(count_eq_circ-1))=1;
        A(num_node_add,(count_eq_circ-1))=-1;
        % Element 2 - Resistance element of the capacitor
        A(num_node_add,count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
      
              
%----Stamping resistive and conductive elements into the incidence matrix--
    elseif(net_Ckt(i,6)==2)
        count_eq_circ=count_eq_circ+1; % Add 1 element for R
        Element_weight(count_eq_circ)=5; % Weight of R is 5
        Element_type(count_eq_circ)=net_Ckt(i,6); % R element code - 2
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
        
        
%--------Stamping self-inductance elements into the incidence matrix------
    elseif(net_Ckt(i,6)==4)
        % Norton equivalent companion model of the capacitor is used
        count_eq_circ=count_eq_circ+2; % Add two element for each cap
        Element_weight(count_eq_circ-1)=5; % Weight of R_l is 5
        Element_weight(count_eq_circ)=999; % Weight of I_source_l is 5
        Element_type(count_eq_circ-1)=net_Ckt(i,6)+2; % ELement code R_l - 6
        Element_type(count_eq_circ)=net_Ckt(i,6); % Element code of I_source_l - 4
        Element_branch(count_eq_circ-1)=i;
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        % Additional branch is added due to thevenin circuit
        % Element 1 - Resistive element of the capacitor
        A(net_Ckt(i,2),(count_eq_circ-1))=1;
        A(net_Ckt(i,3),(count_eq_circ-1))=-1;
        % Element 2 - Current Source element of the inductance
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
  
        
%---------Stamping the mutual inductor elements to the incidence matrix---- 
%Thevenin equivalent model of the inductor is used for the mutual inductor
    elseif(net_Ckt(i,6)==44)
       % Stamping the indices for the dependent and independent voltage sources for the mutual coupling.
       % Independent first - Dependent Second
        count_eq_circ=count_eq_circ+2; % Add two elements 
        Element_weight(count_eq_circ-1)=1; % Weight of V_ml element
        Element_weight(count_eq_circ)=3; % Weight of R_ml element 
        Element_type(count_eq_circ-1)=net_Ckt(i,6); % Element code for V_ml - 44
        Element_type(count_eq_circ)=net_Ckt(i,6)+2; % Element code for R_ml - 46
        Element_branch(count_eq_circ-1)=i;
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        % Additional node and branch is added to the circuit
        num_node_add=num_node_add+1;
        % Element 1 - Independent Voltage element of the mutual inductor
        A(net_Ckt(i,2),(count_eq_circ-1))=1;
        A(num_node_add,(count_eq_circ-1))=-1;
        % Element 2 - Dependent Voltage element of the mutual inductor
        A(num_node_add,count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
    
%---------Stamping the dependent voltage sources to the incidence matrix----    
    elseif(net_Ckt(i,6)==11)
        % Stamping the indices for the  dependent resitors in the circuit.
        count_eq_circ=count_eq_circ+1;
        Element_weight(count_eq_circ)=3; % Weight of R_d/G_d element
        Element_type(count_eq_circ)=net_Ckt(i,6); % Element code R_d/G_d
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
        
        
%--------- Stamping current sources into the incidence matrix--------------
    elseif(net_Ckt(i,6)==7)
        count_eq_circ=count_eq_circ+1;
        Element_weight(count_eq_circ)=999; % Element weight for Isource
        Element_type(count_eq_circ)=net_Ckt(i,6); % Element code of Isource -7
        Element_branch(count_eq_circ)=i;
        % Stamping from and to nodes into the A matrix
        A(net_Ckt(i,2),count_eq_circ)=1;
        A(net_Ckt(i,3),count_eq_circ)=-1;
    end
end

% Creating the index table
% Column 1 - sequence of elements 
Element_sequence=1:num_branches_eq_circ;
% Column 2 - Element Code | Column 3 - Element Weight | Column 4 - Element Branch in netlist
Element_index=[Element_type' Element_weight' Element_branch'];
% Concatenating all the columns together
Initial_Echelon_index=[Element_sequence' Element_index];
% Sorting the rows based on element weight - Column 2
[Echelon_index,Sorted_index]=sortrows(Element_index,2);
%Echelon_index= [Initial Sequence -> Corresponding Element_type ->
%Corresponding Element Weight -> Sorted index]
Sorted_Echelon_index=[Sorted_index Echelon_index ];
A_TLA = A(:,Sorted_Echelon_index(:,1));
Num_nodes=[num_nodes_net_Ckt,num_nodes_eq_circ];
Num_branches=[num_branches_net_Ckt,num_branches_eq_circ];
end