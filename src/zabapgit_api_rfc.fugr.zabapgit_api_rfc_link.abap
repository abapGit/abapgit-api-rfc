FUNCTION zabapgit_api_rfc_link.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ABAP_PACKAGE) TYPE  DEVCLASS DEFAULT ''
*"     VALUE(GIT_REPO_URL) TYPE  STRING
*"     VALUE(GIT_USER) TYPE  STRING
*"     VALUE(GIT_PASSWORD) TYPE  STRING
*"     VALUE(BRANCH) TYPE  STRING DEFAULT ''
*"     VALUE(FOLDER_LOGIC) TYPE  STRING DEFAULT 'PREFIX'
*"     VALUE(IGNORE_SUBPACKAGES) TYPE  XFELD DEFAULT ''
*"     VALUE(MAIN_LANG_ONLY) TYPE  XFELD DEFAULT ''
*"     VALUE(STARTING_FOLDER) TYPE  STRING DEFAULT '/src/'
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"--------------------------------------------------------------------
  IF abap_package IS INITIAL.
    " https://github.com/abapgit/abapgit.git -> [ 'https:', '', 'github.com', 'abapgit', 'abapgit.git']
    SPLIT git_repo_url AT '/' INTO TABLE DATA(url_parts).
    " [ 'https:', '', 'github.com', 'abapgit', 'abapgit.git'] -> 'abapgit.git'
    DATA(repo_name_url_part) = url_parts[ lines( url_parts ) ].

    " 'abapgit.git' -> [ 'abapgit', 'git' ]
    SPLIT repo_name_url_part AT '.' INTO TABLE DATA(repo_name_parts).
    " [ 'abapgit', 'git' ] -> 'abapgit'
    abap_package = repo_name_parts[ 1 ].

    " make sure we use UPPER CASE
    TRANSLATE abap_package TO UPPER CASE.

    SELECT COUNT( * ) FROM tdevc WHERE devclass = @abap_package INTO @DATA(found).

    IF found = 0.
      APPEND VALUE #( type = 'I' message = |Did not find package: { abap_package }| ) TO return.

      " Try adding prefix $ which is often used for local packages.
      " Repository name cannot start with $ but ABAP package can.
      abap_package = |${ abap_package }|.
      SELECT COUNT( * ) FROM tdevc WHERE devclass = @abap_package INTO @found.

      IF found = 0.
        APPEND VALUE #( type = 'I' message = |Did not find local package: { abap_package }| ) TO return.
        APPEND VALUE #( type = 'E' message = |Cannot deduce ABAP package from Repository name| ) TO return.
        RETURN.
      ENDIF.
    ENDIF.

    APPEND VALUE #( type = 'I' message = |Parsed ABAP Package name: { abap_package }| ) TO return.
  ENDIF.

  TRY.
      APPEND VALUE #( type = 'I' message = |Running migrations| ) TO return.
      zcl_abapgit_migrations=>run( ).

      APPEND VALUE #( type = 'I' message = |Setting credentials of { git_user } for { git_repo_url }| ) TO return.
      zcl_abapgit_login_manager=>set(
        iv_uri = git_repo_url
        iv_username = git_user
        iv_password = git_password ).

      APPEND VALUE #( type = 'I' message = |Linking { git_repo_url } with { abap_package }| ) TO return.
      DATA(repo) = zcl_abapgit_repo_srv=>get_instance( )->new_online(
        iv_url = git_repo_url
        iv_branch_name = branch
        iv_package = abap_package
        iv_folder_logic = folder_logic
        iv_ign_subpkg = ignore_subpackages
        iv_main_lang_only = main_lang_only ).

      APPEND VALUE #( type = 'I' message = |Changing Folder logic| ) TO return.
      repo->get_dot_abapgit( )->set_starting_folder( starting_folder ).

      APPEND VALUE #( type = 'I' message = |Done| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(ex).
      APPEND VALUE #( type = 'E' message = ex->if_message~get_text( ) ) TO return.
  ENDTRY.

ENDFUNCTION.
