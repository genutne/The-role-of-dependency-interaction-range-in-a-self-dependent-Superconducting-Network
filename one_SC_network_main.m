tic
clear

% general structure of the network
W = 100; % width size
L = 100; % length size
NR = (2*W-1)*L; % number of links (without entrance)
NN = W*L; % number of nodes
epsilon = 10^(-5); % threshold for epsilon to determine that the system converged
kappa_own = 2*L^2*[5]*10^3; % kappa for the media in each layer, banyaRhot = 500; % the resistance in the Normal phase. 5*10^1
Rhot = 500; % the resistance in the Normal phase
RSc = 10^(-5); % the resistance in the SC (Super-Conducting) phase
Ic0 = 58*10^(-6); % avg critical current layer1
sigma_vec = [0.1]; % Level of disorder
sigma = 0.1;
Dt_vec = [0.5 0.6 0.7 1 3 9 L^2]; % Dt sets the level of heat diffusion [1:10 20:10:150] [0:0.2:0.9 1:10 20:10:150]
Itotal = 500*10^(-6);
Ti = 1.5;
Tf = 1.8;
Tjumps = 200;
dT = 10^-3;
movie_flag = 0; %change to 1 if you want to create a movie, note that it takes a lots of time
s_max = 1;

plateau_vec = nan;
% x = 1:100;
% f = @(x) (10.^(-5.05))*exp(0.11*x);
% TC = 1.912;
% plateau_vec = TC;

if isnan(plateau_vec)
    plateau = 0;
else
    plateau = 1;
end  

if plateau
    pl = struct('T',[],'iter',[],'R',[]);
    plateau_structor(length(plateau_vec)) = pl;
end
   
for s = 1:s_max
    
    % Ic for each resistor
    Ic_in = Ic0*(1+sigma*randn(1,NR));
    Ic = Ic0*(1+sigma*randn(1,NR));
    save(['Ic_zeros_W100_sig0.1_net',num2str(s),'.mat'],'Ic_in','Ic');
%     load(['Ic_zeros_W',num2str(W),'_sig',num2str(sigma),'.mat']); %load a setup
%     Ic_in = Ic_in1; 
%     Ic = Ic1; 
    figure;
    
for Dt = Dt_vec
    
for heating = [0] %change to 1 if you want to increase the temperature, 0 is for cooling
    for p = 1:length(plateau_vec)

        %seting the general currents vector
        I = zeros(1,NN+1);
        I(end) = Itotal;

        % vector currents for each link
        cin = zeros(1,W);
        currents = zeros(1,NR);

        % vector resistors for each link. we start with all at the Normal phase
        if heating
            Rin = RSc*ones(1,W);
            R = RSc*ones(1,NR);
        elseif ~heating
            Rin = Rhot*ones(1,W);
            R = Rhot*ones(1,NR);
        end
        
        % vector states for each link. 1=SC , 2=intermidiate , 3=normal.
        states_in = zeros(1,W);
        states = zeros(1,NR);

        % Tc for each resistor
        factor = 100;  % the 100 here can be modified but should be close to it to match the experiment
        Tc = factor*Rhot*Ic;
        Tcin = factor*Rhot*Ic_in;

        %temperature properties
%         T_range = linspace(Ti,Tf,Tjumps);
        T_range = Ti:dT:Tf;
        if ~heating
            T_range = flip(T_range); % cooling T range
        end
%         x = 1:100;
%         f = @(x) (10.^(-5.05))*exp(0.11*x);
%         TC = 1.9958;
%         T_range =  TC + f(x);
        if plateau %for plateau
            if heating
                T_range = [Ti plateau_vec(p)];
            elseif ~heating
                T_range = [Tf plateau_vec(p)];
            end
        end
        LT = length(T_range);
        iterations = zeros(1,LT);
        R_all = zeros(1,LT);

        %start creating a movie
        if movie_flag
            video_name = ['video_heating_Iin' ,num2str(Itotal*10^6),'Dt', num2str(Dt), 'L',num2str(L), '.avi'];
            %current_date = datestr(now, 'yyyy-mm-dd');
            v = VideoWriter(video_name);
            v.Quality = 50;
            open(v);
            %figure('visible','off');     tiledlayout(1,3);
            %figure;     tiledlayout(1,3);
