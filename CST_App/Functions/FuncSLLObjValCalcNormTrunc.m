% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncSLLObjValCalcNormTrunc(DirCoNorm, GoalVal, RangeVec, Weight)

    % Get Max SLL of all cuts
    SLLValMax = FuncSLLValMaxGet(DirCoNorm);
    
    ObjectiveVal = max((SLLValMax - GoalVal), 0)/(abs(GoalVal)/2);
    ObjectiveVal = ObjectiveVal*Weight;
end
