classdef splitInj < handle
    % Split injection context class
    
    properties ( Access = protected )
        StateIntObj     splitInjStateInt                                    % splitInjStateInt object
    end
    
    properties ( SetObservable = true, AbortSet = true )
        InjectionState  splitInjectionCounts    {...                        % current injection state
                                  mustBePositive( InjectionState ),...      
                                  mustBeFinite( InjectionState ),...
                                  mustBeNonNan( InjectionState ),...
                                  mustBeNumeric( InjectionState ),...
                                  mustBeReal( InjectionState ),...
                                  mustBeLessThan( InjectionState, 4 )}                                      
    end
    
    methods
        function obj = splitInj( NumInj, CalStructure, DI_IPW_SEP_IDK )
            %--------------------------------------------------------------
            % Split injection context class
            %
            % obj = splitInj( NumInj );
            %
            % Input Arguments:
            %
            % NumInj    --> Initial state for number of injections {1}
            %--------------------------------------------------------------
            if ( nargin < 3 )
                error('Must supply all 3 arguments to constructor method for class "splitInj"');
            end
            if ( isempty( NumInj ) )
                NumInj = "SingleShot";                                      % Apply defaults
            end
            obj.StateIntObj = splitInjStateInt( obj, CalStructure,...       % Retain a pointer to the state interface
                                                DI_IPW_SEP_IDK );                      
            obj.InjectionState = NumInj;                                    % Set the inital number of injections
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
            [ LCL_FUEL_PW, DI_PWEFF ] = obj.StateIntObj.calcPulseWidth( MF, FRP, FRT );
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
            %               Default is BDC intake { 180 }.
            % SEP       --> Seperation time [micro sec], not required for
            %               single shot call
            %---------------------------------------------------------------------------
            if ( nargin < 7 ) || isempty( LastAngle )
                LastAngle = 180;
            end
            Ok = obj.StateIntObj.constraintMet( MF, N, FRP, FRT, SOI, LastAngle, varargin{ : } );
        end
        
        function [ SOI, EOI ] = calc_pw_angle( obj, MF, N, FRP, FRT, SOI, varargin )
            %--------------------------------------------------------------
            % Calculate the start and end of injection angles. Note for
            % single shot the SOI is just passed through, but provides a
            % consistent interface with overloaded child methods.
            %
            % [ SOI, EOI ] = obj.calc_pw_angle( MF, N, FRP, FRT, SOI );         % single shot call
            % [ SOI, EOI ] = obj.calc_pw_angle( MF, N, FRP, FRT, SOI, SEP );    % multiple shot call
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
            [ SOI, EOI ] = obj.StateIntObj.calc_pw_angle( MF, N, FRP, FRT, SOI, varargin{ : } );
        end

    end % constructor and ordinary methods
    
    methods
        function set.InjectionState( obj, Value )
            % Set the current desired number of injections
            obj.InjectionState = Value;
        end
    end
end