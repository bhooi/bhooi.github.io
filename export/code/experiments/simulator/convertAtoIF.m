function [F,IF_Echelon_index,check,A_ech_standard]=convertAtoIF(A,Num_nodes,Sorted_Echelon_index)
% Reducing the incidence matrix
A_red= A(setdiff(1:size(A,1),Num_nodes(1)),:); % Removes the ground node
% Forming the cutset matrix 
A_ech=frref(A_red);
% Obtaining the graph parameters from the row echelon A matrix
A_red_dim=size(A_ech);
A_ech_column_sum=sum(abs(A_ech));
% Sort the columns of A_ech_column_sum such that columns of the identity
% matrix are in the leftmost side of the matrix
[~,Sorted_Index]=sort(A_ech_column_sum);
count_graph_elements = accumarray(A_ech_column_sum(:),1);
% Write the routine to get the index of element with sum 1 
num_twigs=Num_nodes(2)-1;
A_ech_standard= A_ech(:,Sorted_Index);
% Moving any rows that need moving
Sorted_Shift_Index=Sorted_Index;
for i=1:num_twigs
    if(A_ech_standard(i,i)~=1)
        for j=i:count_graph_elements
            if(A_ech_standard(i,j)==1)
                Sorted_Shift_Index([i j])=Sorted_Shift_Index([j i]);
                A_ech_standard(:,[i,j])=A_ech_standard(:,[j,i]);
                break
            end
        end
    end
end 
% Updating the echelon index table
IF_Echelon_index=Sorted_Echelon_index(Sorted_Shift_Index,:);
% Check for I|F form
check=det(A_ech_standard(:,1:num_twigs));
F=A_ech_standard(:,(num_twigs+1):end);
end