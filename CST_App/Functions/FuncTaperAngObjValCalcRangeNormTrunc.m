% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncTaperAngObjValCalcRangeNormTrunc(ThetaFarfield, DirCoNorm, Taper, GoalRange, Weight)

    % Get the max Taper Angle of the Radiation Patterns
    TaperAng = FuncTaperAngleGet(ThetaFarfield, DirCoNorm, Taper);
    
    RangeCent = mean(GoalRange);
    if ((TaperAng >= GoalRange(1)) && (TaperAng <= GoalRange(2)))
        ObjectiveVal = 0;
    else
        ObjectiveVal = abs(TaperAng - RangeCent)/RangeCent;
    end
    
    ObjectiveVal = ObjectiveVal * Weight;

end
