% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncObjValCalcAbs(ExportFolder, FileName, GoalVal, RangeVec, Weight)

    % Load exported file of S-parameters
    FullDataFile = fullfile(ExportFolder, FileName);
    Data = load(FullDataFile);
    
    X_Vec = Data(:,1)';
    Y_Vec = Data(:,2)';
    
    Index = find(((X_Vec>=RangeVec(1))&(X_Vec<=RangeVec(2))));
    
    %plot(Freq(Index), AR(Index));
    %grid minor;
    
    %ObjectiveVal = sum(AR(Index) - GoalVal)/length(Index);
    ObjectiveVal = sum(abs(Y_Vec(Index) - GoalVal));
    ObjectiveVal = ObjectiveVal*Weight;
end