%             figure;     tiledlayout(2,3);
            figure;     tiledlayout(2,2);
            handles = {};
            [nodes, connections] = creat_nodes_and_links_array(L, W);
        end

        for i=1:length(T_range)

            T0 = T_range(i); % heat-bath temperature T0
            finish = 0;
            iter = 0;
            flag = 0;                
            iter_per_T = [];
            R_per_T = [];

            cc1 = [];
            cc3 = [];

            while flag==0 
                iter = iter+1;

                %saving 2 last voltege results for exit condition
                if iter>2
                    Vold2 = Vold;
                end

                if iter>1
                    Vold = V;
                end

                % first, calculate the voltage at each node in the two networks    
                V = Voltage_nodes(L, W, NN, NR,Rin, R,I);

                % checking exit condition
                if iter>2
                    if norm(V-Vold2)/norm(V)<epsilon || norm(V-Vold)/norm(V)<epsilon
                        flag=1;
                    end

                    cc1 = [cc1 norm(V-Vold2)/norm(V)];
                    cc3 = [cc3 norm(V-Vold)/norm(V)];

                    if flag == 0 && iter>1005
    %                     if (norm(V1-V1old2)/norm(V1)<10^(-4) && norm(V2-V2old2)/norm(V2)<10^(-4)) || (norm(V1-V1old)/norm(V1)<10^(-4) && norm(V2-V2old)/norm(V2)<10^(-4))
    %                         flag=1;
    %                         ["Number of iterations is too high"]
    %                     end
                        if mean(cc1(end-1000:end-500))-mean(cc1(end-500:end-2))<10^(-5) || mean(cc3(end-1000:end-500))-mean(cc3(end-500:end))<10^(-5)
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
                [currents,cin,heat,heat_in] = find_currents(V, L, W, NN, NR, Rin, R,1);              

                % let the heat diffuse (only in the bulk, no exit/entrence nodes)       
                Q = heat_transfer_spectral(L,W,Dt,heat(1:NR-W)*kappa_own);
                heat(1:NR-W) = Q;

                [R , Rin, states ,states_in] = update_resistors_SC(NR, W, R, Rin, heat, heat_in, Ic, Ic_in, Tc, Tcin, Rhot, RSc, currents, cin,T0, states ,states_in);

                iter_per_T = [iter_per_T iter];
                R_per_T = [R_per_T V(end)/Itotal];

                if movie_flag
                    [frame ,handles] = set_frame_for_movie_one_layer_states_new(i,T0, Rhot, [states_in states],nodes, connections,T_range, R_all, R_per_T, iter_per_T,handles,iter,[cin currents]);
                    frame.cdata = imresize(frame.cdata, [975, 1920]);
                    writeVideo(v , frame);
                end
                
            end

            if finish
                break
            end

            %%%% resistence
            R_all(i) = V(end)/Itotal;
            iterations(i) = iter;

            % add frame to the movie
            if movie_flag
                [frame ,handles] = set_frame_for_movie_one_layer_states_new(i,T0, Rhot, [states_in states],nodes, connections,T_range, R_all, R_per_T, iter_per_T,handles,iter,[cin currents]);
                frame.cdata = imresize(frame.cdata, [975, 1920]);
                writeVideo(v , frame);
            end

            [s Dt T0 R_all(i) iter]

        end
        if plateau
            plateau_structor(p).T = T0;
            plateau_structor(p).iter = iter_per_T;
            plateau_structor(p).R = R_per_T;
        end
    end
       
    if finish
        finish = 0;
        continue
    end
    
    % finish movie
    if movie_flag
        close(v);
    end
    
    if heating
        description ='heating';
    elseif ~heating
        description ='cooling';
    end
    
    if plateau
        %ploting plateau results
        figure; hold on;
        for iii = 1:length(plateau_vec)
            legendlist{iii} = ['T = ', num2str(plateau_structor(iii).T)];
            plot(plateau_structor(iii).iter, plateau_structor(iii).R1);    
        end   
        title(['the plateau effect [',description,'], for: Ib=',num2str(Itotal*(10^6)), ', L=' ,num2str(L),' one layer']);
        legend(legendlist, 'Location', 'best');
        ylabel('R');
        xlabel('iterations');
    else    
        %ploting regular results
%         figure;
        hold on;
        plot(T_range, R_all,'-o');
        title(['Resistence by ',description,': ', 'I0 =', num2str(Itotal*10^6),' L=' , num2str(L), ', kappa=',num2str(kappa_own), ', one layer, net',num2str(s),'']);
        ylabel('R');
        xlabel('T(K)'); 
    end

    %save results
    if plateau
        %saving plateau results
        filename =  [description,'_sigma' ,num2str(sigma),'Iin' ,num2str(Itotal*10^6),'Dt', num2str(Dt), 'L',num2str(L), 'k',num2str(kappa_own), '_onelayer_plateau_net',num2str(s),'.mat'];
        save(filename, 'plateau_structor');
    else
        %saveing regular results
        filename = [description,'_sigma' ,num2str(sigma),'Iin' ,num2str(Itotal*10^6),'Dt', num2str(Dt), 'L',num2str(L), 'k',num2str(kappa_own), '_onelayer_net',num2str(s),'.mat'];
        save(filename, 'T_range','R_all','iterations');
    end

end
end
end

toc