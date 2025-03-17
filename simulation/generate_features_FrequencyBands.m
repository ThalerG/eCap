results_Folder = "Results";

files = dir(fullfile(results_Folder, '*'));
files = files(~[files.isdir]);

pattern = '^\d+_\d+\.mat$';
files = files(~cellfun('isempty', regexp({files.name}, pattern)));

file = files(1);
data = load(fullfile(file.folder, file.name));
I_features = extract_fft_features(data.I_Out, 1/data.dt);
V_source_features = extract_fft_features(data.V_DC, 1/data.dt);

% Add prefixes to the field names
V_source_features = prefix_struct_fields(V_source_features, 'V_source_');
I_features = prefix_struct_fields(I_features, 'I_Out_');

% Add parameters
V_source_features = extract_parameters(data,V_source_features);

% Combine the structs
T_FFT = [struct2table(I_features,'AsArray',true), struct2table(V_source_features,'AsArray',true)];

parfor i = 2:length(files)
    file = files(i);
    data = load(fullfile(file.folder, file.name));
    I_features = extract_fft_features(data.I_Out, 1/data.dt);
    V_source_features = extract_fft_features(data.V_DC, 1/data.dt);

    % Add prefixes to the field names
    V_source_features = prefix_struct_fields(V_source_features, 'V_source_');
    I_features = prefix_struct_fields(I_features, 'I_Out_');
    
    % Add parameters
    V_source_features = extract_parameters(data,V_source_features);

    % Combine the structs
    T_FFT(i,:) = [struct2table(I_features,'AsArray',true), struct2table(V_source_features,'AsArray',true)];
end

save("FFT_features_table.mat","T_FFT")
T = load("features_table.mat");

% Convert loaded struct to table
T = struct2table(T);

% Combine tables based on common columns
common_columns = intersect(T_FFT.Properties.VariableNames, T.Properties.VariableNames);
T_combined = join(T_FFT, T, 'Keys', common_columns);

% Save the combined table
save("combined_features_table.mat", "T_combined");

function [parameters] = extract_parameters(data, parameters)
    if nargin < 2
        parameters = struct();
    end
    parameters.freq_ref = data.freq_ref;
    parameters.I_ref = data.I_ref;
    parameters.capacitor_C = data.capacitor_C;
    parameters.capacitor_R = data.capacitor_R;
    parameters.source_L = data.source_L;
    parameters.source_R = data.source_R;
end

function prefixed_struct = prefix_struct_fields(s, prefix)
    fields = fieldnames(s);
    for i = 1:numel(fields)
        prefixed_struct.([prefix fields{i}]) = s.(fields{i});
    end
end

function [features] = extract_fft_features(X, fs)
    % Inputs:
    % X: Nx3 matrix of 3-phase time series (each column is a phase)
    % fs: Sampling frequency (Hz)

    features = struct();
    
    % Frequency-domain features
    N = size(X, 1); % Number of samples
    f = (0:N-1) * (fs / N); % Frequency vector
    X_fft = fft(X); % FFT of each phase
    X_fft_mag = abs(X_fft / N); % Magnitude of FFT
    % Define 1/3 octave band filters
    % Calculate center frequencies based on fs
    min_freq = 12.5; % Minimum frequency of interest
    max_freq = fs / 2; % Maximum frequency is the Nyquist frequency
    num_bands = 33; % Number of bands

    % Calculate center frequencies using geometric progression
    center_frequencies = min_freq * (2 .^ ((0:num_bands-1) / 3));
    center_frequencies = center_frequencies(center_frequencies <= max_freq);
    bands = [center_frequencies / (2^(1/6)); center_frequencies * (2^(1/6))];
    
    % Store the band-filtered magnitudes as features
    if size(X, 2) > 1
        for phase = 1:3
            for b = 1:length(center_frequencies)
                band_indices = (f >= bands(1, b) & f < bands(2, b));
                features.(['Band_' strrep(num2str(center_frequencies(b)), '.', '_') '_Phase_' char(64+phase)]) = sum(X_fft_mag(band_indices, phase));
            end
        end
    else
        for b = 1:length(center_frequencies)
            band_indices = (f >= bands(1, b) & f < bands(2, b));
            features.(['Band_' strrep(num2str(center_frequencies(b)), '.', '_')]) = sum(X_fft_mag(band_indices));
        end
    end
end
