FUNCTION zabapgit_api_rfc_pull.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ABAP_PACKAGE) TYPE  DEVCLASS
*"     VALUE(GIT_USER) TYPE  STRING
*"     VALUE(GIT_PASSWORD) TYPE  STRING
*"     VALUE(CORRNR) TYPE  TRKORR DEFAULT ''
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"--------------------------------------------------------------------
  TRY.
      APPEND VALUE #( type = 'I' message = 'Run migration' ) TO return.
      zcl_abapgit_migrations=>run( ).

      APPEND VALUE #( type = 'I' message = |Find repo for package { abap_package }| ) TO return.
      zcl_abapgit_repo_srv=>get_instance( )->get_repo_from_package(
        EXPORTING
          iv_package = abap_package
        IMPORTING
          ei_repo = DATA(repo) ).

      IF repo IS INITIAL.
        zcx_abapgit_exception=>raise( |Unable to find repo for package { abap_package }! | ).
      ENDIF.

      APPEND VALUE #( type = 'I' message = |Setting credentials of { git_user } for { repo->ms_data-url }| ) TO return.
      zcl_abapgit_login_manager=>set(
        iv_uri = repo->ms_data-url
        iv_username = git_user
        iv_password = git_password ).

      APPEND VALUE #( type = 'I' message = |Deserialize checks| ) TO return.
      DATA(checks) = repo->deserialize_checks( ).

      APPEND VALUE #( type = 'I' message = |Overwrite| ) TO return.
      LOOP AT checks-overwrite ASSIGNING FIELD-SYMBOL(<overwrite>).
        " object has been modified locally
        " decision field must be filled with y or n. y overwrites the object
        <overwrite>-decision = 'y'.
      ENDLOOP.

      APPEND VALUE #( type = 'I' message = |Correct packages| ) TO return.
      LOOP AT checks-warning_package ASSIGNING FIELD-SYMBOL(<warning_package>).
        " y or n if object from unexpected package should be overwritten
        <warning_package>-decision = 'y'.
      ENDLOOP.

      APPEND VALUE #( type = 'I' message = |Requirements| ) TO return.
      IF checks-requirements-met = 'n'.
        " code must decide if deserialization should continue or not
        checks-requirements-decision = 'y'.
      ENDIF.

      APPEND VALUE #( type = 'I' message = |Transport| ) TO return.
      IF checks-transport-required = abap_true.
        checks-transport-transport = corrnr.
      ENDIF.

      APPEND VALUE #( type = 'I' message = |Log| ) TO return.
      DATA(log) = NEW zcl_abapgit_log( ).

      APPEND VALUE #( type = 'I' message = |Deserializing| ) TO return.
      repo->deserialize(
        is_checks = checks
        ii_log = log ).

      APPEND VALUE #( type = 'I' message = |Finished| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(err).
      APPEND VALUE #( type = 'E' message = err->if_message~get_text( ) ) TO return.
  ENDTRY.
ENDFUNCTION.
