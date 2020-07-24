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
        DIPWADJ             double                                          % Injection pulsewith adjustment
        NUMCYL              int8                                            % Number of cylinders
    end
    
    properties ( SetAccess = protected, GetAccess = public )
        NumIntShots         int8                            = int8( 1 )     % number of intake shots
    end
    
    methods
        function obj = singleShot( CalStructure )
            %--------------------------------------------------------------------------
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
            %   DIPWADJ             --> Injection pulsewidth adjustment factor: (double)
            %   NUMCYL              --> Number of cylinders: (int8)
            %--------------------------------------------------------------------------
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
            Slope = obj.calcSlope( FRP, FRT );
            %--------------------------------------------------------------
            % Calculate the effective pulsewidth and apply the lower clip
            %--------------------------------------------------------------
            DI_PWEFF = 1000000*MF./Slope;
            Idx = DI_PWEFF < obj.DIMINPW1;
            DI_PWEFF( Idx ) = obj.DIMINPW1;
            %--------------------------------------------------------------
            % Calculate the injector offset
            %--------------------------------------------------------------
            Offset = obj.calcOffset( FRP, FRT, DI_PWEFF );
            %--------------------------------------------------------------
            % Calculate the total pulsewidth
            %--------------------------------------------------------------
            LCL_FUEL_PW = DI_PWEFF + Offset;
        end
        
        function [ SOI, EOI ] = calc_pw_angle( obj, MF, N, FRP, FRT, SOI )
            %--------------------------------------------------------------
            % Calculate the start and end of injection angles. Note for
            % single shot the SOI is just passed through, but provides a
            % consistent interface with overloaded child methods.
            %
            % [ SOI, EOI ] = obj.calc_pw_angle( MF, N, FRP, FRT, SOI );
            %
            % Input Arguments:
            %
            % MF    --> Desired fuel mass [lb]
            % N     --> Engine speed [RPM]
            % FRP   --> Injection pressure [PSI]
            % FRT   --> Inferred fuel rail temperature [deg F]
            % SOI   --> Start of injection angle [deg BTDC Power stroke]
            %
            % Output Arguments:
            %
            % SOI   --> Start of injection angle [deg BTDC Power stroke]
            % EOI   --> End of injection angle [deg BTDC Power stroke]
            %
            % Note due to reference angle being TDC power stroke, EOI < SOI
            %--------------------------------------------------------------
            Time2Angle = 1000000./( 6*N );                                  % time [micro sec] correpsonding to 1 deg of crank rotation
            %--------------------------------------------------------------
            % Calculate the total pulsewidth in microseconds
            %--------------------------------------------------------------
            LCL_FUEL_PW = obj.calcPulseWidth( MF, FRP, FRT );
            %--------------------------------------------------------------
            % Calculate the corresponding injection duration in deg
            %--------------------------------------------------------------
            LCL_FUEL_PW_ANGLE = LCL_FUEL_PW./Time2Angle;
            EOI = SOI - LCL_FUEL_PW_ANGLE;
        end
        
        function Ok = constraintMet( obj, MF, N, FRP, FRT, SOI, LastAngle )
            %--------------------------------------------------------------------------
            % Out put a logical output to see if the constraints are met
            %
            % Ok = obj.constraintMet( MF, N, FRP, FRT, SOI, LastAngle );
            %
            % Input Arguments:
            %
            % MF        --> Desired fuel mass [lb]
            % N         --> Engine speed [RPM]
            % FRP       --> Injection pressure [PSI]
            % FRT       --> Inferred fuel rail temperature [deg F]
            % SOI       --> Start of injection angle [deg BTDC Power stroke]
            % LastAngle --> Last feasible end of injection angle [deg BTDC Power stroke]
            %---------------------------------------------------------------------------
            [ ~, EOI ] = obj.calc_pw_angle( MF, N, FRP, FRT, SOI );
            Ok = ( EOI < LastAngle );
        end
    end % Constructor and ordinary methods
    
    methods ( Access = protected )
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
        
        function Slp = calcSlope( obj, FRP, FRT )
            %--------------------------------------------------------------
            % calculate the injector slope for the DI system
            %
            % Slp = obj.calcSlope( FRP, FRT );
            %
            % Input Arguments:
            %
            % FRP   --> Injection pressure [PSI]
            % FRT   --> Inferred fuel rail temperature [deg F]
            %--------------------------------------------------------------
            Slp = obj.FNINJSLOPE1F.interp( FRP )./obj.FNDIINJSLPCOR.interp( FRT );
        end
        
        function Off = calcOffset( obj, FRP, FRT, DI_PWEFF )
            %--------------------------------------------------------------
            % Calculate the injector offset for the DI system
            %
            % Off = obj.calcOffset( FRP, FRT );
            %
            % Input Arguments:
            %
            % FRP       --> Injection pressure [PSI]
            % FRT       --> Inferred fuel rail temperature [deg F]
            % DI_PWEFF  --> Effective pulsewidth [micro sec]
            %--------------------------------------------------------------
            Off = obj.FNINJ_OP_DLY.interp( FRP ) + obj.DIPWADJ +...
                  obj.FNFUL_INJ_OFF_COR.interp( FRT ) -...
                  obj.FNINJ_CL_DLY.interp( [ FRP( : ), DI_PWEFF( : ) ] );
        end
     end % Protected methods
    
    methods ( Access = private )       
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