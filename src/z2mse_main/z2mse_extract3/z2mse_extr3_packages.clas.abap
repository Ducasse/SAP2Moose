CLASS z2mse_extr3_packages DEFINITION
  PUBLIC
  INHERITING FROM z2mse_extr3_elements
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF element_type,
             obj_id  TYPE z2mse_extr3_element_manager=>element_id_type,
             devclass TYPE DEVCLASS,
           END OF element_type.
ENDCLASS.

CLASS z2mse_extr3_packages IMPLEMENTATION.
ENDCLASS.
