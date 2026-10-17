FUNCTION zabapgit_api_rfc_list.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      REPOSITORIES TYPE  ZABAPGIT_API_RFC_REPO_T
*"      RETURN TYPE  BAPIRET2_T
*"--------------------------------------------------------------------
  TRY.
      APPEND VALUE #( type = 'I' message = |Running migrations| ) TO return.
      zcl_abapgit_migrations=>run( ).

      APPEND VALUE #( type = 'I' message = |Listing repositories| ) TO return.
      DATA(repo_list) = zcl_abapgit_repo_srv=>get_instance( )->list( ).

      LOOP AT repo_list INTO DATA(repo).
        APPEND VALUE #(
          repo_key        = repo->ms_data-key
          name            = repo->get_name( )
          abap_package    = repo->ms_data-package
          is_offline      = repo->ms_data-offline
          url             = repo->ms_data-url
          branch_name     = repo->ms_data-branch_name
          selected_commit = repo->ms_data-selected_commit
          created_by      = repo->ms_data-created_by
          created_at      = repo->ms_data-created_at
          deserialized_by = repo->ms_data-deserialized_by
          deserialized_at = repo->ms_data-deserialized_at ) TO repositories.
      ENDLOOP.

      APPEND VALUE #( type = 'I' message = |Found { lines( repositories ) } repositories| ) TO return.
    CATCH zcx_abapgit_exception INTO DATA(ex).
      APPEND VALUE #( type = 'E' message = ex->if_message~get_text( ) ) TO return.
  ENDTRY.

ENDFUNCTION.
