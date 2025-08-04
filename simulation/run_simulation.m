mdl = 'model_sys';
open_system(mdl)

% Simulation parameters
Tf = 10;         % Simulation end time
Ts = 1e-6;        % Simulation step
T_save_start = 9.5; % Start of data logging
fsw = 10000;      % PWM switching frequency

% Simulation space
load_sim_space;

% Controller parameters
load_control_params;

% Build all simulations from the parameter table tab_combs
siminputs = [];

for k = 1:height(tab_combs)
  siminput = Simulink.SimulationInput(mdl);
  siminput = siminput.setVariable('Tf',Tf);
  siminput = siminput.setVariable('Ts',Ts);
  siminput = siminput.setVariable('T_save_start',T_save_start);
  siminput = siminput.setVariable('fsw',fsw);
  siminput = siminput.setVariable('capacitor_C',tab_combs{k,"capacitor_C"},'Workspace',mdl);
  siminput = siminput.setVariable('capacitor_R',tab_combs{k,"capacitor_R"},'Workspace',mdl);
  siminput = siminput.setVariable('source_L', tab_combs{k,"source_L"},'Workspace',mdl);
  siminput = siminput.setVariable('source_R', tab_combs{k,"source_R"},'Workspace',mdl);
  siminput = siminput.setVariable('freq_ref', tab_combs{k,"frequency_ref"},'Workspace',mdl);
  siminput = siminput.setVariable('I_ref', tab_combs{k,"I_ref"},'Workspace',mdl);
  siminput = siminput.setModelParameter("LoggingFileName", ...
      char(strcat("/media/ntfs/Documentos/LIAE/eCap/Results/",num2str(k),".mat")),...
                    'DatasetSignalFormat', 'timetable',...
                    'SaveFormat', 'Dataset',...
                    'SignalLogging', 'on', ...
                    'LoggingToFile', 'on',...
                    'SimulationMode', 'rapid', ...
                    'RapidAcceleratorUpToDateCheck', 'off');
  siminputs = [siminputs,siminput];
end

writetable(tab_combs, strcat("/media/ntfs/Documentos/LIAE/eCap/Results/", 'tab_combs.csv'));

% Folder to store results
folder = fullfile(pwd,'Results');
if ~exist(folder,'dir')
  mkdir(folder)
else
  delete(fullfile(folder,'*.mat'))
end

% Run simulations
out = parsim(siminputs, 'SetupFcn', @() build_accelerator(mdl));

function build_accelerator(mdl)
    % Temporarily change the current folder on the workers to an empty
    % folder so that any existing slprj folder on the client does not
    % interfere in the build process.
    currentFolder = pwd;
    tempDir = tempname;
    mkdir(tempDir);
    cd (tempDir);
    oc = onCleanup(@() cd (currentFolder));
    Simulink.BlockDiagram.buildRapidAcceleratorTarget(mdl);
end