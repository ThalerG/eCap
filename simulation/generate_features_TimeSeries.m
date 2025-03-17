results_Folder = "Results";

files = dir(fullfile(results_Folder, '*'));
files = files(~[files.isdir]);

pattern = '^\d+_\d+\.mat$';
files = files(~cellfun('isempty', regexp({files.name}, pattern)));

file = files(1);
data = load(fullfile(file.folder, file.name));
I_features = extract_features(data.I_Out, 1/data.dt);
V_source_features = statistical_features(data.V_DC);

% Add prefixes to the field names
V_source_features = prefix_struct_fields(V_source_features, 'V_source_');
I_features = prefix_struct_fields(I_features, 'I_Out_');

% Add parameters
V_source_features = extract_parameters(data,V_source_features);

% Combine the structs
T = [struct2table(I_features,'AsArray',true), struct2table(V_source_features,'AsArray',true)];

parfor i = 2:length(files)
    file = files(i);
    data = load(fullfile(file.folder, file.name));
    I_features = extract_features(data.I_Out, 1/data.dt);
    V_source_features = statistical_features(data.V_DC);

    % Add prefixes to the field names
    V_source_features = prefix_struct_fields(V_source_features, 'V_source_');
    I_features = prefix_struct_fields(I_features, 'I_Out_');
    
    % Add parameters
    V_source_features = extract_parameters(data,V_source_features);

    % Combine the structs
    T(i,:) = [struct2table(I_features,'AsArray',true), struct2table(V_source_features,'AsArray',true)];
end

save("features_table.mat","T")

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

function [features] = statistical_features(X, features, term)
    if nargin < 2
        features = struct();
    end
    
    if nargin < 3
        term = '';
    end

    if size(X, 2) > 1
        for kP = 1:size(X, 2)
            switch kP
                case 1
                    term = '_A';
                case 2
                    term = '_B';
                case 3
                    term = '_C';
                otherwise
                    term = ['_',num2str(kP)];
            end
            
            features = statistical_features(X(:, kP), features, term);
        end
    else
        % Time-domain features
        features.(['RMS' term]) = rms(X); % RMS
        features.(['Peak' term]) = max(abs(X)); % Peak
        features.(['Mean' term]) = mean(X); % Mean
        features.(['StdDev' term]) = std(X); % Standard deviation
        features.(['CrestFactor' term]) = max(abs(X)) ./ rms(X); % Crest factor
        features.(['FormFactor' term]) = rms(X) ./ mean(abs(X)); % Form factor
        features.(['Skewness' term]) = skewness(X); % Skewness
        features.(['Kurtosis' term]) = kurtosis(X); % Kurtosis
    end
end

function [features] = extract_features(I, fs)
    % Inputs:
    % I: Nx3 matrix of 3-phase current time series (each column is a phase)
    % fs: Sampling frequency (Hz)

    features = statistical_features(I);
    
    % Current unbalance
    avg_current = mean(I, 2); % Average current across phases
    deviation = I - avg_current;
    features.Unbalance = max(abs(deviation), [], 1) ./ mean(abs(I), 1) * 100; % Unbalance (%)

    % Symmetrical components
    a = exp(1j * 2 * pi / 3); % 120-degree phase shift
    I0 = (I(:,1) + I(:,2) + I(:,3)) / 3; % Zero-sequence current
    I1 = (I(:,1) + a * I(:,2) + a^2 * I(:,3)) / 3; % Positive-sequence current
    I2 = (I(:,1) + a^2 * I(:,2) + a * I(:,3)) / 3; % Negative-sequence current
    % features.ZeroSeq = I0;
    % features.PosSeq = I1;
    % features.NegSeq = I2;

    % Frequency-domain features
    N = size(I, 1); % Number of samples
    f = (0:N-1) * (fs / N); % Frequency vector
    I_fft = fft(I); % FFT of each phase
    I_fft_mag = abs(I_fft / N); % Magnitude of FFT
    I_fft_phase = angle(I_fft); % Phase of FFT

    % Detect the fundamental frequency
    [~, idx] = max(I_fft_mag(1:floor(N/2), :)); % Find index of the fundamental frequency
    features.FundamentalFreq = f(idx(1)); % Fundamental frequency
    FundamentalMag = I_fft_mag(idx(1), :); % Magnitude at fundamental Hz
    features.FundamentalMag_A = FundamentalMag(1);
    features.FundamentalMag_B = FundamentalMag(2);
    features.FundamentalMag_C = FundamentalMag(3);

    FundamentalPhase = I_fft_phase(idx(1), :); % Phase at fundamental Hz
    features.FundamentalPhase_A = FundamentalPhase(1);
    features.FundamentalPhase_B = FundamentalPhase(2);
    features.FundamentalPhase_C = FundamentalPhase(3);

    % Harmonic distortion (up to 10th harmonic)
    if size(I,2) == 1
        features.THD = thd(I, fs, 10); % Total harmonic distortion
    else
        features.THD_A = thd(I(:,1), fs, 10); % Total harmonic distortion A
        features.THD_B = thd(I(:,2), fs, 10); % Total harmonic distortion B
        features.THD_C = thd(I(:,3), fs, 10); % Total harmonic distortion C
    end

    % Entropy
    Entropy = zeros(1, 3);
    for phase = 1:3
        Entropy(phase) = entropy(I(:, phase)); % Entropy of each phase
    end

    features.Entropy_A = Entropy(1);
    features.Entropy_A = Entropy(2);
    features.Entropy_A = Entropy(3);
    
end