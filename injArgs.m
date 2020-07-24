classdef  ( ConstructOnLoad ) injArgs < event.EventData
    % injArgs - add custom event data to transmit to concrete states
    
    properties ( SetAccess = immutable )
        CalStructure    struct                                              % Structure defining injector calibration data 
        DI_IPW_SEP_IDK  double                                              % Minimum Separation between intake injections
        AffectedObject  splitInj                                            % source object
    end % immutable properties
    
    methods
        function eventData = injArgs( Source, CalStructure, DI_IPW_SEP_IDK )
            %--------------------------------------------------------------------------
            % Define custom event data for split injection calculation
            %
            % eventData = injArgs( Source, CalStructure, DI_IPW_SEP_IDK );
            %
            % Input Arguments:
            %
            % Source        --> Affected object
            % CalStructure  --> Structure of lookup table objects with
            %                   field names:
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
            %                       injections: (double)
            %--------------------------------------------------------------------------   
            eventData.CalStructure = CalStructure;                          % Supply calibration data
            eventData.DI_IPW_SEP_IDK = DI_IPW_SEP_IDK;                      % Minimum injector Separation
            eventData.AffectedObject = Source;
        end
    end % constructor and ordinary methods
end

