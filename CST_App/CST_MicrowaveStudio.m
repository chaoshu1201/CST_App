classdef CST_MicrowaveStudio < handle
    %CST_MicrowaveStudio creates a CST_MicrowaveStudio object which acts as
    %an interface between MATLAB and CST Microwave Studio.
    %   CST_MicrowaveStudio(folder,filename) creates a new CST MWS session
    %   in a subfolder in the specified file location. The subfolder is
    %   called '/CST_MicrowaveStudio_Files' and is only created when the
    %   CST file is saved. CST_MicrowaveStudio contains a number of
    %   functions to perform regular operations in CST mathematically. All
    %   steps are added to the history tree as if the user had created the
    %   model interactively.
    %
    %   -----Methods Overview-----
    %
    %   --Class Creator--
    %   CST_MicrowaveStudio
    %
    %   --File Methods--
    %   save
    %   quit
    %   openFile (Static)
    %
    %   --Paremeter Methods
    %   addParameter
    %   changeParemeter
    %   parameterUpdate
    %   getParameterValue
    %
    %   --Simulation Methods--
    %   addDiscretePort
    %   defineUnits
    %   setFreq
    %   setSolver
    %   setBoundaryCondition
    %   addFieldMonitor
    %   setBackgroundLimits
    %   addSymmetryPlane
    %   defineFloquetModes
    %   runSimulation
    %
    %   --Build Methods--
    %   addNormalMaterial
    %   addAnisotropicMaterial
    %   addBrick
    %   addCylinder
    %   addPolygonBlock
    %   addPolygonBlock3D
    %   addSpline3D
    %   addSphere
    %   rotateObject
    %   translateObject
    %   connectFaces
    %   mergeCommonSolids
    %   deleteObject
    %
    %   --Result Methods--
    %   getSParameters
    %   getFarfield
    %   getEFieldVector
    %   getMeshInfo
    %   getFieldIDStrings
    %
    %   --Other--
    %   addToHistory
    %   setUpdateStatus
    %   update
    %
    %   For help on specific functions, type
    %   CST_MicrowaveStuio.FunctionName (e.g. "help CST_MicrowaveStudio.setBoundaryCondition")
    %
    %   Additional custom functions may be added to CST histroy list using
    %   the same VBA format below and calling:
    %   CST_MicrowaveStudioHandle.mws.invoke('AddToHistory','Action String identifier',VBA])
    %
    %   See Also: actxserver, addGradedIndexMaterialCST, CST_App\Examples
    %   
    %   Latest Versions Available: 
    %   https://uk.mathworks.com/matlabcentral/fileexchange/67731-hgiddenss-cst_app
    %   https://github.com/hgiddenss/CST_App
    %
    %   Copyright: Henry Giddens 2018, Antennas and Electromagnetics
    %   Group, Queen Mary University London, 2018 (For further help,
    %   functionality requests, and bug fixes contact h.giddens@qmul.ac.uk)
    
    properties
        CST       % Handle to CST through actxserver
        folder    % Folder
        filename  % Filename
        mws       % Handle to the microwave studio project
    end          
    properties (Hidden)
        ports = 0; %to be removed
        solver = 't';
        listeners
    end
