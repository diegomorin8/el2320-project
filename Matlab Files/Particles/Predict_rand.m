% function [S_bar] = predict(S,u,R)
% This function should perform the prediction step of MCL
% Inputs:
%           S(t-1)              3XM
%           R                   2x2
%          
% Outputs:
%           S_bar(t)            4XM

function [S_bar] = Predict_rand(S,R,x,y,particle_size)

%Number of particles
N = size(S,2);

%The prediction of the particles has ti be random in this case as we can
%not measure any odometry or movement of the object tracked
Mult_factor = 0.01;

dimensions = zeros(2,N);
dimensions(1,1:N) = x;
dimensions(2,1:N) = y;
S(1:2,:) = abs(S(1:2,:) + Mult_factor*dimensions.*randn(2,N));

Random_mat = randn(N,2)*R;

%We add a rows of zeros so the weight is not chenged, as we did for the
%matrix u
Normal_R = [Random_mat zeros(N,1)]';

%Diffusion
S = (round(S + Normal_R));

%Check dimension boundaries to make sure that all of the particles follow
%inside the image boundaries
for i = 1:size(S,2)
    if S(1,i) > (x - particle_size/2)
        S(1,i) = x - round(particle_size/2) - 1;
    end
    if S(2,i) > (y - particle_size/2)
        S(2,i) = y - round(particle_size/2) - 1;
    end
    if (S(1,i) < particle_size/2)||(S(1,i) == 0)
        S(1,i) = round(particle_size/2) + 1;
    end
    if (S(2,i) < particle_size/2)||(S(2,i) == 0)
        S(2,i) = 1 + round(particle_size/2);
    end
end

S_bar = abs(S);

end