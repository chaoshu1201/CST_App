% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncSLLObjValCalcMaxTrunc(ExportFolder, FileName, NpTheta, NpPhi, GoalVal, RangeVec, Weight)

    % Load exported file of Farfield
    FullExpFarfieldFile = fullfile(ExportFolder, FileName);
    [DirLHCP, DirRHCP, DirABS, AR] = FuncExpFarfieldDataProc(FullExpFarfieldFile, NpTheta, NpPhi);

    %Get SLL in Phi=45 plane
    DirLHCP_cut = DirLHCP(2,:);
    DirRHCP_cut = DirRHCP(2,:);
    SLLVal = FuncSLLValGet(DirLHCP_cut, DirRHCP_cut);
    
    
    ObjectiveVal = max((SLLVal - GoalVal), 0);
    ObjectiveVal = ObjectiveVal*Weight;
end
