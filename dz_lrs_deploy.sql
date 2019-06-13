WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;

--******************************--
PROMPT Packages/DZ_LRS_UTIL.pks 

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

--******************************--
PROMPT Packages/DZ_LRS_UTIL.pkb 

CREATE OR REPLACE PACKAGE BODY dz_lrs_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER      := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
            
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
               
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'boolean error'
         );
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
            
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         
         int_delim  := REGEXP_INSTR(
             p_str
            ,p_regex
            ,int_position
            ,1
            ,0
            ,p_match
         );
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      RETURN TO_NUMBER(
         REPLACE(
            REPLACE(
               p_input,
               CHR(10),
               ''
            ),
            CHR(13),
            ''
         ) 
      );
      
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN p_null_replacement;
         
   END safe_to_number;
   
   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN

      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_input.get_gtype() = 1
      THEN
         IF p_input.get_dims() = 2
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                   p_input.SDO_ORDINATES(1)
                  ,p_input.SDO_ORDINATES(2)
                  ,NULL
                )
               ,NULL
               ,NULL
            );
            
         ELSIF p_input.get_dims() = 3
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                    p_input.SDO_ORDINATES(1)
                   ,p_input.SDO_ORDINATES(2)
                   ,p_input.SDO_ORDINATES(3)
                )
               ,NULL
               ,NULL
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'function true_point can only work on 2 and 3 dimensional points - dims=' || p_input.get_dims() || ' '
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function true_point can only work on point geometries'
         );
         
      END IF;
      
   END true_point;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   -- From code posted by Albert Godfrind
   AS
      geom_2d       MDSYS.SDO_GEOMETRY;
      dim_count     PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF LENGTH (p_input.SDO_GTYPE) = 4
      THEN
         dim_count := p_input.get_dims();
         gtype     := p_input.get_gtype();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'Unable to determine dimensionality from gtype'
         );
         
      END IF;

      IF dim_count = 2
      THEN
         RETURN p_input;
         
      END IF;

      geom_2d := MDSYS.SDO_GEOMETRY(
          2000 + gtype
         ,p_input.sdo_srid
         ,p_input.sdo_point
         ,MDSYS.SDO_ELEM_INFO_ARRAY()
         ,MDSYS.SDO_ORDINATE_ARRAY()
      );

      IF geom_2d.SDO_POINT IS NOT NULL
      THEN
         geom_2d.SDO_POINT.z   := NULL;
         geom_2d.SDO_ELEM_INFO := NULL;
         geom_2d.SDO_ORDINATES := NULL;
         
      ELSE
         n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
         n_ordinates := n_points * 2;
         geom_2d.SDO_ORDINATES.EXTEND(n_ordinates);
         j := p_input.SDO_ORDINATES.FIRST;
         k := 1;
         
         FOR i IN 1 .. n_points
         LOOP
            geom_2d.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
            geom_2d.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
            j := j + dim_count;
            k := k + 2;
         
         END LOOP;

         geom_2d.sdo_elem_info := p_input.sdo_elem_info;

         i := geom_2d.SDO_ELEM_INFO.FIRST;
         WHILE i < geom_2d.SDO_ELEM_INFO.LAST
         LOOP
            offset := geom_2d.SDO_ELEM_INFO(i);
            geom_2d.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 2 + 1;
            i := i + 3;
            
         END LOOP;

      END IF;

      IF geom_2d.SDO_GTYPE = 2001
      THEN
         RETURN true_point(geom_2d);
         
      ELSE
         RETURN geom_2d;
         
      END IF;

   END downsize_2d;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION fast_point(
       p_x             IN  NUMBER
      ,p_y             IN  NUMBER
      ,p_z             IN  NUMBER DEFAULT NULL
      ,p_m             IN  NUMBER DEFAULT NULL
      ,p_srid          IN  NUMBER DEFAULT 8265
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_x IS NULL
      OR p_y IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'x and y cannot be NULL');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Do the simplest solution first
      --------------------------------------------------------------------------
      IF  p_z IS NULL
      AND p_m IS NULL
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             2001
            ,p_srid
            ,MDSYS.SDO_POINT_TYPE(
                 p_x
                ,p_y
                ,NULL
             )
            ,NULL
            ,NULL
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Do the other wilder choices
      --------------------------------------------------------------------------
      IF p_z IS NULL
      AND p_m IS NOT NULL
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             3301
            ,p_srid
            ,MDSYS.SDO_POINT_TYPE(
                 p_x
                ,p_y
                ,p_m
             )
            ,NULL
            ,NULL
         );
         
      ELSIF p_z IS NOT NULL
      AND   p_m IS NULL
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             3001
            ,p_srid
            ,MDSYS.SDO_POINT_TYPE(
                 p_x
                ,p_y
                ,p_z
             )
            ,NULL
            ,NULL
         );
         
      ELSIF p_z IS NOT NULL
      AND   p_m IS NOT NULL
      THEN
         RETURN MDSYS.SDO_GEOMETRY(
             4401
            ,p_srid
            ,NULL
            ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1,1)
            ,MDSYS.SDO_ORDINATE_ARRAY(p_x,p_y,p_z,p_m)
         );
      
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'ERR!');
         
      END IF;
      
   END fast_point;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_start_point(
      p_input        IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      int_dims PLS_INTEGER;
      int_gtyp PLS_INTEGER;
      int_lrs  PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Gather information about the geometry
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Handle point and multipoint inputs
      --------------------------------------------------------------------------
      IF int_gtyp = 1
      THEN
         RETURN p_input;
         
      ELSIF int_gtyp = 5
      THEN
         RETURN MDSYS.SDO_UTIL.EXTRACT(p_input,1);
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Return results
      --------------------------------------------------------------------------
      IF int_dims = 2
      THEN
         RETURN fast_point(
             p_input.SDO_ORDINATES(1)
            ,p_input.SDO_ORDINATES(2)
            ,NULL
            ,NULL
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 3
      AND int_lrs = 3
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(1)
            ,p_input.SDO_ORDINATES(2)
            ,NULL
            ,p_input.SDO_ORDINATES(3)
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 3
      AND int_lrs = 0
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(1)
            ,p_input.SDO_ORDINATES(2)
            ,p_input.SDO_ORDINATES(3)
            ,NULL
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 4
      AND int_lrs IN (4,0)
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(1)
            ,p_input.SDO_ORDINATES(2)
            ,p_input.SDO_ORDINATES(3)
            ,p_input.SDO_ORDINATES(4)
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 4
      AND int_lrs = 3
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(1)
            ,p_input.SDO_ORDINATES(2)
            ,p_input.SDO_ORDINATES(4)
            ,p_input.SDO_ORDINATES(3)
            ,p_input.SDO_SRID
         );
      
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'ERR!');
            
      END IF;

   END get_start_point;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_end_point(
      p_input        IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      int_dims PLS_INTEGER;
      int_gtyp PLS_INTEGER;
      int_lrs  PLS_INTEGER;
      int_len  PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Gather information about the geometry
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      int_len  := p_input.SDO_ORDINATES.COUNT();
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Handle point and multipoint inputs
      --------------------------------------------------------------------------
      IF int_gtyp = 1
      THEN
         RETURN p_input;
         
      ELSIF int_gtyp = 5
      THEN
         RETURN MDSYS.SDO_UTIL.EXTRACT(
             p_input
            ,MDSYS.SDO_UTIL.GETNUMELEM(p_input)
         );
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Return results
      --------------------------------------------------------------------------
      IF int_dims = 2
      THEN
         RETURN fast_point(
             p_input.SDO_ORDINATES(int_len - 1)
            ,p_input.SDO_ORDINATES(int_len)
            ,NULL
            ,NULL
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 3
      AND int_lrs = 3
      THEN
         RETURN fast_point(
             p_input.SDO_ORDINATES(int_len - 2)
            ,p_input.SDO_ORDINATES(int_len - 1)
            ,NULL
            ,p_input.SDO_ORDINATES(int_len)
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 3
      AND int_lrs = 0
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(int_len - 2)
            ,p_input.SDO_ORDINATES(int_len - 1)
            ,p_input.SDO_ORDINATES(int_len)
            ,NULL
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 4
      AND int_lrs IN (4,0)
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(int_len - 3)
            ,p_input.SDO_ORDINATES(int_len - 2)
            ,p_input.SDO_ORDINATES(int_len - 1)
            ,p_input.SDO_ORDINATES(int_len)
            ,p_input.SDO_SRID
         );
         
      ELSIF  int_dims = 4
      AND int_lrs = 3
      THEN 
         RETURN fast_point(
             p_input.SDO_ORDINATES(int_len - 3)
            ,p_input.SDO_ORDINATES(int_len - 2)
            ,p_input.SDO_ORDINATES(int_len)
            ,p_input.SDO_ORDINATES(int_len - 1)
            ,p_input.SDO_SRID
         );
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'ERR!');
         
      END IF;

   END get_end_point;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_GEOMETRY_ARRAY
      ,p_value      IN     MDSYS.SDO_GEOMETRY
   )
   AS
      num_index   PLS_INTEGER;
      
   BEGIN
      
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         p_input := MDSYS.SDO_GEOMETRY_ARRAY();
         
      END IF;
      
      num_index := p_input.COUNT + 1;
      p_input.EXTEND(1);
      p_input(num_index) := p_value;
      
   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_GEOMETRY_ARRAY
      ,p_value      IN     MDSYS.SDO_GEOMETRY_ARRAY
   )
   AS
   BEGIN
   
      IF p_value IS NULL
      OR p_value.COUNT = 0
      THEN
         RETURN;
         
      END IF;
   
      FOR i IN 1 .. p_value.COUNT
      LOOP
         append2(
             p_input => p_input
            ,p_value => p_value(i)
         );
         
      END LOOP;
      
   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_value      IN     NUMBER
   )
   AS
      num_index   PLS_INTEGER;
      
   BEGIN
      
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         p_input := MDSYS.SDO_ORDINATE_ARRAY();
         
      END IF;
      
      num_index := p_input.COUNT + 1;
      p_input.EXTEND(1);
      p_input(num_index) := p_value;
      
   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_value      IN     MDSYS.SDO_ORDINATE_ARRAY
   )
   AS
   BEGIN
      IF p_value IS NULL
      OR p_value.COUNT = 0
      THEN
         RETURN;
         
      END IF;
   
      FOR i IN 1 .. p_value.COUNT
      LOOP
         append2(
             p_input => p_input
            ,p_value => p_value(i)
         );
         
      END LOOP;
      
   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input_array      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_input_value      IN     NUMBER
      ,p_unique           IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      boo_check   BOOLEAN;
      num_index   PLS_INTEGER;
      str_unique  VARCHAR2(5 Char);
      
   BEGIN
   
      IF p_unique IS NULL
      THEN
         str_unique := 'FALSE';
         
      ELSIF UPPER(p_unique) IN ('FALSE','TRUE')
      THEN
         str_unique := UPPER(p_unique);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_unique flag must be TRUE or FALSE'
         );
         
      END IF;

      IF p_input_array IS NULL
      THEN
         p_input_array := MDSYS.SDO_NUMBER_ARRAY();
         
      END IF;

      IF p_input_array.COUNT > 0
      THEN
         IF str_unique = 'TRUE'
         THEN
            boo_check := FALSE;
            
            FOR i IN 1 .. p_input_array.COUNT
            LOOP
               IF p_input_value = p_input_array(i)
               THEN
                  boo_check := TRUE;
                  
               END IF;
               
            END LOOP;

            IF boo_check = TRUE
            THEN
               -- Do Nothing
               RETURN;
               
            END IF;

         END IF;

      END IF;

      num_index := p_input_array.COUNT + 1;
      p_input_array.EXTEND(1);
      p_input_array(num_index) := p_input_value;

   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input_array      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_input_value      IN     MDSYS.SDO_NUMBER_ARRAY
      ,p_unique           IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
   BEGIN
   
      FOR i IN 1 .. p_input_value.COUNT
      LOOP
         append2(
             p_input_array => p_input_array
            ,p_input_value => p_input_value(i)
            ,p_unique      => p_unique
         );
         
      END LOOP;
      
   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2varray(
      p_input IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY_ARRAY
   AS
      ary_output MDSYS.SDO_GEOMETRY_ARRAY;
      int_elems  NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming paramters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_GEOMETRY_ARRAY();
      
      IF p_input IS NULL
      THEN
         RETURN ary_output;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Break into components
      --------------------------------------------------------------------------
      int_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      ary_output.EXTEND(int_elems);
      FOR i IN 1 .. int_elems
      LOOP
         ary_output(i) := MDSYS.SDO_UTIL.EXTRACT(p_input,i);
         
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Return results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END sdo2varray;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION varray2sdo(
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
            sdo_output := MDSYS.SDO_UTIL.APPEND(sdo_output,p_input(i));
            
         END IF;
         
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Return results
      --------------------------------------------------------------------------
      RETURN sdo_output;
      
   END varray2sdo;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION count_points(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN NUMBER
   AS
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 0;
         
      END IF;
      
      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN 1;
         
      ELSE
         RETURN p_input.SDO_ORDINATES.COUNT / p_input.get_dims();
         
      END IF;
      
   END count_points;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE simple_dual_split(
       p_input           IN  VARCHAR2
      ,p_delimiter       IN  VARCHAR2
      ,p_output_left     OUT VARCHAR2
      ,p_output_right    OUT VARCHAR
   )
   AS
      ary_splits  MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Split the input, one split only
      --------------------------------------------------------------------------
      ary_splits := gz_split(
          p_str   => p_input
         ,p_regex => p_delimiter
         ,p_end   => 2
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Figure out the results
      --------------------------------------------------------------------------
      IF ary_splits.COUNT = 1
      THEN
         p_output_left  := ary_splits(1);
         p_output_right := NULL;
         
      ELSIF ary_splits.COUNT = 2
      THEN
         p_output_left  := ary_splits(1);
         p_output_right := ary_splits(2);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'error parsing input'
         );
         
      END IF;

   END simple_dual_split;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE parse_error_message(
       p_input       IN  VARCHAR2
      ,p_code        OUT NUMBER
      ,p_message     OUT VARCHAR2
      ,p_authority   OUT VARCHAR2
   )
   AS
      str_temp  VARCHAR2(4000 Char);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;
      
      IF p_input = 'TRUE'
      THEN
         p_code := 0;
         p_message := 'TRUE';
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- authority hyphen code colon message
      --------------------------------------------------------------------------
      simple_dual_split(
          p_input           => p_input
         ,p_delimiter       => '-'
         ,p_output_left     => p_authority
         ,p_output_right    => str_temp
      );
      
      simple_dual_split(
          p_input           => str_temp
         ,p_delimiter       => ':'
         ,p_output_left     => str_temp
         ,p_output_right    => p_message
      );
      
      p_code := safe_to_number(str_temp) * -1;
      p_message := TRIM(p_message);
   
   END parse_error_message;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_string(
       p_input_array      IN  MDSYS.SDO_STRING2_ARRAY
      ,p_direction        IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique           IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY
   AS
      idx           PLS_INTEGER;
      tmp           VARCHAR2(4000 Char);
      ary_output    MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
      ary_output_u  MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
      str_direction VARCHAR2(4 Char);
      str_unique    VARCHAR2(5 Char);
      
   BEGIN
   
      IF p_direction IS NULL
      THEN
         str_direction := 'ASC';
         
      ELSIF UPPER(p_direction) IN ('ASC','DESC')
      THEN
         str_direction := UPPER(p_direction);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'p_direction must be ASC or DESC');
         
      END IF;

      IF p_unique IS NULL
      THEN
         str_unique := 'FALSE';
         
      ELSIF UPPER(p_unique) IN ('TRUE','FALSE')
      THEN
         str_unique := UPPER(p_unique);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'p_unique must be TRUE or FALSE');
         
      END IF;

      IF p_input_array IS NULL
      THEN
         RETURN ary_output;
         
      ELSIF p_input_array.COUNT = 1
      THEN
         RETURN p_input_array;
         
      END IF;

      -- yes this is a shameful bubble sort
      ary_output := p_input_array;
      idx := p_input_array.COUNT - 1;
      WHILE ( idx > 0 )
      LOOP
         FOR j IN 1 .. idx
         LOOP
            IF str_direction = 'DESC'
            THEN
               IF ary_output(j) < ary_output(j+1)
               THEN
                  tmp             := ary_output(j);
                  ary_output(j)   := ary_output(j+1);
                  ary_output(j+1) := tmp;
                  
               END IF;
               
            ELSE
               IF ary_output(j) > ary_output(j+1)
               THEN
                  tmp             := ary_output(j);
                  ary_output(j)   := ary_output(j+1);
                  ary_output(j+1) := tmp;
                  
               END IF;
               
            END IF;
            
         END LOOP;
         
         idx := idx - 1;
         
      END LOOP;

      IF str_unique = 'TRUE'
      THEN
         tmp := NULL;
         idx := 1;
         
         FOR i IN 1 .. ary_output.COUNT
         LOOP
            IF tmp IS NULL
            OR tmp != ary_output(i)
            THEN
               ary_output_u.EXTEND;
               ary_output_u(idx) := ary_output(i);
               idx := idx + 1;
               
            END IF;
            
            tmp := ary_output(i);
            
         END LOOP;
         
         RETURN ary_output_u;
         
      ELSE
         RETURN ary_output;
         
      END IF;

   END sort_string;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_number(
       p_input_array      IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_direction        IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique           IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_NUMBER_ARRAY
   AS
      idx           PLS_INTEGER;
      tmp           NUMBER;
      ary_output    MDSYS.SDO_NUMBER_ARRAY := MDSYS.SDO_NUMBER_ARRAY();
      ary_output_u  MDSYS.SDO_NUMBER_ARRAY := MDSYS.SDO_NUMBER_ARRAY();
      str_direction VARCHAR2(4 Char);
      str_unique    VARCHAR2(5 Char);
      
   BEGIN
   
      IF p_direction IS NULL
      THEN
         str_direction := 'ASC';
         
      ELSIF UPPER(p_direction) IN ('ASC','DESC')
      THEN
         str_direction := UPPER(p_direction);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_direction must be ASC or DESC'
         );
         
      END IF;

      IF p_unique IS NULL
      THEN
         str_unique := 'FALSE';
         
      ELSIF UPPER(p_unique) IN ('TRUE','FALSE')
      THEN
         str_unique := UPPER(p_unique);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_unique must be TRUE or FALSE'
         );
         
      END IF;

      IF p_input_array IS NULL
      THEN
         RETURN ary_output;
         
      ELSIF p_input_array.COUNT = 1
      THEN
         RETURN p_input_array;
         
      END IF;
      
      -- yes this is a shameful bubble sort
      ary_output := p_input_array;
      idx := p_input_array.COUNT - 1;
      
      WHILE ( idx > 0 )
      LOOP
         FOR j IN 1 .. idx
         LOOP
            IF str_direction = 'DESC'
            THEN
               IF ary_output(j) < ary_output(j+1)
               THEN
                  tmp             := ary_output(j);
                  ary_output(j)   := ary_output(j+1);
                  ary_output(j+1) := tmp;
                  
               END IF;
               
            ELSE
               IF ary_output(j) > ary_output(j+1)
               THEN
                  tmp             := ary_output(j);
                  ary_output(j)   := ary_output(j+1);
                  ary_output(j+1) := tmp;
                  
               END IF;
               
            END IF;
            
         END LOOP;
         
         idx := idx - 1;
         
      END LOOP;

      IF str_unique = 'TRUE'
      THEN
         tmp := NULL;
         idx := 1;
         
         FOR i IN 1 .. ary_output.COUNT
         LOOP
            IF tmp IS NULL
            OR tmp != ary_output(i)
            THEN
               ary_output_u.EXTEND;
               ary_output_u(idx) := ary_output(i);
               idx := idx + 1;
               
            END IF;
            
            tmp := ary_output(i);
            
         END LOOP;
         
         RETURN ary_output_u;
         
      ELSE
         RETURN ary_output;
         
      END IF;

   END sort_number;
   
END dz_lrs_util;
/

--******************************--
PROMPT Packages/DZ_LRS_MAIN.pks 

CREATE OR REPLACE PACKAGE dz_lrs_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_LRS
     
   - Build ID: DZBUILDIDDZ
   - Change Set: DZCHANGESETDZ
   
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

--******************************--
PROMPT Packages/DZ_LRS_MAIN.pkb 

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

--******************************--
PROMPT Packages/DZ_LRS_TEST.pks 

CREATE OR REPLACE PACKAGE dz_lrs_test
AUTHID DEFINER
AS

   C_CHANGESET CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 0.0;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
      
END dz_lrs_test;
/

GRANT EXECUTE ON dz_lrs_test TO public;

--******************************--
PROMPT Packages/DZ_LRS_TEST.pkb 

CREATE OR REPLACE PACKAGE BODY dz_lrs_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"CHANGESET":' || C_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_lrs_test;
/

SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_LRS%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_LRS_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;
SET DEFINE OFF;

