clear all;
close all;
%Video input file
v = VideoReader('NES Longplay [456] Pinball.avi');

%Specify that reading should begin 2.5 seconds from the beginning of the video.
v.CurrentTime = 260;

%Parameter to decide the colour filtering
colour_thres = 1.55;

%Flag to differenciate the first iteration from the following
count = 0;

%We need this to identify a certain color
c_thres = 12;
    
%%%%%%%%%%%%%%%%%%%
%%Particle filter%%
%%%%%%%%%%%%%%%%%%%

%Size of the particles
particle_size = 1;

%Size of the centroid
c_size = 4;

%outputVideo = VideoWriter('out.avi');
threshold_square = 30;

%Get image size x - vertical y - horizontal
[xp,yp,~] = size(readFrame(v));
% Parameter Initialization
[Sp,Rp,Qp,Lambda_psi] = init_Particles(xp,yp);

%%%%%%%%%%%%%%%%%
%%Kalman filter%%
%%%%%%%%%%%%%%%%%

%Parameters initialization
[R,Q,A,C] = kalmanInit(1);

while hasFrame(v)
    %Frame matrix
    vidFrame = readFrame(v); 
    tic
    
    %Filters the image and transforms it in a binary image. White will
    %represent high intensity colours and black the background. The put put
    %format is RGB so we can represent colorful particles
    [RGB, out] = imageTransformation(vidFrame,colour_thres,[187,187,187],c_thres);
   
    %Particle_filters algorithm to calculate the particles in each time
    %step
    [Sp] = Particles_filters(Sp,Rp,xp,yp,out,particle_size);
    
    %Centroid calculation
    centroid_aux = mean(Sp,2);
    centroid = centroid_aux(1:2);
    
    %This function represents the particles in the binary and original
    %pictures and compute the distances of each particle to the centroid in
    %ascending order
    [vidFrame, RGB, distance] = particle_distance_and_out( vidFrame ,RGB, Sp,centroid,particle_size,c_size );
    
    %We calculate the roundness of the cloud to see if it is ocluded
    [roundness,param] = roundness_calc(Sp, threshold_square);
    roundness
    %Parameters initialization
    [R,Q,A,C] = kalmanInit(param);

    % (1) If we are at t = 0, we obtain the centroid and set it as 
    % the initial point. We use a variable count to know at which 
    % time step are we currently.
    if count == 0
        mu = centroid;
        x1 = centroid; % initial position (t=0)
        count = count+1;
    % (2) When we are at t=1, we are able to obtain the initial
    % speed as the difference of the position at t=1 and t=0.
    % Next, we also initialize the initial covariance matrix
    % with an arbitrary value (high, since we are at the
    % beginning and we are not really sure!)
    elseif  count == 1
        x2 = centroid; % position at t=1
        vv = x2 - x1; % initial speed
        x = [x2(1); x2(2); vv(1); vv(2)]; % Initial state
        Sigma = 10*eye(4); % Uncertainty at the beginning
        % Prediction step
        [mu_bar, Sigma_bar] = kalmanPredict(x, Sigma, A, R);
        z = x2; % obtain measure (should be from PF)
        % Update step
        [mu, Sigma] = kalmanUpdate(mu_bar, Sigma_bar, z, C, Q);
        count = count+1;
    % (3) We enter this whenever t>=1. We proceed as following. 
    else
        % Prediction step
        [mu_bar, Sigma_bar] = kalmanPredict(mu, Sigma, A, R);

        % Measurement (should come from Particle Filter)
        z = centroid;


        % Update step
        [mu, Sigma] = kalmanUpdate(mu_bar, Sigma_bar, z, C, Q);
        count = count+1; 
     
    end
    if mu(1) >= xp - 4
        mu(1) = xp - 4;
    end
    if mu(2) >= yp - 4
         mu(2) = yp - 4;
    end
    vidFrame(abs(round(mu(1))-4 + 1):round(mu(1))+4,abs(round(mu(2))-4 +1):round(mu(2))+4,2) = 256;
    RGB(abs(round(mu(1))-4 + 1):round(mu(1))+4,abs(round(mu(2))-4 +1):round(mu(2))+4,:) = 0;
    RGB(abs(round(mu(1))-4 + 1):round(mu(1))+4,abs(round(mu(2))-4 +1):round(mu(2))+4,2) = 256;

    %Calculate the max size of the square that will be painted around the
    %object
    
    [max_distance_x, max_distance_y] = rect_size(xp,yp,centroid(1),centroid(2),threshold_square,Sp,distance);
    [max_distance_x_K, max_distance_y_K] = rect_size(xp,yp,mu(1),mu(2),threshold_square,Sp,distance);

    subplot(2,1,1); image(RGB); axis image
    hold on
    rectangle('position',[centroid(2)-max_distance_y centroid(1)-max_distance_x 2*max_distance_y 2*max_distance_x], 'EdgeColor','r')
    hold on
    rectangle('position',[abs(mu(2)-max_distance_y_K) abs(mu(1)-max_distance_x_K) abs(2*max_distance_y_K) abs(2*max_distance_x_K)], 'EdgeColor','g')
    hold off
    subplot(2,1,2); image(vidFrame); axis image
    hold on
    rectangle('position',[centroid(2)-max_distance_y centroid(1)-max_distance_x 2*max_distance_y 2*max_distance_x], 'EdgeColor','r')
    hold on
    rectangle('position',[abs(mu(2)-max_distance_y_K) abs(mu(1)-max_distance_x_K) abs(2*max_distance_y_K) abs(2*max_distance_x_K)], 'EdgeColor','g')
    hold off
    %We ensure the video output has the same frame rate as the origina
    pause(abs((1/v.FrameRate)-toc));
    
end