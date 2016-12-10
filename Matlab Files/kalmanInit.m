% function [R,Q,A,C,x,Sigma] = kalmanInit()
% This function initializes the parameters of the Kalman Filter
%
% Outputs:   
%           R             nXn
%           Q             mXm
%           A             nXn
%           C             mXn
%           x             nX1
%           Sigma         nXn
%
% Where n := length of state vector and m := length of measurement vector
%
function [R,Q,A,C] = kalmanInit()

dt = 1;

% Define system parameters
R = 10*eye(4); % Process noise
Q = 1*eye(2); % Measurement noise
A = [1,0,dt,0;
     0,1,0,dt;
     0,0,1,0;
     0,0,0,1]; % State transition matrix
C = [1, 0, 0, 0; 
     0, 1, 0, 0]; % Measurement - State mapping

end