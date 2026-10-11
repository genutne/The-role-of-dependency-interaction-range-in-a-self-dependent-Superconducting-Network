function [Tc1, Tc2] = find_Tc(T_range,R1_all,R2_all)
%this function get the values of layer 1 and 2 resistance by temperature,
%and find the critical Tc (were the layers change phaze *from above*).
%if the phaze transition is'nt 1st order, Tc would get a nan value.

dR1 = abs(R1_all(2:end) - R1_all(1:end-1));
dR2 = abs(R2_all(2:end) - R2_all(1:end-1));
dT = T_range(2:end) - T_range(1:end-1);
if dT(1) > 0
    heat = 1;%heating prosses
else
    heat = 0;%cooling prosses
end

% if max(abs(dT))<5*10^-2
%     ['looks like a good resolution, dT=',num2str(max(abs(dT)))]
% else
%     ["dosen't looks like a good resolution"]
% end

if max(dR1)>50
    idx1 = find(dR1==max(dR1));
    if heat 
        idx1 = idx1+1;
    end
    Tc1 = T_range(idx1);
    PT1 = 1;
else
    R_0 = find(R1_all<30);
    idx1 = R_0(1);
    if heat 
        idx1 = R_0(end);
    end
    Tc1 = T_range(idx1);
    PT1 = 2;
end

if max(dR2)>50
    idx2 = find(dR1==max(dR1));
    if heat 
        idx2 = idx2+1;
    end
    Tc2 = T_range(idx2);
    PT2 = 1;
else
    R_0 = find(R2_all<30);
    idx2 = R_0(1);
    if heat 
        idx2 = R_0(end);
    end
    Tc2 = T_range(idx2);
    PT2 = 2;
end

if Tc1 == Tc2
    if PT2 == 1 
        ['shared first order phase transition']
    else
        ['shared second order phase transition']
    end
else
    ['un-coupled phase transition']
end















    
    