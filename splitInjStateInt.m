classdef splitInjStateInt < handle
    % Split injection state abstract interface    
    properties ( SetAccess = protected )
        StateRequest           int8                                         % Current number of injections
    end
    
    properties ( SetAccess = private )
        Listener                                                            % Pointer to listener object
    end
    
    properties ( Access = private )
        InjCalcs                                                            % Pointer to current concrete state
        InjCalibration         injArgs                                      % Custom event data for calibration  
    end
    
    methods
        function obj = splitInjStateInt( Source, CalStructure, DI_IPW_SEP_IDK )
            %-------------------------------------------------------------------------
            % Split injection state interface
            %
            % Single intake shot syntax:
            %
            % obj = splitInjStateInt( Source, CalStructure ); 
            %
            % Multiple intake shot syntax:
            %
            % obj = splitInjStateInt( Source, CalStructure, DI_IPW_SEP_IDK ); 
            % 
            % Input Arguments:
            % 
            % Source            --> context object
            % CalStructure      --> Structure of lookup table objects with
            %                       field names:
            %
            %   FNINJSLOPE1F        --> Injector slope: (fcnLookUp)
            %   FNDINJSLPCOR        --> Injection slope correction factor: (fcnLookUp)
            %   FNINJ_OP_DLY        --> Injector opening delay: (fcnLookUp)
            %   FNFUL_INJ_OFF_COR   --> Injector offset correction factor: (fcnLookUp)
            %   FNINJ_CL_DLY        --> Injector offset closing delay: (tableLookUp)
            %   DIMINPW1            --> Injection effecctive pulesidth:(double)
            %   DIPWADJ             --> Injection pulsewidth adjustment factor: (double)
            %   NUMCYL              --> Number of cylinders: (int8)
            %
            % DI_IPW_SEP_IDK    --> Minimum Separation between intake
            %                       injections.
            %--------------------------------------------------------------
            obj.StateRequest = Source.InjectionState;
            %--------------------------------------------------------------
            % Define the special event data property containing the
            % calibration data
            %--------------------------------------------------------------
            obj.InjCalibration = injArgs( Source, CalStructure,...
                                          DI_IPW_SEP_IDK );
            %--------------------------------------------------------------
            % Define listener for context class request. Switches injection
            % state automatically.
            %--------------------------------------------------------------
            Fh = @( Src, EventData )obj.selectNumInj( Source,...
                                                      obj.InjCalibration );
            obj.Listener = addlistener( Source, 'InjectionState',...
                                        'PostSet', Fh );
        end
        
        function [ LCL_FUEL_PW, DI_PWEFF ] = calcPulseWidth( obj, MF, FRP, FRT )
            %--------------------------------------------------------------
            % Calculate the total and effective injection pulsewidths 
            % in micro seconds
            %
            % [ LCL_FUEL_PW, DI_PWEFF ] = obj.calcPulseWidth( MF, FRP, FRT )
            %
            % Input Arguments:
            %
            % MF    --> Desired fuel mass [lb]
            % FRP   --> Injection pressure [PSI]
            % FRT   --> Inferred fuel rail temperature [deg F]
            %
            % Output Arguments:
            %
            % LCL_FUEL_PW   --> Total fuel pulsewidth
            % DI_PWEFF      --> Effective fuel pulsewidth
            %--------------------------------------------------------------
            [ LCL_FUEL_PW, DI_PWEFF ] = obj.InjCalcs.calcPulseWidth( MF, FRP, FRT );
        end
                
        function[ SOI, EOI ] = calc_pw_angle( obj, MF, N, FRP, FRT, SOI, varargin )
            %--------------------------------------------------------------
            % Calculate the start and end of injection angles. Note for
            % single shot the SOI is just passed through, but provides a
            % consistent interface with overloaded child methods.
            %
            % [ SOI, EOI ] = obj.calc_pw_angle( MF, N, FRP, FRT, SOI, SEP );
            %
            % Input Arguments:
            %
            % MF    --> Desired fuel mass [lb]
            % N     --> Engine speed [RPM]
            % FRP   --> Injection pressure [PSI]
            % FRT   --> Inferred fuel rail temperature [deg F]
            % SOI   --> Start of injection angle [deg BTDC Power stroke]
            % SEP   --> Seperation time [micro sec]. Not required for
            %           single shot injection
            %
            % Output Arguments:
            %
            % SOI   --> Start of injection angle [deg BTDC Power stroke]
            % EOI   --> End of injection angle [deg BTDC Power stroke]
            %
            % Note due to reference angle being TDC power stroke, EOI < SOI
            %--------------------------------------------------------------
            [ SOI, EOI ] = obj.InjCalcs.calc_pw_angle( MF, N, FRP, FRT,...
                                                       SOI, varargin{ : }  );
        end
        
        function Ok = constraintMet( obj, MF, N, FRP, FRT, SOI, LastAngle, varargin )
            %--------------------------------------------------------------------------
            % Out put a logical output to see if the constraints are met
            %
            % Ok = obj.constraintMet( MF, N, FRP, FRT, SOI, LastAngle, SEP );
            %
            % Input Arguments:
            %
            % MF        --> Desired fuel mass [lb]
            % N         --> Engine speed [RPM]
            % FRP       --> Injection pressure [PSI]
            % FRT       --> Inferred fuel rail temperature [deg F]
            % SOI       --> Start of injection angle [deg BTDC Power stroke]
            % LastAngle --> Last feasible end of injection angle [deg BTDC Power stroke]
            % SEP       --> Seperation time [micro sec]. Ignored for single shot 
            %               injection
            %---------------------------------------------------------------------------
            Ok = obj.InjCalcs.constraintMet( MF, N, FRP, FRT, SOI, LastAngle, varargin{ : } );
        end
    end % constructor and ordinary methods
    
    methods ( Access = protected )
        function selectNumInj( obj, ~, EventData )
            %--------------------------------------------------------------
            % Select the desired state on demand
            %
            % obj.selectNumInj( ~, EventData );
            %
            % Input Argument:
            %
            % Source        --> Handle of the object which is the source of
            %                   the event.
            % EventData     --> event.EventData object
            %--------------------------------------------------------------
            obj.StateRequest = EventData.AffectedObject.InjectionState;
            %--------------------------------------------------------------
            % Delete the existing concrete state object pointer
            %--------------------------------------------------------------
            if ishandle( obj.InjCalcs )
                delete( obj.InjCalcs );
            end
            
            switch obj.StateRequest
                case "SingleShot"
                    %------------------------------------------------------
                    % Single intake shot 
                    %------------------------------------------------------
                    obj.InjCalcs = singleShot( EventData.CalStructure );
                case "DoubleShot"
                    %------------------------------------------------------
                    % Two intake shots
                    %------------------------------------------------------
                    obj.InjCalcs = twoShots( EventData.CalStructure, ...
                                              EventData.DI_IPW_SEP_IDK);
                case "TripleShot"
                    %------------------------------------------------------
                    % Three intake shots
                    %------------------------------------------------------
                    obj.InjCalcs = threeShots( EventData.CalStructure, ...
                                              EventData.DI_IPW_SEP_IDK);
                otherwise
                    error('%4.0d injections not supported at this time', obj.StateRequest );
            end
        end
    end
end