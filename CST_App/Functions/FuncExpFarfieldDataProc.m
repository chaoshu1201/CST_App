%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output Structure: DirLHCP(PhiPlaneIndex,Theta), -180<=Theta<=180
%                   DirRHCP(PhiPlaneIndex,Theta), -180<=Theta<=180
%                   AR(PhiPlaneIndex,Theta), -180<=Theta<=180
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DirLHCP, DirRHCP, DirABS, AR] = FuncExpFarfieldDataProc(file, NpTheta, NpPhi)

    %Load data
    delimiterIn = ' ';
    headerlinesIn = 2; 
    cut_data_context = importdata(file,delimiterIn,headerlinesIn);
    cut_data = cut_data_context.data;
    
    %Get Directivity for LHCP(Col.4) and RHCP (Col.6) and AR (Col.8)
    Offset = NpTheta*2+1; %offset line to read. There're 2*NpTheta points for Phi=-90 and -45, so Phi=0 start at Offset line
    for n = 1:1:NpPhi
        %LHCP component
        DirLHCP_tmp(n,:) = cut_data((Offset+(n-1)*NpTheta):(Offset+n*NpTheta-1), 4);
        DirLHCP(n,:) = [DirLHCP_tmp(n,:) DirLHCP_tmp(n,1)];  %Add first data (theta=-180) to the end to make the theta range -180~180
        
        %RHCP component
        DirRHCP_tmp(n,:) = cut_data((Offset+(n-1)*NpTheta):(Offset+n*NpTheta-1), 6);
        DirRHCP(n,:) = [DirRHCP_tmp(n,:) DirRHCP_tmp(n,1)];
        
        %AR
        AR_tmp(n,:) = cut_data((Offset+(n-1)*NpTheta):(Offset+n*NpTheta-1), 8);
        AR(n,:) = [AR_tmp(n,:) AR_tmp(n,1)];
        
        %Abs Component
        DirABS_tmp(n,:) = cut_data((Offset+(n-1)*NpTheta):(Offset+n*NpTheta-1), 3);
        DirABS(n,:) = [DirABS_tmp(n,:) DirABS_tmp(n,1)];
    end
    
end
    
