Ts   = 1e-6;    % Fundamental sample time       [s]
fsw  = 10000;   % Inverter switching frequency [Hz]

% Kp_vd = Kp;   % Proportional term d-axis voltage controller
% Ki_vd = I;    % Integral term d-axis voltage controller
% Kp_vq = Kp;   % Proportional term q-axis voltage controller
% Ki_vq = I;    % Integral term q-axis voltage controller 
Kp_i = 0.0405;   % Proportional term dynamometer controller
Ki_i = 36.06;    % Integral term dynamometer controller

Lm = 0.1486;

Rs = 0.6837;
Lls = 0.004152;
Ls = Lls+Lm;

Rr = 0.451;
Llr = 0.004152;
Lr = Llr+Lm;

% Rs = 0.33;
% Ls = 1.38e-3;
% 
% Rr = 0.16;
% Lr = 0.717e-3;
% 
% Lm = 38e-3;

Bw = fsw/20;

Rdq = Rs+Rr*(Lm/Lr)^2;

sigma = 1-Lm^2/(Ls*Lr);

Ldq = sigma*Ls/Rdq;

Kp = Bw*Ldq;
Ki = Bw*Rs;

Kp_vq = Kp;
Ki_vq = Ki;

Kp_vd = Kp;
Ki_vd = Ki;

Vref = 380;     % Reference voltage (ph-ph, RMS)

DEAD_TIME_US1 = 0;
