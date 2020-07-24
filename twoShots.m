classdef twoShots < singleShot 
    
    properties ( SetAccess = private )
        DI_IPW_SEP_IDK      double  { mustBePositive( DI_IPW_SEP_IDK ),...  % Minimum separation between intake injections
                                      mustBeFinite(  DI_IPW_SEP_IDK ),...
                                      mustBeNonNan( DI_IPW_SEP_IDK ),...
                                      mustBeNumeric( DI_IPW_SEP_IDK ),...
                                      mustBeReal( DI_IPW_SEP_IDK ) }
    end
    
    methods
        function obj = twoShots( CalStructure, DI_IPW_SEP_IDK )
            %--------------------------------------------------------------------------
            % twoShots class constructor function
            %
            % obj = twoShots( CalStructure, DI_IPW_SEP_IDK );
            % 
            % Input Arguments:
            %
            % CalStructure      --> Structure of lookup table objects with
            %                       field names:
            %
            %   FNINJSLOPE1F        --> Injector slope: (fcnLookUp)
            %   FNDINJSLPCOR        --> Injection slope correction factor: (fcnLookUp)
            %   FNINJ_OP_DLY        --> Injector opening delay: (fcnLookUp)
            %   FNFUL_INJ_OFF_COR   --> Injector offset correction factor: (fcnLookUp)
            %   FNINJ_CL_DLY        --> Injector offset closing delay: (tableLookUp)
            %   DIMINPW1            --> Injection effective pulesidth:(double)
            %   DIPWADJ             --> Injection pulsewidth adjustment factor: (double)
            %   NUMCYL              --> Number of cylinders: (int8)
            %
            % DI_IPW_SEP_IDK    --> Minimum Separation between intake
            %                       injections
            %--------------------------------------------------------------------------
            obj = obj@singleShot( CalStructure );
            obj.DI_IPW_SEP_IDK = DI_IPW_SEP_IDK;
            obj.NumIntShots = int8( 2 );
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
            % MF    --> (Px1) Desired fuel mass vector [lb]
            % FRP   --> (Px1) Injection pressure vector [PSI]
            % FRT   --> (Px1) Inferred fuel rail temperature vector[deg F]
            %
            % Output Arguments:
            %
            % LCL_FUEL_PW   --> (Px2) Total fuel pulsewidth array
            % DI_PWEFF      --> (Px2) Effective fuel pulsewidth array
            %--------------------------------------------------------------
            [ ~, DI_PWEFF ] = ...
                obj.calcPulseWidth@singleShot( MF, FRP, FRT );              % Return the single shot effective pulsewidth
            DI_PWEFF = DI_PWEFF/double( obj.NumIntShots );                  % Determine the size of the individual effective pulsewidths
            Offset = obj.calcOffset( FRP, FRT, DI_PWEFF );                  % Compute the relative offset
            LCL_FUEL_PW = ( DI_PWEFF + Offset );                            % Compute the corresponding total pulse widths
        end
        
        function [ SOI, EOI ] = calc_pw_angle( obj, MF, N, FRP, FRT, SOI, SEP )
            %---------------------------------------------------------------
            % Calculate the start and end of injection angles. 
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
            % SEP   --> Seperation time [micro sec]
            %
            % Output Arguments:
            %
            % SOI   --> Start of injection angle [deg BTDC Power stroke]
            % EOI   --> End of injection angle [deg BTDC Power stroke]
            %
            % Note due to reference angle being TDC power stroke, EOI < SOI
            %---------------------------------------------------------------
            Time2Angle = 1000000./( 6*N );                                  % time [micro sec] correpsonding to 1 deg of crank rotation
            %--------------------------------------------------------------
            % Clip the seperation time to the minimum and convert to an
            % angle of rotation
            %--------------------------------------------------------------
            SEP( SEP < obj.DI_IPW_SEP_IDK ) = obj.DI_IPW_SEP_IDK;           % Apply the clip
            SepAngle = SEP./Time2Angle;                                     % Seperation angle
            %--------------------------------------------------------------
            % Calculate the total pulsewidth in microseconds
            %--------------------------------------------------------------
            LCL_FUEL_PW = obj.calcPulseWidth( MF, FRP, FRT );
            %--------------------------------------------------------------
            % Calculate the corresponding injection duration in deg
            %--------------------------------------------------------------
            LCL_FUEL_PW_ANGLE = LCL_FUEL_PW./Time2Angle;
            %--------------------------------------------------------------
            % Compute the SOI data
            %--------------------------------------------------------------
            SOI = repmat( SOI, 1, obj.NumIntShots );
            for Q = 2:obj.NumIntInj
                SOI( :, Q ) = SOI( :, Q - 1 ) + SepAngle;
            end
            %--------------------------------------------------------------
            % Compute the corresponding EOI data
            %--------------------------------------------------------------
            EOI = SOI + LCL_FUEL_PW_ANGLE;
        end
    end
end