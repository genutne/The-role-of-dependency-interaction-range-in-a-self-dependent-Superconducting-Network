tic

% geeral structure of the network
W = 100; % width size
L = 100; % length size
NR = (2*W-1)*L; % number of links (without entrance)
NN = W*L; % number of nodes
epsilon = 10^(-5); % threshold for epsilon to determine that the system converged
kappa = L^2*50*10^3; % kappa sets the rate of heat production (the fraction of I^2R that stay in the network
% kappa_own = L^2*5*10^-3;
% kappa = 10*10^6; % kappa for the media between layers, bnaya
% kappa_own = 5*10^1; % kappa for the media in each layer, banyaRhot = 500; % the resistance in the Normal phase
% kappa = 50*10^3; % kappa for the media between layers, bnaya
kappa = 2*L^2*4*10^3;
kappa_own = kappa ; 
Rhot = 500; % the resistance in the Normal phase
RSc = 10^(-5); % the resistance in the SC (Super-Conducting) phase
Ic0_1 = 58*10^(-6); % avg critical current layer1
Ic0_2 = 58*10^(-6); %48*10^(-6); % avg critical current layer2
sigma_vec = [0.1]; % Level of disorder
Dt_vec = [10000]; % Dt sets the level of heat diffusion [1:10 20:10:150] [0:0.2:0.9 1:10 20:10:150]
I_vec = [300]*10^(-6);
% I_vec = 50;
Ti = 2.1;
Tf = 2.3;
Tjumps = 100;
T_up_plateau = 3;
T_down_plateau = 0.1;
movie_flag = 0; %change to 1 if you want to create a movie, note that it takes a lots of time
states_movie_flag = 0;

%%%plateau properties
plateau_vec = nan;
% plateau_vec = flip([2.12224]);
% Tc = 0.6;
% dT = [0:150]*0.01;
% plateau_vec = Tc-dT;
% plateau_vec = Tc;

if isnan(plateau_vec)
    plateau = 0;
else
    plateau = 1;
end  
if plateau
    plateau_structor = struct('T',[],'iter',[],'R1',[],'R2',[]);
end


for dependent = [1] % 1 = layers dependent, 0 = layers undependent
for sigma = sigma_vec
for Dt = Dt_vec
for heat = [1] % 1 = heating, 0 = cooling
for I = I_vec

for p = 1:length(plateau_vec)
    sum_heat_vec = [];
    
    Itotal1 = I; % currents at entrence node
    Itotal2 = I; % currents at entrence node

    %seting the general currents vector
    I1 = zeros(1,NN+1);
    I1(end) = Itotal1;
    I2 = zeros(1,NN+1);
    I2(end) = Itotal2;

    % vector currents for each link
    cin1 = zeros(1,W);
    currents1 = zeros(1,NR);
    cin2 = zeros(1,W);
    currents2 = zeros(1,NR);
   
    % vector resistors for each link.   
    if heat 
        %heating, we start with all at the SC phase.
        Rin1 = RSc*ones(1,W);
        R1 = RSc*ones(1,NR);
        Rin2 = RSc*ones(1,W);
        R2 = RSc*ones(1,NR);
    elseif ~heat
        %cooling, we start with all at the Normal phase.
        Rin1 = Rhot*ones(1,W);
        R1 = Rhot*ones(1,NR);
        Rin2 = Rhot*ones(1,W);
        R2 = Rhot*ones(1,NR);
    end

    % vector states for each link. 1=SC , 2=intermidiate , 3=normal.
    states_in1 = zeros(1,W);
    states1 = zeros(1,NR);
    states_in2 = zeros(1,W);
    states2 = zeros(1,NR);

    % Ic for each resistor
    Ic_in1 = Ic0_1*(1+sigma*randn(1,W));
    Ic1 = Ic0_1*(1+sigma*randn(1,NR));
    Ic_in2 = Ic0_2*(1+sigma*randn(1,W));
    Ic2 = Ic0_2*(1+sigma*randn(1,NR));
%     load(['Ic_zeros_W',num2str(W),'_sig',num2str(sigma),'.mat']); %load a setup
    %for identical layers:
%     Ic1 = Ic2;
%     Ic_in1 = Ic_in2;

    % Tc for each resistor
    factor = 100;  % the 100 here can be modified but should be close to it to match the experiment
    Tc1 = factor*Rhot*Ic1;
    Tcin1 = factor*Rhot*Ic_in1;
    Tc2 = factor*Rhot*Ic2;
    Tcin2 = factor*Rhot*Ic_in2;
    
    %temperature properties
    T_range = linspace(Ti,Tf,Tjumps); % heating T range
    if ~heat  
        T_range = flip(T_range); % cooling T range
    end
    
    %temperature properties for plateau
    if plateau
        if heat
            T_range = [T_down_plateau plateau_vec(p)]; %for plateau heating
        elseif ~heat
            T_range = [T_up_plateau plateau_vec(p)]; %for plateau cooling            
        end
    end
 
    LT = length(T_range);
    iterations = zeros(1,LT);
    R1_all = zeros(1,LT);
    R2_all = zeros(1,LT);

    %start creating a movie
    if movie_flag
        video_name = ['video_cooling_Iin' ,num2str(Itotal1*10^6),'Dt', num2str(Dt), 'L',num2str(L), '.avi'];
        %current_date = datestr(now, 'yyyy-mm-dd');
        v = VideoWriter(video_name);
        v.Quality = 50;
        open(v);
        %figure('visible','off');     tiledlayout(1,3);
        %figure;     tiledlayout(1,3);
        figure;     tiledlayout(2,3);
%         figure;     tiledlayout(2,2);
        handles = {};
        [nodes, connections] = creat_nodes_and_links_array(L, W);
    end
    if states_movie_flag
        video_name = ['states_video_cooling_Iin' ,num2str(Itotal1*10^6),'Dt', num2str(Dt), 'L',num2str(L), '.avi'];
        v = VideoWriter(video_name);
        v.Quality = 50;
        open(v);
        figure;
        handles = {};
    end
    
    for i=1:length(T_range)

        T0 = T_range(i); % heat bath temperature T0
        finish = 0;
        iter = 0;
        flag = 0;                
        iter_per_T = [];
        R1_per_T = [];
        R2_per_T = [];

        cc1 = [];
        cc2 = [];
        cc3 = [];
        cc4 = [];
            
        while flag==0 
            iter = iter+1;

            if iter>20000
                flag=1;
            end
               
            %saving 2 last voltege results for exit condition
            if iter>2
                V1old2 = V1old;
                V2old2 = V2old;
            end

            if iter>1
                V1old = V1;
                V2old = V2;
            end

            % first, calculate the voltage at each node in the two networks    
            V1 = Voltage_nodes(L, W, NN, NR,Rin1, R1,I1);
            V2 = Voltage_nodes(L, W, NN, NR,Rin2, R2,I2);

            % checking exit condition
            if iter>2
                if norm(V1-V1old2)/norm(V1)+norm(V2-V2old2)/norm(V2)<epsilon || norm(V1-V1old)/norm(V1)+norm(V2-V2old)/norm(V2)<epsilon
                    flag=1;
                end
                
                cc1 = [cc1 norm(V1-V1old2)/norm(V1)];
                cc2 = [cc2 norm(V2-V2old2)/norm(V2)];
                cc3 = [cc3 norm(V1-V1old)/norm(V1)];
                cc4 = [cc4 norm(V2-V2old)/norm(V2)];
            
                if flag == 0 && iter>1500
%                     if (norm(V1-V1old2)/norm(V1)<10^(-4) && norm(V2-V2old2)/norm(V2)<10^(-4)) || (norm(V1-V1old)/norm(V1)<10^(-4) && norm(V2-V2old)/norm(V2)<10^(-4))
%                         flag=1;
%                         ["Number of iterations is too high"]
%                     end
                    if mean(cc1(end-1000:end-500))-mean(cc1(end-500:end-2))<10^(-5) && mean(cc2(end-1000:end-500))-mean(cc2(end-500:end-2))<10^(-5) || mean(cc3(end-1000:end-500))-mean(cc3(end-500:end))<10^(-5) && mean(cc4(end-1000:end-500))-mean(cc4(end-500:end))<10^(-5)
                        flag=1;
                        ["Number of iterations is very high"]
                    end
                end
            end
            
            
            if flag == 0 && iter>15000
                finish = 1;
                break
            end

            % now, calculate the currents in each resistor and its heat production
            [currents1,cin1,heat1,heat_in_1] = find_currents(V1, L, W, NN, NR, Rin1, R1,1);
            [currents2,cin2,heat2,heat_in_2] = find_currents(V2, L, W, NN, NR, Rin2, R2,1);    

            % let the heat diffuse (only in the bulk, no exit/entrence nodes)       
            Q12 = heat_transfer_spectral(L,W,Dt,heat1(1:NR-W)*kappa);
            Q21 = heat_transfer_spectral(L,W,Dt,heat2(1:NR-W)*kappa);
            Q11 = heat_transfer_spectral(L,W,Dt,heat1(1:NR-W)*kappa_own);
            Q22 = heat_transfer_spectral(L,W,Dt,heat2(1:NR-W)*kappa_own);

            if dependent
                %dependent layers
                heat1(1:NR-W) = Q21+Q11;                  
                %heat_in_1(1:end) =  Q2/(NR+W);
                heat2(1:NR-W) =  Q12+Q22;
                %heat_in_2(1:end) =  Q1/(NR+W);
            else
                %seperated layers
                heat1(1:NR-W) = Q11;
                heat2(1:NR-W) = Q22;
            end
            
            %%%%%%%%%%%  update resistors
            [R1 , Rin1, states1 ,states_in1] = update_resistors_SC(NR, W, R1, Rin1, heat1, heat_in_1, Ic1, Ic_in1, Tc1, Tcin1, Rhot, RSc, currents1, cin1,T0, states1 ,states_in1);
            [R2 , Rin2, states2 ,states_in2] = update_resistors_SC(NR, W, R2, Rin2, heat2, heat_in_2, Ic2, Ic_in2, Tc2, Tcin2, Rhot, RSc, currents2, cin2,T0, states2 ,states_in2);

%             [N1, between1, SC1] = states_follower(states1, L, W);
%             [N2, between2, SC2] = states_follower(states2, L, W);
%             figure(11); plot(1:length(N1),N1,1:length(between1),between1,1:length(SC1),SC1);
%             figure(11); plot(1:length(N1(2:2:end)),N1(2:2:end),1:length(between1(2:2:end)),between1(2:2:end),1:length(SC1(2:2:end)),SC1(2:2:end));
%             legend('normal state','intermediate state','superconducting state');
            
            if states_movie_flag
                [frame] = set_movie_states(T0,N1, between1, SC1);
%                 frame.cdata = imresize(frame.cdata, [560]);
                writeVideo(v , frame);
            end

            iter_per_T = [iter_per_T iter];
            R1_per_T = [R1_per_T V1(end)/Itotal1];
            R2_per_T = [R2_per_T V2(end)/Itotal2];
 
            if movie_flag
%                 [frame ,handles] = set_frame_for_movie_two_layers_states_new(i,T0, Rhot, [states_in1 states1], [states_in2 states2] ,nodes, connections, T_range, R1_all, R2_all, R1_per_T, R2_per_T, iter_per_T,handles,iter);
                [frame ,handles] = set_frame_for_movie_two_layers_states_and_currents(i,T0, Rhot, [states_in1 states1], [states_in2 states2] ,nodes, connections, T_range, R1_all, R2_all, R1_per_T, R2_per_T, iter_per_T,handles,iter,[cin1 currents1],[cin2 currents2]);
                frame.cdata = imresize(frame.cdata, [975, 1920]);
                writeVideo(v , frame);
            end  
        end
        
        if finish
            break
        end

        %%%% resistence
        R1_all(i) = V1(end)/Itotal1;
        R2_all(i) = V2(end)/Itotal2;
        iterations(i) = iter;

        % add frame to the movie
        if movie_flag
%             [frame,handles] = set_frame_for_movie_two_layers_states_new(i,T0, Rhot, [states_in1 states1], [states_in2 states2] ,nodes, connections, T_range, R1_all, R2_all, R1_per_T, R2_per_T, iter_per_T,handles,iter);
            [frame ,handles] = set_frame_for_movie_two_layers_states_and_currents(i,T0, Rhot, [states_in1 states1], [states_in2 states2] ,nodes, connections, T_range, R1_all, R2_all, R1_per_T, R2_per_T, iter_per_T,handles,iter,[cin1 currents1],[cin2 currents2]);
            frame.cdata = imresize(frame.cdata, [975, 1920]);
            writeVideo(v , frame);
        end

        [T0 R1_all(i) R2_all(i) iter]

    end
       
    if plateau
        plateau_structor(p).T = T0;
        plateau_structor(p).iter = iter_per_T;
        plateau_structor(p).R1 = R1_per_T;
        plateau_structor(p).R2 = R2_per_T;
    end
    
    if finish
        finish = 0;
        continue
    end
    
    % finish movie
    if movie_flag
        close(v);
    end
    if states_movie_flag
        close(v);
    end
        
end

    if heat
        description ='heating';
    elseif ~heat
        description ='cooling';
    end
    
    if plateau
        %ploting plateau results
        figure; hold on;
        for iii = 1:length(plateau_vec)
            legendlist{iii} = ['T = ', num2str(plateau_structor(iii).T)];
            plot(plateau_structor(iii).iter, plateau_structor(iii).R1,'-o');    
        end   
        title(['the plateau effect for ',description,': I=',num2str(I), ', L=' ,num2str(L)]);
        legend(legendlist, 'Location', 'best');
        ylabel('R (\Omega)');
        xlabel('iterations');
    else    
        %ploting regular results
        figure;
        hold on;
        plot(T_range, R1_all,'-ro', T_range, R2_all,'-bo');
        title(['Resistence  I =', num2str(I), ', Dt=', num2str(Dt), ', L=' , num2str(L), ', kappa=',num2str(kappa*(10^-6)), ', two layers ',description]);
        legend([description,' layer1'],[description,' layer2'], 'Location', 'best');
        ylabel('R (\Omega)');
        xlabel('T (K)');
    end
    
    %save results
%     if plateau
%         %saving plateau results
%         filename =  [description,'_sigma' ,num2str(sigma),'Iin' ,num2str(Itotal1*10^6),'Dt', num2str(Dt), 'L',num2str(L), 'k',num2str(kappa*(10^-6)),'_dep',num2str(dependent),'_plateau.mat'];
%         save(filename, 'plateau_structor');
%     else
%         %saveing regular results
%         filename = [description,'_sigma' ,num2str(sigma),'Iin' ,num2str(Itotal1*10^6),'Dt', num2str(Dt), 'L',num2str(L), 'k',num2str(kappa*(10^-6)),'_dep',num2str(dependent),'.mat'];
%         save(filename, 'T_range','R1_all','R2_all','iterations');
%     end
    
end
end
end
end
end

toc