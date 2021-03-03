% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncARObjValCalcMaxTrunc(ExportFolder, FileName, NpTheta, NpPhi, GoalVal, RangeVec, Weight)

    % Load exported file of Farfield
    FullExpFarfieldFile = fullfile(ExportFolder, FileName);
    [DirLHCP, DirRHCP, DirABS, AR] = FuncExpFarfieldDataProc(FullExpFarfieldFile, NpTheta, NpPhi);
    
    ThetaStep = 360/NpTheta;
    Theta = [-180:ThetaStep:180];

    %Get Phi=45 plane
    AR_cut = AR(2,:);
    
    Index = find(((Theta>=RangeVec(1))&(Theta<=RangeVec(2))));
    
    %plot(Freq(Index), AR(Index));
    %grid minor;
    
    %ObjectiveVal = sum(AR(Index) - GoalVal)/length(Index);
    ObjectiveVal = sum(max((AR_cut(Index) - GoalVal),0));
    ObjectiveVal = ObjectiveVal*Weight;
end