%     properties (Hidden, SetObservable) %For future use
%         F1 = []
%         F2 = []
%     end
    properties (SetAccess = private)
        autoUpdate = true %If true, each relevant command will be added to history once function finishes executing
        VBAstring = [];     %If false, the VBA commands will be added to the VBAstring property, and the addToHistory Method must be called. 
                            %All commands will be added in same action and it is sometimes fast when dealing with large loops. 
    end
    properties(Access = private)
        version = '1.2.1'; 
    end
    methods
        function obj = CST_MicrowaveStudio(folder,filename)
            %CST_MicrowaveStudio with no input parameters will construct an
            % instance of CST_MicrowaveStudio related to the currently open
            % project in CST.
            %
            % CST_MicrowaveStudio(folder,filename) will either create a new
            % CST mws project, or will open an existing project (if it
            % exists).
            %
            % Examples:
            % To create a new microwave studio project
            % CST = CST_MicrowaveStudio(cd,'New_MWS_Simulation.cst'); 
            %
            % CST = CST_MicrowaveStudio; %Return the currently active MWS
            % project
            
            if nargin == 0
                %Get the current MWS session
                obj.CST = actxserver('CSTStudio.application');
                obj.mws = obj.CST.Active3D;
                if isempty(obj.mws)
                    error('CSTMicrowaveStudio:NoFileOpen',...
                        'I tried to return the active microwave studio session, but it appears that no proects are currently open');
                end
                [obj.folder,obj.filename] = fileparts(obj.mws.invoke('GetProjectPath','Project'));
                fprintf('CST_MicrowaveStudio Successfully opened. Active microwave studio project is:\n%s\\%s.cst\n',obj.folder,obj.filename)
                return
                
            end
            
            obj.folder = folder;
            
            %Ensure file has .cst extension.
            [~,filename,ext] = fileparts(filename);
            
            if ~isempty(ext)
                if ~strcmpi('.cst',ext)
                    error('CST_MicrowaveStudio:wrongFileExtension','File extension must be .CST')
                end
            end
            obj.filename = [filename,'.cst'];
            
            ff = fullfile(obj.folder,obj.filename);
            
            if exist(ff,'file') == 2
                %If file exists, open
                [obj.CST,obj.mws] = CST_MicrowaveStudio.openFile(obj.folder,obj.filename);
                fprintf('Microwave studio project was successfully opened\n')
            else %Create a new MWS session
                %Create a directory in 'folder' called
                %CST_MicrowaveStudio_Files which is added to .gitignore
                fprintf('Creating new microwave studio session\n');
                dirstring = fullfile(obj.folder,'CST_MicrowaveStudio_Files');
                obj.folder = dirstring;
                obj.CST = actxserver('CSTStudio.application');
                obj.mws = obj.CST.invoke('NewMWS');
                %obj.mws.invoke('SaveAs', ff, 'True');
                
                %{
                % For Future Version - allow user to store some values as
                % object properties, such as the frequency, which update in the
                % MWS model whenever they are updated in Matlab
                % obj.listeners = addlistener(obj,{'F1','F2'},'PreSet',@obj.setFreqListenerResp);
                
                %Set up some default simulation parameters:
                obj.defineUnits;
                obj.setFreq(11,13);
                
                %Boundaries:
                VBA = sprintf(['With Boundary\n',...
                    '.Xmin "expanded open"\n',...
                    '.Xmax "expanded open"\n',...
                    '.Ymin "expanded open"\n',...
                    '.Ymax "expanded open"\n',...
                    '.Zmin "expanded open"\n',...
                    '.Zmax "expanded open"\n',...
                    'End With',...
                    ]);
                
                obj.mws.invoke('addToHistory','define boundaries',VBA);
                
                VBA = sprintf(['With Material\n',...
                    '.Type "Normal\n',...
                    '.Colour "0.6", "0.6", "0.6"\n',...
                    '.ChangeBackgroundMaterial\n',...
                    'End With',...
                    ]);
                
                obj.mws.invoke('addToHistory','Set Background Material',VBA);
                %}
            end
        end
        function setUpdateStatus(obj,status)
           %CST.setUpdateStatus sets the status of the addToHistoryList property 
           if status == 1 || status == 0
               status = logical(status);
           end
           if ~islogical(status)
               error('CST_MicrowaveStudio:incorrectParameterType','Input parameter "status" must be of boolean/logical type');
           end
           if nargin == 2
               obj.autoUpdate = status;
           end
           
        end
        function addToHistory(obj,commandString,VBAstring)
            %CST.addToHistoryList(commandString,VBAstring) adds the commands in
            %VBAstring to the history list. They must be correctly
            %formatted else errors in CST will occur, halting the execution
            %of any code.
            %CST.addToHistory(commandString) will add any strings stored in
            %the object property VBAstring. commandString will be the
            %string shown in the history list. consecutive commandStrings
            %should never be the same as this may cause errors when the CST
            %history list is updated
            if nargin < 2
                commandString = ['CST_update_',datestr(now(),"HHMMSSddmmyyyy")]; %A unique string based on current time
            end
            if nargin < 3
                VBAstring = obj.VBAstring;
                obj.VBAstring = [];
            end
            obj.mws.invoke('addToHistory',commandString,VBAstring);
        end
        function save(obj)
            if ~exist(obj.folder,'file') == 7
                makedir(obj.folder);
            end
            obj.mws.invoke('saveas',fullfile(obj.folder,obj.filename),'false');
        end
        function saveNewProject(obj, ProjFolder, ProjFileName)
            if ~exist(ProjFolder,'file') == 7
                makedir(ProjFolder);
            end
            obj.mws.invoke('saveas',fullfile(ProjFolder,ProjFileName),'True');
        end
        function saveProject(obj)
            obj.mws.invoke('Save');
        end
        function closeProject(obj)
            obj.mws.invoke('quit');
        end
        function quit(obj)
            % Close the application
            obj.CST.invoke('quit');
        end
        function StoreParameterStr(obj,name,value_str)
            % CST_MicrowaveStudio.addStrParameter(name,value_str)
            % Create a new string parameter or changes an existing one, 
            % with the spepcified string value

            obj.mws.invoke('StoreParameter',name,value_str);
           
        end
        function addParameter(obj,name,value)
            % CST_MicrowaveStudio.addParameter(name,value)
            % Add a new parameter to the project. Value must be a
            % double
           
           if obj.isParameter(name)
               obj.changeParameterValue(obj,name,value)
           else
               obj.mws.invoke('StoreDoubleParameter',name,value);
           end
           
        end
        function changeParameterValue(obj,name,value)
            % CST_MicrowaveStudio.changeParameterValue(name,value)
            % Change the value of an existing parameter. Value must be a
            % double
            
            if ~obj.isParameter(name)
                addParameter(obj,name,value)
            else
                obj.mws.invoke('StoreDoubleParameter',name,value);
                obj.parameterUpdate;
            end
        end
        function parameterUpdate(obj)
            % CST_MicrowaveStudio.parameterUpdate
            % Update the history list
            obj.mws.invoke('Rebuild');
        end
        function retVal = RebuildOnParaChange(obj, FullRebuild, ShowErrMsg)
            % CST_MicrowaveStudio.RebuildOnParaChange
            % Update the history list
            retVal = obj.mws.invoke('RebuildOnParametricChange', FullRebuild, ShowErrMsg);
        end
        function out = isParameter(obj,name)
            % CST_MicrowaveStudio.isParameter(name)
            % Check if a parameter exists
            
            out = obj.mws.invoke('DoesParameterExist',name);
        end
        function val = getParameterValue(obj,name)
            %Returns the value of the named parameter. val is returned
            %empty if the parameter does not exist
            val = [];
            if obj.isParameter(name)
                val = obj.mws.invoke('RestoreDoubleParameter',name);
            end
             
        end
        function applyProjTemplate(obj,ProjectTemplateName, ProjectTemplateFile)
            %Apply a ProjectTemplate.
            VBA = fileread(ProjectTemplateFile);
            
            obj.update(['use template: ', ProjectTemplateName],VBA);
        end
        function createComponent(obj,ComponentName)
            %Creates a new component with the given name.
            VBA = sprintf(['Component.New "%s"\n'], ComponentName);
            
            obj.update(['new component: ', ComponentName],VBA);
        end
        function defineUnits(obj,varargin)
            %defineUnits(Parameter,value) - Define the units used in the CST_MicrowaveStudio
            %simulation. The default parameters and units arelisted below.
            %Any wrong arguments for value will currently resutl in a CST
            %error, and wont be picked up by matlab, so be careful! If a
            %particular parameter isnt set, it will be reset to its default
            %value as specified below
            %
            % --Parameter--          --Value-- (default) in parenthesis
            %   Geometry             'm' 'cm' ('mm') 'um' 'nm' 'ft' 'mil' 'in'
            %   Frequency            'Hz' 'kHz' 'MHz' 'GHz' 'THz' 'pHz'
            %   Time                 ('s') 'ms' 'us' 'ns' 'ps' 'fs'
            %   Temperature          ('Kelvin') 'Celsius' 'Farenheit'
            %   Voltage              ('V') % These 6 values apear to be fixed in microwave studio, so cannot be changed here either
            %   Current              ('A') %
            %   Resistance           ('Ohm') %
            %   Conductance          ('Siemens') %
            %   Capacitance          ('PikoF') %
            %   Inductance           ('NanoH') %
            %
            % Example:
            % CST.defineUnits('Frequency','THz','Geometery','nm');
            
            %Should these eventually be stored as class properties, or
            %persistant variable, else you have to define all units every
            %time they are changed or else the defaults below will be reset?
            
            p = inputParser;
            p.addParameter('Geometry','mm');
            p.addParameter('Frequency','GHz');
            p.addParameter('Time','S');
            p.addParameter('Temperature','Kelvin');
            p.addParameter('Votlage','V');
            p.addParameter('Current','A');
            p.addParameter('Resistance','Ohm');
            p.addParameter('Conductance','Siemens');
            p.addParameter('Capacitance','PiKoF');
            p.addParameter('Inductance','NanoH');
            
            p.parse(varargin{:});
            [geom,freq,time,temp] = deal(p.Results.Geometry,...
                p.Results.Frequency,p.Results.Time,p.Results.Temperature);
            
            VBA = sprintf(['With Units\n',...
                '.Geometry "%s"\n',...
                '.Frequency "%s"\n',...
                '.Time "%s"\n',...
                '.TemperatureUnit "%s"\n',...
                '.Voltage "V"\n',...
                '.Current "A"\n',...
                '.Resistance "Ohm"\n',...
                '.Conductance "Siemens"\n',...
                '.Capacitance "PikoF"\n',...
                '.Inductance "NanoH"\n',...
                'End With' ],geom,freq,time,temp);
            
            obj.update('Set Units',VBA);
            
        end
        function addBrick(obj,X,Y,Z,name,component,material,varargin)
            p = inputParser;
            p.addParameter('color',[])
            
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            
            %VBA = cell(0,1);
            
            VBA = sprintf(['With Brick\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.XRange "%f", "%f"\n',...
                '.YRange "%f", "%f"\n',...
                '.ZRange "%f", "%f"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            
            obj.update(['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
        end
        function mergeCommonSolids(obj,component,SolidCompName)
            %CST.mergeCommonSolids(component) will merge all solids in the
            % named components that share the same material. It seems to be
            % much quicker than calling booleanAdd for each pair of
            % individually. 
            % See SinusoidSurface example for extra information
            % obj.update(['new component:',component],['Solid.MergeMaterialsOfComponent "',component,'"']);
            
            VBA = sprintf(['With Solid\n',...
                '.MergeMaterialsOfComponent "%s" \n',...
                'End With'],...
                SolidCompName);

            obj.update(['merge materials of component: ',component],VBA);
        end
        function SubtractSolids(obj,SolidCompName1,SolidCompName2)
            %CST.mergeCommonSolids(component) will merge all solids in the
            % named components that share the same material. It seems to be
            % much quicker than calling booleanAdd for each pair of
            % individually. 
            % See SinusoidSurface example for extra information
            % obj.update(['new component:',component],['Solid.MergeMaterialsOfComponent "',component,'"']);
            
            VBA = sprintf(['Solid.Subtract "%s", "%s" '],...
                SolidCompName1, SolidCompName2);

            obj.update(['boolean subtract shape: ',SolidCompName1,', ', SolidCompName2],VBA);
        end
        function addNormalMaterial(obj,name,Eps,Mue,C)
            %Add a new 'Normal' material to the CST project
            
            %Attempt to allow parametric assignment to Epsilon and Mue
            if isnumeric(Eps)
                Eps = num2str(Eps);
            else
                if ~obj.isParameter(Eps)
                    error("CST:MicrowaveStudio:ParameterDoesntExist",...
                        "Parameter "+ Eps +" does not exist. Please add it to the project before assigning it to the material property");
                end
            end
            if isnumeric(Mue)
                Mue = num2str(Mue);
            else
                if ~obj.isParameter(Eps)
                    error("CST:MicrowaveStudio:ParameterDoesntExist",...
                        "Parameter "+ Eps +" does not exist. Please add it to the project before assigning it to the material property");
                end
            end
            
            VBA =  sprintf(['With Material\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Type "Normal"\n',...
                '.Epsilon "%s"\n',...
                '.Mue "%s"\n',...
                '.Colour "%f", "%f", "%f"\n',...
                '.Create\n',...
                'End With'],...
                name,Eps,Mue,C(1),C(2),C(3));
            obj.update(['define material: ',name],VBA);
        end
        function addAnisotropicMaterial(obj,name,Eps,Mue,C)
            VBA =  sprintf(['With Material\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Type "Anisotropic"\n',...
                '.EpsilonX "%f"\n',...
                '.EpsilonY "%f"\n',...
                '.EpsilonZ "%f"\n',...
                '.MueX "%f"\n',...
                '.MueY "%f"\n',...
                '.MueZ "%f"\n',...
                '.Colour "%f", "%f", "%f"\n',...
                '.Create\n',...
                'End With'],...
                name,Eps(1),Eps(2),Eps(3),Mue(1),Mue(2),Mue(3),C(1),C(2),C(3));
            obj.update(['define material: ',name],VBA);
        end
        function defineMaterial(obj, MaterialName, MaterialTemplateFile)
            %Load predefined materail.
            VBA = fileread(MaterialTemplateFile);
            Description = sprintf(['define material: %s'], MaterialName);
            
            obj.update([Description],VBA);
        end
        function changeSolidMaterial(obj, SolidCompName, MaterialName)
            
            VBA = sprintf(['Solid.ChangeMaterial "%s", "%s" '],...
                SolidCompName, MaterialName);

            obj.update(['change material: ', SolidCompName,' to: ', MaterialName], VBA);
        end
        function addDiscretePort(obj,X,Y,Z,R,impedance,varargin)
            %Add a discrete line source in the positions defined by the X, Y and Z
            %inputs, with radius, R, and impedance defined by the other
            %input arguments
            %
            % Example:
            % %Add a Z-directed line source of 20 units long at point XY = [0,5]
            % CST.addDiscretePort([0 0], [5 5], [-10 10], 1, 50)
            if nargin  < 5
                R = 0;
            end
            if nargin <6
                impedance = 50;
            end
            
            if nargin == 7
                warning('The input paramter "portNumber" is obsolete and will be removed in future release');
            end
            
            %Get the total next available port number
            p = obj.mws.invoke('Port');
            portNumber = p.invoke('StartPortNumberIteration') + 1;
            
            VBA =  sprintf(['With DiscretePort\n',...
                '.Reset\n',...
                '.Type "SParameter"\n',...
                '.PortNumber "%d"\n'...
                '.SetP1 "False", "%f", "%f", "%f"\n',...
                '.SetP2 "False", "%f", "%f", "%f"\n',...
                '.Impedance "%f"\n',...
                '.Radius "%f"\n',...
                '.Create\n',...
                'End With'],...
                portNumber, X(1),Y(1),Z(1),X(2),Y(2),Z(2),impedance,R);
            
            obj.update(['define discrete port: ',num2str(obj.ports+1)],VBA);
            
            obj.ports = obj.ports + 1; %Should this be obtained from the MWS file?
        end
        function portNumber = addWaveguidePort(obj,orientation,ModeNum,Pol,PolAng,X,Y,Z,varargin)
            % Add a wave guide port to the simulation file.
            % CST.addWaveguidePort(orientation,X,Y,Z) adds a wavegiude port
            % oriented in one of the X,Y,Z planes. Orientation can
            % be one of the following strings:
            % 'xmin' 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'
            % The port should be in the direction away from the defined
            % orientation (an 'xmin' orineted port will propogate towards
            % the xmax boundary). The cooridnates associated with the
            % plane of the port should contain two equal values, or a
            % single values indicating the position of the port.
            % Examples:
            % % Add a 5 x 10 (X x Y) units port at the z=5 position propagating towards zmin.
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.addPort('zmax',(0 5),(0 10), 5)
            %
            % portNumber is obsolete and will be removed in future release
            
            %Orientation defines the direction of the port
            switch lower(orientation)
                case{'xmin','xmax'}
                    if numel(X) == 1
                        X(2) = X(1);
                    end
                    
                case {'ymin','ymax'}
                    if numel(Y) == 1
                        Y(2) = Y(1);
                    end
                case {'zmin','zmax'}
                    if numel(Z) == 1
                        Z(2) = Z(1);
                    end
                otherwise
                    warning('Invalid port orientation')
                    return
            end
            
            if nargin == 6
                warning('The input paramter "portNumber" is obsolete and will be removed in future release');
            end
            
            p = obj.mws.invoke('Port');
            portNumber = p.invoke('StartPortNumberIteration') + 1;
            
            VBA = sprintf(['With Port\n'...
                '.Reset\n'...
                '.PortNumber "%d"\n'...
                '.Label ""\n'...
                '.Folder ""\n'...
                '.NumberOfModes "%d"\n'...
                '.AdjustPolarization "%s"\n'...
                '.PolarizationAngle "%f"\n'...
                '.ReferencePlaneDistance "0"\n'...
                '.TextSize "50"\n'...
                '.TextMaxLimit "1"\n'...
                '.Coordinates "Free"\n'...
                '.Orientation "%s"\n'...
                '.PortOnBound "False"\n'...
                '.ClipPickedPortToBound "False"\n'...
                '.Xrange "%s", "%s"\n'...
                '.Yrange "%s", "%s"\n'...
                '.Zrange "%s", "%s"\n'...
                '.XrangeAdd "0.0", "0.0"\n'...
                '.YrangeAdd "0.0", "0.0"\n'...
                '.ZrangeAdd "0.0", "0.0"\n'...
                '.SingleEnded "False"\n'...
                '.WaveguideMonitor "False"\n'...
                '.Create\n'...
                'End With'],...
                portNumber,ModeNum,Pol,PolAng,orientation,X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            
            obj.update(['define waveguide port: ',num2str(obj.ports+1)],VBA);
            obj.ports = obj.ports + 1; %Should this be obtained from the MWS file?
        end
        function addFieldMonitor(obj,fieldType,freq)
            % Add a field monitor at specified frequency
            % Field type can be one of the following strings:
            % 'Efield', 'Hfield', 'Surfacecurrent', 'Powerflow', 'Current',
            % 'Powerloss', 'Eenergy', 'Elossdens', 'Lossdens', 'Henergy',
            % 'Farfield', 'Temperature', 'Fieldsource', 'Spacecharge',
            % 'ParticleCurrentDensity' or 'Electrondensity'.
            % Examples:
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.AddMonitor('Efield',2.4);
            % CST.AddMonitor('farfield',10);
            
            %Try to implment default CST naming strings
            switch lower(fieldType)
                case 'efield'
                    name = ['e-field',' (f=',num2str(freq),')'];
                case 'hfield'
                    name = ['h-field',' (f=',num2str(freq),')'];
                otherwise
                    name = [fieldType,' (f=',num2str(freq),')'];
            end
            
            
            VBA =  sprintf(['With Monitor\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Dimension "Volume"\n',...
                '.Domain "Frequency"\n',...
                '.FieldType "%s"\n',...
                '.MonitorValue "%f"\n',...
                '.UseSubVolume "False"\n',...
                '.Create\n',...
                'End With'],...
                name,fieldType,freq);
            obj.update(['define field monitor: ',name],VBA);
            
        end
        function addFieldMonitorLinearStep(obj,fieldType,FreqRange, FreqStep)
            % Add a field monitor at specified frequency
            % Field type can be one of the following strings:
            % 'Efield', 'Hfield', 'Surfacecurrent', 'Powerflow', 'Current',
            % 'Powerloss', 'Eenergy', 'Elossdens', 'Lossdens', 'Henergy',
            % 'Farfield', 'Temperature', 'Fieldsource', 'Spacecharge',
            % 'ParticleCurrentDensity' or 'Electrondensity'.
            % Examples:
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.AddMonitor('Efield',2.4);
            % CST.AddMonitor('farfield',10);
            
            
            VBA =  sprintf(['With Monitor\n',...
                '.Reset\n',...
                '.Domain "Frequency"\n',...
                '.FieldType "%s"\n',...
                '.ExportFarfieldSource "False" \n',...
                '.UseSubVolume "False"\n',...
                '.CreateUsingLinearStep "%f", "%f", "%f"\n',...
                'End With'],...
                fieldType,FreqRange(1),FreqRange(2),FreqStep);
            obj.update(['define monitors (using linear step)'],VBA);
            
        end
        function addFieldSource(obj,SourceName,FileName,copy,varargin)
            
            p = inputParser;
            p.parse(varargin{:})
                
            objFieldSource = obj.mws.invoke('FieldSource');
            objFieldSource.invoke('FileName', FileName);
            Id = objFieldSource.invoke('GetNextId');
            
            VBA = sprintf(['With FieldSource\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.FileName "%s"\n',...
                '.Id "%s"\n',...
                '.UseCopyOnly "%d"\n',...
                '.ImportToActiveCoordinateSystem "True"\n',...
                '.Read\n',...
                'End With'],...
                SourceName,FileName,Id,copy);
            
            obj.update(['define field source: ', SourceName],VBA);
        end
        function setBackgroundLimits(obj,X,Y,Z)
            %CST.setBackgroundLimits sets the backgroun limits in the model
            %in the +/-X, +/-Y, and +/-Z directions, as specified.
            
            %Limits should always be positive
            X = abs(X);
            Y = abs(Y);
            Z = abs(Z);
            
            VBA = sprintf(['With Background\n',...
                '.XminSpace "%f"\n',...
                '.XmaxSpace "%f"\n',...
                '.YminSpace "%f"\n',...
                '.YmaxSpace "%f"\n',...
                '.ZminSpace "%f"\n',...
                '.ZmaxSpace "%f"\n',...
                '.ApplyInAllDirections "False"\n',...
                'End With'],...
                X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            obj.update('define background',VBA);
            
        end
        function addSymmetryPlane(obj,planeNormal,symType)
            %addSymmetryPlane(planeNormal,symType) sets the specified plane
            %to the defined symmetry type.
            % Examples:
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.addSymetryPlane('X','magnetic')
            
            VBA = sprintf(['With Boundary\n',...
                '.%ssymmetry "%s"\n',...
                'End With'],...
                planeNormal,symType);
            obj.update(['define boundary: ',planeNormal,' normal'],VBA);
        end
        function setBoundaryCondition(obj,varargin)
            %Set the boundary conditions for CST MWS simulation:
            % Examples:
            % CST.setBoundaryCondition('Xmin','Open add space')
            % CST.setBoundaryCondition('YMin','Electric Wall','YMin','Magnetic Wall')
            % CST.setBoundaryCondition('ZMin','Periodic')
            %
            % Options:
            % Boundaries - 'Xmin','Xmax','Ymin','Ymax','Zmin','Zmax'
            % Boundary Type - 'Open','Open add space','Electric',
            % 'Magnetic','Periodic','Unit cell','conducting wall'
            % Note: 'Unit Cell boundaries can only be applied in X and Y
            % directions'
            
            boundaries = {'Xmin','Xmax','Ymin','Ymax','Zmin','Zmax'};
            str = '';
            for i = 1:2:numel(varargin)
                
                boundary = [upper(varargin{i}(1)),lower(varargin{i}(2:end))];
                
                if any(strcmp(boundary,boundaries))
                    
                    switch lower(varargin{i+1})
                        case 'open add space'
                            boundaryType = 'expanded open';
                        otherwise
                            boundaryType = varargin{i+1};
                    end
                    
                    str = [str,'.',boundary,' "',boundaryType,'"\n']; %#ok<AGROW>
                else
                    warning('Unrecognised boundary "%s". Boundary condition ignored', boundary);
                end
            end
            VBA = sprintf(['With Boundary\n',...
                str,...
                'End With',...
                ]);
            
            obj.update('define boundaries',VBA);
            
            if any(strcmpi(varargin,'unit cell'))
                %Set Floquet port mode to 2 (default - 18)
                VBA = sprintf(['With FloquetPort\n',...
                    '.Reset\n',...
                    '.SetDialogTheta "0"\n',...
                    '.SetDialogPhi "0"\n',...
                    '.SetPolarizationIndependentOfScanAnglePhi "0.0", "False"\n',...
                    '.SetSortCode "+beta/pw"\n',...
                    '.SetCustomizedListFlag "False"\n',...
                    '.Port "Zmin"\n',...
                    '.SetNumberOfModesConsidered "2"\n',...
                    '.SetDistanceToReferencePlane "0.0"\n',...
                    '.SetUseCircularPolarization "False"\n',...
                    '.Port "Zmax"\n',...
                    '.SetNumberOfModesConsidered "2"\n',...
                    '.SetDistanceToReferencePlane "0.0"\n',...
                    '.SetUseCircularPolarization "False"\n',...
                    'End With']);
                obj.update('define Floquet Port boundaries',VBA);
                
                
            end
        end
        function setPmlBoundaryConditions(obj,FrequencyForMinimumDistance)
            
            VBA = sprintf(['With Boundary\n',...
                '.ReflectionLevel "0.0001"\n',...
                '.MinimumDistanceType "Fraction"\n',...
                '.MinimumDistancePerWavelengthNewMeshEngine "4"\n',...
                '.MinimumDistanceReferenceFrequencyType "User"\n',...
                '.FrequencyForMinimumDistance "%d"\n',...
                '.SetAbsoluteDistance "0.0"\n',...
                'End With'],...
                FrequencyForMinimumDistance);
            obj.update(['define pml specials'],VBA);
        end
        function rotateObject(obj,componentName,objectName,rotationAngles,rotationCenter,copy,repetitions)
            % Rotate an object in located in one of the components
            %
            % 
            % THIS WILL BE UPDATED IN FUTURE VERSION
            % Currently not possible to rotate ports, faces, curves etc...
            
            warning('CST_MicrowaveStudio:rotateObject','The inputparameter list of rotateObject will change in a future release')
            
            nameStr = [componentName,':',objectName];
            if nargin < 6
                copy = 'False';
            end
            
            if nargin < 7
                repetitions = 1;
            end
            
            if copy
                copyStr = 'True';
            else
                copyStr = 'False';
            end
            
            VBA = sprintf(['With Transform\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Origin "Free"\n',...
                '.Center "%f", "%f", "%f"\n',...
                '.Angle "%f", "%f", "%f"\n',...
                '.MultipleObjects "%s"\n',...
                '.GroupObjects "False"\n',...
                '.Repetitions "%d"\n',...
                '.MultipleSelection "False"\n',...
                '.Transform "Shape", "Rotate"\n',...
                'End With'],...
                nameStr,rotationCenter(1),rotationCenter(2),rotationCenter(3),...
                rotationAngles(1),rotationAngles(2),rotationAngles(3),...
                copyStr,repetitions);
            
            obj.update(['transform: rotate ',nameStr],VBA);
            
        end
        function addPolygonBlock(obj,points,height,name,component,material,varargin)
            %add a polygon with any number of sides to the simulations
            %space. Polygon will be aligned in the x-y plane
            p = inputParser;
            p.addParameter('color',[])
            p.addParameter('zmin',0)
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            zmin = p.Results.zmin;
            %VBA = cell(0,1);
            
            VBA = sprintf(['With Extrude\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Mode "pointlist"\n',...
                '.Height "%f"\n',...
                '.Twist "0.0"\n',...
                '.Taper "0.0"\n',...
                '.Origin "0.0", "0.0", "%f"\n',...
                '.Uvector "1.0", "0.0", "0.0"\n',...
                '.Vvector "0.0", "1.0", "0.0"\n',...
                '.Point "%f", "%f"\n'],...
                name,component,material,height,zmin,points(1,1),points(1,2));
            
            VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.LineTo "%f", "%f"\n', points(i,1),points(i,2))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.update(['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
            
        end
        function addPolygonBlock3D(obj,points,thickness,name,component,material,varargin)
            %Add a block in any plane using 3-column coordinates
            p = inputParser;
            p.addParameter('color',[])
            p.addParameter('curve','3dpolygon1')
            p.addParameter('curveName','curve1')
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            
            %VBA = cell(0,1);
            
            VBA = sprintf(['With Polygon3D\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.Point "%f", "%f", "%f"\n'],...
                p.Results.curve,p.Results.curveName,points(1,1),points(1,2),points(1,3));
            
            VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.Point "%f", "%f", "%f"\n', points(i,1),points(i,2),points(i,3))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.update(['define curve: ',p.Results.curve,':',p.Results.curveName],VBA);
            
            VBA = sprintf(['With ExtrudeCurve\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Thickness  "%f"\n',...
                '.Twistangle "0.0"\n',...
                '.Taperangle "0"\n',...
                '.DeleteProfile "True"\n',...
                '.Curve "%s:%s"\n',...
                '.Create\nEnd With'],...
            name,component,material,thickness,p.Results.curveName,p.Results.curve);
            
            obj.update(['define extrudeprofile: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
        end
        function ShapeName = addSpline3D(obj,points,SplineName,CurveName,varargin)
            %Add a Spline in any plane using 3-column coordinates
            p = inputParser;
            p.addParameter('SplineName',SplineName)
            p.addParameter('CurveName',CurveName)
            p.parse(varargin{:});
            
            VBA = sprintf(['With Polygon3D\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.SetInterPolation "Spline"\n'],...
                p.Results.SplineName,p.Results.CurveName);
            
            PointList = [];
            for i = 1:size(points, 1)
                PointList = [PointList,sprintf('.Point "%f", "%f", "%f"\n', points(i,1),points(i,2),points(i,3))];
            end
            VBA = [VBA,PointList,sprintf('.create\nEnd With')];
            
            ShapeName = [p.Results.CurveName,':', p.Results.SplineName];
            obj.update(['define curve 3dpolygon: ',ShapeName],VBA);           
        end
        function ShapeName = addPolygon3D(obj,points,Polygon3DName,CurveName,varargin)
            %Add a polygon in any plane using 3-column coordinates
            p = inputParser;
            p.addParameter('Polygon3DName',Polygon3DName)
            p.addParameter('CurveName',CurveName)
            p.parse(varargin{:});
            
            VBA = sprintf(['With Polygon3D\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n'],...
                p.Results.Polygon3DName,p.Results.CurveName);
            
            PointList = [];
            for i = 1:size(points, 1)
                if (isstring(points))
                    PointList = [PointList,sprintf('.Point "%s", "%s", "%s"\n', points(i,1),points(i,2),points(i,3))];
                else
                    PointList = [PointList,sprintf('.Point "%f", "%f", "%f"\n', points(i,1),points(i,2),points(i,3))];
                end
            end
            VBA = [VBA,PointList,sprintf('.create\nEnd With')];
            
            ShapeName = [p.Results.CurveName,':', p.Results.Polygon3DName];
            obj.update(['define curve 3dpolygon: ',ShapeName],VBA);           
        end
        function ShapeName = addCurveCircle(obj,CircleName,CurveName,R,Xcent,Ycent,Seg,varargin)
            %Add a Circle in working plane
            p = inputParser;
            p.addParameter('CircleName',CircleName)
            p.addParameter('CurveName',CurveName)
            p.parse(varargin{:});
            
            VBA = sprintf(['With Circle\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.Radius "%s"\n',...
                '.Xcenter "%s"\n',...
                '.Ycenter "%s"\n',...
                '.Segments "%d"\n',...
                '.Create\n',...
                'End With',...
                ],...
                p.Results.CircleName,p.Results.CurveName,R,Xcent,Ycent,Seg);
            
            ShapeName = [p.Results.CurveName,':', p.Results.CircleName];
            obj.update(['define curve circle: ',ShapeName],VBA);           
        end
        function ShapeName = addCurveRectangle(obj,RectangleName,CurveName,X_Range,Y_Range,varargin)
            %Add a rectangle in working plane
            p = inputParser;
            %p.addParameter('CircleName',CircleName)
            %p.addParameter('CurveName',CurveName)
            %p.parse(varargin{:});
            
            VBA = sprintf(['With Rectangle\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.Xrange "%s", "%s"\n',...
                '.Yrange "%s", "%s"\n',...
                '.Create\n',...
                'End With',...
                ],...
                RectangleName,CurveName,X_Range(1),X_Range(2),Y_Range(1),Y_Range(2));
            
            ShapeName = [CurveName,':', RectangleName];
            obj.update(['define curve rectangle: ',ShapeName],VBA);           
        end
        function connectFaces(obj,component1,face1,component2,face2,component,name,material)
            %Connect two face to form a solid block. This is useful if
            %trying to create 3D surfaces with thickness > 0. See Sinusoid
            %Surface Example
            
            VBA = sprintf('Pick.PickFaceFromId "%s:%s", "1" ',component1,face1);
            obj.update('pick face',VBA);
            VBA = sprintf('Pick.PickFaceFromId "%s:%s", "1" ',component2,face2);
            obj.update('pick face',VBA);
            
            VBA = sprintf(['With Loft\n',... 
                    '.Reset\n',...
                    '.Name "%s"\n',... 
                    '.Component "%s"\n',... 
                    '.Material "%s"\n',... 
                    '.Tangency "0.0"\n',... 
                    '.Minimizetwist "true"\n',... 
                    '.CreateNew\n',... 
                    'End With',...
                    ],name,component,material);
                
            obj.update(['define loft: ',component,':',name],VBA);
        end
        function ShapeName = addCylinder(obj,R1,R2,orientation,X,Y,Z,name,component,material)
            if ~strcmpi(orientation,'z')
                warning('Only Z-orientated cylinders are currently allowed')
                return
            end
            VBA = sprintf(['With Cylinder\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.OuterRadius "%s"\n',...
                '.InnerRadius "%s"\n',...
                '.Axis "%s"\n',...
                '.Zrange "%s", "%s"\n',...
                '.Xcenter "%s"\n',...
                '.Ycenter "%s"\n',...
                '.Segments "0"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,R1,R2,lower(orientation),Z(1),Z(2),X,Y);
            obj.update(['define cylinder:',component,':',name],VBA);
            
            ShapeName = [component,':', name];
            %obj.update(['define cylinder:',component,':',name],VBA);
            
        end
        function ShapeName = addCone(obj,BotR,TopR,orientation,X,Y,Z,name,component,material)
            if ~strcmpi(orientation,'z')
                warning('Only Z-orientated cylinders are currently allowed')
                return
            end
            VBA = sprintf(['With Cone\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.BottomRadius "%s"\n',...
                '.TopRadius "%s"\n',...
                '.Axis "%s"\n',...
                '.Zrange "%s", "%s"\n',...
                '.Xcenter "%s"\n',...
                '.Ycenter "%s"\n',...
                '.Segments "0"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,BotR,TopR,lower(orientation),Z(1),Z(2),X,Y);
            obj.update(['define cone:',component,':',name],VBA);
            
            ShapeName = [component,':', name];
            %obj.update(['define cylinder:',component,':',name],VBA);
            
        end
        function addSphere(obj,X,Y,Z,R1,R2,R3,name,component,material,varargin)
            if R2 > R1 || R3 > R1
                warning('Center Radius (R1) must be larger than top (R2) and bottom (R3) radii\nExiting without adding sphere');
                return
            end
            
            p = inputParser;
            p.addParameter('orientation','z');
            p.addParameter('segments',0);
            p.parse(varargin{:})
            
            %add the following to input parser
            orientation = p.Results.orientation;
            segments = p.Results.segments;
            
            VBA = sprintf(['With Sphere\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Axis "%s"\n',...
                '.CenterRadius "%f"\n',...
                '.TopRadius "%f"\n',...
                '.BottomRadius "%f"\n',...
                '.Center "%f", "%f", "%f"\n',...
                '.Segments "%d"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,orientation,R1,R2,R3,X,Y,Z,segments);
            
            obj.update(['define sphere:',component,':',name],VBA);
            
        end
        %{
        function translateObject(obj,name,x,y,z,copy,rep,varargin)
            
            if copy
                copy = 'True';
            else
                copy = 'Fase';
            end
            
            p = inputParser;
            p.addParameter('repetitions',rep);
            p.addParameter('material','');
            p.addParameter('destination','');
            p.parse(varargin{:})
            
                
            VBA = sprintf(['With Transform\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Vector "%.4f", "%.4f", "%.4f"\n',...
                '.UsePickedPoints "False"\n',...
                '.InvertPickedPoints "False"\n',...
                '.MultipleObjects "%s"\n',...
                '.GroupObjects "False"\n',...
                '.Repetitions "%d"\n',...
                '.MultipleSelection "False"\n',...
                '.Material "%s"\n',...
                '.Transform "Shape", "Translate"\n',...
                'End With'],...
                name,x,y,z,copy,p.Results.repetitions,p.Results.destination,p.Results.material);
            
            %Check for destination component?
            
            obj.update(['transform:',name],VBA);
        end
        %}
        function translateObject(obj,ObjType,name,x,y,z,copy,rep,varargin)
            
            if copy
                copy = 'True';
            else
                copy = 'False';
            end
            
            p = inputParser;
            p.parse(varargin{:})
            
                
            VBA = sprintf(['With Transform\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Vector "%s", "%s", "%s"\n',...
                '.UsePickedPoints "False"\n',...
                '.InvertPickedPoints "False"\n',...
                '.MultipleObjects "%s"\n',...
                '.GroupObjects "False"\n',...
                '.Repetitions "%d"\n',...
                '.MultipleSelection "False"\n',...
                '.Transform "%s", "Translate"\n',...
                'End With'],...
                name,x,y,z,copy,rep,ObjType);
            
            obj.update(['transform ', ObjType, ':' 'translate ',name],VBA);
        end
        function ShapeName = sweepCurve(obj,name,CompName,Material,...
                             TwistAng,TaperAng,PathName,CurveName,varargin)
            
            p = inputParser;
            p.parse(varargin{:})
                      
            VBA = sprintf(['With SweepCurve\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Twistangle "%f"\n',...
                '.Taperangle "%f"\n',...
                '.ProjectProfileToPathAdvanced "False"\n',...
                '.DeleteProfile "True"\n',...
                '.DeletePath "True"\n',...
                '.Path  "%s"\n',...
                '.Curve "%s"\n',...
                '.Create\n',...
                'End With'],...
                name,CompName,Material,TwistAng,TaperAng,PathName,CurveName);
            
            ShapeName = [CompName,':',name];
            obj.update(['define sweepprofile: ',ShapeName],VBA);
        end
        function ShapeName = loftCurve(obj,name,CompName,Material,...
                             CreateSolid,DelCurve,CurveList, varargin)
            
            p = inputParser;
            p.parse(varargin{:})
                      
            VBA = sprintf(['With LoftCurves\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Solid "%s"\n',...
                '.MinimizeTwist "True"\n',...
                '.DeleteCurves "%s"\n'],...
                name,CompName,Material,CreateSolid,DelCurve);
            
            AddCurveList = [];
            CurveNum = length(CurveList);
            for i = 1:1:CurveNum
                AddCurveList = [AddCurveList,sprintf('.AddCurve "%s"\n', CurveList(i))];
            end
            VBA = [VBA,AddCurveList,sprintf('.Create\nEnd With')];
            
            ShapeName = [CompName,':',name];
            obj.update(['define curveloft: ',ShapeName],VBA);
        end
        function deleteObject(obj,objectType,objectName)
            %deleteObject(objectType,objectName)
            % Object type is the VBA object type - currently only
            % 'component' and 'solid' are allowed
            % Objectname must include the full component reference, e.g.
            % component1:solid1
            % Example:
            % CST.addBrick([0 1],[0 1],[0 1],'Brick1','component1','PEC');
            % CST.addBrick([1 3],[1 4], [1 4],'Brick2','component2','PEC');
            % pause(3)
            % CST.deleteObject('component','component1');
            % pause(3)
            % CST.deleteObject('solid','component2:Brick2');
            
            
            switch lower(objectType)
                case{'component','solid'}
                
                otherwise
                    error('You cannot currently delete %s programatically, please send a request to h.giddens@qmul.ac.uk',objectType);
            end
            
            obj.update(['delete ',objectType,': ',objectName],[objectType,'.Delete "',objectName,'" ']);
        end
        function addComponent(obj,component)
            %addComponent  add a new co
            obj.update(['new component:',component],['Component.New "',component,'"']);
        end
        function setFreq(obj,Fmin,Fmax)
            obj.update('define frequency range',sprintf('Solver.FrequencyRange "%s", "%s"',num2str(Fmin),num2str(Fmax)));

        end
        
        function setSolver(obj,solver)
            switch lower(solver)
                case {'frequency','f','freq'}
                    VBA = 'ChangeSolverType "HF Frequency Domain"';
                    obj.solver = 'f';
                case {'time','time domain','td','t'}
                    VBA = 'ChangeSolverType "HF Time Domain" ';
                    obj.solver = 't';
            end
            obj.update('change solver type',VBA);
            
        end
        function setSolverTemplate(obj,SolverTemplateName, SolverTemplateFile)
            %Apply a ProjectTemplate.
            VBA = fileread(SolverTemplateFile);
            switch lower(SolverTemplateName)
                case {'frequency','f','freq'}
                    Description = 'define frequency domain solver parameters';
                case {'time','time domain','td','t'}
                    Description = 'define time domain solver parameters';
            end
            obj.update([Description],VBA);
        end
        function defineFloquetModes(obj,nModes)
            
            VBA = sprintf(['With FloquetPort\n',...
                '.Reset\n',...
                '.SetDialogTheta "0"\n',...
                '.SetDialogPhi "0"\n',...
                '.SetPolarizationIndependentOfScanAnglePhi "0.0", "False"\n',...
                '.SetSortCode "+beta/pw"\n',...
                '.SetCustomizedListFlag "False"\n',...
                '.Port "Zmin"\n',...
                '.SetNumberOfModesConsidered "%d"\n',...
                '.SetDistanceToReferencePlane "0.0"\n',...
                '.SetUseCircularPolarization "False"\n',...
                '.Port "Zmax"\n',...
                '.SetNumberOfModesConsidered "%d"\n',...
                '.SetDistanceToReferencePlane "0.0"\n',...
                '.SetUseCircularPolarization "False"\n',...
                'End With'],nModes,nModes);
            obj.update('define Floquet Port boundaries',VBA);
        end
        function runSimulation(obj)
            switch obj.solver
                case 'f'
                    s = obj.mws.invoke('FDSolver'); % handle to frequency domain solver
                case 't'
                    s = obj.mws.invoke('Solver');   % handle to time domain solver
            end
            s.invoke('Start');
        end
        function [freq,sparam,sFileType] = getSParameters(obj,sParamType,parSweepNum) %#ok<INUSD>
            %Get the Sparameters from the 1D results in CST
            % CST.getSParameters will return all available S-Parameters
            % CST.getSParameters('S11') will return the S1,1 value in the
            % 1D result tree.
            % CST.getSParameters on its own will return all sparameters
            % from the most recent simulation.
            % CST.getSParameters('SZmax(1)Zmax(1)') will return the
            % reflection coefficient of mode 1 at the ZMax port for a unit
            % cell type simulation
            %
            % Examples:
            % %Open an existing simulation with results (e.g.)
            % CST = CST_MicrowaveStudio('C:\Users\Henry-Laptop\Documents\CST\BST\','BST_DRA_5GHz.cst')
            % % read in all sparameters
            % [freq,sparam,stype] = CST.getSParameters;
            % % read in S11
            % [freq,s11,type] = CST.getSParameter('S11')
            %
            % NOTE: We can only currently read in data from the latest
            % parameter sweep, and cannot obtain the results from previous
            % simulations yet. Hopefully this will be added in a future
            % version.
            % See Examples\Metasurface for more
            %
            
            %I dont know the method CST uses to name its sparameter result
            %files - but it seems they enter "(1)" after each port (I guess
            %to indicate the number associated with each parameter sweep).
            %I cannot work out how to get data from any of the previous
            %parameter sweeps, and can only currently obtain the data from
            %the latest simulation
            %
            %Update - it seems we need to use something like:
            % 'GetResultIDsFromTreeItem( name sTreePath )'
            
            parSweepNum = 1; %To be used in future version
            
            %             if nargin == 2
            %                %Check if only 1 parameter sweep has been performed - We
            %                need to somehow acces the result navigator and check the
            %                number of entries...
            %                How to do this?
            %                if nSweep == 1
            %                     parSweepNum = 1;
            %                     nn = 3;
            %                end
            %             end
            
            
            try
                if nargin == 3 || nargin == 2
                    
                    if numel (sParamType) == 3
                        sparameterString = sprintf('%s(%d)%s(%d)',sParamType(1:2),parSweepNum,sParamType(3),parSweepNum);
                    end
                    
                    fname = fullfile(obj.mws.invoke('GetProjectPath','Result'),['c',sparameterString,'.sig']);
                    
                    result1D = obj.mws.invoke('Result1DComplex',fname);
                    freq = result1D.invoke('GetArray','x');
                    s_real = result1D.invoke('GetArray','yre');
                    s_im = result1D.invoke('GetArray','yim');
                    sparam = s_real + 1i*s_im;
                    sFileType = sParamType;
                    
                    return %Results has been successfully obtained so return
                end
            catch
                warning('The requested S-Param type "%s" was not found, All available S-parameters have been output',sParamType)
            end
            
            
            %Search trough all s-parameter results and return all available
            %results. If the requested sparam type is not available output
            %empty parameters. If a defined s-parameter has been requested,
            %output all results that fit that string only
            
            %---------For Future Use-----------
            %             if nargin == 2
            %                 sParamType = [sParamType(1:2),',',sParamType(3)];
            %                 if ~obj.mws.invoke('SelectTreeItem',['1D Results\S-Parameters\',sParamType])
            %                     obj.mws.invoke('SelectTreeItem','1D Results\S-Parameters');
            %                 end
            %             else
            %                 obj.mws.invoke('SelectTreeItem','1D Results\S-Parameters');
            %             end
            
            
            obj.mws.invoke('SelectTreeItem','1D Results\S-Parameters');
            
            plot1D = obj.mws.invoke('Plot1D');
            nCurves = plot1D.invoke('GetNumberOfCurves');
            sFileType = cell(0,1);
            
            for i = 1:nCurves
                fname = plot1D.invoke('GetCurveFileName',i-1);
                
                [~,sFileType{end+1},~] = fileparts(fname); %#ok<AGROW>
                %remove the c in sFileType - is this always the case?
                sFileType{end} = sFileType{end}(2:end);
                result1D = obj.mws.invoke('Result1DComplex',fname);
                
                
                try
                    freq(:,i) = result1D.invoke('GetArray','x'); %This will fail if curves have different numbers of points
                    s_real = result1D.invoke('GetArray','yre');
                    s_im = result1D.invoke('GetArray','yim');
                    
                    sparam(:,i) = s_real + 1i*s_im; %#ok<AGROW>
                    
                catch err
                    warning('Error Occurred when fetching sparameter data - maybe the vectors contain a different number of frequency points');
                    rethrow(err);
                end
            end
            if numel(sFileType) == 1
                sFileType = sFileType{1};
            end
        end
        function [ExpFileName]...
                  = ExportSParaResult(obj,SParaItemName,ExportFolder,varargin)
            
            p = inputParser;
            
            %Access S-Parameter item
            if ~obj.mws.invoke('SelectTreeItem',['1D Results\S-Parameters\',SParaItemName])
                warning('CST_MicrowaveStudio:ResultFileDoesntExist',...
                    'S-Parameter result does not exist.')
                ExpFileName = 'Null';
                return;
            end
            
            plot1DObj = obj.mws.invoke('Plot1D');
            plot1DObj.invoke('PlotView','magnitudedb');
            plot1DObj.invoke('Plot');
            
            %Export S-Para amplitude
            %SParaExpFolder = fullfile(ExportFolder, 'Farfields');
            if exist(ExportFolder,'dir') ~= 7
                mkdir(ExportFolder);
            end
                
            ExpFileName = ['S-Parameters_' SParaItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, ExpFileName);
            ASCIIExportObj = obj.mws.invoke('ASCIIExport');
            ASCIIExportObj.invoke('Reset');
            ASCIIExportObj.invoke('SetVersion', '2010');
            ASCIIExportObj.invoke('FileName', FullExpFile);
            ASCIIExportObj.invoke('Execute');
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [ExpFileName]...
                  = ExportSParaResultLast(obj,SParaItemName,ExportFolder,varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = ['1D Results\S-Parameters\',SParaItemName];
            %Get last result ID, shoudl be a string like '3D:RunID:0'
            LastResID = obj.mws.invoke('GetLastResultID');
            
            %Access to the result object containing the last S parameter result
            LastSParaObj = ResultTreeObj.invoke('GetResultFromTreeItem', TreeItem, LastResID);
            
            if LastSParaObj.invoke('GetResultObjectType') ~= '1DC'
                warning('CST_MicrowaveStudio:S parameter result type error')
                ExpFileName = 'Null';
                return;
            end
            
            %Get frequencies as X axis
            FreqVec = LastSParaObj.invoke('GetArray', 'x');
            
            %Get magnitude
            SParaMagObj = LastSParaObj.invoke('Magnitude');
            SparaMagVec = SParaMagObj.invoke('GetArray', 'y');
            
            %Get Phase
            SParaPhObj = LastSParaObj.invoke('Phase');
            SparaPhVec = SParaPhObj.invoke('GetArray', 'y');
            
            % Create export matrix
            ExportDataMat = [FreqVec; SparaMagVec; SparaPhVec];
            
            %Export S-Para to file
            if exist(ExportFolder,'dir') ~= 7
                mkdir(ExportFolder);
            end
            ExpFileName = ['S-Parameters_' SParaItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, ExpFileName);
            fileID = fopen(FullExpFile,'w');
            %fprintf(fileID,'%6s %12s\n','x','exp(x)');
            fprintf(fileID,'%.7e\t%.7e\t%.7e\r\n', ExportDataMat);
            fclose(fileID);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [ExpFileName]...
                  = ExportSParaResultRunID(obj,SParaItemName,ExportFolder,ResID,varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = ['1D Results\S-Parameters\',SParaItemName];
            %Get result ID, shoudl be a string like '3D:RunID:0'
            % LastResID = obj.mws.invoke('GetLastResultID');
            % ResID = ['3D:RunID:', str(RunID)];
            
            %Access to the result object containing the last S parameter result
            SParaObj = ResultTreeObj.invoke('GetResultFromTreeItem', TreeItem, ResID);
            
            if SParaObj.invoke('GetResultObjectType') ~= '1DC'
                warning('CST_MicrowaveStudio:S parameter result type error')
                ExpFileName = 'Null';
                return;
            end
            
            %Get frequencies as X axis
            FreqVec = SParaObj.invoke('GetArray', 'x');
            
            %Get magnitude
            SParaMagObj = SParaObj.invoke('Magnitude');
            SparaMagVec = SParaMagObj.invoke('GetArray', 'y');
            
            %Get Phase
            SParaPhObj = SParaObj.invoke('Phase');
            SparaPhVec = SParaPhObj.invoke('GetArray', 'y');
            
            % Create export matrix
            ExportDataMat = [FreqVec; SparaMagVec; SparaPhVec];
            
            %Export S-Para to file
            if exist(ExportFolder,'dir') ~= 7
                mkdir(ExportFolder);
            end
            ExpFileName = ['S-Parameters_' SParaItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, ExpFileName);
            fileID = fopen(FullExpFile,'w');
            %fprintf(fileID,'%6s %12s\n','x','exp(x)');
            fprintf(fileID,'%.7e\t%.7e\t%.7e\r\n', ExportDataMat);
            fclose(fileID);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [ExpFileName]...
                  = ExportPostProcResultRunID(obj,PostProcItemName,ExportFolder,ResID,varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = ['Tables\1D Results\',PostProcItemName];
            %Get result ID, shoudl be a string like '3D:RunID:0'
            % LastResID = obj.mws.invoke('GetLastResultID');
            % ResID = ['3D:RunID:', str(RunID)];
            
            %Access to the result object containing the last S parameter result
            PostProcObj = ResultTreeObj.invoke('GetResultFromTreeItem', TreeItem, ResID);
            
            %{
            if PostProcObj.invoke('GetResultObjectType') ~= '1DC'
                warning('CST_MicrowaveStudio:S parameter result type error')
                ExpFileName = 'Null';
                return;
            end
            %}
            
            %Get frequencies as X axis
            FreqVec = PostProcObj.invoke('GetArray', 'x');
            
            %Get real
            PostProcRealObj = PostProcObj.invoke('Real');
            PostProcRealVec = PostProcRealObj.invoke('GetArray', 'y');
            
            %Get Imaginary
            PostProcImObj = PostProcObj.invoke('Imaginary');
            PostProcImVec = PostProcImObj.invoke('GetArray', 'y');
            
            % Create export matrix
            ExportDataMat = [FreqVec; PostProcRealVec; PostProcImVec];
            
            %Export S-Para to file
            if exist(ExportFolder,'dir') ~= 7
                mkdir(ExportFolder);
            end
            ExpFileName = [PostProcItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, ExpFileName);
            fileID = fopen(FullExpFile,'w');
            %fprintf(fileID,'%6s %12s\n','x','exp(x)');
            fprintf(fileID,'%.7e\t%.7e\t%.7e\r\n', ExportDataMat);
            fclose(fileID);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [ExpFileName]...
                  = ExportTreeItemResultRunID(obj, TreePath, ItemName, ExportFolder, ResID, varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = [TreePath, ItemName];
            %Get result ID, shoudl be a string like '3D:RunID:0'
            % LastResID = obj.mws.invoke('GetLastResultID');
            % ResID = ['3D:RunID:', str(RunID)];
            
            %Access to the result object containing the last S parameter result
            ResultObj = ResultTreeObj.invoke('GetResultFromTreeItem', TreeItem, ResID);
            
            %{
            if PostProcObj.invoke('GetResultObjectType') ~= '1DC'
                warning('CST_MicrowaveStudio:S parameter result type error')
                ExpFileName = 'Null';
                return;
            end
            %}
            
            %Get frequencies as X axis
            FreqVec = ResultObj.invoke('GetArray', 'x');
            
            %Get real
            ResultRealObj = ResultObj.invoke('Magnitude');
            ResultRealVec = ResultRealObj.invoke('GetArray', 'y');
            
            %Get Imaginary
            ResultImObj = ResultObj.invoke('Phase');
            ResultImVec = ResultImObj.invoke('GetArray', 'y');
            
            % Create export matrix
            ExportDataMat = [FreqVec; ResultRealVec; ResultImVec];
            
            %Export S-Para to file
            if exist(ExportFolder,'dir') ~= 7
                mkdir(ExportFolder);
            end
            ExpFileName = [ItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, ExpFileName);
            fileID = fopen(FullExpFile,'w');
            %fprintf(fileID,'%6s %12s\n','x','exp(x)');
            fprintf(fileID,'%.7e\t%.7e\t%.7e\r\n', ExportDataMat);
            fclose(fileID);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [RunID_vec]...
                  = GetRunIDsFromResult(obj,SParaItemName,varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = ['1D Results\S-Parameters\',SParaItemName];
            %Get result ID, shoudl be a string like '3D:RunID:0'
            % RunID_vec = obj.mws.invoke('GetResultIDsFromTreeItem', TreeItem);
            %Access to the result object containing the last S parameter result
            RunID_vec = ResultTreeObj.invoke('GetResultIDsFromTreeItem', TreeItem);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [RunID_vec]...
                  = GetRunIDsFromTreeItem(obj, TreePath, ItemName, varargin)
            
            p = inputParser;
            
            %Access to the ResultTree object
            ResultTreeObj = obj.mws.invoke('ResultTree');
            
            %Get the tree item string for S parameters
            TreeItem = [TreePath, ItemName];
            %Get result ID, shoudl be a string like '3D:RunID:0'
            % RunID_vec = obj.mws.invoke('GetResultIDsFromTreeItem', TreeItem);
            %Access to the result object containing the last S parameter result
            RunID_vec = ResultTreeObj.invoke('GetResultIDsFromTreeItem', TreeItem);
            
            %fprintf('Export S-Parameter Result:\n%s\n',FullExpFile);
        end
        function [Eabs,Etheta_am,Ephi_am,Etheta_ph,Ephi_ph] = getFarField(obj,freq,theta,phi,varargin)
            % CST.getFarField(freq,theta,phi) returns the Etheta and EPhi
            % farfield results at the specified frequency and polar angles
            % defined by theta and phi. the default units is 'directivity'.
            % CST.getFarField(freq,theta,phi,'property',value) to define
            % the units and the farfield result identifier
            %
            % Properties:
            % ffid: farfield identifier frequency (default: ['farfield (f=',num2str(freq),') [1]']
            % units: units of the farfield plot. Options are:
            %   'directivity' (default), 'gain', 'realized gain', 'efield',
            %   'epattern', 'hfield', 'pfield', 'rcs', 'rcsunits',' rcssw'
            %
            % See Examples\dipole for more
            
            %Future update to allow user to specify the field component
            %outputs that they require?
            
            % if a numerical input is defined for ffid, use the
            % conventional CST farfield naming format to define monitor,
            % otherwise the input should be a string defining the name of
            % the farfield monitor
            
            p = inputParser;
            p.addParameter('ffid',[])
            p.addParameter('units','directivity')
            
            %The [1] in ffid below is actually related to the 'simulation identifier' but most commonly refers to the port number, port 1 is most common
            p.addParameter('SimID',1) %This is ignored if the ffid string is input as an argument
            
            
            p.parse(varargin{:});
            
            ffid = p.Results.ffid;
            units = p.Results.units;
            SimID = p.Results.SimID;
            
            if isempty(ffid)
                ffid = ['farfield (f=',num2str(freq),') [',num2str(SimID),']']; %e.g. "farfield (f=2.4)[1]"
            end
            
            if ~obj.mws.invoke('SelectTreeItem',['Farfields\',ffid])
                error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                    'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results')
            end
            
            
            ff = obj.mws.invoke('farfieldplot');
            ff.invoke('Reset');
            ff.invoke('setPlotMode',units);
            ff.invoke('plotType','3d');
            ff.invoke('plot');
            
            
            for p = phi
                for t = theta
                    ff.invoke('AddListEvaluationPoint',t, p, 0, 'spherical','frequency',freq);
                end
            end
            
            ff.invoke('CalculateList','');
            %These take quite a long time. We could speed things up by
            %allowing user to specify which data they want - if only EAbs
            %is required then it will be 5x quicker.
            %
            %As a temporary way to speed up data output, use nargout to
            %determine which patterns user has asked for...
            
            nTheta = numel(theta);
            nPhi = numel(phi);
            
            if nargout >= 1
                Eabs = ff.invoke('GetList','Spherical abs');
                Eabs = reshape(Eabs,nTheta,nPhi);
            end
            if nargout >= 2
                theta_am = ff.invoke('GetList','Spherical linear theta abs');
                Etheta_am = reshape(theta_am,nTheta,nPhi);
            end
            if nargout >= 3
                phi_am = ff.invoke('GetList','Spherical linear phi abs');
                Ephi_am = reshape(phi_am,nTheta,nPhi);
            end
            if nargout >= 4
                theta_ph = ff.invoke('GetList','Spherical linear theta phase');
                Etheta_ph = reshape(theta_ph,nTheta,nPhi);
            end
            if nargout >= 5
                phi_ph = ff.invoke('GetList','Spherical linear phi phase');
                Ephi_ph = reshape(phi_ph,nTheta,nPhi);
            end
            %position_theta = ff.invoke('GetList','Point_T');
            %position_phi   = ff.invoke('GetList','Point_P');
            
        end
        function setFarfieldPlotOption(obj,FarfieldPlotOptionFile)
            %Apply a ProjectTemplate.
            VBA = fileread(FarfieldPlotOptionFile);
            
            obj.update(['farfield plot options'],VBA);
        end
        function [ExpFileName]...
                  = ExportFarfieldResult(obj,Freq,ExcitationId,ExportFolder,varargin)
            % CST.getFarField(freq,theta,phi) returns the Etheta and EPhi
            % farfield results at the specified frequency and polar angles
            % defined by theta and phi. the default units is 'directivity'.
            % CST.getFarField(freq,theta,phi,'property',value) to define
            % the units and the farfield result identifier
            % 
            
            p = inputParser;
            p.addParameter('ffid',[])
            p.addParameter('units','directivity')
            
            %Access Farfield item e.g. "farfield (f=85)[1]"
            FarfieldItemName = ['farfield (f=',num2str(Freq),') [',ExcitationId,']'];
            if ~obj.mws.invoke('SelectTreeItem',['Farfields\',FarfieldItemName])
                warning('CST_MicrowaveStudio:ResultFileDoesntExist',...
                    'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results');
                ExpFileName = 'Null';
                return;
            end
            
            
            
            %Export all farfield components in ASCII format
            FarfieldExpFolder = fullfile(ExportFolder, 'Farfields');
            if exist(FarfieldExpFolder,'dir') ~= 7
                mkdir(ExportFolder, 'Farfields');
            end
                
            ExpFileName = [FarfieldItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, 'Farfields', ExpFileName);
            ASCIIExportObj = obj.mws.invoke('ASCIIExport');
            ASCIIExportObj.invoke('Reset');
            ASCIIExportObj.invoke('SetVersion', '2010');
            ASCIIExportObj.invoke('FileName', FullExpFile);
            ASCIIExportObj.invoke('Execute');
            %fprintf('Export Farfield Result:\n%s\n',FullExpFile);
        end
        function [Dir_max, SLL, F2B, Beamwidth, RadEff, TotalEff, MainLobeDir, ExpFileName]...
                  = getFarfieldResult(obj,Freq,ExcitationId,PlotMode,...
                  AntType,PolType,ThetaStep,PhiStep,ExportFolder,ViewPhiCut,FieldCompName,varargin)
            % CST.getFarField(freq,theta,phi) returns the Etheta and EPhi
            % farfield results at the specified frequency and polar angles
            % defined by theta and phi. the default units is 'directivity'.
            % CST.getFarField(freq,theta,phi,'property',value) to define
            % the units and the farfield result identifier
            % 
            
            p = inputParser;
            p.addParameter('ffid',[])
            p.addParameter('units','directivity')
            
            %Access Farfield item e.g. "farfield (f=85)[1]"
            FarfieldItemName = ['farfield (f=',num2str(Freq),') [',ExcitationId,']'];
            if ~obj.mws.invoke('SelectTreeItem',['Farfields\',FarfieldItemName])
                error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                    'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results')
            end
            
            %Set Farfield plot options to correct mode
            FarfieldPlotObj = obj.mws.invoke('FarfieldPlot');
            FarfieldPlotObj.invoke('Reset');
            FarfieldPlotObj.invoke('Plottype', '3d'); %3d/cartesian/polar...
            FarfieldPlotObj.invoke('SetLockSteps', 'False');
			FarfieldPlotObj.invoke('Step', ThetaStep);
			FarfieldPlotObj.invoke('Step2', PhiStep);
            FarfieldPlotObj.invoke('SetTheta360', 'True');
            FarfieldPlotObj.invoke('SymmetricRange', 'True');
            FarfieldPlotObj.invoke('SetPlotMode', PlotMode); %directivity/gain/efield...
            FarfieldPlotObj.invoke('UseFarfieldApproximation', 'True');
            FarfieldPlotObj.invoke('Origin', 'zero');
            FarfieldPlotObj.invoke('SetAntennaType', AntType); %'directional_circular'...
            FarfieldPlotObj.invoke('SetCoordinateSystemType', 'ludwig3');
            FarfieldPlotObj.invoke('SetPolarizationType', PolType); %Supported values are "linear", "circular" and "slant".
            FarfieldPlotObj.invoke('EnablePhaseCenterCalculation', 'True');
            FarfieldPlotObj.invoke('SetPhaseCenterComponent', 'boresight'); %enum{"theta", "phi", "boresight"}
			FarfieldPlotObj.invoke('SetPhaseCenterPlane', 'both'); % enum{"both", "e-plane", "h-plane"}
            FarfieldPlotObj.invoke('ShowPhaseCenter', 'True');
            FarfieldPlotObj.invoke('Plot');
            PlotObj = obj.mws.invoke('Plot');
            PlotObj.invoke('Update');
            
            %Export all farfield components in ASCII format
            FarfieldExpFolder = fullfile(ExportFolder, 'Farfields');
            if exist(FarfieldExpFolder,'dir') ~= 7
                mkdir(ExportFolder, 'Farfields');
            end
                
            ExpFileName = [FarfieldItemName,'.txt'];
            FullExpFile = fullfile(ExportFolder, 'Farfields', ExpFileName);
            ASCIIExportObj = obj.mws.invoke('ASCIIExport');
            ASCIIExportObj.invoke('Reset');
            ASCIIExportObj.invoke('SetVersion', '2010');
            ASCIIExportObj.invoke('FileName', FullExpFile);
            ASCIIExportObj.invoke('Execute');
            fprintf('Export Farfield Result:\n%s\n',FullExpFile);

            %Set to polar type to get Summary Results
            FarfieldPlotObj.invoke('Plottype', 'polar');
            FarfieldPlotObj.invoke('Vary', 'angle1');
            FarfieldPlotObj.invoke('Phi', ViewPhiCut);
            FarfieldPlotObj.invoke('Step', ThetaStep);
            FarfieldPlotObj.invoke('SetTheta360', 'True');
            FarfieldPlotObj.invoke('SymmetricRange', 'True');
            FarfieldPlotObj.invoke('Plot');
            PlotObj.invoke('Update');
            %Get Dir_max, SLL, F2B, Beamwidth, RadEff, TotalEff, MainLobeDir,
            FarfieldPlotObj.invoke('SelectComponent',FieldCompName);
            Dir_max = FarfieldPlotObj.invoke('Getmax');
            SLL = FarfieldPlotObj.invoke('GetSideLobeLevel');
            F2B = FarfieldPlotObj.invoke('GetFrontToBackRatio');
            Beamwidth = FarfieldPlotObj.invoke('GetAngularWidthXdB');
            RadEff = FarfieldPlotObj.invoke('GetRadiationEfficiency');
            TotalEff = FarfieldPlotObj.invoke('GetTotalEfficiency');
            MainLobeDir = FarfieldPlotObj.invoke('GetMainLobeDirection');
            
            % View in Cartesion mode
            FarfieldPlotObj.invoke('Plottype', 'cartesian'); %3d/cartesian/polar...
            FarfieldPlotObj.invoke('Plot');
            PlotObj.invoke('Update');
        end
        function [meshOut] = getMeshInfo(obj)
            if obj.solver == "f"
                error('CST_MicrowaveStudio:getMeshPoints:SolverTypeError',...
                    'This function is currently not available for results from the frequency domain solver');
            end
            
            mesh = obj.mws.invoke('Mesh');
            nP = mesh.invoke('GetNP');
            
            X = zeros(nP,1);
            Y = zeros(nP,1);
            % If we just try to get every mesh point for each axis, it can
            % take a very long time. If we loop through X until it repeates
            % then we know nX. We can then loop through nY and nZ:
            % index = ix + iy*nx + iz*nx*ny < .GetLength = nx*ny*nz
            for i = 1:nP
                X(i) = mesh.invoke('GetXPos',i-1); %Mesh in CST is zero-indexed
                if X(i) == X(1) && i~= 1
                    X = X(1:i-1);
                    break
                end
            end
            nX = numel(X);
            for i = 1:nP
                idx = (i-1)*nX;
                Y(i) = mesh.invoke('GetYPos',idx);
                if Y(i) == Y(1) && i~= 1
                    Y = Y(1:i-1);
                    break
                end
            end
            nY = numel(Y);
            nZ = nP/nX/nY;
            Z = zeros(nZ,1);
            for i = 1:nZ
                idx = (i-1)*nX*nY;
                Z(i) = mesh.invoke('GetZPos',idx);
            end
            
            meshOut = struct('X',X,'Y',Y,'Z',Z,'nX',nX,'nY',nY,'nZ',nZ,'meshPoints',nP);
            
        end
        
        function [outputField,XPos,YPos,ZPos] = getEFieldVector(obj,freq,fieldComponent,plane,location,varargin)
            % [This function is not finalized and may change in a future
            % version. Follow the examples for information on how to use
            % the function correctly. There are currently quite a few bugs.
            % For example, you can only retreive the fields correctly in
            % all planes when open (PML) boundary conditions are applied in
            % all directions! This works for resutls from the Time Domain
            % solver only!]
            %
            % Get the Electric field strength and phase for a particular
            % component (Ex, Ey, Ez, or E_Abs) on a single plane (XY, XZ or YZ) at a
            % specified location in the simulation space. This is currently
            % limited to Electric Field only but will be updated to include
            % the opttion to specify H-field/Surface currents in future
            %
            % The location refers to the index of the mesh cell in the
            % specified plane. e.g. a 'location' = 0 in the 'XY' will
            % return the field at the first z point in the simulation
            % space. If the 'location' is negative, the field at the halfway
            % point in the specified plane will be returned
            %
            % Examples:
            % %Get the absolute Electric field value from a monitor at 2.5
            % %GHz in the yz plane at the 10th mesh cell along the x axis
            % [Efield_abs,x,y,z] = CST.getEFieldVector(2.5,'abs','yz',10);
            %
            % Get Ez directed field at the middle mesh cell in the xy plane
            % [Ez,x,y,z] = CST.getEFieldVector(2.5,'Ez','xy',-1);
            %
            % See Examples\dipole for working examples
            %
            % NOTE: There are currently problems specifying the field
            % identifiers when simulation has been run with the frequency
            % domain solver, due to the way CST names the result files.
            % Furthermore, you cannot just retrieve the field from a plane
            % as tetrahedral meshing does not automatically just mesh a
            % single plane like the time domain hexahedral mesh. It will
            % probably be easier to save the fields using one of CSTs
            % readily available macros over the given plane, and then
            % import into matlab seperately
            %
            
            if obj.solver == "f"
                error('CST_MicrowaveStudio:getEfieldVector:SolverTypeError',...
                    'This function is currently not available for results from the frequency domain solver');
            end
            
            p = inputParser;
            p.addParameter('ffid',[])
            %The [1] in SimID below is actually related to the 'simulation
            %identifier'. It most commonly refers to the port number, port
            %1 is most common. It can be found by looking at the
            %information in the square brackets after the field monitor
            %results in CST
            p.addParameter('SimID',1) %This is ignored if the ffid string is input as an argument
            
            p.parse(varargin{:});
            
            field_id = p.Results.ffid;
            SimID = p.Results.SimID;
            
            if isempty(field_id)
                %Update this for specified field type (E/H)
                field_id = ['^e-field (f=',num2str(freq),')_',num2str(SimID),'']; %e.g. "farfield (f=2.4)[1]"
                %A better solution would be to search through the available
                %.m3d files for any matching the frequency/sim id
                
            else
                field_id = ['^',field_id];
            end
            
            %For Future Info:
            %If the tetrahedral mesh is used, the field_id uses a different
            %string and different type of file with a string like this:
            % 'e-field (#0001)_1(1).m3t'
            %There appear to be some .m3m files which contain the field_id
            %filenames similar to the transient solver results as above,
            %which may contain the information
            
            
            try
                fieldObject = obj.mws.invoke('Result3D',field_id);
            catch
                try
                    %Sometimes there is a ',1' at the end of the file
                    %name...
                    fieldObject = obj.mws.invoke('Result3D',[field_id,',1']);
                catch
                    error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                        'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results')
                end
            end
            %The 'get' methods are indexed using the following equation:
            % index = ix + iy*nx + iz*nx*ny < .GetLength = nx*ny*nz
            
            nX = fieldObject.invoke('GetNx');
            nY = fieldObject.invoke('GetNy');
            nZ = fieldObject.invoke('GetNz');
            
            switch lower(plane)
                case 'xy'
                    ix = 0:nX-1;
                    iy = 0:nY-1;
                    iy = (iy*nX)';
                    index = iy+ix;
                    if location < 0
                        index = index+(round(nZ/2)-1)*nX*nY;
                    elseif location > nZ
                        warning('The specified Z location of the xy plane is larger than the number of z-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location*nX*nY;
                    end
                case 'xz'
                    ix = 0:nX-1;
                    iz = 0:nZ-1;
                    iz = (iz*nX*nY)';
                    index = iz+ix;
                    if location < 0
                        index = index+(round(nY/2)-1)*nY;
                    elseif location > nY
                        warning('The specified Y location of the xz plane is larger than the number of y-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location*nY;
                    end
                case 'yz'
                    iy = 0:nY-1;
                    iy = (iy*nX);
                    iz = 0:nZ-1;
                    iz = (iz*nX*nY)';
                    
                    index = iz+iy;
                    if location < 0
                        index = index+(round(nX/2)-1);
                    elseif location > nX
                        warning('The specified x location of the yz plane is larger than the number of x-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location; %is this correct?
                    end
            end
            
            %there are a few ways to return the field values, but i dont
            %know the quickest way yet...
            %             re = zeros(numel(index),1);
            %             im = zeros(numel(index),1);
            %
            %             for iField = 1:numel(index)
            %                 re(iField) = fieldObject.invoke('GetXRe',index(iField));
            %                 im(iField) = fieldObject.invoke('GetXIm',index(iField));
            %             end
            
            switch lower(fieldComponent)
                case {'ex','x'}
                    re =  fieldObject.invoke('GetArray','xre');
                    im =  fieldObject.invoke('GetArray','xim');
                case {'ey','y'}
                    re =  fieldObject.invoke('GetArray','yre');
                    im =  fieldObject.invoke('GetArray','yim');
                case {'ez','z'}
                    re =  fieldObject.invoke('GetArray','zre');
                    im =  fieldObject.invoke('GetArray','zim');
                case {'abs'}   %This is a problem when using closed boundaries!
                    reX =  fieldObject.invoke('GetArray','xre');
                    imX =  fieldObject.invoke('GetArray','xim');
                    reY =  fieldObject.invoke('GetArray','yre');
                    imY =  fieldObject.invoke('GetArray','yim');
                    reZ =  fieldObject.invoke('GetArray','zre');
                    imZ =  fieldObject.invoke('GetArray','zim');
                    
                    Ex = reX + 1i*imX;
                    Ey = reY + 1i*imY;
                    Ez = reZ + 1i*imZ;
                    
                    if numel(Ex) ~= numel(Ey) || numel(Ex) ~= numel(Ez)
                        error("The different components of the E-field vectors appear to have a different number"...
                            + " of elements. This has not been accounted for and results in an error")
                    end
                    
                    re = (abs(Ex) + abs(Ey) + abs(Ez));
                    im = zeros(size(re));
            end
            
            re = re(index+1);
            im = im(index+1);
            outputField = re+1i*im;
            
            %Retrieve the actual XY,/XZ/YZ meshgrid coordinates so the
            %field can be plotted to scale
            %This takes quite a long time, so will only be output if the
            %user requests the coordinates as output options. May be a
            %better idea to use the getMeshInfo Method if repeated calls to
            %the function are required
            if nargout > 1
                mesh = obj.mws.invoke('Mesh');
                fprintf('Retrieving Mesh Coordinates...\n');
                switch lower(plane)
                    case {'xy'}
                        XPos = zeros(1,nX);
                        YPos = zeros(nY,1);
                        
                        for i = 1:nX
                            idx = index( (i-1)*nY + 1 );
                            XPos(i) = mesh.invoke('GetXPos',idx);
                        end
                        for i = 1:nY
                            YPos(i) = mesh.invoke('GetYPos',index(i));
                        end
                        
                        ZPos = mesh.invoke('GetZPos',index(1));
                    case {'xz'}
                        XPos = zeros(1,nX);
                        ZPos = zeros(nZ,1);
                        
                        for i = 1:nX
                            idx = index( (i-1)*nZ + 1 );
                            XPos(i) = mesh.invoke('GetXPos',idx);
                        end
                        for i = 1:nZ
                            ZPos(i) = mesh.invoke('GetZPos',index(i));
                        end
                        
                        YPos = mesh.invoke('GetYPos',index(1));
                    case {'yz'}
                        YPos = zeros(1,nY);
                        ZPos = zeros(nZ,1);
                        
                        for i = 1:nY
                            idx = index( (i-1)*nZ + 1 );
                            YPos(i) = mesh.invoke('GetYPos',idx);
                        end
                        for i = 1:nZ
                            ZPos(i) = mesh.invoke('GetZPos',index(i));
                        end
                        XPos = mesh.invoke('GetXPos',index(1));
                end
            end
        end
        function [idStrings] = getFieldIDStrings(obj,monitor)
            %getFieldIDStrings
            %   getFieldIDStrings returns a list of all the available 3D and
            %   farfield monitors, along with the identification strings which
            %   can be used as arguments in the getFarField and getEFieldVector
            %   functions
            %
            %   idStrings = getFieldIDStrings(monitor) returns the
            %   identidication strings for a particular type of field monitor.
            %   Acceptable strings for monitor are: 'farfield','3dfield' where
            %   'farfield' will return the identification strings for all
            %   farfield resutls (.ffm files), and 3dfield will return all
            %   e/h-field results (.m3d, Hexahederal Mesh Only)
            
            %We could use obj.folder, but this only really works when the
            %project has been saved. If a new file which hasnt yet been saved
            %and is stored in a CST temp directory is being used then this wont
            %work.
            %direc = fullfile(obj.folder,obj.filename,'Result');
            direc = obj.mws.invoke('GetProjectPath','Result');
            
            info = dir(direc);
            filenames = (arrayfun(@(x)x.name,info,'uni',false));
            f_strings = convertCharsToStrings(filenames);
            
            ffm = endsWith(f_strings,'.ffm');
            m3d = endsWith(f_strings,'.m3d');
            
            if nargin == 2
                switch lower(monitor)
                    case{'farfield','ffid','ffm','.ffm'}
                        idStrings = filenames(ffm);
                        
                        %Try to correct for the way the ffid and idstrings
                        %change with the first underscore and brackets
                        for i = 1:numel(idStrings)
                            idx = strfind(idStrings{i},'_');
                            if ~isempty(idx)
                                idStrings{i} = [idStrings{i}(1:idx(1)-1),' [',idStrings{i}(idx(1)+1:end)];
                            end
                        end
                        idStrings = replace(idStrings,'.ffm',']');
                        
                    case{'3dfield','efield','hfield','m3d','.m3d'}
                        idStrings = filenames(m3d);
                end
            else
                idStrings = filenames(ffm | m3d);
            end
            
            
        end
    end
    methods (Hidden, Access = protected)
        function update(obj,commandString,VBAstring)
            if obj.autoUpdate
                obj.addToHistory(commandString,VBAstring);
            else
                obj.VBAstring = [obj.VBAstring,VBAstring,newline];
            end
        end
    end
    methods (Static)
        function [CST,mws] = openFile(folder,filename)
            
            CST = actxserver('CSTStudio.application');
            CST.invoke('OpenFile',fullfile(folder,filename));
            mws = CST.Active3D;
        end
    end
end

