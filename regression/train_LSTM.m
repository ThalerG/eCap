% Create a datastore with the .mat files in the folder 'results'
folderPath = 'Results';
ds = signalDatastore(folderPath, "SignalVariableNames",["I_Out","V_DC","capacitor_C"],"ReadOutputOrientation","row");

transform_fcn = @(T) {[T.I_Out_RMS,T.V_DC]',T.capacitor_C};

[idxTrain,idxValidation, idxTest] = trainingPartitions(length(ds.Files), [0.7 0.1 0.2]);

dsTrain = subset(ds,idxTrain);
dsValidation = subset(ds,idxValidation);
dsTest = subset(ds,idxTest);

data = read(dsTrain);

numObservations = length(ds.Files);
numChannels = size(data{1},1);
numResponses = size(data{2},2);

reset(dsTrain)

%%

numHiddenUnits = 100;

layers = [ ...
    sequenceInputLayer(numChannels, Normalization="zscore")
    lstmLayer(numHiddenUnits, OutputMode="last")
    fullyConnectedLayer(numResponses)
    regressionLayer];

miniBatchSize = 10;

options = trainingOptions("adam", ...
    MaxEpochs=75, ...
    ValidationData= dsValidation, ...
    OutputNetwork="best-validation-loss", ...
    InitialLearnRate=0.005, ...
    SequenceLength="shortest", ...
    Plots="training-progress", ...
    MiniBatchSize=miniBatchSize, ...
    ExecutionEnvironment="parallel", ...
    Verbose= false);

net = trainNetwork(dsTrain,layers,options);