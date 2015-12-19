CREATE OR REPLACE PACKAGE dz_lrs_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_LRS
     
   - Build ID: DZBUILDIDDZ
   - TFS Change Set: DZTFSCHANGESETDZ
   
   Utilities for the creation and manipulation of Oracle Spatial LRS geometries.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.round_measures

   Function to round LRS measures within an Oracle Spatial geometry.  Function
   can optionally push measures below a given value to zero and measures above a
   given value to 100.

   Parameters:

      p_input - LRS geometry with measures to round
      p_round - rounding value to implement, default is 5
      p_below_to_zero - optional value below which all measures are set to 0
      p_above_to_100 - optional value above which all measures are set to 100
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   Notes:
   
   - The optional functionality top snap to 0 or 100 is highly tied to the 0 to 
     100 measure range used by the National Hydrography Dataset flowline system
     and may not be of much value to other users.

   */
   FUNCTION round_measures(
       p_input           IN  MDSYS.SDO_GEOMETRY
      ,p_round           IN  NUMBER DEFAULT 5
      ,p_below_to_zero   IN  NUMBER DEFAULT NULL
      ,p_above_to_100    IN  NUMBER DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.get_lrs_point

   Simple wrapper function around MDSYS.SDO_LRS.GEOM_SEGMENT_START_PT and
   MDSYS.SDO_LRS.GEOM_SEGMENT_END_PT to allow results to be returned as 2d
   rather than LRS points.  This is useful in situation whereby you may wish
   to test endpoints with SDO_GEOM.RELATE and this function will not allow
   LRS measures as input.

   Parameters:

      p_endpoint - keyword to implement, START or END
      p_input - LRS geometry
      p_2d_flag - optional TRUE/FALSE flag to remove LRS or 3D dimensions.
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION get_lrs_point(
       p_endpoint        IN  VARCHAR2
      ,p_input           IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag         IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.get_lrs_measure

   Simple wrapper function around  MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE
   and MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE.

   Parameters:

      p_endpoint - keyword to implement, START or END
      p_input - LRS geometry
      
   Returns:

      NUMBER measure value
      
   */
   FUNCTION get_lrs_measure(
       p_endpoint        IN  VARCHAR2
      ,p_input           IN  MDSYS.SDO_GEOMETRY
   ) RETURN NUMBER;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.safe_lrs_intersection

   Function designed to supplement the broken functionality of 
   SDO_LRS.LRS_INTERSECTION.  For more information see
   https://community.oracle.com/thread/2158723?tstart=0

   Parameters:

      p_geometry_1 - input geometry to intersect against geometry 2
      p_geometry_2 - geometry to be intersected against
      p_sdo_tolerance - 2d tolerance used in the intersecton, default is 0.05
      p_lrs_tolerance - measure tolerance used in the intersection, default
      is 0.00000001
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   Notes:
   
   - Note that LRS_INTERSECTION conceptually confuses the tolerance for the 2D
     part of the intersection with the tolerance for the LRS part of the 
     intersection.  As this function first tries the intersection using 
     LRS_INTERSECTION, it thus preserves the confusion.  If this creates
     issues for users, then just roll your own version without the Oracle 
     function.
      
   */
   FUNCTION safe_lrs_intersection(
       p_geometry_1      IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2      IN  MDSYS.SDO_GEOMETRY
      ,p_sdo_tolerance   IN  NUMBER DEFAULT 0.05
      ,p_lrs_tolerance   IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.overlay_lrs_measures

   Function which transfers measures from a base lrs geometry onto the input 
   geometry.  If the input geometry has preexisting measures, those are replaced.
   The two geometries are assume to overlay each other or be in very close 
   proximity.  Results will be nonsensical otherwise.   

   Parameters:

      p_input_geometry - input geometry to add or redefine measures from lrs
      geometry.
      p_lrs_geometry - base LRS geometry from which to derive measures for input 
      geometry.
      p_lrs_tolerance - measure tolerance, default is 0.00000001.
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION overlay_lrs_measures(
       p_input_geometry  IN  MDSYS.SDO_GEOMETRY
      ,p_lrs_geometry    IN  MDSYS.SDO_GEOMETRY
      ,p_lrs_tolerance   IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.concatenate_no_remeasure

   Function to concatenate two intersecting LRS linestrings without recalculating  
   the LRS measures on either.  In some scenarios, measures provided for a given 
   dataset may not be mathematically correct.  Using SDO_LRS.CONCATENATE_GEOM_SEGMENTS
   will recalibrate all measures on the second geometry. As this will then result
   in geometries with measure that no longer match the base dataset, you may
   wish to use this function instead to preserve the original measures.    

   Parameters:

      p_segment_one - input LRS segment one.
      p_segment_two - input LRS segment two.
      p_lrs_tolerance - 2d intersection tolerance, default is 0.05.
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION concatenate_no_remeasure(
       p_segment_one     IN  MDSYS.SDO_GEOMETRY
      ,p_segment_two     IN  MDSYS.SDO_GEOMETRY
      ,p_tolerance       IN  NUMBER DEFAULT 0.05
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.is_null_lrs

   Function to examine an LRS geometry and report whether any vertice in the 
   geometry has a null value.    

   Parameters:

      p_input - input LRS geometry to test.
      
   Returns:

      VARCHAR2 TRUE/FALSE answer
      
   */
   FUNCTION is_null_lrs(
      p_input            IN  MDSYS.SDO_GEOMETRY
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.redefine_geom_segment

   Simple wrapper function around MDSYS.SDO_LRS.REDEFINE_GEOM_SEGMENT.    

   Parameters:

      p_input - input LRS geometry to redefine.
      p_start - start measure to use in redefinition.
      p_end - end measure to use in redefinition.
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION redefine_geom_segment(
       p_input           IN  MDSYS.SDO_GEOMETRY
      ,p_start           IN  NUMBER
      ,p_end             IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.valid_lrs

   SDO_LRS.VALIDATE_LRS_GEOMETRY is a somewhat useless function that does very
   little to tell users if the geometry is reasonable.  This function tries 
   somewhat to improve the situation by allowing the user to validate an array 
   of geometries for both LRS problems and optionally 2d validation issues.   

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY_ARRAY of LRS geometries to test.
      p_validate_geometry - optional TRUE/FALSE flag to run 
      VALIDATE_GEOMETRY_WITH_CONTEXT on the input geometries, default is FALSE.
      p_validate_tolerance - optional tolerance to use when validating geometries
      from second parameter, default is 0.05.
      
   Returns:

      VARCHAR2 TRUE or error message
      
   */
   FUNCTION valid_lrs(
       p_input              IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_validate_geometry  IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_validate_tolerance IN  NUMBER   DEFAULT 0.05
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_lrs_main.concatenate_lrs_mess

   Procedure to take an unordered array of intersecting LRS geometries and tie
   them all together based on their measures and endpoints.  If the geometries
   cannot be put together, then the status message will explain the problems.   

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY_ARRAY of LRS geometries to concatenate.
      
   Returns:

      p_output - output LRS geometry of concatenated input segments.
      p_return_code - return code indicating any errors, success is zero.
      p_status_message - detailed status message describing any errors
      encountered.
      
   */
   PROCEDURE concatenate_lrs_mess(
       p_input          IN  MDSYS.SDO_GEOMETRY_ARRAY
      ,p_output         OUT MDSYS.SDO_GEOMETRY
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.safe_concatenate_geom_segments

   Function to append together two LRS geometries that either touch or overlap
   preserving the original measure systems of both parts.   

   Parameters:

      p_geometry_1 - LRS geometry one
      p_geometry_2 - LRS geometry two
      p_sdo_tolerance - 2d tolerance used in testing endpoints, default is 0.05
      p_lrs_tolerance - measure tolerance used in concatenation, default
      is 0.00000001.
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION safe_concatenate_geom_segments(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
      ,p_sdo_tolerance  IN  NUMBER DEFAULT 0.05
      ,p_lrs_tolerance  IN  NUMBER DEFAULT 0.00000001
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.safe_lrs_append

   Simple wrapper to bypass bug 16223317 which does allow SDO_UTIL.APPEND to
   preserve measures in its output.   

   Parameters:

      p_geometry_1 - LRS geometry one
      p_geometry_2 - LRS geometry two
      
   Returns:

      MDSYS.SDO_GEOMETRY LRS geometry
      
   */
   FUNCTION safe_lrs_append(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_lrs_main.lrs_relate

   As SDO_GEOM.RELATE does not work with LRS inputs, this function will test both
   2D and LRS equality for LRS inputs.  First the function removes LRS measures 
   and tests against SDO_GEOM.RELATE.  If results are equal, the measures are
   tested and if within the measure tolerance, reports EQUAL.  If the measures
   are not equal, the function reports LRS DISJOINT.   

   Parameters:

      p_geometry_1 - LRS geometry one
      p_mask - SDO_GEOM.RELATE mask keyword, only DETERMINE is currently supported.
      p_geometry_2 - LRS geometry two
      p_xy_tolerance - tolerance for SDO_GEOM.RELATE, default is 0.05
      p_m_tolerance - tolerance for determining measures are equal
      
   Returns:

      VARCHAR2 text result of relate
      
   */
   FUNCTION lrs_relate(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_mask           IN  VARCHAR2
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
      ,p_xy_tolerance   IN  NUMBER DEFAULT 0.05
      ,p_m_tolerance    IN  NUMBER DEFAULT 0.00000001
   ) RETURN VARCHAR2;
   
END dz_lrs_main;
/

GRANT EXECUTE ON dz_lrs_main TO public;

