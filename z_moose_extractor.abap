*The MIT License (MIT)
*
*Copyright (c) 2016 Rainer Winkler, CubeServ
*
*Permission is hereby granted, free of charge, to any person obtaining a copy
*of this software and associated documentation files (the "Software"), to deal
*in the Software without restriction, including without limitation the rights
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*copies of the Software, and to permit persons to whom the Software is
*furnished to do so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*SOFTWARE.

"! This is an experimental prototype, that has errors
"!
"! The latest version are available on https://github.com/RainerWinkler/Moose-FAMIX-SAP-Extractor
"!
"! The program follows the naming conventions proposed in the ABAP Programming Guidelines from 2009.
"!
"! Semantics of variables and parameters have to be very strict
"! The code shall be able to be read near to as fluent as a well written English text
"! Use ABAP Doc comments if the technical name is not precise enough
"! Tables are in most cases specified with plural (classes). But not always, mse_model is a table.
"!
"! Prefixes are omitted if the reading is simplified
"!
"! Classes are prefixed with cl_ the instances have no prefixes
"! Global attributes are normally prefixed with g_
"! Instances are normally instanciated only once, to simplify coding no singleton pattern is used
"!
"! Short abbreviations are used if only locally used, in that case an ABAP Doc comments explains the variable
"! See the start of the report for this
REPORT yrw1_moose_extractor.

"! To not compare sy-subrc to zero, but more readable to ok
CONSTANTS ok TYPE i VALUE 0.
"! Redefines abap_bool to simplify coding (Not always reading abap_...)
TYPES bool TYPE abap_bool.
CONSTANTS:
  "! Redefines abap_true to simplify coding (Not always reading abap_...)
  true  TYPE bool VALUE abap_true,
  "! Redefines abap_false to simplify coding (Not always reading abap_...)
  false TYPE bool VALUE abap_false.

PARAMETERS: p_sap AS CHECKBOX DEFAULT 'X'.
"! Extract from SAP
DATA parameter_extract_from_sap TYPE abap_bool.
parameter_extract_from_sap = p_sap.

PARAMETERS: p_pack TYPE parentcl DEFAULT 'YRW1'.
"! Package to be analyzed
DATA parameter_package_to_analyze TYPE parentcl.
parameter_package_to_analyze = p_pack.

PARAMETERS: p_list AS CHECKBOX DEFAULT 'X'.
"! List Tokens of selected programs
DATA parameter_list_tokens TYPE abap_bool.
parameter_list_tokens = p_list.

PARAMETERS: p_dm AS CHECKBOX DEFAULT 'X'.
"! Usages outside package grouped
DATA parameter_usage_outpack_groupd TYPE abap_bool.

include z_mse.

include z_famix.

TYPES: BEGIN OF class_component_type,
         clsname TYPE seocompo-clsname,
         cmpname TYPE seocompo-cmpname,
         cmptype TYPE seocompo-cmptype,
       END OF class_component_type.

TYPES: BEGIN OF tadir_object_type,
          obj_name TYPE sobj_name,
          object   TYPE trobjtype,
          devclass TYPE devclass,
       END OF tadir_object_type.

TYPES: BEGIN OF class_interface_type,
        obj_name TYPE seoclsname,
      END OF class_interface_type.

TYPES: BEGIN OF program_type,
         program TYPE string,
       END OF program_type.

TYPES:BEGIN OF class_type,
        class TYPE seoclsname,
      END OF class_type.

TYPES: BEGIN OF inheritance_type,
         clsname    TYPE seometarel-clsname,
         refclsname TYPE seometarel-refclsname,
         reltype    TYPE seometarel-reltype,
       END OF inheritance_type.

