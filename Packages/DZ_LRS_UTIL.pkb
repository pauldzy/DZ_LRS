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

