% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function SLLVal = FuncSLLValGet(DirCutPol1, DirCutPol2)

    % Get peaks from Directivity cut data
    [pks1, loc1] = findpeaks(DirCutPol1);
    [pks2, loc2] = findpeaks(DirCutPol2);
    
    % Sort peaks in ascending order
    pks1_sort = sort(pks1);
    pks2_sort = sort(pks2);
    
    % find co-pol according to the peak directivity
    % Note that pksx_sort(end-1) is not always the 1st sidelobe, it is the highest
    % sidelobe
    if pks1_sort(end) > pks2_sort(end)
        if 1 == length(pks1_sort)   %No sidelobes
            SLLVal = -128; %Set SLLVal to a vaule that will always be lower than the goal
        else
            SLLVal = pks1_sort(end-1) - pks1_sort(end);
        end
    else
        if 1 == length(pks2_sort)   %No sidelobes
            SLLVal = -128; %Set SLLVal to a vaule that will always be lower than the goal
        else
            SLLVal = pks2_sort(end-1) - pks2_sort(end);
        end
    end
end
