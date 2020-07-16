classdef singleShot
    % Single intake fuel injection class: Computes pulsewidth size and
    % event angles
    
    properties ( SetAccess = immutable )
        FNINJSLOPE1F        fcnLookUp                                       % Injection slope as a function of fuel rail pressure
        FNDIINJSLPCOR       fcnLookUp                                       % Injection slope correction factor
        FNINJ_OP_DLY        fcnLookUp                                       % Injector opening delay
        FNFUL_INJ_OFF_COR   fcnLookUp                                       % Injection offset correction
        FNINJ_CL_DLY        tableLookUp                                     % Injector closing delay
        DIMINPW1            double                                          % Minimum injection pulsewidth clip
        DIPWADJ             double                                          % Incjection pulsewith adjustment
    end
    
    methods
        function obj = singleShot( CalStructure )
            %-------------------------------------------------------------------------
            % singleShot class constructor function
            %
            % obj = singleShot( CalStructure );
            % 
            % Input Arguments:
            %
            % CalStructure  --> Structure of lookup table objects with
            %                   field names:
            %
            %   FNINJSLOPE1F        --> Injector slope: (fcnLookUp)
            %   FNDINJSLPCOR        --> Injection slope correction factor: (fcnLookUp)
            %   FNINJ_OP_DLY        --> Injector opening delay: (fcnLookUp)
            %   FNFUL_INJ_OFF_COR   --> Injector offset correction factor: (fcnLookUp)
            %   FNINJ_CL_DLY        --> Injector offset closing delay: (tableLookUp)
            %   DIMINPW1            --> Injection effecctive pulesidth:(double)
            %   DIPWADJ             --> Injection pulsewidth adjustment factor
            %-------------------------------------------------------------------------
            if isstruct( CalStructure )
                %----------------------------------------------------------
                % Parse the input structure
                %----------------------------------------------------------
                [Ok, ImmutableNames] = obj.allImmutablePropsPresent( CalStructure );
                switch all( Ok )
                    case true
                        %--------------------------------------------------
                        % Assign the calibration data
                        %--------------------------------------------------
                        for Q = 1:numel( ImmutableNames )
                            obj.( ImmutableNames{ Q } ) =...
                                CalStructure.( ImmutableNames{ Q } );
                        end
                    otherwise
                        %--------------------------------------------------
                        % Print out missing field names & throw an error
                        %--------------------------------------------------
                        obj.missingCalData( ImmutableNames( ~Ok ) );
                        error('\nMissing Input Fields in Structure %s', inputname( 1 ) );
                end
            else
                error('Input argument must be a structure');
            end
        end
        
        function injStateMsg( obj )
            fprintf('\nSingle intake injection requested\n');
        end
    end % Constructor and ordinary methods
    
    methods ( Access = private )
        function Names = getImmutableProps( obj )
            %--------------------------------------------------------------
            % Return the names of all the immutable properties in the class
            %
            % Names = obj.getImmutableProps();
            %--------------------------------------------------------------
            MetaData = metaclass( obj );                                    % Create meta class object
            Mp = MetaData.PropertyList;                                     % List of properties and their attribute
            Names = string( { (Mp.Name) } );                                % Names of all properties
            Idx = strcmpi( "immutable", string( { Mp.SetAccess} ) );        % Point to all immutable properties
            Names = Names( Idx );
        end 
        
        function [ Ok, Names ] = allImmutablePropsPresent( obj, CalStructure )
            %--------------------------------------------------------------
            % Check that all immutable property fields are defined.
            %
            % [ Ok, Names ] = obj.allImmutablePropsPresent( CalStructure );
            %
            % Input Arguments:
            %
            % CalStructure  --> Structure of lookup table objects with
            %                   field names:
            %
            %   FNINJSLOPE1F        --> Injector slope: (fcnLookUp)
            %   FNDINJSLPCOR        --> Injection slope correction factor: (fcnLookUp)
            %   FNINJ_OP_DLY        --> Injector opening delay: (fcnLookUp)
            %   FNFUL_INJ_OFF_COR   --> Injector offset correction factor: (fcnLookUp)
            %   FNINJ_CL_DLY        --> Injector offset closing delay: (tableLookUp)
            %   DIMINPW1            --> Injection effecctive pulesidth:(double)
            %   DIPWADJ             --> Injection pulsewidth adjustment factor
            %
            % Output Arguments:
            %
            % Ok                    --> Array of logical variables
            %                           indicating immutable property field
            %                           is present
            % Names                 --> Names of immutable properties
            %--------------------------------------------------------------
            Names = obj.getImmutableProps();                                % Immutable properties
            Ok = false( numel( Names ), 1 );
            StructFields = fieldnames( CalStructure );                      % List of structure fields
            for Q = 1:numel( Names )
                %----------------------------------------------------------
                % Check to see if property name is present
                %----------------------------------------------------------
                Ok( Q ) = any( strcmpi( Names( Q ), StructFields ) );
            end
        end
    end % private methods
    
    methods( Static = true, Hidden = true )
        function missingCalData( Missing )
            %--------------------------------------------------------------
            % Print out the missing immutable property names
            %
            % obj.missingCalData( Missing );
            % singleShot.missingCalData( Missing );
            %
            % Input Arguments:
            %
            % Missing   --> String array of missing channel names
            %--------------------------------------------------------------
            fprintf('\nList of Missing Inputs Fields from Structure\n\n');
            for Q = 1:numel( Missing )
                fprintf('%s\n', Missing( Q ) );
            end
            fprintf('\n');
        end
    end % static & hidden methods
end