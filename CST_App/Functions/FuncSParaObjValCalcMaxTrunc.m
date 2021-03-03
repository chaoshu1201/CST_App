% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncSParaObjValCalcMaxTrunc(ExportFolder, FileName, GoalVal, RangeVec, Weight)

    % Load exported file of S-parameters
    FullSParaFile = fullfile(ExportFolder, FileName);
    %SParaTable = importdata(FullSParaFile);
    SparaData = load(FullSParaFile);
    
    %Freq = SParaTable.data(:,1)';
    %S_Mag_dB = SParaTable.data(:,2)';
    %S_Phase = spara_data(:,3)';
    
    Freq = SparaData(:,1)';
    S_Mag = SparaData(:,2)';
    S_Mag_dB = 20*log10(S_Mag);
    S_Phase = SparaData(:,3)';
    
    Index = find(((Freq>=RangeVec(1))&(Freq<=RangeVec(2))));
    
    %plot(Freq(Index), S_Mag_dB(Index));
    %grid minor;
    
    %ObjectiveVal = sum(S_Mag_dB(Index) - GoalVal)/length(Index);
    ObjectiveVal = sum(max((S_Mag_dB(Index) - GoalVal), 0));
    ObjectiveVal = ObjectiveVal*Weight;
end
