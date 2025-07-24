mdl = 'model_sys';
open_system(mdl)

% Simulation parameters
Tf = 0.5;         % Simulation end time
Ts = 1e-5;        % Simulation step
T_save_start = 0.3; % Start of data logging
fsw = 10000;      % PWM switching frequency

% Simulation space
load_sim_space;

% Controller parameters
load_control_params;

% Build all simulations from the parameter table tab_combs
siminputs = [];
% for k = 1:height(tab_combs)
for k = 1:4
  siminput = Simulink.SimulationInput(mdl);
  siminput = siminput.setVariable('capacitor_C',tab_combs{k,"capacitor_C"},'Workspace',mdl);
  siminput = siminput.setVariable('capacitor_R',tab_combs{k,"capacitor_R"},'Workspace',mdl);
  siminput = siminput.setVariable('source_L', tab_combs{k,"source_L"},'Workspace',mdl);
  siminput = siminput.setVariable('source_R', tab_combs{k,"source_R"},'Workspace',mdl);
  siminput = siminput.setVariable('freq_ref', tab_combs{k,"frequency_ref"},'Workspace',mdl);
  siminput = siminput.setVariable('I_ref', tab_combs{k,"I_ref"},'Workspace',mdl);
  siminputs = [siminputs,siminput];
end

% Folder to store results
folder = fullfile(pwd,'Results');
if ~exist(folder,'dir')
  mkdir(folder)
else
  delete(fullfile(folder,'*.mat'))
end

% Run simulations
[ok,e] = generateSimulationEnsemble(siminputs,folder, "UseParallel", true);