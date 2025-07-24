% References for the inverter and motor control
freq_ref_all = [30, 40, 50, 60]; % Frequency
I_ref_all = [4.5, 5.5, 6.5];     % Load current

% Source impedances (LR)
source_L = {0, 0.3e-3, 0.6e-3, 1e-3, 1.8e-3, 3.5e-3, 5e-3, 8e-3, 15e-3, 25e-3, 165e-3};
source_R = {0, 0.1, 0.2, 0.3, 0.5, 1, 1.5, 2.5, 5, 8, 12.5};
source_impedance = struct("L",source_L,"R",source_R);

% Capacitor parameters (RC)
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

% Build test conditions. Total number of tests:
% len(capacitor_params)*len(source_imp)*len(freq_ref)*len(I_load_ref)
[freq_ref_all,I_ref_all] = ndgrid(freq_ref_all,I_ref_all);

tab_combs = table(freq_ref_all(:),I_ref_all(:), 'VariableNames', ["frequency_ref","I_ref"]);

tab_combs{:,"capacitor_C"} = capacitor_all(1).C;
tab_combs{:,"capacitor_R"} = capacitor_all(1).R;

tab_temp = tab_combs;

for k = 2:length(capacitor_all)
    tab_temp{:,"capacitor_C"} = capacitor_all(k).C;
    tab_temp{:,"capacitor_R"} = capacitor_all(k).R;
    tab_combs = [tab_combs;tab_temp];
end

tab_combs{:,"source_L"} = source_impedance(1).L;
tab_combs{:,"source_R"} = source_impedance(1).R;

tab_temp = tab_combs;

for k = 2:length(source_impedance)
    tab_temp{:,"source_L"} = source_impedance(k).L;
    tab_temp{:,"source_R"} = source_impedance(k).R;
    tab_combs = [tab_combs;tab_temp];
end

% Clear temporary vars
clear tab_temp freq_ref_all I_ref_all capacitor_all source_impedance source_L source_R k