CLASS cl_extract_sap DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS extract
      EXPORTING
        mse_model TYPE cl_model=>lines_type.
  PRIVATE SECTION.

    CONSTANTS comptype_attribute TYPE seocmptype VALUE '0'.
    CONSTANTS comptype_method TYPE seocmptype VALUE '1'.

    CLASS-METHODS _determine_usages
      IMPORTING
        famix_class      TYPE REF TO cl_famix_class
        class_component  TYPE class_component_type
        famix_method     TYPE REF TO cl_famix_method
        famix_invocation TYPE REF TO cl_famix_invocation
        famix_access     TYPE REF TO cl_famix_access
        used_id          TYPE i.

    CLASS-METHODS _set_default_language
      IMPORTING
        model TYPE REF TO cl_model.

    TYPES: BEGIN OF devclass_type,
          devclass TYPE DEVCLASS,
          END OF devclass_type.
    TYPES:
      processed_dev_classes_type TYPE HASHED TABLE OF devclass_type WITH UNIQUE KEY devclass.
    CLASS-METHODS _determine_packages_to_analyze
      IMPORTING
        model                       TYPE REF TO cl_model
        devclass_first              TYPE tdevc
      RETURNING
        VALUE(processed_dev_classes) TYPE processed_dev_classes_type.
    TYPES:
      tadir_objects_type TYPE HASHED TABLE OF tadir_object_type WITH UNIQUE KEY obj_name,
      classes_type     TYPE STANDARD TABLE OF class_interface_type WITH DEFAULT KEY,
      programs_type      TYPE STANDARD TABLE OF program_type WITH DEFAULT KEY.
    CLASS-METHODS _objects_to_analyze_by_tadir
      IMPORTING
        tadir_objects TYPE tadir_objects_type
      EXPORTING
        classes     TYPE classes_type
        programs      TYPE programs_type.
    TYPES:
      tadir_objects_2_type TYPE HASHED TABLE OF tadir_object_type WITH UNIQUE KEY obj_name,
      programs_1_type      TYPE STANDARD TABLE OF program_type WITH DEFAULT KEY.
    CLASS-METHODS _read_all_programs
      IMPORTING
        tadir_objects TYPE tadir_objects_2_type
        programs      TYPE programs_1_type
      CHANGING
        model          TYPE REF TO cl_model.
    TYPES:
      tadir_objects_3_type  TYPE HASHED TABLE OF tadir_object_type WITH UNIQUE KEY obj_name,
      existing_classes_type TYPE HASHED TABLE OF class_type WITH UNIQUE KEY class.
    CLASS-METHODS _add_classes_to_model
      IMPORTING
        famix_class        TYPE REF TO cl_famix_class
        tadir_objects     TYPE tadir_objects_3_type
        existing_classes  TYPE existing_classes_type.
    TYPES:
      existing_classes_1_type TYPE HASHED TABLE OF class_type WITH UNIQUE KEY class.
    CLASS-METHODS _determine_inheritances_betwee
      IMPORTING
        famix_inheritance        TYPE REF TO cl_famix_inheritance
        existing_classes        TYPE existing_classes_1_type.
    TYPES:
      existing_classes_2_type TYPE HASHED TABLE OF class_type WITH UNIQUE KEY class,
      class_components_type   TYPE HASHED TABLE OF class_component_type WITH UNIQUE KEY clsname cmpname.
    CLASS-METHODS _determine_class_components
      IMPORTING
        existing_classes        TYPE existing_classes_2_type
      RETURNING
        VALUE(class_components) TYPE class_components_type.
    TYPES:
      class_components_1_type TYPE HASHED TABLE OF class_component_type WITH UNIQUE KEY clsname cmpname.
    CLASS-METHODS _add_to_class_components_to_mo
      IMPORTING
        class_components       TYPE class_components_1_type
        famix_method           TYPE REF TO cl_famix_method
        famix_attribute        TYPE REF TO cl_famix_attribute
      RETURNING
        VALUE(class_component) TYPE class_component_type.
    TYPES:
      class_components_2_type TYPE HASHED TABLE OF class_component_type WITH UNIQUE KEY clsname cmpname.
    CLASS-METHODS _determine_usage_of_methods
      IMPORTING
        famix_class       TYPE REF TO cl_famix_class
        class_components TYPE class_components_2_type
        famix_method      TYPE REF TO cl_famix_method
        famix_attribute   TYPE REF TO cl_famix_attribute
        famix_invocation  TYPE REF TO cl_famix_invocation
        famix_access      TYPE REF TO cl_famix_access.
    TYPES:
      classes_4_type        TYPE STANDARD TABLE OF class_interface_type WITH DEFAULT KEY,
      existing_classes_3_type TYPE HASHED TABLE OF class_type WITH UNIQUE KEY class.
    CLASS-METHODS _read_all_classes
      IMPORTING
        classes               TYPE classes_4_type
      RETURNING
        VALUE(existing_classes) TYPE existing_classes_3_type.
    TYPES:
      tadir_objects_4_type TYPE HASHED TABLE OF tadir_object_type WITH UNIQUE KEY obj_name.
    CLASS-METHODS _select_objects_in_package_and
      IMPORTING
        model          TYPE REF TO cl_model
      EXPORTING
        tadir_objects TYPE tadir_objects_4_type
        return        TYPE bool.

ENDCLASS.

TYPES: BEGIN OF indexed_token_type,
         index TYPE i,
         str   TYPE string,
         row   TYPE token_row,
         col   TYPE token_col,
         type  TYPE token_type,
       END OF indexed_token_type.

TYPES sorted_tokens_type TYPE SORTED TABLE OF indexed_token_type WITH UNIQUE KEY index.

"! Analyze ABAP Statement of type K (Other ABAP key word)
CLASS cl_ep_analyze_other_keyword DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        sorted_tokens TYPE sorted_tokens_type.
    METHODS analyze
      IMPORTING
        statement TYPE sstmnt.
    TYPES statement_type TYPE c LENGTH 2.
    CONSTANTS:

      start_class_definition      TYPE statement_type VALUE 'CD',
      start_class_implementation  TYPE statement_type VALUE 'CI',
      end_class                   TYPE statement_type VALUE 'CE',
      method_definition           TYPE statement_type VALUE 'MD',
      start_method_implementation TYPE statement_type VALUE 'MI',
      end_method_implementation   TYPE statement_type VALUE 'ME',
      attribute_definition        TYPE statement_type VALUE 'AD',
      start_public                TYPE statement_type VALUE 'PU',
      start_protected             TYPE statement_type VALUE 'PO',
      start_private               TYPE statement_type VALUE 'PR'.


    TYPES: BEGIN OF info_type,
             statement_type      TYPE statement_type,
             is_class_stmnt_info TYPE bool,
             class_is_inheriting TYPE bool,
             class_inherits_from TYPE string,
             is_static           TYPE bool,
             name                TYPE string,
           END OF info_type.
    DATA: g_info TYPE info_type READ-ONLY.
  PRIVATE SECTION.
    DATA g_sorted_tokens TYPE sorted_tokens_type.
ENDCLASS.

