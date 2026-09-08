CLASS zbp_i_nrgp DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zi_nrgp.

  CLASS-METHODS get_pdf_xml
    IMPORTING
      im_gate     TYPE ZI_GATEENTRY_hdr_R-Zgate
      im_plant    TYPE ZI_GATEENTRY_hdr_R-Plant
      im_gatetype TYPE string
    EXPORTING
      ex_base_64  TYPE string.

ENDCLASS.



CLASS ZBP_I_NRGP IMPLEMENTATION.


  METHOD get_pdf_xml.


    DATA: lv_plant_addr  TYPE string,
          lv_date        TYPE string,
          lv_rows_p1     TYPE string,
          lv_rows_p2     TYPE string,
          lv_row         TYPE string,
          lv_srno        TYPE i,
          lwa_plant_addr TYPE zist_com_9001.

    DATA: lv_hdr_zgate    TYPE string,
          lv_hdr_vehno    TYPE string,
          lv_hdr_gateindt TYPE d,
          lv_hdr_trans    TYPE string,
          lv_hdr_remark   TYPE string,
          lv_hdr_vendor   TYPE string,
          lv_hdr_vndaddr  TYPE string.

    DATA: lv_formtype        TYPE string,
          lv_xml             TYPE string,
          lv_plant_name      TYPE string,
          lv_gatein_datetime TYPE string.


    SELECT SINGLE
        Zgate,
        Vehno,
        Gateindt,
        trans,
        Remark,
        Vendor,
        VendorAddr
      FROM ZI_GATEENTRY_hdr_R
      WHERE Zgate = @im_gate
      INTO ( @lv_hdr_zgate,
             @lv_hdr_vehno,
             @lv_hdr_gateindt,
             @lv_hdr_trans,
             @lv_hdr_remark,
             @lv_hdr_vendor,
             @lv_hdr_vndaddr ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.


    SELECT SINGLE *
      FROM zdb_rgp_nrgp
      WHERE name = @im_gatetype
      INTO @DATA(ls_name).

    lv_formtype = ls_name-id.


    zicl_com_9002=>get_address(
      EXPORTING
        im_plant        = im_plant
      IMPORTING
        ex_address_data = lwa_plant_addr
    ).

    IF lwa_plant_addr-addressline1 IS NOT INITIAL.
      lv_plant_addr = lwa_plant_addr-addressline1.
    ENDIF.
    IF lwa_plant_addr-addressline2 IS NOT INITIAL.
      lv_plant_addr = lv_plant_addr && |, | && lwa_plant_addr-addressline2.
    ENDIF.
    IF lwa_plant_addr-addressline3 IS NOT INITIAL.
      lv_plant_addr = lv_plant_addr && |, | && lwa_plant_addr-addressline3.
    ENDIF.
    IF lwa_plant_addr-addressline4 IS NOT INITIAL.
      lv_plant_addr = lv_plant_addr && |, | && lwa_plant_addr-addressline4.
    ENDIF.
    IF lwa_plant_addr-addressline5 IS NOT INITIAL.
      lv_plant_addr = lv_plant_addr && |, | && lwa_plant_addr-addressline5.
    ENDIF.

    IF lv_plant_name IS INITIAL.
      SELECT SINGLE PlantName
        FROM i_plant
        WHERE Plant = @im_plant
        INTO @lv_plant_name.
      IF sy-subrc <> 0.
        lv_plant_name = im_plant.
      ENDIF.
    ENDIF.

    IF lv_hdr_gateindt IS NOT INITIAL.
      lv_gatein_datetime =
          |{ lv_hdr_gateindt+6(2) }-|
       && |{ lv_hdr_gateindt+4(2) }-|
       && |{ lv_hdr_gateindt(4) }|.
    ENDIF.





    REPLACE ALL OCCURRENCES OF '&' IN lv_plant_addr WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN lv_plant_addr WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN lv_plant_addr WITH '&gt;'.

    REPLACE ALL OCCURRENCES OF '&' IN lv_plant_name  WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN lv_plant_name  WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN lv_plant_name  WITH '&gt;'.


    REPLACE ALL OCCURRENCES OF '&' IN lv_hdr_remark WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN lv_hdr_remark WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN lv_hdr_remark WITH '&gt;'.

    REPLACE ALL OCCURRENCES OF '°' IN lv_hdr_remark WITH '&#176;'.
    REPLACE ALL OCCURRENCES OF 'µ' IN lv_hdr_remark WITH '&#181;'.
    REPLACE ALL OCCURRENCES OF '²' IN lv_hdr_remark  WITH '&#178;'.  " <--- FIX FOR THIS ERROR
    REPLACE ALL OCCURRENCES OF '³' IN lv_hdr_remark  WITH '&#179;'.  " <--- Preventative


    lv_date = |{ lv_hdr_gateindt+6(2) }-{ lv_hdr_gateindt+4(2) }-{ lv_hdr_gateindt(4) }|.


    SELECT *
      FROM ZI_GATEENTRY_itm_R
      WHERE Zgate = @im_gate
*      ORDER BY Posnr ASCENDING
      INTO TABLE @DATA(lt_items).

    SORT lt_items BY Zeile ASCENDING.

    CLEAR: lv_rows_p1, lv_rows_p2, lv_srno.

    LOOP AT lt_items INTO DATA(ls_item).
      lv_srno = lv_srno + 1.
      CLEAR lv_row.

      " -- Material description (XML-escaped)
      DATA(lv_matdesc) = ls_item-Maktx.
      REPLACE ALL OCCURRENCES OF '&' IN lv_matdesc WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '<' IN lv_matdesc WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '>' IN lv_matdesc WITH '&gt;'.
      " ADDED: Sanitize Special Characters in Item Description
      REPLACE ALL OCCURRENCES OF '°' IN lv_matdesc WITH '&#176;'.
      REPLACE ALL OCCURRENCES OF 'µ' IN lv_matdesc WITH '&#181;'.
      REPLACE ALL OCCURRENCES OF '²' IN lv_matdesc WITH '&#178;'.  " <--- FIX FOR THIS ERROR
      REPLACE ALL OCCURRENCES OF '³' IN lv_matdesc WITH '&#179;'.  " <--- Preventative

      " -- Item remark (XML-escaped)
      DATA(lv_remark_itm) = |{ ls_item-Remarks }|.
      REPLACE ALL OCCURRENCES OF '&' IN lv_remark_itm WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '<' IN lv_remark_itm WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '>' IN lv_remark_itm WITH '&gt;'.
      " ADDED: Sanitize Special Characters in Item Remarks
      REPLACE ALL OCCURRENCES OF '°' IN lv_remark_itm WITH '&#176;'.
      REPLACE ALL OCCURRENCES OF 'µ' IN lv_remark_itm WITH '&#181;'.
      REPLACE ALL OCCURRENCES OF '²' IN lv_remark_itm WITH '&#178;'.  " <--- FIX FOR THIS ERROR
      REPLACE ALL OCCURRENCES OF '³' IN lv_remark_itm WITH '&#179;'.  " <--- Preventative

      " -- Return date formatted
      DATA(lv_ret_date) = |{ ls_item-ReturnDate+6(2) }-{ ls_item-ReturnDate+4(2) }-{ ls_item-ReturnDate(4) }|.
      IF ls_item-ReturnDate IS INITIAL.
        CLEAR lv_ret_date.
      ENDIF.





      lv_row = |<Row1>|                                    &&
               |<Sr.No>{ lv_srno }</Sr.No>|               &&
               |<DES>{ lv_matdesc }</DES>|                &&
               |<QUALITY>{ ls_item-Quantity }</QUALITY>|  &&
               |<UOM>{ ls_item-Uom }</UOM>|               &&
               |<VALUE>{ ls_item-Value }</VALUE>|         &&
               |<REMARKS>{ lv_remark_itm }</REMARKS>|     &&
               |</Row1>|.
      lv_rows_p1 = lv_rows_p1 && lv_row.



      CLEAR lv_row.
      lv_row = |<Row1>|                                  &&
               |<Cell1>{ lv_srno }</Cell1>|              &&
               |<Cell2>{ lv_matdesc }</Cell2>|           &&
               |<Cell3>{ ls_item-Quantity }</Cell3>|     &&
               |<Cell4>{ ls_item-Value }</Cell4>|        &&
               |<Cell5>{ lv_remark_itm }</Cell5>|        &&
               |</Row1>|.
      lv_rows_p2 = lv_rows_p2 && lv_row.

    ENDLOOP.




    IF im_gatetype = 'RGP'.


      lv_xml =
        |<?xml version="1.0" encoding="UTF-8"?>|        &&
        |<form1>|                                        &&
        "--- PAGE 1 ---"
        |<MainForm>|                                     &&
        |<addrsubform/>|                                 &&
        |<Headerform>|                                   &&
        |<vndname>{ lv_hdr_vendor }</vndname>|             &&
        |<vndaddr>{ lv_hdr_vndaddr }</vndaddr>|             &&
        |<Gateentryno>{ lv_hdr_zgate }</Gateentryno>|    &&
        |<Requisition></Requisition>|    &&
        |<Gateindate>{ lv_gatein_datetime }</Gateindate>| &&
        |<Plant>{ lv_plant_addr }</Plant>|               &&
        |<DATE>{ lv_date }</DATE>|                       &&
       |<Sr.no></Sr.no>|                                &&
        |<VEHICLE>{ lv_hdr_vehno }</VEHICLE>|           &&
        |</Headerform>|                                  &&
        |<tablesubform>|                                 &&
        |<Table1>|                                       &&
        |<HeaderRow/>|                                   &&
        lv_rows_p1                                       &&
        |</Table1>|                                      &&
        |<Remarks>{ lv_hdr_remark }</Remarks>|          &&
        |</tablesubform>|                                &&
        |<P1FOOTER/>|                                    &&
        |</MainForm>|                                    &&
        "--- PAGE 2 ---"
        |<Page2>|                                        &&
        |<Page2HSF/>|                                    &&
        |<P2HEADERFORM>|                                 &&
        |<Plant>{ lv_plant_addr }</Plant>|               &&
        |<From>{ lv_plant_name  }</From>|                    &&
        |<P2DATE>{ lv_date }</P2DATE>|                   &&
        |</P2HEADERFORM>|                                &&
        |<tablesubform2>|                                &&
        |<Table1>|                                       &&
        |<HeaderRow/>|                                   &&
        lv_rows_p2                                       &&
        |</Table1>|                                      &&
        |<MAINBELOWFORM>|                                &&
        |<LEFTSUB/>|                                     &&
        |<RIGHTSUB>|                                     &&
        |<NAMEADDRV>|                                    &&
        |<vndname>{ lv_hdr_vendor  }</vndname>|             &&
        |<vndaddr>{ lv_hdr_vndaddr }</vndaddr>|             &&
        |</NAMEADDRV>|                                   &&
        |<PRODATE>{ lv_date }</PRODATE>|                &&
        |</RIGHTSUB>|                                    &&
        |<RESVALUE>{ lv_hdr_remark }</RESVALUE>|        &&
        |</MAINBELOWFORM>|                               &&
        |</tablesubform2>|                               &&
        |<FOOTER/>|                                      &&
        |</Page2>|                                       &&
        |</form1>|.

    ELSEIF im_gatetype = 'NRGP'.


      lv_xml =
        |<?xml version="1.0" encoding="UTF-8"?>|        &&
        |<form1>|                                        &&
        "--- PAGE 1 ---"
        |<MainForm>|                                     &&
        |<addrsubform/>|                                 &&
        |<Headerform>|                                   &&
        |<vndname>{ lv_hdr_vendor }</vndname>|             &&
        |<vndaddr>{ lv_hdr_vndaddr }</vndaddr>|             &&
       |<Gateentryno>{ lv_hdr_zgate }</Gateentryno>|    &&
        |<Requisition></Requisition>|    &&
        |<Gateindate>{ lv_gatein_datetime }</Gateindate>| &&
        |<Plant>{ lv_plant_addr }</Plant>|               &&
        |<DATE>{ lv_date }</DATE>|                       &&
         |<Sr.no></Sr.no>|                                &&
        |<VEHICLE>{ lv_hdr_vehno }</VEHICLE>|           &&
        |</Headerform>|                                  &&
        |<tablesubform>|                                 &&
        |<Table1>|                                       &&
        |<HeaderRow/>|                                   &&
        lv_rows_p1                                       &&
        |</Table1>|                                      &&
        |<Remarks>{ lv_hdr_remark }</Remarks>|          &&
        |</tablesubform>|                                &&
        |<P1FOOTER/>|                                    &&
        |</MainForm>|                                    &&
        "--- PAGE 2 ---"
        |<Page2>|                                        &&
        |<Page2HSF/>|                                    &&
        |<P2HEADERFORM>|                                 &&
        |<From>{ lv_plant_name  }</From>|                    &&
        |<P2DATE>{ lv_date }</P2DATE>|                   &&
        |</P2HEADERFORM>|                                &&
        |<tablesubform2>|                                &&
        |<Table1>|                                       &&
        |<HeaderRow/>|                                   &&
        lv_rows_p2                                       &&
        |</Table1>|                                      &&
        |<MAINBELOWFORM>|                                &&
        |<LEFTSUB/>|                                     &&
        |<RIGHTSUB>|                                     &&
        |<NAMEADDRV>|                                    &&
        |<vndname>{ lv_hdr_vendor  }</vndname>|             &&
        |<vndaddr>{ lv_hdr_vndaddr }</vndaddr>|             &&
        |</NAMEADDRV>|                                   &&
        |<PRODATE>{ lv_date }</PRODATE>|                &&
        |</RIGHTSUB>|                                    &&
        |<RESVALUE>{ lv_hdr_remark }</RESVALUE>|        &&
        |</MAINBELOWFORM>|                               &&
        |</tablesubform2>|                               &&
        |<FOOTER/>|                                      &&
        |</Page2>|                                       &&
        |</form1>|.

    ENDIF.


    ex_base_64 = cl_web_http_utility=>encode_base64( unencoded = lv_xml ).

  ENDMETHOD.
ENDCLASS.
