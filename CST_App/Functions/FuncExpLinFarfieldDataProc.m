%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output Structure: DirCo(PhiPlaneIndex,Theta), -180<=Theta<=180
%                   DirCx(PhiPlaneIndex,Theta), -180<=Theta<=180
%                   DirAbs(PhiPlaneIndex,Theta), -180<=Theta<=180
% PeakCo/Cx/Abs are column vectors
% Input Table: Theta[deg.]  Phi[deg.]  Abs(Dir.)[dBi]   Abs(Cross)[dBi]  Phase(Cross)[deg.]  Abs(Copol)[dBi]  Phase(Copol)[deg.]  Ax.Ratio[dB]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ThetaFarfieldVec, DirCo, DirCx, DirAbs, DirCoNorm, DirCxNorm, DirAbsNorm,...
          PeakCo, PeakCx, PeakAbs] = FuncExpLinFarfieldDataProc(ExportFolder, FileName, NpTheta, NpPhi)

    % Load expoFrted file of Farfield
    FullExpFarfieldFile = fullfile(ExportFolder, FileName);
    
    %Load data
    delimiterIn = ' '; 
    headerlinesIn =2; 
    cut_data_context = importdata(FullExpFarfieldFile,delimiterIn,headerlinesIn);
    cut_data = cut_data_context.data;
    
    % Get Theta (Col.1)
    ThetaFarfieldArr = transpose(reshape(cut_data(:, 1), [NpTheta, NpPhi]));
    ThetaFarfieldArr = [ThetaFarfieldArr 360+ThetaFarfieldArr(:,1)]; %Add first data (theta=-180) to the end to make the theta range -180~180
    ThetaFarfieldVec = ThetaFarfieldArr(1,:);
    
    % Get Directivity for Copol (Col.6) of each cut
    DirCoAll = transpose(reshape(cut_data(:, 6), [NpTheta, NpPhi]));
    DirCo = DirCoAll(3:5, :);  %Only need 0/45/90 plane
    DirCo = [DirCo DirCo(:,1)]; %Add first data (theta=-180) to the end to make the theta range -180~180
    PeakCo = DirCo(:, (NpTheta+2)/2);
    DirCoNorm = DirCo - PeakCo;
    
    % Get Directivity for Cxpol (Col.4) of each cut
    DirCxAll = transpose(reshape(cut_data(:, 4), [NpTheta, NpPhi]));
    DirCx = DirCxAll(3:5, :);  %Only need 0/45/90 plane
    DirCx = [DirCx DirCx(:,1)]; %Add first data (theta=-180) to the end to make the theta range -180~180
    PeakCx = max(DirCx, [], 2); %Cx-pol Peaks of each cut, can be used to determing worst XPD
    DirCxNorm = DirCx - PeakCo; %Normalize Cx-pol by Peak of Co-pol!
    
    % Get Directivity for Copol (Col.3) of each cut
    DirAbsAll = transpose(reshape(cut_data(:, 3), [NpTheta, NpPhi]));
    DirAbs = DirAbsAll(3:5, :);  %Only need 0/45/90 plane
    DirAbs = [DirAbs DirAbs(:,1)]; %Add first data (theta=-180) to the end to make the theta range -180~180
    PeakAbs = DirAbs(:, (NpTheta+2)/2);
    DirAbsNorm = DirAbs - PeakAbs;
    
end
    
