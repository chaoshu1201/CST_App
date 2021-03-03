% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncARObjValCalcMax(ExportFolder, FileName, GoalVal, RangeVec, Weight)

    % Load exported file of S-parameters
    FullARFile = fullfile(ExportFolder, FileName);
    AR_data = load(FullARFile);
    
    Freq = AR_data(:,1)';
    AR = AR_data(:,2)';
    
    Index = find(((Freq>=RangeVec(1))&(Freq<=RangeVec(2))));
    
    %plot(Freq(Index), AR(Index));
    %grid minor;
    
    %ObjectiveVal = sum(AR(Index) - GoalVal)/length(Index);
    ObjectiveVal = sum(max((AR(Index) - GoalVal), 0));
    ObjectiveVal = ObjectiveVal*Weight;
end
