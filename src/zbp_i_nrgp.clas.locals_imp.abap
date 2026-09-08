CLASS lhc_ZI_nrgp_doc DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZI_NRGP_DOC RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZI_NRGP_DOC RESULT result.

    METHODS zprint FOR MODIFY
      IMPORTING keys FOR ACTION ZI_NRGP_DOC~zprint RESULT result.

ENDCLASS.


CLASS lhc_ZI_nrgp_doc IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD zprint.

    DATA: lv_base64         TYPE string,
          lv_token          TYPE string,
          lv_message        TYPE string,
         lv_gatetype       TYPE string,
          lv_pdf_b64_string TYPE string,
           lv_xdp_template   TYPE string,
          lit_header_upd    TYPE TABLE FOR UPDATE zi_nrgp.

    DATA lwa_header_upd LIKE LINE OF lit_header_upd.



    READ ENTITIES OF zi_nrgp
      IN LOCAL MODE
      ENTITY ZI_NRGP_DOC
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lit_result)
      FAILED DATA(lit_failed).

    CHECK lit_result IS NOT INITIAL.


    DATA: lv_gate  TYPE ZI_GATEENTRY_hdr_R-Zgate,
          lv_plant TYPE ZI_GATEENTRY_hdr_R-Plant.

    LOOP AT lit_result INTO DATA(lwa_result).
      lv_gate  = lwa_result-Zgate.
      lv_plant = lwa_result-Plant.
      lv_gatetype = lwa_result-type.
      MOVE-CORRESPONDING lwa_result TO lwa_header_upd.
      APPEND lwa_header_upd TO lit_header_upd.
      CLEAR lwa_header_upd.
    ENDLOOP.

 IF lv_gatetype IS INITIAL.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Gate Type (RGP/NRGP) is not set on this record.' )
      ) TO reported-ZI_NRGP_DOC.
      RETURN.
    ENDIF.

    SELECT COUNT(*)
      FROM ZI_GATEENTRY_itm_R
      WHERE Zgate = @lv_gate
      INTO @DATA(lv_itemcount).

    IF lv_itemcount = 0.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'No items found for this gate entry.' )
      ) TO reported-ZI_NRGP_DOC.
      RETURN.
    ENDIF.

 CASE lv_gatetype.
      WHEN 'RGP'.
        lv_xdp_template = 'ZMM_RGP/ZMM_RGP'.
      WHEN 'NRGP'.
        lv_xdp_template = 'ZMM_NRGP/ZMM_NRGP'.
      WHEN OTHERS.
        APPEND VALUE #(
          %tky = keys[ 1 ]-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Unknown type '{ lv_gatetype }'. Expected RGP or NRGP.| )
        ) TO reported-ZI_NRGP_DOC.
        RETURN.
    ENDCASE.

    zicl_com_9001=>get_ouath_token(
      EXPORTING
        im_oauth_url    = 'ADS_OAUTH_URL'
        im_clientid     = 'ADS_CLIENTID'
        im_clientsecret = 'ADS_CLIENTSECRET'
      IMPORTING
        ex_token        = lv_token
        ex_message      = lv_message
    ).

    IF lv_token IS INITIAL.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |ADS token error: { lv_message }| )
      ) TO reported-ZI_NRGP_DOC.
      RETURN.
    ENDIF.


    zbp_i_nrgp=>get_pdf_xml(
      EXPORTING
        im_gate     = lv_gate
        im_plant    = lv_plant
        im_gatetype = lv_gatetype
      IMPORTING
        ex_base_64  = lv_base64
    ).

    IF lv_base64 IS INITIAL.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'XML generation failed. Check gate entry data.' )
      ) TO reported-ZI_NRGP_DOC.
      RETURN.
    ENDIF.

    "--- 7. Call ADS to render PDF ---
    zicl_com_9001=>get_pdf_api(
      EXPORTING
        im_url           = 'ADS_URL'
        im_url_path      = '/v1/adsRender/pdf?TraceLevel=2&templateSource=storageName'
        im_clientid      = 'ADS_CLIENTID'
        im_clientsecret  = 'ADS_CLIENTSECRET'
        im_token         = lv_token
        im_base64_encode = lv_base64
        im_xdp_template  = lv_xdp_template
      IMPORTING

        ex_base64_decode = lv_pdf_b64_string
        ex_message       = lv_message
    ).

    IF lv_pdf_b64_string IS INITIAL.
      APPEND VALUE #(
        %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = |ADS render error: { lv_message }| )
      ) TO reported-ZI_NRGP_DOC.
      RETURN.
    ENDIF.



    LOOP AT lit_header_upd ASSIGNING FIELD-SYMBOL(<lwa_upd>).
      <lwa_upd>-MimeType    = 'application/pdf'.
      <lwa_upd>-Attachments = lv_pdf_b64_string.
      <lwa_upd>-FileName    = lv_gate && '.pdf'.
    ENDLOOP.

    MODIFY ENTITIES OF zi_nrgp IN LOCAL MODE
      ENTITY ZI_NRGP_DOC
      UPDATE FIELDS ( MimeType FileName Attachments )
      WITH lit_header_upd
      REPORTED DATA(lit_reported)
      FAILED DATA(lit_failed1).

    READ ENTITIES OF zi_nrgp IN LOCAL MODE
      ENTITY ZI_NRGP_DOC
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lit_final).

    result = VALUE #( FOR lwa_f IN lit_final
      ( %tky   = lwa_f-%tky
        %param = lwa_f ) ).

    APPEND VALUE #(
      %tky = keys[ 1 ]-%tky
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-success
        text     = 'PDF Generated Successfully!' )
    ) TO reported-ZI_NRGP_DOC.

  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_nrgp DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.


CLASS lsc_zi_nrgp IMPLEMENTATION.

  METHOD save_modified.

    DATA: lit_nrgp_att TYPE STANDARD TABLE OF zita_nrgp.

    IF update-ZI_NRGP_DOC IS NOT INITIAL.

      LOOP AT update-ZI_NRGP_DOC INTO DATA(ls_upd).


        IF ls_upd-Attachments IS INITIAL.
          CONTINUE.
        ENDIF.

        DATA(ls_att) = VALUE zita_nrgp(
          zgate      = ls_upd-Zgate
          mimetype   = ls_upd-MimeType
          filename   = ls_upd-FileName
          attachment = ls_upd-Attachments
        ).

        APPEND ls_att TO lit_nrgp_att.

      ENDLOOP.

      CHECK lit_nrgp_att IS NOT INITIAL.

      DATA(lwa_first) = VALUE #( lit_nrgp_att[ 1 ] OPTIONAL ).

      SELECT SINGLE zgate
        FROM zita_nrgp
        WHERE zgate = @lwa_first-zgate
        INTO @DATA(lv_exists).

      IF sy-subrc = 0.
        MODIFY zita_nrgp FROM TABLE @lit_nrgp_att.
      ELSE.
        INSERT zita_nrgp FROM TABLE @lit_nrgp_att.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