CLASS cl_ep_analyze_other_keyword IMPLEMENTATION.

  METHOD constructor.
    g_sorted_tokens = sorted_tokens.
  ENDMETHOD.

  METHOD analyze.
    ASSERT statement-type EQ 'K'.
    g_info = VALUE #( ).

    " First Run, what is the keyword
    READ TABLE g_sorted_tokens ASSIGNING FIELD-SYMBOL(<token>) WITH TABLE KEY index = statement-from.
    IF sy-subrc <> ok.
      " TBD Error handling
      " In the moment ignore
      RETURN.
    ENDIF.

    CASE <token>-str.
      WHEN 'CLASS'.
        g_info-is_class_stmnt_info = true.

      WHEN 'ENDCLASS'.
        g_info-statement_type = end_class.
      WHEN 'PUBLIC'.
        g_info-statement_type = start_public.
      WHEN 'PROTECTED'.
        g_info-statement_type = start_protected.
      WHEN 'PRIVATE'.
        g_info-statement_type = start_private.
      WHEN 'METHODS'.
        " info-is_method_stmnt = true.
        g_info-statement_type = method_definition.
      WHEN 'CLASS-METHODS'.
        g_info-statement_type = method_definition.
        g_info-is_static = true.
      WHEN 'METHOD'.
        g_info-statement_type = start_method_implementation.
      WHEN 'ENDMETHOD'.
        g_info-statement_type = end_method_implementation.

      WHEN 'DATA'.
        g_info-statement_type = attribute_definition.
      WHEN 'CLASS-DATA'.
        g_info-statement_type = attribute_definition.
        g_info-is_static = true.
      WHEN OTHERS.
        " TBD
        " Add further, in the moment ignore
        RETURN.
    ENDCASE.

    " Second Run, what is the name
    IF g_info-is_class_stmnt_info EQ true
    OR g_info-statement_type EQ method_definition
    OR g_info-statement_type EQ start_method_implementation
    OR g_info-statement_type EQ attribute_definition.

      DATA(position_of_name) = statement-from + 1.
      READ TABLE g_sorted_tokens ASSIGNING <token> WITH TABLE KEY index = position_of_name.
      IF sy-subrc <> ok.
        " TBD Error handling
        " In the moment ignore
        RETURN.
      ENDIF.

      g_info-name = <token>-str.

      " Third run, further keywords
      IF g_info-is_class_stmnt_info EQ true.
        LOOP AT g_sorted_tokens ASSIGNING <token> WHERE index > position_of_name
                                                       AND index <= statement-to.
          CASE <token>-str.
            WHEN 'DEFINITION'.
              g_info-statement_type = start_class_definition.
            WHEN 'IMPLEMENTATION'.
              g_info-statement_type = start_class_implementation.
            WHEN 'INHERITING'.
              g_info-class_is_inheriting = true.
              DATA(superclass_is_at) = sy-tabix + 2.
              READ TABLE g_sorted_tokens ASSIGNING FIELD-SYMBOL(<ls_superclass_token>) WITH TABLE KEY index = superclass_is_at.
              IF sy-subrc EQ ok.
                g_info-class_inherits_from = <ls_superclass_token>-str.
              ELSE.
                " TBD Error handling
                " In the moment ignore
                RETURN.
              ENDIF.
          ENDCASE.
        ENDLOOP.
      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.


CLASS cl_program_analyzer DEFINITION.
  PUBLIC SECTION.
    METHODS extract
      IMPORTING
        module_reference TYPE i
        program          TYPE progname
      CHANGING
        model           TYPE REF TO cl_model.

ENDCLASS.

