FUNCTION zabapgit_api_rfc_switchbranch.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ABAP_PACKAGE) TYPE  DEVCLASS
*"     VALUE(BRANCH_NAME) TYPE  STRING DEFAULT 'master'
*"     VALUE(GIT_USER) TYPE  STRING
*"     VALUE(GIT_PASSWORD) TYPE  STRING
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

      DATA(online_repo) = CAST zcl_abapgit_repo_online( repo ).
      DATA(url) = online_repo->get_url( ).

      APPEND VALUE #( type = 'I' message = |Setting credentials of { git_user } for { url }| ) TO return.
      zcl_abapgit_login_manager=>set(
        iv_uri = url
        iv_username = git_user
        iv_password = git_password ).

      APPEND VALUE #( type = 'I' message = |Checking out { branch_name } in { url }| ) TO return.

      IF substring( val = url
                    off = strlen( url ) - 1
                    len = 1 ) = '/'.
        url = substring( val = url
                         off = 0
                         len = strlen( url ) - 1 ).
      ENDIF.

      DATA(branch_list) = zcl_abapgit_git_transport=>branches( url ).
      DATA(branches) = branch_list->get_branches_only( ).

      IF strlen( branch_name ) < 5 OR NOT substring( val = branch_name
                                                     off = 0
                                                     len = 5 ) = 'refs/'.
        CONCATENATE 'refs/heads/' branch_name INTO branch_name.
      ENDIF.

      IF NOT line_exists( branches[ name = branch_name ] ).
        zcx_abapgit_exception=>raise( |Checkout failed: Branch { branch_name } does not exist! | ).
      ENDIF.

      online_repo->select_branch( branch_name ).

      APPEND VALUE #( type = 'I' message = |Finished| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(err).
      APPEND VALUE #( type = 'E' message = err->if_message~get_text( ) ) TO return.
  ENDTRY.
ENDFUNCTION.
