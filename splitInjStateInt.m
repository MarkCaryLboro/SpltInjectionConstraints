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
    end
    
    methods
        function obj = splitInjStateInt( Source )
            %--------------------------------------------------------------
            % Split injection state interface
            %
            % obj = splitInjStateInt( Source );
            %
            % Input Arguments:
            % 
            % Source    --> context object
            %--------------------------------------------------------------
            obj.StateRequest = Source.InjectionState;
            %--------------------------------------------------------------
            % Define listener for context class request. Switches injection
            % state automatically.
            %--------------------------------------------------------------
            obj.Listener = addlistener( Source, 'InjectionState',...
                                        'PostSet', @obj.selectNumInj );
        end
        
        function calcInjEvent( obj )
            obj.InjCalcs.injStateMsg();
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
                case 1
                    %------------------------------------------------------
                    % Single shot injection
                    %------------------------------------------------------
                    obj.InjCalcs = singleShot();
                case 2
                    %------------------------------------------------------
                    % Two intake shots
                    %------------------------------------------------------
                    obj.InjCalcs = twoShots();
                case 3
                    %------------------------------------------------------
                    % Three intake shots
                    %------------------------------------------------------
                    obj.InjCalcs = threeShots();
                otherwise
                    error('%4.0d injections not supported at this time', obj.StateRequest );
            end
        end
    end
end