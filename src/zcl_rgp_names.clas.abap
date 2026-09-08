CLASS zcl_rgp_names DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_RGP_NAMES IMPLEMENTATION.


METHOD if_oo_adt_classrun~main.


select *  "#EC CI_NOWHERE
from zdb_rgp_nrgp
into table @data(lt_stat).

 IF  sy-subrc = 0.
      DELETE zdb_rgp_nrgp FROM TABLE @lt_stat.
    ENDIF.

    CLEAR : lt_stat.

    lt_stat = VALUE #( ( id = 'RGP' name = 'RGP' )
                       ( id = 'NRGP' name = 'NRGP' )

                                    ).

    IF  lt_stat IS NOT INITIAL.
      INSERT zdb_rgp_nrgp FROM TABLE @lt_stat.
      COMMIT WORK.
    ENDIF.


eNDMETHOD.
ENDCLASS.
