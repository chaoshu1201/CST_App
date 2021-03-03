% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function ObjectiveVal = FuncRotSymObjValCalcMse(ThetaFarfield, DirCoNorm, Taper, GoalVal, RangeVec, Weight)

    % Get the real taper angle
    TaperAng = FuncTaperAngleGet(ThetaFarfield, DirCoNorm, Taper);
    AngRange = [-TaperAng TaperAng];
    % Find the theta range
    Index = ((ThetaFarfield>=AngRange(1))&(ThetaFarfield<=AngRange(2)));
    theta = ThetaFarfield(Index);
    theta_max = max(theta);
    RadPatWeightVec = 10.^((-1)*(abs(theta)/theta_max));
    
    % Calculate differene between 0/45/90 and average beam
    SampleNum = length(theta);
    DirCoAvg = (DirCoNorm(1,Index) + DirCoNorm(2,Index) + DirCoNorm(3,Index))/3;
    MseVec(1) = sum((DirCoNorm(1,Index) - DirCoAvg).^2.*RadPatWeightVec)/SampleNum;
    MseVec(2) = sum((DirCoNorm(2,Index) - DirCoAvg).^2.*RadPatWeightVec)/SampleNum;
    MseVec(3) = sum((DirCoNorm(3,Index) - DirCoAvg).^2.*RadPatWeightVec)/SampleNum;
    MseSum = sum(MseVec);
    %Diff(1,:) = ((DirCoNorm(1,Index) - DirCoAvg)./DirCoAvg).^2;
    %Diff(2,:) = ((DirCoNorm(2,Index) - DirCoAvg)./DirCoAvg).^2;
    %Diff(3,:) = ((DirCoNorm(3,Index) - DirCoAvg)./DirCoAvg).^2;
    
    %DiffSum = Diff(1,:) + Diff(2,:) + Diff(3,:);
    %DiffSum((length(theta)+1)/2) = 0;
    
    % Calculate Objective value
    ObjectiveVal = MseSum*Weight;
    
end