CLASS cl_program_analyzer IMPLEMENTATION.

  METHOD extract.
    DATA source TYPE TABLE OF string.
    READ REPORT program INTO source.

    DATA: tokens TYPE STANDARD TABLE OF stokes.

    DATA: sorted_tokens TYPE sorted_tokens_type.

    DATA statements TYPE STANDARD TABLE OF sstmnt.

    SCAN ABAP-SOURCE source TOKENS INTO tokens STATEMENTS INTO statements.

    LOOP AT tokens ASSIGNING FIELD-SYMBOL(<ls_token_2>).
      sorted_tokens = VALUE #( BASE sorted_tokens ( index = sy-tabix
                                                    str   = <ls_token_2>-str
                                                    row   = <ls_token_2>-row
                                                    col   = <ls_token_2>-col
                                                    type  = <ls_token_2>-type ) ).
    ENDLOOP.

    SORT statements BY from.

    IF parameter_list_tokens EQ true.
      WRITE: /.
      WRITE: / program.

    ENDIF.

    " TBD Continue here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    TYPES: ty_statement_type TYPE c LENGTH 1.
    TYPES ty_section_type TYPE c LENGTH 1.

    CONSTANTS: "! Is in public section
      public    TYPE ty_section_type VALUE '1',
      "! Is in protected section
      protected TYPE ty_section_type VALUE '2',
      "! Is in private section
      private   TYPE ty_section_type VALUE '3',
      "! Not in a section
      none      TYPE ty_section_type VALUE ' '.

    TYPES: BEGIN OF ty_codecontext,
             in_section               TYPE ty_section_type,
             in_class_definition      TYPE bool,
             implementation_of_class  TYPE string,
             implementation_of_method TYPE string,
           END OF ty_codecontext.

    "! Context of statement in the code
    DATA context TYPE ty_codecontext.

    TYPES: BEGIN OF ty_class,
             classname   TYPE string,
             id_in_model TYPE i,
           END OF ty_class.

    DATA: classes      TYPE HASHED TABLE OF ty_class WITH UNIQUE KEY classname,
          actual_class TYPE ty_class.

    TYPES: BEGIN OF ty_method,
             classname          TYPE string,
             class_id_in_model  TYPE i,
             methodname         TYPE string,
             method_id_in_model TYPE i,
             in_section         TYPE ty_section_type,
             instanciable       TYPE bool,
           END OF ty_method.

    DATA: methods       TYPE STANDARD TABLE OF ty_method,
          actual_method TYPE ty_method.

    TYPES: BEGIN OF ty_inheritance,
             subclass   TYPE string,
             superclass TYPE string,
           END OF ty_inheritance.

    DATA: inheritances TYPE STANDARD TABLE OF ty_inheritance.

    DATA token_number TYPE i.

    "! Instance that analyzes other ABAP Keywords
    DATA aok TYPE REF TO cl_ep_analyze_other_keyword.
    aok = NEW cl_ep_analyze_other_keyword( sorted_tokens = sorted_tokens ).

    LOOP AT statements ASSIGNING FIELD-SYMBOL(<ls_statement>).

      token_number = 0.
      CASE <ls_statement>-type.
        WHEN 'K'.

          aok->analyze( statement = <ls_statement> ).
          CASE aok->g_info-statement_type.
            WHEN aok->start_class_definition.
              " SAP_2_FAMIX_28        Determine local classes in programs
              context-in_class_definition = true.
              actual_class-classname = aok->g_info-name.
              classes = VALUE #( BASE classes ( actual_class ) ).
              IF aok->g_info-class_is_inheriting EQ true.
                " SAP_2_FAMIX_37        Determine local inheritances of classes
                inheritances = VALUE #( BASE inheritances ( subclass = actual_class-classname
                                                                  superclass = aok->g_info-class_inherits_from ) ).
              ENDIF.
            WHEN aok->start_public.
              context-in_section = public.
            WHEN aok->start_protected.
              context-in_section = protected.
            WHEN aok->start_private.
              context-in_section = private.
            WHEN aok->end_class.
              context-in_section = none.
              context-in_class_definition = false.
              context-implementation_of_class = VALUE #( ).
            WHEN aok->method_definition.
              " SAP_2_FAMIX_29      Determine local class methods in programs
              IF aok->g_info-is_static EQ true.
                actual_method = VALUE #( classname = actual_class-classname
                                            in_section = context-in_section ).
              ELSE.
                actual_method = VALUE #( classname = actual_class-classname
                                            in_section = context-in_section
                                            instanciable = true ).
              ENDIF.
              actual_method-methodname = aok->g_info-name.
            WHEN aok->start_class_implementation.
              context-implementation_of_class = aok->g_info-name.
            WHEN aok->start_method_implementation.
              context-implementation_of_method = aok->g_info-name.
              IF parameter_list_tokens EQ abap_true.
                FORMAT COLOR COL_GROUP.
              ENDIF.
            WHEN aok->end_method_implementation.
              context-implementation_of_method = VALUE #( ).
              IF parameter_list_tokens EQ abap_true.
                FORMAT COLOR COL_BACKGROUND.
              ENDIF.
            WHEN OTHERS.

          ENDCASE.

        WHEN OTHERS.

      ENDCASE.

      IF parameter_list_tokens EQ abap_true.
        WRITE: / <ls_statement>-type.
        LOOP AT sorted_tokens ASSIGNING FIELD-SYMBOL(<token>) WHERE
            index >= <ls_statement>-from
        AND index <= <ls_statement>-to.
          WRITE: '|', <token>-type, <token>-str.
        ENDLOOP.
      ENDIF.

    ENDLOOP.

    " Add local classes to model

    DATA(famix_class) = NEW cl_famix_class( model ).

    LOOP AT classes ASSIGNING FIELD-SYMBOL(<class>).
      " SAP_2_FAMIX_30        Map local classes of programs to FAMIX.Class

      <class>-id_in_model = famix_class->add( EXPORTING name_group = CONV string( program )
                                                        name                   = <class>-classname ).

      " SAP_2_FAMIX_31     Assign local classes to a container of type FAMIX.Module with the name of the program

      famix_class->set_container( EXPORTING container_element = 'FAMIX.Module'
                                            parent_container  = CONV string( program ) ).


    ENDLOOP.

    " Add local methods to model

    DATA(famix_method) = NEW cl_famix_method( model ).

    LOOP AT methods ASSIGNING FIELD-SYMBOL(<method>).
      READ TABLE classes ASSIGNING FIELD-SYMBOL(<class_2>) WITH TABLE KEY classname = <method>-classname.
      <method>-class_id_in_model = <class_2>-id_in_model.

      " SAP_2_FAMIX_32      Map local methods to the FAMIX.Method

      <method>-method_id_in_model = famix_method->add( EXPORTING name_group = <class_2>-classname
                                                                 name       = <method>-methodname ).
      " SAP_2_FAMIX_43        Fill the attribut signature of FAMIX.METHOD with the name of the method
      famix_method->set_signature( signature = <method>-methodname ).

      " SAP_2_FAMIX_33      Set the attribute parentType of FAMIX.Method for local methods to the name of the local class


      famix_method->set_parent_type( EXPORTING parent_element = 'FAMIX.Class'
                                               parent_id      =  <class_2>-id_in_model ).
    ENDLOOP.

    " Add local inheritances to model

    DATA(famix_inheritance) = NEW cl_famix_inheritance( model ).
    LOOP AT inheritances INTO DATA(inheritance).
      " SAP_2_FAMIX_38        Map local inheritances of classes to FAMIX.Inheritance
      famix_inheritance->add( ).
      famix_inheritance->set_sub_and_super_class( EXPORTING subclass_element      = 'FAMIX.Class'
                                                            subclass_name_group   = CONV #( program )
                                                            subclass_name         = inheritance-subclass
                                                            superclass_element    = 'FAMIX.Class'
                                                            superclass_name_group = CONV #( program )
                                                            superclass_name       = inheritance-superclass ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS cl_extract_sap IMPLEMENTATION.

  METHOD extract.

    TYPES:BEGIN OF ty_devclass,
            devclass TYPE devclass,
          END OF ty_devclass.


    DATA first_devclass type tdevc.
    DATA processed_dev_classes TYPE processed_dev_classes_type.
    DATA: tadir_objects TYPE HASHED TABLE OF tadir_object_type WITH UNIQUE KEY obj_name.
    DATA: classes TYPE STANDARD TABLE OF class_interface_type.
    DATA: programs TYPE STANDARD TABLE OF program_type.
    DATA: existing_classes TYPE HASHED TABLE OF class_type WITH UNIQUE KEY class.

    DATA: class_components TYPE HASHED TABLE OF class_component_type WITH UNIQUE KEY clsname cmpname.

    DATA class_component TYPE class_component_type.

    " Do not use singleton pattern, but define each instance only one time at the start

    DATA(model) = NEW cl_model( ).
    DATA(famix_class) = NEW cl_famix_class( model ).
    DATA(famix_inheritance) = NEW cl_famix_inheritance( model ).
    DATA(famix_method) = NEW cl_famix_method( model ).
    DATA(famix_attribute) = NEW cl_famix_attribute( model ).
    DATA(famix_invocation) = NEW cl_famix_invocation( model ).
    DATA(famix_access) = NEW cl_famix_access( model ).

    _set_default_language( model ).

    DATA do_return TYPE abap_bool.


    _select_objects_in_package_and( EXPORTING model = model
                                    IMPORTING tadir_objects = tadir_objects
                                              return        = do_return ).

    IF do_return EQ true.
      RETURN.
    ENDIF.

   _objects_to_analyze_by_tadir( EXPORTING tadir_objects = tadir_objects
                                 IMPORTING classes = classes
                                           programs  = programs ).

   _read_all_programs( EXPORTING tadir_objects = tadir_objects
                                 programs      = programs
                        CHANGING model = model ).

    existing_classes = _read_all_classes( classes ).

    _add_classes_to_model( famix_class       = famix_class
                           tadir_objects    = tadir_objects
                           existing_classes = existing_classes ).

    _determine_inheritances_betwee( famix_inheritance             = famix_inheritance
                                    existing_classes = existing_classes ).

    class_components = _determine_class_components( existing_classes ).

    class_component = _add_to_class_components_to_mo( class_components = class_components
                                                         famix_method      = famix_method
                                                         famix_attribute   = famix_attribute ).

    _determine_usage_of_methods( famix_class       = famix_class
                                 class_components = class_components
                                 famix_method      = famix_method
                                 famix_attribute   = famix_attribute
                                 famix_invocation  = famix_invocation
                                 famix_access      = famix_access ).

    model->make_mse( IMPORTING mse_model = mse_model ).

  ENDMETHOD.


  METHOD _determine_usages.

    DATA where_used_name TYPE eu_lname.
    CASE class_component-cmptype.
      WHEN comptype_method.

        " SAP_2_FAMIX_17      Determine usage of class methods by programs and classes
        " SAP_2_FAMIX_18      Determine usage of interface methods by programs and classes

        where_used_name = class_component-clsname && |\\ME:| && class_component-cmpname.
        SELECT * FROM wbcrossgt INTO TABLE @DATA(where_used_objects) WHERE otype = 'ME' AND name = @where_used_name.
      WHEN comptype_attribute.

        " SAP_2_FAMIX_19      Determine usage of class attributes by programs and classes
        " SAP_2_FAMIX_20      Determine usage of interface attributes by programs and classes

        where_used_name = class_component-clsname && |\\DA:| && class_component-cmpname.
        SELECT * FROM wbcrossgt INTO TABLE @where_used_objects WHERE otype = 'DA' AND name = @where_used_name.
      WHEN OTHERS.
        ASSERT 1 = 2.
    ENDCASE.

    LOOP AT where_used_objects ASSIGNING FIELD-SYMBOL(<where_used_object>).
      SELECT SINGLE * FROM ris_prog_tadir INTO @DATA(ris_prog_tadir_line) WHERE program_name = @<where_used_object>-include.
      IF sy-subrc EQ ok.
        CASE ris_prog_tadir_line-object_type.
          WHEN 'CLAS'.
            " Used by method
            DATA: using_method TYPE string.
            IF ris_prog_tadir_line-method_name IS INITIAL.
              using_method = 'DUMMY'.
            ELSE.
              using_method = CONV string( ris_prog_tadir_line-method_name ).
            ENDIF.


            DATA(using_method_id) = famix_method->get_id( class  = CONV string( ris_prog_tadir_line-object_name )
                                                             method = using_method ).
            IF using_method_id EQ 0.

              IF parameter_usage_outpack_groupd EQ false.

                " Method does not exist, create the class
                " SAP_2_FAMIX_21      If an object is used by a class that is not selected, add this class to the model
                " SAP_2_FAMIX_22      Do not assign classes that included due to usage to a package

                famix_class->add( EXPORTING name = CONV string( ris_prog_tadir_line-object_name )
                                  IMPORTING exists_already_with_id = DATA(lv_exists_already_with_id) ).

              ELSE.
                " SAP_2_FAMIX_35        Add a usage to a single dummy class "OTHER_SAP_CLASS" if required by a parameter

                famix_class->add( EXPORTING name = 'OTHER_SAP_CLASS'
                                  IMPORTING exists_already_with_id = lv_exists_already_with_id ).

              ENDIF.

              " Now there is a class, but no duplicate class

              IF parameter_usage_outpack_groupd EQ false.
                using_method_id = famix_method->get_id( class  = CONV string( ris_prog_tadir_line-object_name )
                                                                method = using_method ).
              ELSE.
                using_method_id = famix_method->get_id( class  = 'OTHER_SAP_CLASS'
                                                             method = 'OTHER_SAP_METHOD' ).
              ENDIF.


              IF using_method_id EQ 0.
                IF parameter_usage_outpack_groupd EQ false.
                  " Now also the method is to be created
                  " SAP_2_FAMIX_23        If an object is used by a class that is not selected, add the using methods to the model

                  using_method_id = famix_method->add( EXPORTING name = using_method ).
                  " SAP_2_FAMIX_41      Fill the attribut signature of FAMIX.METHOD with the name of the method
                  famix_method->set_signature( signature = using_method ).
                  famix_method->set_parent_type( EXPORTING parent_element = 'FAMIX.Class'
                                                           parent_name    = CONV string( ris_prog_tadir_line-object_name ) ).
                  famix_method->store_id( class = CONV string( ris_prog_tadir_line-object_name )
                                            method = using_method ).
                ELSE.

                  " SAP_2_FAMIX_36        Add a usage to a single dummy method "OTHER_SAP_METHOD" if required by a parameter

                  using_method_id = famix_method->add( EXPORTING name = 'OTHER_SAP_METHOD' ).
                  " SAP_2_FAMIX_41      Fill the attribut signature of FAMIX.METHOD with the name of the method
                  famix_method->set_signature( signature = 'OTHER_SAP_METHOD' ).
                  famix_method->set_parent_type( EXPORTING parent_element = 'FAMIX.Class'
                                                           parent_name    = 'OTHER_SAP_CLASS' ).
                  famix_method->store_id( class = 'OTHER_SAP_CLASS'
                                            method = 'OTHER_SAP_METHOD' ).
                ENDIF.
              ENDIF.

            ENDIF.

            CASE class_component-cmptype.
              WHEN comptype_method.

                " SAP_2_FAMIX_24      Map usage of ABAP class methods by methods of classes to FAMIX.Invocation
                " SAP_2_FAMIX_25      Map usage of ABAP interface methods by methods of classes to FAMIX.Invocation
                IF famix_invocation->is_new_invocation_to_candidate( sender_id     = using_method_id
                                                                     candidates_id = used_id ).
                  famix_invocation->add( ).
                  famix_invocation->set_invocation_by_reference( EXPORTING sender_id     = using_method_id
                                                                           candidates_id = used_id
                                                                           signature     = 'DUMMY' ).
                ENDIF.
              WHEN comptype_attribute.
                " SAP_2_FAMIX_26      Map usage of ABAP class attributes by methods of classes to FAMIX.Invocation
                " SAP_2_FAMIX_27      Map usage of ABAP interface attributes by methods of classes to FAMIX.Invocation

                IF famix_access->is_new_access( accessor_id = using_method_id
                                                variable_id = used_id ).
                  famix_access->add( ).
                  famix_access->set_accessor_variable_relation( EXPORTING accessor_id = using_method_id
                                                                          variable_id = used_id ).
                ENDIF.
              WHEN OTHERS.
                ASSERT 1 = 2.
            ENDCASE.


          WHEN OTHERS.
            " TBD Implement other usages
        ENDCASE.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD _set_default_language.

    " Set default language

    DATA(famix_custom_source_language) = NEW cl_famix_custom_source_lang( model ).

    famix_custom_source_language->add( name = 'ABAP' ).

    " Do not assign any entities to ABAP, because otherwise this will not be the default language anymore
    " So do not do this for ABAP, but maybe for another language
    " famix_package->set_declared_source_language( EXPORTING i_source_language_element = 'FAMIX.CustomSourceLanguage'
    "                                                        i_source_language_name    = 'ABAP' ).

  ENDMETHOD.


  METHOD _determine_packages_to_analyze.

    DATA ty_devclass TYPE devclass_type.

    " Determine packages to analyze

    DATA(famix_package) = NEW cl_famix_package( model ).

    "! A temporal helper table used to find all packages (development classes) in the selection
    DATA temp_dev_classes_to_search TYPE STANDARD TABLE OF devclass_type.

    famix_package->add( name = CONV string( devclass_first-devclass ) ).

    INSERT VALUE devclass_type( devclass = devclass_first-devclass ) INTO TABLE processed_dev_classes.

    temp_dev_classes_to_search = VALUE #( ( devclass = parameter_package_to_analyze ) ).
    WHILE temp_dev_classes_to_search IS NOT INITIAL.
      IF temp_dev_classes_to_search IS NOT INITIAL.
        SELECT devclass, parentcl FROM tdevc INTO TABLE @DATA(devclasses)
         FOR ALL ENTRIES IN @temp_dev_classes_to_search WHERE parentcl = @temp_dev_classes_to_search-devclass.
      ENDIF.

      temp_dev_classes_to_search = VALUE #( ).

      LOOP AT devclasses INTO DATA(devclass).

        INSERT VALUE devclass_type( devclass = devclass-devclass ) INTO TABLE processed_dev_classes.
        IF sy-subrc EQ ok.
          " New devclass
          " Search again
          temp_dev_classes_to_search = VALUE #( BASE temp_dev_classes_to_search ( devclass = devclass-devclass ) ).
          famix_package->add( name = CONV string( devclass-devclass ) ).
          famix_package->set_parent_package( parent_package = CONV string( devclass-parentcl ) ).
        ENDIF.

      ENDLOOP.

      SORT temp_dev_classes_to_search.
      DELETE ADJACENT DUPLICATES FROM temp_dev_classes_to_search.

    ENDWHILE.

  ENDMETHOD.


  METHOD _objects_to_analyze_by_tadir.

    " Loop over all packages to find classes and programms

    " SAP_2_FAMIX_1     Extract classes from Dictionary
    " SAP_2_FAMIX_2     Extract interfaces as FAMIX.Class with attribute isinterface

    MOVE-CORRESPONDING tadir_objects TO classes.

    LOOP AT tadir_objects ASSIGNING FIELD-SYMBOL(<tadir_object>).

      IF <tadir_object>-object EQ 'CLAS'
      OR <tadir_object>-object EQ 'INTF'.

        classes = VALUE #( BASE classes ( obj_name = <tadir_object>-obj_name ) ).

      ELSE.

        programs = VALUE #( BASE programs ( program = <tadir_object>-obj_name ) ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD _read_all_programs.

    " Read all programs

    " SAP_2_FAMIX_4     Extract programs

    DATA(famix_module) = NEW cl_famix_module( model ).

    LOOP AT programs ASSIGNING FIELD-SYMBOL(<program>).

      " SAP_2_FAMIX_5     Map program to FAMIX.Module
      DATA(module_reference) = famix_module->add( EXPORTING name = <program>-program ).

      READ TABLE tadir_objects ASSIGNING FIELD-SYMBOL(<tadir_object>) WITH TABLE KEY obj_name = <program>-program.
      ASSERT sy-subrc EQ ok.

      famix_module->set_parent_package( parent_package = CONV string( <tadir_object>-devclass ) ).

      DATA(program_analyzer) = NEW cl_program_analyzer( ).

      program_analyzer->extract( EXPORTING module_reference = module_reference
                                           program          = CONV #( <program>-program )
                                  CHANGING model           = model ).

    ENDLOOP.

  ENDMETHOD.


  METHOD _add_classes_to_model.

    " Add to model
    LOOP AT existing_classes INTO DATA(existing_class).

      " SAP_2_FAMIX_6     Map ABAP classes to FAMIX.Class
      " SAP_2_FAMIX_7     Map ABAP Interfaces to FAMIX.Class
      famix_class->add( name = CONV string( existing_class-class ) ).

      READ TABLE tadir_objects ASSIGNING FIELD-SYMBOL(<tadir_object>) WITH TABLE KEY obj_name = existing_class-class.
      ASSERT sy-subrc EQ ok.

      famix_class->set_parent_package( parent_package = CONV string( <tadir_object>-devclass ) ).
      IF <tadir_object>-object EQ 'INTF'.
        " SAP_2_FAMIX_8       Set the attribute isInterface in case of ABAP Interfaces
        famix_class->is_interface( ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD _determine_inheritances_betwee.

    " Determine inheritances between selected classes

    DATA: inheritances TYPE STANDARD TABLE OF  inheritance_type.

    IF existing_classes IS NOT INITIAL.
      SELECT clsname, refclsname, reltype FROM seometarel INTO CORRESPONDING FIELDS OF TABLE @inheritances
        FOR ALL ENTRIES IN @existing_classes WHERE clsname = @existing_classes-class
                                               AND version = 1.
    ENDIF.

    " Delete all inheritances where superclass is not in selected packages
    LOOP AT inheritances INTO DATA(inheritance).
      READ TABLE existing_classes TRANSPORTING NO FIELDS WITH TABLE KEY class = inheritance-refclsname.
      IF sy-subrc <> ok.
        DELETE inheritances.
      ENDIF.
    ENDLOOP.

    " Add inheritances to model
    LOOP AT inheritances INTO DATA(inheritance_2).
      CASE inheritance_2-reltype.
        WHEN 2.
          " Inheritance
          " SAP_2_FAMIX_39     Map all inheritances between classes in selected packages to FAMIX.Inheritance
          famix_inheritance->add( ).
          famix_inheritance->set_sub_and_super_class( EXPORTING subclass_element      = 'FAMIX.Class'
                                                                subclass_name_group   = ''
                                                                subclass_name         = CONV #( inheritance_2-clsname )
                                                                superclass_element    = 'FAMIX.Class'
                                                                superclass_name_group = ''
                                                                superclass_name       = CONV #( inheritance_2-refclsname ) ).
        WHEN 1.
          " Interface implementation
          " SAP_2_FAMIX_40        Map all interface implementations of interfaces in selected packages by classes of selected packages by FAMIX.Inheritance

          famix_inheritance->add( ).
          famix_inheritance->set_sub_and_super_class( EXPORTING subclass_element      = 'FAMIX.Class'
                                                                subclass_name_group   = ''
                                                                subclass_name         = CONV #( inheritance_2-clsname )
                                                                superclass_element    = 'FAMIX.Class'
                                                                superclass_name_group = ''
                                                                superclass_name       = CONV #( inheritance_2-refclsname ) ).

        WHEN 0.
          " Interface composition     (i COMPRISING i_ref)
          " TBD
        WHEN 5.
          " Enhancement            ( c enhances c_ref)
          " TBD
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD _determine_class_components.

    " Determine class components

    " SAP_2_FAMIX_9         Extract methods of classes
    " SAP_2_FAMIX_10        Extract methods of interfaces
    " SAP_2_FAMIX_11        Extract attributes of classes
    " SAP_2_FAMIX_12        Extract attributes of interfaces

    IF existing_classes IS NOT INITIAL.
      "
      SELECT clsname, cmpname, cmptype FROM seocompo INTO TABLE @class_components
        FOR ALL ENTRIES IN @existing_classes
        WHERE
          clsname = @existing_classes-class.

    ENDIF.

  ENDMETHOD.


  METHOD _add_to_class_components_to_mo.

    " Add to class components to model

    LOOP AT class_components INTO class_component.

      CASE class_component-cmptype.
        WHEN comptype_attribute. "Attribute

          " SAP_2_FAMIX_13        Mapp attributes of classes to FAMIX.Attribute
          " SAP_2_FAMIX_14        Mapp attributes of interfaces to FAMIX.Attribute

          famix_attribute->add( name = CONV string( class_component-cmpname ) ).
          famix_attribute->set_parent_type(
            EXPORTING
              parent_element = 'FAMIX.Class'
              parent_name    = CONV string( class_component-clsname ) ).
          famix_attribute->store_id( EXPORTING class     = CONV string( class_component-clsname )
                                               attribute = CONV string( class_component-cmpname ) ).

        WHEN comptype_method. "Method

          " SAP_2_FAMIX_15        Map methods of classes to FAMIX.Method
          " SAP_2_FAMIX_16        Map methods of interfaces to FAMIX.Method

          famix_method->add( name = CONV string( class_component-cmpname ) ).
          " SAP_2_FAMIX_41      Fill the attribut signature of FAMIX.METHOD with the name of the method
          " SAP_2_FAMIX_42        Fill the attribut signature of FAMIX.METHOD with the name of the method
          famix_method->set_signature( signature = CONV string( class_component-cmpname ) ).
          famix_method->set_parent_type(
            EXPORTING
              parent_element = 'FAMIX.Class'
              parent_name    = CONV string( class_component-clsname ) ).
          famix_method->store_id( EXPORTING class  = CONV string( class_component-clsname )
                                            method = CONV string( class_component-cmpname ) ).
        WHEN 2. "Event
        WHEN 3. "Type
        WHEN OTHERS.
          " TBD Warn

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.


  METHOD _determine_usage_of_methods.

    DATA class_component TYPE class_component_type.

    " Determine usage of methods

    LOOP AT class_components INTO class_component WHERE cmptype = comptype_attribute  " Methods
                                                     OR cmptype = comptype_method. "Attributes

      CASE class_component-cmptype.
        WHEN comptype_method.
          DATA(used_id) = famix_method->get_id( class  = CONV string( class_component-clsname )
                                                method = CONV string( class_component-cmpname ) ).

        WHEN comptype_attribute.
          used_id = famix_attribute->get_id( class     = CONV string( class_component-clsname )
                                             attribute = CONV string( class_component-cmpname ) ).

        WHEN OTHERS.
          ASSERT 1 = 2.
      ENDCASE.

      _determine_usages( famix_class      = famix_class
                         class_component  = class_component
                         famix_method     = famix_method
                         famix_invocation = famix_invocation
                         famix_access     = famix_access
                         used_id          = used_id ).

    ENDLOOP.

  ENDMETHOD.


  METHOD _read_all_classes.

    " Read all classes

    " Determine existing classes
    IF classes IS NOT INITIAL.
      SELECT clsname AS class FROM seoclass INTO TABLE @existing_classes FOR ALL ENTRIES IN @classes
        WHERE
          clsname = @classes-obj_name.
    ENDIF.

  ENDMETHOD.

  METHOD _select_objects_in_package_and.

    DATA first_devclass TYPE tdevc.
    DATA processed_dev_classes TYPE cl_extract_sap=>processed_dev_classes_type.

    " Select objects in package and sub package
    " SAP_2_FAMIX_3     Select all Objects in a package and the sub packages of this package

    SELECT SINGLE devclass, parentcl FROM tdevc INTO @first_devclass WHERE devclass = @parameter_package_to_analyze.
    IF sy-subrc <> ok.
      WRITE: 'Package does not exist: ', parameter_package_to_analyze.
      return  = abap_true.
    ENDIF.

    processed_dev_classes = _determine_packages_to_analyze( model           = model
                                                            devclass_first = first_devclass ).

    IF processed_dev_classes IS NOT INITIAL.
      SELECT obj_name, object, devclass FROM tadir INTO TABLE @tadir_objects FOR ALL ENTRIES IN @processed_dev_classes
        WHERE
          pgmid = 'R3TR'
          AND ( object = 'CLAS' OR object = 'INTF' OR object = 'PROG' )
          AND devclass = @processed_dev_classes-devclass.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.

  DATA: mse_model TYPE cl_model=>lines_type.
  IF parameter_extract_from_sap EQ false.
    cl_make_demo_model=>make( IMPORTING mse_model = mse_model ).
  ELSE.
    cl_extract_sap=>extract( IMPORTING mse_model = mse_model ).
  ENDIF.

  cl_output_model=>make( mse_model = mse_model ).