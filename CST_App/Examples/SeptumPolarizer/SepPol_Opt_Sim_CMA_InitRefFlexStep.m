clear all;
close all;

str=pwd;
index_dir=findstr(str,'\');
str_temp=str(1:index_dir(end)-1);
addpath(genpath(str_temp))

global IsOpen;
global SimCnt;
global plot_ObjValVec;
global plot_ObjVal;
global ParaValMat;
IsOpen = 0;
SimCnt = 0;

% myfun='fitness1_updated_wo_Am_fast';
myfun='FuncSepPolSimSParaOnlyFlexStep_SingleObj';
ParaList = [1.9, 0.44, 4.98, 3.49, 0.36, 0.93, 0.91, 1.19, 0.7843, 0.613, 0.5914, 0.4494];
N=length(ParaList);
opts.LBounds=[1.667 0.3   4   1.5 0   0   0   0   0 0 0 0]';
opts.UBounds=[1.928  1    10  5   2.5 2.5 2.5 2.5 1 1 1 1]';
%opts.StopFitness  = -13;
opts.Restarts     = 1;    % number of restarts ';
opts.CMA.active =2;  % active CMA, 1: neg. updates with pos. def. check, 2: neg. updates';
opts.TolFun       = 100; % stop if fun-changes smaller TolFun';
opts.TolHistFun   = 10; % stop if back fun-changes smaller TolHistFun';
opts.MaxIter      = 4000;
% opts.Popsize=(4 + floor(3*log(N)));
%opts.MaxFunEvals  = 22000;
opts.DispModulo = 1;  % [0:Inf], disp messages after every i-th iteration';
opts.LogModulo = 0;   % [0:Inf] if >1 record data less frequently after gen=100';
opts.SaveFilename = [myfun,'_InitRefFlexStep_Result.mat'];  % save all variables, see SaveVariables';

init_var = ParaList';

% [XMIN,FMIN,COUNTEVAL,STOPFLAG,OUT,BESTEVER]=cmaes(myfun,unifrnd(0,1,N,1),[],opts);
[XMIN,FMIN,COUNTEVAL,STOPFLAG,OUT,BESTEVER]=cmaes(myfun,init_var,[],opts);





