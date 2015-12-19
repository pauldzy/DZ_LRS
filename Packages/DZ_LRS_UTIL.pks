CREATE OR REPLACE PACKAGE dz_lrs_util
AUTHID CURRENT_USER
AS
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input             IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input             IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION fast_point(
       p_x                IN  NUMBER
      ,p_y                IN  NUMBER
      ,p_z                IN  NUMBER DEFAULT NULL
      ,p_m                IN  NUMBER DEFAULT NULL
      ,p_srid             IN  NUMBER DEFAULT 8265
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_start_point(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_end_point(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input            IN OUT MDSYS.SDO_GEOMETRY_ARRAY
      ,p_value            IN     MDSYS.SDO_GEOMETRY
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input            IN OUT MDSYS.SDO_GEOMETRY_ARRAY
      ,p_value            IN     MDSYS.SDO_GEOMETRY_ARRAY
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input            IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_value            IN     NUMBER
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input            IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_value            IN     MDSYS.SDO_ORDINATE_ARRAY
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input_array      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_input_value      IN     MDSYS.SDO_NUMBER_ARRAY
      ,p_unique           IN     VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input_array      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_input_value      IN     NUMBER
      ,p_unique           IN     VARCHAR2 DEFAULT 'FALSE'
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2varray(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY_ARRAY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION varray2sdo(
      p_input             IN  MDSYS.SDO_GEOMETRY_ARRAY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION count_points(
      p_input             IN MDSYS.SDO_GEOMETRY
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE parse_error_message(
       p_input           IN  VARCHAR2
      ,p_code            OUT NUMBER
      ,p_message         OUT VARCHAR2
      ,p_authority       OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_string(
       p_input_array     IN  MDSYS.SDO_STRING2_ARRAY
      ,p_direction       IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique          IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_number(
       p_input_array     IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_direction       IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique          IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_NUMBER_ARRAY;

END dz_lrs_util;
/

GRANT EXECUTE ON dz_lrs_util TO PUBLIC;

