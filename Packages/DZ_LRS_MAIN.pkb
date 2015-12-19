CREATE OR REPLACE PACKAGE BODY dz_lrs_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION lrs_varray2sdo(
      p_input                   IN  MDSYS.SDO_GEOMETRY_ARRAY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output  MDSYS.SDO_GEOMETRY;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming paramters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Combine the varray together
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF sdo_output IS NULL
         THEN
            sdo_output := p_input(i);
            
         ELSE
            sdo_output := safe_lrs_append(sdo_output,p_input(i));
            
         END IF;
         
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Return results
      --------------------------------------------------------------------------
      RETURN sdo_output;
      
   END lrs_varray2sdo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION round_measures(
       p_input          IN  MDSYS.SDO_GEOMETRY
      ,p_round          IN  NUMBER DEFAULT 5
      ,p_below_to_zero  IN  NUMBER DEFAULT NULL
      ,p_above_to_100   IN  NUMBER DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_input     MDSYS.SDO_GEOMETRY := p_input;
      dim_count     PLS_INTEGER;
      measure_chk   PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      k             PLS_INTEGER;
      num_round     NUMBER := p_round;
      num_temp      NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF sdo_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF num_round IS NULL
      THEN
         num_round := 5;
         
      END IF;

      IF LENGTH(sdo_input.SDO_GTYPE) = 4
      THEN
         dim_count   := sdo_input.get_dims();
         measure_chk := sdo_input.get_lrs_dim();
         gtype       := sdo_input.get_gtype();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to determine dimensionality from gtype'
         );
         
      END IF;

      IF dim_count = 2
      THEN
         RETURN sdo_input;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Verify that measure is proper in the gtype
      --------------------------------------------------------------------------
      IF measure_chk = 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'geometry does not have measure flag properly set in the geometry gtype'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Pass on the point stuff for now
      --------------------------------------------------------------------------
      IF gtype NOT IN (2,6)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'LRS Points and Polygons not support at this time!'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Loop through the ordinates and round the measure
      --------------------------------------------------------------------------
      n_points := sdo_input.SDO_ORDINATES.COUNT / dim_count;
      k := 1;
      
      FOR i IN 1 .. n_points
      LOOP
         IF dim_count = 3
         AND measure_chk = 3
         THEN
            num_temp := ROUND(
                sdo_input.SDO_ORDINATES(k + 2)
               ,num_round
            );
            
            IF p_below_to_zero IS NOT NULL
            THEN
               IF num_temp < p_below_to_zero
               THEN
                  num_temp := 0;
                  
               END IF;
               
            END IF;
            
            IF p_above_to_100 IS NOT NULL
            THEN
               IF num_temp > p_above_to_100
               THEN
                  num_temp := 100;
                  
               END IF;
               
            END IF;
            
            sdo_input.SDO_ORDINATES(k + 2) := num_temp;
            k := k + 3;
            
         ELSIF dim_count = 4
         AND measure_chk = 3
         THEN
            num_temp := ROUND(
                sdo_input.SDO_ORDINATES(k + 2)
               ,num_round
            );
            
            IF p_below_to_zero IS NOT NULL
            THEN
               IF num_temp < p_below_to_zero
               THEN
                  num_temp := 0;
                  
               END IF;
               
            END IF;
            
            IF p_above_to_100 IS NOT NULL
            THEN
               IF num_temp > p_above_to_100
               THEN
                  num_temp := 100;
                  
               END IF;
               
            END IF;
            
            sdo_input.SDO_ORDINATES(k + 2) := num_temp;
            k := k + 4;
         
         ELSIF dim_count = 4
         AND measure_chk = 4
         THEN
            num_temp := ROUND(
                sdo_input.SDO_ORDINATES(k + 3)
               ,num_round
            );
            
            IF p_below_to_zero IS NOT NULL
            THEN
               IF num_temp < p_below_to_zero
               THEN
                  num_temp := 0;
                  
               END IF;
               
            END IF;
            
            IF p_above_to_100 IS NOT NULL
            THEN
               IF num_temp > p_above_to_100
               THEN
                  num_temp := 100;
                  
               END IF;
               
            END IF;
            
            sdo_input.SDO_ORDINATES(k + 3) := num_temp;
            k := k + 4;   
         
         ELSE
            RAISE_APPLICATION_ERROR(-20001,'ERR');
         
         END IF;   

      END LOOP;
      
      RETURN sdo_input;
      
   END round_measures;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_lrs_point(
       p_endpoint  IN  VARCHAR2
      ,p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag   IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      str_2d_flag VARCHAR2(5 Char) := UPPER(p_2d_flag);
      
   BEGIN
   
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'TRUE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF UPPER(p_endpoint) IN ('START','NOT END','FROM')
      THEN
         IF str_2d_flag = 'FALSE'
         THEN
            RETURN MDSYS.SDO_LRS.GEOM_SEGMENT_START_PT(p_input);
            
         ELSE
            RETURN dz_lrs_util.downsize_2d(
               p_input => MDSYS.SDO_LRS.GEOM_SEGMENT_START_PT(p_input)
            );
            
         END IF;
         
      ELSIF UPPER(p_endpoint) IN ('END','NOT START','STOP','TO')
      THEN
         IF str_2d_flag = 'FALSE'
         THEN
            RETURN MDSYS.SDO_LRS.GEOM_SEGMENT_END_PT(p_input);
            
         ELSE
            RETURN dz_lrs_util.downsize_2d(
               p_input => MDSYS.SDO_LRS.GEOM_SEGMENT_END_PT(p_input)
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'unknown endpoint type');
         
      END IF;

   END get_lrs_point;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_lrs_measure(
       p_endpoint  IN VARCHAR2
      ,p_input     IN MDSYS.SDO_GEOMETRY
   ) RETURN NUMBER
   AS
   BEGIN
      
      IF UPPER(p_endpoint) IN ('START','NOT END')
      THEN
         RETURN MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
            p_input
         );
      
      ELSIF UPPER(p_endpoint) IN ('END','NOT START')
      THEN
         RETURN MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(
            p_input
         );
      
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'unknown endpoint type');
         
      END IF;
      
   END get_lrs_measure;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_lrs_intersection(
       p_geometry_1      IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2      IN  MDSYS.SDO_GEOMETRY
      ,p_sdo_tolerance   IN  NUMBER DEFAULT 0.05
      ,p_lrs_tolerance   IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_initial       MDSYS.SDO_GEOMETRY;
      boo_baddie        BOOLEAN := FALSE;
      sdo_oldinter      MDSYS.SDO_GEOMETRY;
      sdo_newinter      MDSYS.SDO_GEOMETRY;
      num_sdo_tolerance NUMBER := p_sdo_tolerance;
      num_lrs_tolerance NUMBER := p_lrs_tolerance;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 20
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF num_sdo_tolerance IS NULL
      THEN
         num_sdo_tolerance := 0.05;
         
      END IF;
      
      IF num_lrs_tolerance IS NULL
      THEN
         num_lrs_tolerance := 0.00000001;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Run the initial Intersection and hope for the best
      --------------------------------------------------------------------------
      BEGIN
         sdo_initial := MDSYS.SDO_LRS.LRS_INTERSECTION(
             geom_1    => p_geometry_1
            ,geom_2    => p_geometry_2
            ,tolerance => num_sdo_tolerance
         );
         
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -13331
            THEN
               boo_baddie := TRUE;
               
            ELSE
               RAISE;
               
            END IF;
            
      END;

      --------------------------------------------------------------------------
      -- Step 20
      -- Dump out the results as we assume things went successfully
      --------------------------------------------------------------------------
      IF boo_baddie = FALSE
      THEN
         RETURN sdo_initial;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- At this point Oracle Spatial's LRS_INTERSECTION has failed
      -- Lets verify that we have a single linestring in 1 and polygon
      -- or multipolygon in 2
      --------------------------------------------------------------------------
      IF p_geometry_1.get_gtype() = 2
      AND p_geometry_2.get_gtype() IN (3,7)
      THEN
         NULL; -- OK
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'LRS_INTERSECTION failed with error -13331 - cannot recover. ' || CHR(13) ||
             'geometry 1 gtype = ' || TO_CHAR(p_geometry_1.get_gtype()) || ' ' || CHR(13) ||
             'geometry 2 gtype = ' || TO_CHAR(p_geometry_2.get_gtype())
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Lets do the intersection again with regular old SDO_INTERSECTIOM
      --------------------------------------------------------------------------
      sdo_oldinter := MDSYS.SDO_GEOM.SDO_INTERSECTION(
          geom1 => p_geometry_1
         ,geom2 => p_geometry_2
         ,tol   => num_sdo_tolerance
      );

      --------------------------------------------------------------------------
      -- Step 50
      -- Now see what we got, only gtypes 2, 5, 6 and 4 are reasonable for this scenario
      -- 5 means we just got back a bunch of points so we can ditch them all
      -- and return NULL
      --------------------------------------------------------------------------
      IF sdo_oldinter.get_gtype() = 5
      THEN
         RETURN NULL;
         
      ELSIF sdo_oldinter.get_gtype() IN (2,4,6)
      THEN
         NULL; -- OK
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'LRS_INTERSECTION failed with error -13331 - cannot recover. ' || CHR(13) ||
             'sdo_intersection component returned gtype ' || TO_CHAR(sdo_oldinter.get_gtype())
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- So now we have gtype 4 with two or more points in it
      -- Lets pick out the linestrings into a new gtype 6
      --------------------------------------------------------------------------
      FOR i IN 1 .. MDSYS.SDO_UTIL.GETNUMELEM(sdo_oldinter)
      LOOP
         sdo_initial := MDSYS.SDO_UTIL.EXTRACT(sdo_oldinter,i);

         IF sdo_initial.get_gtype() = 2
         THEN
            sdo_initial := overlay_lrs_measures(
                p_input_geometry => sdo_initial
               ,p_lrs_geometry   => p_geometry_1
               ,p_lrs_tolerance  => num_lrs_tolerance
            );

            IF sdo_newinter IS NULL
            THEN
               sdo_newinter := sdo_initial;
               
            ELSE
               sdo_newinter := safe_concatenate_geom_segments(
                   p_geometry_1    => sdo_newinter
                  ,p_geometry_2    => sdo_initial
                  ,p_sdo_tolerance => num_sdo_tolerance
                  ,p_lrs_tolerance => num_lrs_tolerance
               );
               
            END IF;

         END IF;

      END LOOP;

      --------------------------------------------------------------------------
      -- Step 70
      -- Final check and then return the results
      --------------------------------------------------------------------------
      IF sdo_newinter.get_gtype() NOT IN (2,6)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to process geometry'
         );
         
      END IF;

      RETURN sdo_newinter;

   END safe_lrs_intersection;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION overlay_lrs_measures(
       p_input_geometry  IN  MDSYS.SDO_GEOMETRY
      ,p_lrs_geometry    IN  MDSYS.SDO_GEOMETRY
      ,p_lrs_tolerance   IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      num_lrs_tolerance NUMBER := p_lrs_tolerance;
      sdo_input_start   MDSYS.SDO_GEOMETRY;
      sdo_input_end     MDSYS.SDO_GEOMETRY;
      num_start_meas    NUMBER;
      num_end_meas      NUMBER;
      sdo_lrs_output    MDSYS.SDO_GEOMETRY;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_lrs_geometry.get_lrs_dim() = 0
      OR p_lrs_geometry.get_gtype() <> 2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_lrs_geometry must be an single linestring LRS geometry'
         );
         
      END IF;

      IF p_input_geometry.get_gtype() <> 2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_input_geometry must a single linestring! (gtype ' || p_input_geometry.get_gtype() || ')'
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Collect the start and end points of the input geometry
      --------------------------------------------------------------------------
      sdo_input_start := dz_lrs_util.get_start_point(p_input_geometry);
      sdo_input_end   := dz_lrs_util.get_end_point(p_input_geometry);

      --------------------------------------------------------------------------
      -- Step 30
      -- Collect the start and end measure of the input geometry on the lrs
      --------------------------------------------------------------------------
      num_start_meas := MDSYS.SDO_LRS.GET_MEASURE(
         MDSYS.SDO_LRS.PROJECT_PT(
             geom_segment => p_lrs_geometry
            ,point        => sdo_input_start
            ,tolerance    => num_lrs_tolerance
         )
      );
         
      num_end_meas := MDSYS.SDO_LRS.GET_MEASURE(
         MDSYS.SDO_LRS.PROJECT_PT(
             geom_segment => p_lrs_geometry
            ,point        => sdo_input_end
            ,tolerance    => num_lrs_tolerance
         )
      );

      --------------------------------------------------------------------------
      -- Step 40
      -- Build the new LRS string from the measures
      --------------------------------------------------------------------------
      sdo_lrs_output := p_input_geometry;

      IF sdo_lrs_output.get_dims() = 2
      THEN
         sdo_lrs_output := MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(
            standard_geom => sdo_lrs_output
         );
         
      END IF;

      MDSYS.SDO_LRS.RESET_MEASURE(
         geom_segment => sdo_lrs_output
      );
      
      MDSYS.SDO_LRS.REDEFINE_GEOM_SEGMENT(
          geom_segment  => sdo_lrs_output
         ,start_measure => num_start_meas
         ,end_measure   => num_end_meas
      );

      IF sdo_lrs_output.get_lrs_dim() = 0
      THEN
         sdo_lrs_output.SDO_GTYPE := TO_NUMBER(
            sdo_lrs_output.get_dims() ||
            sdo_lrs_output.get_dims() ||
            '0' ||
            sdo_lrs_output.get_gtype()
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Check to see if the geometry is backwards
      --------------------------------------------------------------------------
      IF num_start_meas < num_end_meas
      THEN
         sdo_lrs_output := MDSYS.SDO_LRS.REVERSE_GEOMETRY(
            geom => sdo_lrs_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 50
      -- Return the results
      --------------------------------------------------------------------------
      RETURN sdo_lrs_output;

   END overlay_lrs_measures;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION concatenate_no_remeasure(
       p_segment_one     IN  MDSYS.SDO_GEOMETRY
      ,p_segment_two     IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance       IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_seg_one_start  MDSYS.SDO_GEOMETRY;
      sdo_seg_one_end    MDSYS.SDO_GEOMETRY;
      sdo_seg_two_start  MDSYS.SDO_GEOMETRY;
      sdo_seg_two_end    MDSYS.SDO_GEOMETRY;
      sdo_results        MDSYS.SDO_GEOMETRY;
      sdo_results_two    MDSYS.SDO_GEOMETRY;
      num_tolerance      NUMBER := p_tolerance;
      num_dimensions     PLS_INTEGER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_segment_one IS NULL
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input p_segment_one is NULL'
         );
         
      END IF;

      IF p_segment_two IS NULL
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input p_segment_two is NULL'
         );
         
      END IF;

      IF p_segment_one.SDO_GTYPE NOT IN (3002,3302,4002,4402)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input p_segment_one is not an LRS line segment'
         );
         
      END IF;

      IF p_segment_two.SDO_GTYPE NOT IN (3002,3302,4002,4402)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input p_segment_two is not an LRS line segment'
         );
         
      END IF;

      IF p_segment_one.SDO_GTYPE <> p_segment_two.SDO_GTYPE
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input line segments do not have the same GTYPE values'
         );
         
      END IF;

      IF p_segment_one.SDO_SRID <> p_segment_two.SDO_SRID
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input line segments do not have the same SRID values'
         );
         
      END IF;
      
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
      
      END IF;

      num_dimensions := p_segment_one.get_dims();

      --------------------------------------------------------------------------
      -- Step 20
      -- Grab LRS endpoints, include Z and M for this comparison work
      --------------------------------------------------------------------------
      sdo_seg_one_start  := get_lrs_point('START',p_segment_one,'FALSE');
      sdo_seg_one_end    := get_lrs_point('END',p_segment_one,'FALSE');
      sdo_seg_two_start  := get_lrs_point('START',p_segment_two,'FALSE');
      sdo_seg_two_end    := get_lrs_point('END',p_segment_two,'FALSE');

      --------------------------------------------------------------------------
      -- Step 30
      -- Determine connectivity and gently append changing no values or remeasuring
      --------------------------------------------------------------------------
      IF lrs_relate(
          p_geometry_1   => sdo_seg_one_end
         ,p_mask         => 'DETERMINE'
         ,p_geometry_2   => sdo_seg_two_start
         ,p_xy_tolerance => num_tolerance
      ) = 'EQUAL'
      THEN
         sdo_results := p_segment_one;
         
         FOR i IN num_dimensions + 1 .. p_segment_two.SDO_ORDINATES.COUNT
         LOOP
            dz_lrs_util.append2(
                p_input  => sdo_results.SDO_ORDINATES
               ,p_value  => p_segment_two.SDO_ORDINATES(i)
            );
            
         END LOOP;

      ELSIF lrs_relate(
          p_geometry_1   => sdo_seg_one_end
         ,p_mask         => 'DETERMINE'
         ,p_geometry_2   => sdo_seg_two_end
         ,p_xy_tolerance => num_tolerance
      ) = 'EQUAL'
      THEN
         sdo_results     := p_segment_one;
         sdo_results_two := MDSYS.SDO_LRS.REVERSE_GEOMETRY(
            geom => p_segment_two
         );
         
         FOR i IN num_dimensions + 1 .. sdo_results_two.SDO_ORDINATES.COUNT
         LOOP
            dz_lrs_util.append2(
                p_input  => sdo_results.SDO_ORDINATES
               ,p_value  => sdo_results_two.SDO_ORDINATES(i)
            );
            
         END LOOP;

      ELSIF lrs_relate(
          p_geometry_1   => sdo_seg_one_start
         ,p_mask         => 'DETERMINE'
         ,p_geometry_2   => sdo_seg_two_end
         ,p_xy_tolerance => num_tolerance
      ) = 'EQUAL'
      THEN
         sdo_results := p_segment_two;
         FOR i IN num_dimensions + 1 .. p_segment_one.SDO_ORDINATES.COUNT
         LOOP
            dz_lrs_util.append2(
                p_input => sdo_results.SDO_ORDINATES
               ,p_value => p_segment_one.SDO_ORDINATES(i)
            );
            
         END LOOP;

      ELSIF lrs_relate(
          p_geometry_1   => sdo_seg_one_start
         ,p_mask         => 'DETERMINE'
         ,p_geometry_2   => sdo_seg_two_start
         ,p_xy_tolerance => num_tolerance
      ) = 'EQUAL'
      THEN
         sdo_results     := p_segment_two;
         sdo_results_two := MDSYS.SDO_LRS.REVERSE_GEOMETRY(
            geom => p_segment_one
         );
         
         FOR i IN num_dimensions + 1 .. sdo_results_two.SDO_ORDINATES.COUNT
         LOOP
            dz_lrs_util.append2(
                p_input => sdo_results.SDO_ORDINATES
               ,p_value => sdo_results_two.SDO_ORDINATES(i)
            );
            
         END LOOP;

      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'LRS segments do not share a common end point and cannot be concatenated using this method' || CHR(10) ||
             sdo_seg_one_start.SDO_ORDINATES(1) || ',' || sdo_seg_one_start.SDO_ORDINATES(2) || ',' || sdo_seg_one_start.SDO_ORDINATES(3) || CHR(10) ||
             sdo_seg_one_end.SDO_ORDINATES(1)   || ',' || sdo_seg_one_end.SDO_ORDINATES(2) || ',' || sdo_seg_one_end.SDO_ORDINATES(3) || CHR(10) ||
             sdo_seg_two_start.SDO_ORDINATES(1) || ',' || sdo_seg_two_start.SDO_ORDINATES(2) || ',' || sdo_seg_two_start.SDO_ORDINATES(3) || CHR(10) ||
             sdo_seg_two_end.SDO_ORDINATES(1)   || ',' || sdo_seg_two_end.SDO_ORDINATES(2) || ',' || sdo_seg_two_end.SDO_ORDINATES(3) || CHR(10)
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Do some quick error checking
      --------------------------------------------------------------------------
      IF (p_segment_one.SDO_ORDINATES.COUNT / num_dimensions) + (p_segment_two.SDO_ORDINATES.COUNT / num_dimensions) =
      (sdo_results.SDO_ORDINATES.COUNT / num_dimensions) + 1
      THEN
         RETURN sdo_results;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'ERROR in concatentation - ordinate counts are not reasonable.'
         );
         
      END IF;

   END concatenate_no_remeasure;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION is_null_lrs(
      p_input         IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2
   AS
      num_lrs   NUMBER;
      int_index PLS_INTEGER;
      
   BEGIN
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      num_lrs := p_input.get_lrs_dim();
      
      IF num_lrs = 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input geometry is not LRS geometry'
         );
         
      END IF;
      
      IF  num_lrs = 3
      AND p_input.sdo_point IS NOT NULL
      THEN
         IF p_input.sdo_point.z IS NULL
         THEN
            RETURN 'TRUE';
            
         ELSE
            RETURN 'FALSE';
            
         END IF;
         
      END IF;
      
      int_index := 0;
      WHILE int_index <= p_input.SDO_ORDINATES.COUNT
      LOOP
         int_index := int_index + num_lrs;
         
         IF p_input.SDO_ORDINATES(num_lrs) IS NULL
         THEN
            RETURN 'TRUE';
            
         END IF;
      
      END LOOP;
      
      RETURN 'FALSE';
      
   END is_null_lrs;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION redefine_geom_segment(
       p_input         IN  MDSYS.SDO_GEOMETRY
      ,p_start         IN  NUMBER
      ,p_end           IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output  MDSYS.SDO_GEOMETRY := p_input;
      
   BEGIN
   
      MDSYS.SDO_LRS.REDEFINE_GEOM_SEGMENT(
          geom_segment  => sdo_output
         ,start_measure => p_start
         ,end_measure   => p_end
      );
      
      RETURN sdo_output;

   END redefine_geom_segment;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION valid_lrs(
       p_input              IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_validate_geometry  IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_validate_tolerance IN  NUMBER   DEFAULT 0.05
   ) RETURN VARCHAR2
   AS
      str_validate_results VARCHAR2(4000 Char);
      
   BEGIN
      
      -------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      -------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN NULL;
         
      END IF;
      
      -------------------------------------------------------------------------
      -- Step 20
      -- Loop through array looking for problems
      -------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         str_validate_results := MDSYS.SDO_LRS.VALIDATE_LRS_GEOMETRY(
            geom_segment => p_input(i)
         );
         
         IF str_validate_results <> 'TRUE'
         THEN
            RETURN str_validate_results;
            
         END IF;
         
         IF p_validate_geometry = 'TRUE'
         THEN
            str_validate_results := MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(
                p_input(i)
               ,p_validate_tolerance
            );
            
            IF str_validate_results <> 'TRUE'
            THEN
               RETURN str_validate_results;
               
            END IF;
            
         END IF;
         
      END LOOP;
      
      RETURN 'TRUE';
   
   END valid_lrs;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE concatenate_lrs_mess(
       p_input          IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_output         OUT MDSYS.SDO_GEOMETRY
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   )
   AS
      str_valid        VARCHAR2(4000 Char);
      str_authority    VARCHAR2(4000 Char);
      ary_lows         MDSYS.SDO_NUMBER_ARRAY;
      ary_lows_sorted  MDSYS.SDO_NUMBER_ARRAY;
      ary_sdo_sorted   MDSYS.SDO_GEOMETRY_ARRAY;
      ary_highs        MDSYS.SDO_NUMBER_ARRAY;
      ary_highs_sorted MDSYS.SDO_NUMBER_ARRAY;
      ary_unq_measures MDSYS.SDO_NUMBER_ARRAY;
      num_start        NUMBER;
      num_end          NUMBER;
      idx              PLS_INTEGER;
      tmp              NUMBER;
      tmp_sdo          MDSYS.SDO_GEOMETRY;
      tmp_final        MDSYS.SDO_GEOMETRY;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN;
         
      END IF;
      
      str_valid := valid_lrs(p_input);
      IF str_valid <> 'TRUE'
      THEN
         dz_lrs_util.parse_error_message(
             p_input     => str_valid
            ,p_code      => p_return_code
            ,p_message   => p_status_message
            ,p_authority => str_authority
         );
         
         RETURN;
         
      END IF;   
      
      IF p_input.COUNT = 1
      THEN
         p_output      := p_input(1);
         p_return_code := 0;
         RETURN;
         
      END IF;        
       
      --------------------------------------------------------------------------
      -- Step 20
      -- Validate that the measure ranges are reasonable
      --------------------------------------------------------------------------
      ary_lows  := MDSYS.SDO_NUMBER_ARRAY();
      ary_highs := MDSYS.SDO_NUMBER_ARRAY();
      ary_lows.EXTEND(p_input.COUNT);
      ary_highs.EXTEND(p_input.COUNT);
      
      FOR i IN 1 .. p_input.COUNT
      LOOP
         num_start := MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(p_input(i));
         num_end   := MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(p_input(i));
         
         IF num_end < num_start
         THEN
            ary_lows(i)  := num_end;
            ary_highs(i) := num_start;
            
         ELSE
            ary_lows(i)  := num_start;
            ary_highs(i) := num_end;
            
         END IF;
         
         dz_lrs_util.append2(ary_unq_measures,num_end,'TRUE');
         dz_lrs_util.append2(ary_unq_measures,num_start,'TRUE');
         
      END LOOP;
      
      IF ary_unq_measures.COUNT <> p_input.COUNT + 1
      THEN
         p_return_code    := 1;
         p_status_message := 'measure values are not sequential';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- sort by the low measure value
      --------------------------------------------------------------------------
      ary_sdo_sorted   := p_input;
      ary_lows_sorted  := ary_lows;
      ary_highs_sorted := ary_highs;
      idx := ary_lows.COUNT - 1;
      
      WHILE ( idx > 0 )
      LOOP
         FOR j IN 1 .. idx
         LOOP
            IF ary_lows_sorted(j) > ary_lows_sorted(j+1)
            THEN
               tmp                  := ary_lows_sorted(j);
               ary_lows_sorted(j)   := ary_lows_sorted(j+1);
               ary_lows_sorted(j+1) := tmp;
               
               tmp                  := ary_highs_sorted(j);
               ary_highs_sorted(j)   := ary_highs_sorted(j+1);
               ary_highs_sorted(j+1) := tmp;
               
               tmp_sdo              := ary_sdo_sorted(j);
               ary_sdo_sorted(j)    := ary_sdo_sorted(j+1);
               ary_sdo_sorted(j+1)  := tmp_sdo;
               
            END IF;
            
         END LOOP;
         
         idx := idx - 1;
         
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- concatenate the results
      --------------------------------------------------------------------------
      tmp_sdo := ary_sdo_sorted(1);
      
      FOR i IN 2 .. ary_sdo_sorted.COUNT
      LOOP
         IF ary_highs_sorted(i-1) = ary_lows_sorted(i)
         THEN
            tmp_sdo := concatenate_no_remeasure(
                p_segment_one => tmp_sdo
               ,p_segment_two => ary_sdo_sorted(i)
            );
            
         ELSE
            IF tmp_final IS NULL
            THEN
               tmp_final := tmp_sdo;
               
            ELSE
               tmp_final := MDSYS.SDO_UTIL.APPEND(
                   tmp_final
                  ,tmp_sdo
               );
               
            END IF;
            
            tmp_sdo := ary_sdo_sorted(i);
            
         END IF;
      
      END LOOP;
      
      IF tmp_final IS NULL
      THEN
         tmp_final := tmp_sdo;
         
      ELSE
         tmp_final := MDSYS.SDO_UTIL.APPEND(
             tmp_final
            ,tmp_sdo
         );
         
      END IF;
         
      --------------------------------------------------------------------------
      -- Step 50
      -- Return what we have
      --------------------------------------------------------------------------
      p_output      := tmp_final;
      p_return_code := 0;
      RETURN;
      
   END concatenate_lrs_mess;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_concatenate_geom_segments(
       p_geometry_1    IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2    IN  MDSYS.SDO_GEOMETRY
      ,p_sdo_tolerance IN  NUMBER DEFAULT 0.05
      ,p_lrs_tolerance IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      num_sdo_tolerance NUMBER := p_sdo_tolerance;
      num_lrs_tolerance NUMBER := p_lrs_tolerance;
      sdo_array_in      MDSYS.SDO_GEOMETRY_ARRAY;
      sdo_array_in2     MDSYS.SDO_GEOMETRY_ARRAY;
      sdo_concatenate   MDSYS.SDO_GEOMETRY;
      num_remove1       NUMBER;
      num_remove2       NUMBER;
      int_counter       PLS_INTEGER;
      int_sanity        PLS_INTEGER := 0;
      
   BEGIN
   
      IF num_sdo_tolerance IS NULL
      THEN
         num_sdo_tolerance := 0.05;
         
      END IF;
      
      IF num_lrs_tolerance IS NULL
      THEN
         num_lrs_tolerance := 0.00000001;
         
      END IF;
      
      IF p_geometry_1 IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF p_geometry_2 IS NULL
      THEN
         RETURN p_geometry_1;
         
      END IF;
      
      IF p_geometry_1.get_lrs_dim() = 0
      OR p_geometry_2.get_lrs_dim() = 0
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input must be valid LRS');
         
      END IF;
      
      IF p_geometry_1.get_gtype() = 2
      AND p_geometry_2.get_gtype() = 2
      THEN
         IF MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(
            p_geometry_1
         ) = MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
            p_geometry_2
         )
         THEN
            RETURN MDSYS.SDO_LRS.CONCATENATE_GEOM_SEGMENTS(
                p_geometry_1
               ,p_geometry_2
               ,num_lrs_tolerance
            );
            
         ELSIF MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(
            p_geometry_2
         ) = MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
            p_geometry_1
         )
         THEN
            RETURN MDSYS.SDO_LRS.CONCATENATE_GEOM_SEGMENTS(
                p_geometry_2
               ,p_geometry_1
               ,num_lrs_tolerance
            );
            
         ELSE
            RETURN safe_lrs_append(
                p_geometry_2
               ,p_geometry_1
            );           
         
         END IF;
         
      END IF;
      
      sdo_array_in := dz_lrs_util.sdo2varray(p_geometry_1);
      dz_lrs_util.append2(
          sdo_array_in
         ,p_geometry_2
      );
      
      <<start_over>>
      num_remove1 := NULL;
      num_remove2 := NULL;
      
      <<outer_loop>>
      FOR i IN 1 .. sdo_array_in.COUNT
      LOOP
         FOR j IN 1 .. sdo_array_in.COUNT
         LOOP
            IF i <> j 
            AND MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(
               sdo_array_in(i)
            ) = MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
               sdo_array_in(j)
            ) 
            THEN
               sdo_concatenate := MDSYS.SDO_LRS.CONCATENATE_GEOM_SEGMENTS(
                  sdo_array_in(i),
                  sdo_array_in(j),
                  num_lrs_tolerance
               );
               
               IF sdo_concatenate.get_gtype() = 2
               THEN
                  num_remove1 := i;
                  num_remove2 := j;
                  EXIT outer_loop;
                  
               END IF;
               
            END IF;
        
         END LOOP;
         
      END LOOP;
      
      IF num_remove1 IS NULL
      THEN
         RETURN lrs_varray2sdo(sdo_array_in);
         
      END IF;
      
      int_counter := 1;
      sdo_array_in2 := MDSYS.SDO_GEOMETRY_ARRAY();
      sdo_array_in2.EXTEND();
      sdo_array_in2(int_counter) := sdo_concatenate;
      int_counter := int_counter + 1;
      
      FOR i IN 1 .. sdo_array_in.COUNT
      LOOP
         IF i <> num_remove1
         AND i <> num_remove2
         THEN
            sdo_array_in2.EXTEND();
            sdo_array_in2(int_counter) := sdo_array_in(i);
            int_counter := int_counter + 1;
            
         END IF;
         
      END LOOP;
      
      sdo_array_in := sdo_array_in2;
      
      IF int_sanity > sdo_array_in.COUNT * sdo_array_in.COUNT
      THEN
         RETURN lrs_varray2sdo(sdo_array_in);
         
      END IF;
      
      int_sanity := int_sanity + 1;
      GOTO start_over;      
   
   END safe_concatenate_geom_segments;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_lrs_append(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      num_dim_1  NUMBER;
      num_dim_2  NUMBER;
      num_lrs_1  NUMBER;
      num_lrs_2  NUMBER;
      sdo_output MDSYS.SDO_GEOMETRY;
      
   BEGIN
   
      IF p_geometry_1 IS NULL
      THEN
         RETURN p_geometry_2;
         
      ELSIF p_geometry_2 IS NULL
      THEN
         RETURN p_geometry_1;
         
      END IF;
      
      num_dim_1  := p_geometry_1.get_dims();
      num_dim_2  := p_geometry_2.get_dims();
      num_lrs_1  := p_geometry_1.get_lrs_dim();
      num_lrs_2  := p_geometry_2.get_lrs_dim();
      
      IF num_dim_1 <> num_dim_2
      OR num_lrs_1 <> num_lrs_2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'both inputs must be valid LRS with same dimensionality'
         );
         
      END IF; 
      
      sdo_output := MDSYS.SDO_UTIL.APPEND(
          p_geometry_1
         ,p_geometry_2
      );
      
      sdo_output.SDO_GTYPE := TO_NUMBER(
         TO_CHAR(num_dim_1) || TO_CHAR(num_lrs_1) || '0' || TO_CHAR(sdo_output.get_gtype())
      );
      
      RETURN sdo_output;
      
   END safe_lrs_append;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION lrs_relate(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_mask           IN  VARCHAR2
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
      ,p_xy_tolerance   IN  NUMBER DEFAULT 0.05
      ,p_m_tolerance    IN  NUMBER DEFAULT 0.00000001
   ) RETURN VARCHAR2
   AS
      num_xy_tolerance NUMBER := p_xy_tolerance;
      num_m_tolerance  NUMBER := p_m_tolerance;
      str_mask         VARCHAR2(4000 Char) := UPPER(p_mask);
      sdo_geometry_1   MDSYS.SDO_GEOMETRY;
      sdo_geometry_2   MDSYS.SDO_GEOMETRY;
      num_measure_1    NUMBER;
      num_measure_2    NUMBER;
      str_relate       VARCHAR2(4000 Char);
       
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_geometry_1.get_lrs_dim() <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'geometry 1 is not lrs geometry'
         );
         
      END IF;
      
      IF p_geometry_2.get_lrs_dim() <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'geometry 2 is not lrs geometry'
         );
         
      END IF;
      
      IF num_xy_tolerance IS NULL
      THEN
         num_xy_tolerance := 0.05;
         
      END IF;
      
      IF num_m_tolerance IS NULL
      THEN
         num_m_tolerance := 0.00000001;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Grab 2d version of geometry
      --------------------------------------------------------------------------
      sdo_geometry_1 := dz_lrs_util.downsize_2d(p_geometry_1);
      sdo_geometry_2 := dz_lrs_util.downsize_2d(p_geometry_2);
   
      --------------------------------------------------------------------------
      -- Step 30
      -- Grab 2d version of geometry and exit if nothing interesting
      --------------------------------------------------------------------------
      IF str_mask = 'DETERMINE'
      THEN      
         str_relate := MDSYS.SDO_GEOM.RELATE(
             geom1 => sdo_geometry_1
            ,mask  => 'DETERMINE'
            ,geom2 => sdo_geometry_2
            ,tol   => num_xy_tolerance
         );
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'unimplemented');      
      
      END IF;
      
      IF str_relate NOT IN (
          'EQUAL'
         ,'TOUCH'
         ,'OVERLAPBDYINTERSECT'
         ,'OVERLAPBDYDISJOINT'
      )
      THEN
         RETURN str_relate;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- If two points then check the LRS measures
      --------------------------------------------------------------------------
      IF  sdo_geometry_1.get_gtype() = 1
      AND sdo_geometry_2.get_gtype() = 1
      THEN
         IF str_relate = 'EQUAL'
         THEN
            num_measure_1 := MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
               p_geometry_1
            );
            num_measure_2 := MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(
               p_geometry_2
            );
            
            IF ABS(num_measure_1 - num_measure_2) <= num_m_tolerance
            THEN
               RETURN str_relate;
            
            ELSE
               RETURN 'LRS DISJOINT';
            
            END IF;
            
         ELSE
            RETURN str_relate;
            
         END IF;
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Nothing else implemented at this time
      --------------------------------------------------------------------------
      RAISE_APPLICATION_ERROR(-20001,'unimplemented');
   
   END lrs_relate;

END dz_lrs_main;
/

