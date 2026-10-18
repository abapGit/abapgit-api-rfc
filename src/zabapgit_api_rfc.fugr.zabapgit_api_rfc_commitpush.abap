FUNCTION zabapgit_api_rfc_commitpush.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ABAP_PACKAGE) TYPE  DEVCLASS
*"     VALUE(GIT_USER) TYPE  STRING
*"     VALUE(GIT_PASSWORD) TYPE  STRING
*"     VALUE(COMMENT) TYPE  STRING
*"     VALUE(BODY) TYPE  STRING DEFAULT ''
*"     VALUE(ALL) TYPE  XFELD DEFAULT ''
*"     VALUE(COMMITTER_NAME) TYPE  STRING DEFAULT ''
*"     VALUE(COMMITTER_EMAIL) TYPE  STRING DEFAULT ''
*"     VALUE(AUTHOR_NAME) TYPE  STRING DEFAULT ''
*"     VALUE(AUTHOR_EMAIL) TYPE  STRING DEFAULT ''
*"  TABLES
*"      RETURN TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
  DATA committed TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

  TRY.
      " Only committing all changes is supported for now; the flag keeps
      " room for passing a list of objects in the future.
      IF all <> abap_true.
        zcx_abapgit_exception=>raise( |Only committing all changes is supported - set the parameter ALL| ).
      ENDIF.

      IF comment IS INITIAL.
        zcx_abapgit_exception=>raise( |Commit comment must not be empty| ).
      ENDIF.

      IF author_email IS NOT INITIAL AND author_name IS INITIAL.
        zcx_abapgit_exception=>raise( |Author name must not be empty when author email is given| ).
      ENDIF.

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

      IF repo->is_offline( ) = abap_true.
        zcx_abapgit_exception=>raise( |Cannot push offline repo of the package { abap_package }| ).
      ENDIF.

      DATA(repo_online) = CAST zif_abapgit_repo_online( repo ).

      APPEND
        VALUE #( type = 'I' message = |Setting credentials of { git_user } for { repo_online->get_url( ) }| )
        TO return.

      zcl_abapgit_login_manager=>set_basic(
        iv_uri = repo_online->get_url( )
        iv_username = git_user
        iv_password = git_password ).

      APPEND VALUE #( type = 'I' message = |Collecting changes| ) TO return.
      DATA(files) = zcl_abapgit_stage_logic=>get_stage_logic( )->get( repo_online ).

      IF files-local IS INITIAL AND files-remote IS INITIAL.
        APPEND VALUE #( type = 'I' message = |Nothing to commit| ) TO return.
        RETURN.
      ENDIF.

      DATA(stage) = NEW zcl_abapgit_stage( ).

      LOOP AT files-local INTO DATA(local).
        stage->add(
          iv_path     = local-file-path
          iv_filename = local-file-filename
          iv_data     = local-file-data ).

        IF local-item-obj_name IS NOT INITIAL.
          APPEND |Committed: { local-item-obj_type } { local-item-obj_name }| TO committed.
        ELSE.
          " Files not belonging to any object - e.g. .abapgit.xml
          APPEND |Committed: { local-file-path }{ local-file-filename }| TO committed.
        ENDIF.
      ENDLOOP.

      LOOP AT files-remote INTO DATA(remote).
        stage->rm(
          iv_path     = remote-path
          iv_filename = remote-filename ).

        READ TABLE files-status INTO DATA(status)
          WITH TABLE KEY path = remote-path filename = remote-filename.
        IF sy-subrc = 0 AND status-obj_name IS NOT INITIAL.
          APPEND |Deleted: { status-obj_type } { status-obj_name }| TO committed.
        ELSE.
          APPEND |Deleted: { remote-path }{ remote-filename }| TO committed.
        ENDIF.
      ENDLOOP.

      " One object consists of several files
      SORT committed AS TEXT.
      DELETE ADJACENT DUPLICATES FROM committed.

      " Committer: parameters -> abapGit repo settings -> abapGit default settings
      "            -> user master record -> SAP user name
      DATA(user_settings) = zcl_abapgit_persist_factory=>get_user( ).
      DATA(user_record) = zcl_abapgit_env_factory=>get_user_record( ).

      IF committer_name IS INITIAL.
        committer_name = user_settings->get_repo_git_user_name( repo_online->get_url( ) ).
      ENDIF.
      IF committer_name IS INITIAL.
        committer_name = user_settings->get_default_git_user_name( ).
      ENDIF.
      IF committer_name IS INITIAL.
        committer_name = user_record->get_name( sy-uname ).
      ENDIF.
      IF committer_name IS INITIAL.
        committer_name = sy-uname.
      ENDIF.

      IF committer_email IS INITIAL.
        committer_email = user_settings->get_repo_git_user_email( repo_online->get_url( ) ).
      ENDIF.
      IF committer_email IS INITIAL.
        committer_email = user_settings->get_default_git_user_email( ).
      ENDIF.
      IF committer_email IS INITIAL.
        committer_email = user_record->get_email( sy-uname ).
      ENDIF.
      IF committer_email IS INITIAL.
        committer_email = |{ sy-uname }@localhost|.
      ENDIF.

      DATA(commit) = VALUE zif_abapgit_git_definitions=>ty_comment(
        committer = VALUE #( name = committer_name email = committer_email )
        author    = VALUE #( name = author_name email = author_email )
        comment   = comment ).

      IF body IS NOT INITIAL.
        CONCATENATE commit-comment '' body
          INTO commit-comment SEPARATED BY cl_abap_char_utilities=>newline.
      ENDIF.

      APPEND VALUE #( type = 'I' message = |Pushing as { committer_name } <{ committer_email }>| ) TO return.
      zcl_abapgit_repo_factory=>get_repo_push( repo_online )->push(
        is_comment = commit
        io_stage   = stage ).

      LOOP AT committed INTO DATA(committed_object).
        APPEND VALUE #( type = 'S' message = committed_object ) TO return.
      ENDLOOP.

      APPEND VALUE #( type = 'I' message = |Pushed { lines( committed ) } objects| ) TO return.
      APPEND VALUE #( type = 'I' message = |Done| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(ex).
      APPEND VALUE #( type = 'E' message = ex->if_message~get_text( ) ) TO return.
  ENDTRY.

ENDFUNCTION.
