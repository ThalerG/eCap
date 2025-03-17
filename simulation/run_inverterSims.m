clear; clc;

freq_ref_all = [30, 40, 50, 60];
I_ref_all = [4.5, 5.5, 6.5];

source_L = {0, 0.3e-3, 0.6e-3, 1e-3, 1.8e-3, 3.5e-3, 5e-3, 8e-3, 15e-3, 25e-3};
source_R = {0, 0.1, 0.2, 0.3, 0.5, 1, 1.5, 2.5, 5, 8};

source_impedance = struct("L",source_L,"R",source_R);



capacitor_all(1).C = 332e-6;
capacitor_all(1).R = 30e-3;

capacitor_all(2).C = 321e-6;
capacitor_all(2).R = 30e-3;

capacitor_all(3).C = 310e-6;
capacitor_all(3).R = 30e-3;

capacitor_all(4).C = 299e-6;
capacitor_all(4).R = 30e-3;

capacitor_all(5).C = 288e-6;
capacitor_all(5).R = 30e-3;

capacitor_all(6).C = 277e-6;
capacitor_all(6).R = 30e-3;

capacitor_all(7).C = 266e-6;
capacitor_all(7).R = 30e-3;

capacitor_all(8).C = 255e-6;
capacitor_all(8).R = 30e-3;

capacitor_all = struct("C",capacitor_C,"R",capacitor_R);

[freq_ref_all,I_ref_all] = ndgrid(freq_ref_all,I_ref_all);

tab_combs = table(freq_ref_all(:),I_ref_all(:), 'VariableNames', ["frequency_ref","I_ref"]);

tab_combs{:,"cap"} = capacitor_all(1);

tab_temp = tab_combs;

for k = 2:length(capacitor_all)
    tab_temp{:,"cap"} = capacitor_all(k);
    tab_combs = [tab_combs;tab_temp];
end

tab_combs{:,"source_impedance"} = source_impedance(1);

tab_temp = tab_combs;

for k = 2:length(source_impedance)
    tab_temp{:,"source_impedance"} = source_impedance(k);
    tab_combs = [tab_combs;tab_temp];
end

fBase = "Results\";
if ~isfolder(fBase)
    mkdir(fBase)
end

mdl = 'sim_inverter_MA';

chunk = 16;

count = 1;
for i = 769:height(tab_combs)
    fName = sprintf('%d' , i);
    fName = strcat(fName(1:end),'.mat');
    fName = char(strcat(fBase,fName));
    in(count) = Simulink.SimulationInput(mdl);
    in(count) = in(count).setVariable('freq_ref',tab_combs{i,"frequency_ref"});
    in(count) = in(count).setVariable('I_ref',tab_combs{i,"I_ref"});

    capacitor = tab_combs{i,"cap"};
    in(count) = in(count).setVariable('capacitor_C',capacitor.C);
    in(count) = in(count).setVariable('capacitor_R',capacitor.R);

    source_imp = tab_combs{i,"source_impedance"};
    in(count) = in(count).setVariable('source_L',source_imp.L);
    in(count) = in(count).setVariable('source_R',source_imp.R);
    in(count) = in(count).setModelParameter('LoggingToFile','on','LoggingFileName',fName,'SimulationMode','accelerator');

    count = count + 1;

    if count>chunk
        out = parsim(in, 'ShowProgress', 'on');
        add_params(in,out);
        clear in out;
        count = 1;
    end
end

if count>1
    out = parsim(in, 'ShowProgress', 'on');
    add_params(in,out);
    clear in out;
end


function [] = add_params(in, out)

parfor k = 1:length(out)
    varNames = {in(k).Variables.Name};
    varValues = [in(k).Variables.Value];
    parameters = struct();
    for kV = 1:length(varNames)
        parameters.(varNames{kV}) = varValues(kV);
    end
    
    fName = char(out(k).SimulationMetadata.ModelInfo.LoggingInfo.LoggingFileName);

    save_vars(parameters,fName)
end

end

function [] = save_vars(parameters, fname)

results = load(fname);
SimulationMetadata  = results.SimulationMetadata;
results = results.logsout.extractTimetable();
parameters.dt = seconds(results.Properties.TimeStep);
parameters.t0 = seconds(results.Properties.StartTime);
vars = results.Properties.VariableNames;

for kV = 1:length(vars)
    data.(vars{kV}) = results.(vars{kV})';
end

M = [fieldnames(data)' fieldnames(parameters)'; struct2cell(data)' struct2cell(parameters)'];
data=struct(M{:});

save(fname,"-struct","data")
save(strcat(fname(1:end-4),"_Meta"), "SimulationMetadata")

end