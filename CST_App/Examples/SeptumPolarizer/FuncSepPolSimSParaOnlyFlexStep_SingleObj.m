% Copyright Chao Shu, 2018

% This function simluate an Axial Displaced Elliptical (ADE) reflector 
% Antenna with one structure
% Calculate the splines of the subreflector and main reflector of an Axial 
% Displaced Elliptical (ADE) reflector Antenna in Matlab
% Construct and simulate the ADE reflector Antenna with a nearfield source
% by using IE-Solver in CST
% Retrieve the farfield and export it into the specified export folder
% Return some key results to main function for analysis and plot.

function [ObjVal] = ...
         FuncSepPolSimSParaOnlyFlexStep_SingleObj(ParaValList)
    global IsOpen;
    global SimCnt;
    global CST;
    global Solver;
    global plot_ObjValVec;
    global plot_ObjVal;
    global ParaValMat;
    
    
    %% Project Settings
    ProjectFolder = 'G:\SeptumPolarizerWBandRTDHIsoOnlyFlexStep_Matlab_CMA';
    ExportFolder = fullfile(ProjectFolder, 'SeptumPolarizerWBandRTDHIsoOnlyFlexStep_Matlab_CMA', 'Export');

    MwsFileName = 'SeptumPolarizerWBandRTDHIsoOnlyFlexStep_Matlab_CMA.cst';
    FullProjFile = fullfile(ProjectFolder, MwsFileName);

    RangeVec = [90, 110];

    S11FileName = 'S-Parameters_S1(1),1(1).txt';
    S11GoalVal = -25; %dB
    S11Weight = 1;
    
    S21FileName = 'S-Parameters_S2(1),1(1).txt';
    S21GoalVal = -40; %dB
    S21Weight = 2;
    
    ARFileName = 'AR_AllFreq.txt';
    ARGoalVal = 0; %dB
    ARWeight = 8*10;
    
    %% Open project file
    if ~IsOpen
        CST = CST_MicrowaveStudio(ProjectFolder, MwsFileName);
        Solver = CST.mws.invoke('FDSolver');
        IsOpen = 1;
    end
    
    %% Store parameters
    CST.StoreParameterStr('pol_w',num2str(ParaValList(1)));
    CST.StoreParameterStr('sep_t_val',num2str(ParaValList(2)));
    CST.StoreParameterStr('sqr_wg_l',num2str(ParaValList(3)));
    
    CST.StoreParameterStr('l0',num2str(ParaValList(4)));
    CST.StoreParameterStr('d1',num2str(ParaValList(5)));
    CST.StoreParameterStr('d2',num2str(ParaValList(6)));
    CST.StoreParameterStr('d3',num2str(ParaValList(7)));
    CST.StoreParameterStr('d4',num2str(ParaValList(8)));
    CST.StoreParameterStr('d5',num2str(0));
    
    CST.StoreParameterStr('w1_r',num2str(ParaValList(9)));
    CST.StoreParameterStr('w2_r',num2str(ParaValList(10)));
    CST.StoreParameterStr('w3_r',num2str(ParaValList(11)));
    CST.StoreParameterStr('w4_r',num2str(ParaValList(12)));
    CST.StoreParameterStr('w5_r',num2str(1));
    
    %% Rebuild and simulate the project
    CST.RebuildOnParaChange('True', 'True');
    
    %solver = CST.mws.invoke('FDSolver');
    %{
    if ~IsOpen
    Solver = CST.mws.invoke('Solver');
    IsOpen = 1;
    end
    %}
    Solver.invoke('Start');
    
    CST.saveProject();
    %CST.closeProject();
    
    %% Calculate Objective Values
    S11ObjVal = FuncSParaObjValCalcMax(ExportFolder, S11FileName, S11GoalVal, RangeVec, S11Weight);
    S21ObjVal = FuncSParaObjValCalcMax(ExportFolder, S21FileName, S21GoalVal, RangeVec, S21Weight);
    %ARObjVal = FuncARObjValCalcMax(ExportFolder, ARFileName, ARGoalVal, RangeVec, ARWeight);
    
    ObjValVec(1) = S11ObjVal;
    ObjValVec(2) = S21ObjVal;
    ObjVal = ObjValVec(1) + ObjValVec(2);
    
    SimCnt = SimCnt + 1;
    fprintf('Sim [%d]: [ObjValVec(1), ObjValVec(2)] = [%f, %f]; ObjVal = %f;\n', SimCnt, ObjValVec(1), ObjValVec(2), ObjVal);
    
    % Record 
    ParaValMat(SimCnt,:) = ParaValList';
    save('ParaValListRecord.mat', 'ParaValMat');
    
    plot_ObjValVec(1,SimCnt) = ObjValVec(1);
    plot_ObjValVec(2,SimCnt) = ObjValVec(2);
    plot_ObjVal(SimCnt) = ObjVal;
    plot_x = [1:1:SimCnt];
    plot(plot_x, plot_ObjValVec(1,:), 'r.-', plot_x, plot_ObjValVec(2,:), 'b.-', 'LineWidth', 1.5);
    hold on;
    plot(plot_x, plot_ObjVal, 'm.-');
    grid minor;
    legend('Objective 1', 'Objective 2', 'ObjectTotal');
    hold off;
end
