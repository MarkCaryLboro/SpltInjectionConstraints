classdef splitInj < handle
    % Split injection context class
    
    properties ( Access = protected )
        StateIntObj                                                         % splitInjStateInt object
    end
    
    properties ( SetObservable = true, AbortSet = true )
        InjectionState  int8    { mustBePositive( InjectionState ),...      % current injection state
                                  mustBeFinite( InjectionState ),...
                                  mustBeNonNan( InjectionState ),...
                                  mustBeNumeric( InjectionState ),...
                                  mustBeReal( InjectionState ) }                                      
    end
    
    methods
        function obj = splitInj( NumInj )
            %--------------------------------------------------------------
            % Split injection context class
            %
            % obj = splitInj( NumInj );
            %
            % Input Arguments:
            %
            % NumInj    --> Initial state for number of injections {1}
            %--------------------------------------------------------------
            if ( nargin < 1 )
                NumInj = 1;                                                 % Apply defaults
            end
            obj.StateIntObj = splitInjStateInt( obj );                      % Retain a pointer to the state interface
            obj.InjectionState = int8( NumInj );                            % Set the inital number of injections
        end
        
        function calcInjData( obj )
            obj.StateIntObj.calcInjEvent();
        end
    end % constructor and ordinary methods
    
    methods
        function set.InjectionState( obj, Value )
            % Set the current desired number of injections
            obj.InjectionState = int8( Value );
        end
    end
end