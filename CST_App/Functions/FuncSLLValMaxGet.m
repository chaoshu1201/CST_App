% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function SLLValMax = FuncSLLValMaxGet(DirCoNorm)

    CutNum = size(DirCoNorm, 1);
    for i=1:1:CutNum
        % Get peaks of each cut
        [pks, loc] = findpeaks(DirCoNorm(i,:));
        
        % Sort peaks in ascending order
        pks_sort = sort(pks);
        
        % Note that pks_sort(end-1) is not always the 1st sidelobe, it is the highest
        % sidelobe
        if 1 == length(pks_sort)   %No sidelobes
            SLLVal(i) = -128; %Set SLLVal to a vaule that will always be lower than the goal
        else
            SLLVal(i) = pks_sort(end-1);
        end
    end
    
    SLLValMax = max(SLLVal);
  
end
