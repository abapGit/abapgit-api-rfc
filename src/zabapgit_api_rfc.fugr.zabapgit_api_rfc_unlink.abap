FUNCTION zabapgit_api_rfc_unlink.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ABAP_PACKAGE) TYPE  DEVCLASS
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"--------------------------------------------------------------------
  TRY.
      APPEND VALUE #( type = 'I' message = |Running migrations| ) TO return.
      zcl_abapgit_migrations=>run( ).

      APPEND VALUE #( type = 'I' message = |Find repo for the package { abap_package }| ) TO return.
      zcl_abapgit_repo_srv=>get_instance( )->get_repo_from_package(
        EXPORTING
          iv_package = abap_package
        IMPORTING
          ei_repo = DATA(repo) ).

      IF repo IS INITIAL.
        zcx_abapgit_exception=>raise( |Unable to find repo for package { abap_package }! | ).
      ENDIF.

      APPEND VALUE #( type = 'I' message = |Unlinking the package { abap_package }| ) TO return.
      DATA(repo_svc) = zcl_abapgit_repo_srv=>get_instance( ).
      repo_svc->delete( repo ).

      APPEND VALUE #( type = 'I' message = |Done| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(ex).
      APPEND VALUE #( type = 'E' message = ex->if_message~get_text( ) ) TO return.
  ENDTRY.

ENDFUNCTION.
