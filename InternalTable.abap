" Definition-1: Types & Table Type & Internal Table
TYPES:
  BEGIN OF ty_auart,
    vbeln TYPE vbak-vbeln,
    posnr TYPE vbrp-posnr,
    auart TYPE vbak-auart,
  END OF ty_auart,

  tt_auart TYPE TABLE OF ty_auart WITH KEY vbeln.

DATA gs_auart TYPE ty_auart.
DATA gt_auart TYPE tt_auart.

" Definition-2: Types & Internal Table
TYPES:
  BEGIN OF ty_mdps,
    include TYPE mdps,
    check TYPE xfeld,
  END OF ty_mdps.

DATA lt_mdps TYPE TABLE OF ty_mdps.
DATA ls_mdps TYPE ty_mdps.

" Definition-3: Types & Internal Table
DATA  BEGIN OF ty_data OCCURS 0.
        INCLUDE TYPE zqmui_s_insplot.
DATA:   objnr TYPE qals-objnr,
      END OF ty_data.

DATA lt_data TYPE TABLE OF ty_data.

" Definition-3: Types & Internal Table w/ Performance
TYPES: BEGIN OF ty_charg,
         matnr LIKE marc-matnr,
         lgort TYPE mseg-lgort,
         charg TYPE mspr-charg,
         pspnr TYPE mspr-pspnr,
         post1 TYPE prps-post1,
       END OF ty_charg.

TYPES tt_charg TYPE STANDARD TABLE OF ty_charg
               WITH KEY matnr lgort
               WITH NON-UNIQUE SORTED KEY matnr_lgort COMPONENTS matnr lgort.

" Append
APPEND INITIAL LINE TO lt_sales_items ASSIGNING FIELD-SYMBOL(<fs_sales_item>).
<fs_sales_item>-itm_number = lv_posnr + 10.
<fs_sales_item>-material   = zsd_iade_giris-matnr.

lt_data = VALUE #( lgort = '1000'
                   ( mtart = 'AAAA' )
                   ( mtart = 'BBBB' ) ).

" Append Corresponding
DATA lt_data TYPE zsm_tt_0001.
APPEND LINES OF CORRESPONDING zsm_tt_0001( lt_itab ) TO lt_data.

" Append Corresponding II
DATA(lt_qmsm) = VALUE crmt_rfc_viqmsm_t( ( ) ).

APPEND CORRESPONDING #( ls_qmsm ) TO lt_qmsm.

" Append Structure To Table
APPEND ls_data TO lt_data.

" Append Value
APPEND VALUE #( material = '123' ) TO lt_sales_items.

" Append Value & Default Parameters
lt_data = VALUE #( refnumber = '1'
                   objectkey = 'X'
                   method    = 'CREATE'
                   ( objecttype = 'HEADER' )
                   ( objecttype = 'OPERATION' ) ).

" Append Value & Default Parameters w/ Table Type
DATA(lt_data) = VALUE tt_auart( ( vbeln  = '1' posnr = '10' auart = 'X' )
                                ( vbeln  = '2' posnr = '20' auart = 'Y' ) ).

" Append Value w/ Base  
lt_data[] = VALUE #( BASE lt_data[]
                     ( vbeln = '3' posnr = '10' auart = 'Z' ) ).

" Append w/ Return Message
DATA et_return TYPE bapiret2_t.
et_return = VALUE #( ( type = 'E' id = 'ZPP_000_MC' number = 001 ) ).

" Append w/ Value & Tables
er_deep_entity = VALUE #( returned = abap_true
                          header   = CORRESPONDING #( ls_entity-header[] )
                          items    = CORRESPONDING #( ls_entity-items[] ) ).

" Assign w/ Index
ASSIGN lt_itab[ 3 ] TO FIELD-SYMBOL(<fs_itab>).

" Assign w/ Key
ASSIGN lt_itab[ ernam = 'SERHAT'
                ersda = '20801212' ] TO FIELD-SYMBOL(<fs_itab>).

" Calculation
DATA(lv_amount) = REDUCE i( INIT i      TYPE labst
                            FOR ls_mard IN lt_mard
                            WHERE ( labst <> '' )
                            NEXT i = i + ls_mard-labst ).

DATA(lv_amount) = REDUCE bstmg( INIT lv_total TYPE bstmg
                                FOR  ls_data IN lt_data
                             WHERE ( mtart EQ 'A' AND werks EQ 'X' )
                                NEXT lv_total = lv_total + ls_data-total ).

DATA(lv_day) = REDUCE #( INIT lv_days = 0
                         FOR ls_days IN is_tcurr-days
                         WHERE ( periodat BETWEEN gv_first_date AND gv_last_date )
                         NEXT lv_days = lv_days + 1 ).

DATA(gv_value) = REDUCE char100( INIT lv_value TYPE char100
                                 FOR  ls_data  IN lt_data
                                 NEXT lv_value = COND char100( WHEN lv_value IS INITIAL
                                                               THEN condense( |{ ls_data-value ALPHA = OUT }| )
                                                               ELSE condense(
                                                                        |{ lv_value } / { ls_data-value ALPHA = OUT }| ) ) ).

" Corresponding w/ Mapping
lt_data = CORRESPONDING #( lo_data-values MAPPING matnr = material_no ).

" Delete All Data
DELETE FROM zsm_t_accounts.

" Delete w/ Condition
DELETE it_itab WHERE id = 'X' AND attribute = 'ABC'.

" Delete w/ Date
DELETE lt_qmsm WHERE peter > sy-datum.

DELETE lt_qmsm WHERE     peter = sy-datum
                     AND petur > sy-uzeit.

" Delete w/ Range Condition
DELETE it_itab WHERE id NOT IN ir_data.

" Filter
DATA(lt_filter_data) = FILTER #( it_itab IN tt_itab WHERE ( ernam = 'X' ) ).

" For
DATA(lt_mara) = VALUE tt_mara( FOR ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' )
                               ( matnr = ls_itab-matnr ernam = ls_itab-ernam ) ).

" For w/ Assignment
lt_data[] = VALUE #( FOR ls_list IN lt_list
                     ( matnr = ls_list-matnr
                       vhart = ls_list-vhart
                       ergew = COND #( WHEN ls_list-vhart = '1003'
                                       THEN CONV ergew( ls_list-veh_maxwgt - ls_list-veh_unlwgt )
                                       ELSE ls_list-ergew ) ) ).

" For w/ Base
lt_data = VALUE #( BASE lt_data
                       FOR ls_itab IN it_itab
                   LET ls_licence = _read_licence( iv_lictp = ls_itab-lictp
                                                   iv_licin = ls_itab-oih_licin_vf )
                   IN  ( VALUE #( BASE CORRESPONDING #( ls_itab )
                                  vbeln_vf = ls_licence-vbeln_vf
                                  zadklno  = ls_licence-zadklno ) ) ).

" For w/ Calculation
DATA(lt_sales_items_in) = VALUE cmp_t_sditm(
    FOR ls_out IN lt_out
    ( itm_number = COND #( WHEN gv_process = 'P'
                           THEN line_index( lt_out[ bonus_group = ls_out-bonus_group
                                                    spmon       = ls_out-spmon
                                                    vkorg       = ls_out-vkorg
                                                    kunnr       = ls_out-kunnr ] ) * 10
                           ELSE line_index( lt_out[ bonus_group = ls_out-bonus_group
                                                    spmon       = ls_out-spmon
                                                    vkorg       = ls_out-vkorg ] ) * 10 )
      material   = COND #( WHEN gv_process = 'C' OR gv_process = 'P'
                           THEN ls_ct0009-matnr
                           ELSE ls_out-matnr )
      short_text = COND #( WHEN gv_process = 'C' OR gv_process = 'P'
                           THEN |{ lv_bezei } - { lv_maktx }|
                           ELSE |{ lv_bezei } - { VALUE #( lt_makt[ matnr = ls_out-matnr ]-maktx OPTIONAL ) }| )
      plant      = ls_out-vkorg
      target_qty = '1'  ) ).

" For w/ Corresponding
DATA(lt_data) = VALUE #( FOR ls_product IN lt_products
                         ( matnr = ls_product-matnr ) ).

" For w/ Groups                                                                                     
DATA(lt_mara) = VALUE tt_mara( FOR GROUPS grp OF ls_itab IN it_itab WHERE ( ernam EQ 'SERHAT' ) GROUP BY ls_itab-ersda
                               ( ersda = grp ) ).

" For w/ Types
TYPES: BEGIN OF ty_licence,
         licin TYPE oihl-licin,
         lictp TYPE oihl-lictp,
         lctxt TYPE oihl-lctxt,
       END OF ty_licence.

DATA lt_licence_md  TYPE TABLE OF ty_licence.
DATA lt_licence_mdx TYPE TABLE OF ty_licence.

lt_licence_mdx = VALUE #( FOR ls_licence_md IN lt_licence_md WHERE ( licin IN ir_adk_lic_numbers )
                          ( CORRESPONDING #( ls_licence_md ) ) ).

" Insert
INSERT VALUE #( id = '1' value= 'X' ) INTO TABLE lt_data.

" Insert w/ Index
INSERT VALUE #( kunnr = ''
                name1 = '' ) INTO et_altmusteriset INDEX 1.

" Line Index
DATA(lv_index) = line_index( gt_table[ vbeln = '0060000001'] ).

" Line Index - Example
IF et_entityset IS NOT INITIAL.
  DATA(lv_index_bank) = line_index( et_entityset[ header = 'Bank' ] ).
  DATA(lv_index_tax)  = line_index( et_entityset[ header = 'Tax' ] ).

  IF lv_index_tax IS NOT INITIAL.
    DATA(ls_tax) = VALUE #( et_entityset[ header = 'Tax' ] OPTIONAL ).

    DELETE et_entityset INDEX lv_index_tax.

    IF lv_index_bank IS NOT INITIAL.
      INSERT ls_tax INTO et_entityset INDEX lv_index_bank + 1.
    ELSE.
      INSERT ls_tax INTO et_entityset INDEX 1.
    ENDIF.
  ENDIF.
ENDIF.

" Loop w/ Reference
LOOP AT lt_order REFERENCE INTO DATA(lr_order).
  CASE lr_order->property.
    WHEN 'OrderNo'.
      lr_order->property = 'ORDER_NO'.
  ENDCASE.
ENDLOOP.

" Loop w/ Group
TYPES: BEGIN OF lty_invoice_material,
         file_no   TYPE zsm_e_file_no,
         materials TYPE string,
       END OF lty_invoice_material.

DATA lt_invoice_materials TYPE TABLE OF lty_invoice_material.

LOOP AT lt_invoice_sum INTO DATA(ls_invoice_sum) GROUP BY ( file_no = ls_invoice_sum-file_no ) ASCENDING INTO DATA(ls_invoice_sum_group).
  APPEND VALUE #(
      file_no   = ls_invoice_sum_group-file_no
      materials = REDUCE string( INIT lv_string = ``
                                  FOR ls_invoice_sum_group_row IN GROUP ls_invoice_sum_group
                                 NEXT lv_string = COND #( WHEN lv_string IS INITIAL
                                                          THEN ls_invoice_sum_group_row-material
                                                          ELSE |{ lv_string }, { ls_invoice_sum_group_row-material }| ) ) )
         TO lt_invoice_materials.
ENDLOOP.

" Loop w/ Group II
LOOP AT lt_data INTO DATA(ls_data)
     GROUP BY ( order_no   = ls_data-order_no
                order_type = ls_data-order_type
                size       = GROUP SIZE
                index      = GROUP INDEX )
     ASCENDING REFERENCE INTO DATA(ls_group).
ENDLOOP.

LOOP AT GROUP ls_group INTO DATA(ls_group_data).
ENDLOOP.

" Modify
MODIFY lt_data
       FROM VALUE #( notification_type = 'X'
                     catalog_type      = 'ABC' )
       TRANSPORTING notification_type catalog_type
       WHERE material_no IS INITIAL.

" Update
UPDATE ls_data FROM lt_data.

" Reduce: Find Count To Duplicate Data
DATA(lv_lines) = REDUCE i( INIT x = 0 FOR wa_deger IN tt_deger WHERE ( deger EQ 'R' ) NEXT x = x + 1 ).

" Reference 
DATA(lr_ref) = REF #( lt_itab[ ernam = 'SERHAT'
                               ersda = '20801212' ] ).
WRITE lr_ref->matnr.

" Read Table - I
READ TABLE it_key INTO ls_key WITH KEY name = 'X' index 1 TRANSPORTING name.
IF sy-subrc = 0.
  DATA(lv_value) = ls_key-value.
ENDIF.

" Read Table - II
READ TABLE it_key ASSIGNING FIELD-SYMBOL(<fs_key>) WITH KEY name = 'X' index 1 TRANSPORTING name.
IF sy-subrc = 0.
  <fs_key>-value = abap_true.
ENDIF.

" Read Table - III
READ TABLE it_key TRANSPORTING NO FIELDS WITH KEY material = ls_data-material BINARY SEARCH.
IF sy-subrc <> 0.
  MESSAGE e001(zsm) WITH ls_data-material INTO DATA(lv_dummy).
ENDIF.

" Read Table - IV
IF line_exists( gt_auart[ vbeln = itab-vbeln ] ).
  data(lv_auart)= gt_auart[ vbeln = itab-vbeln ]-auart.
ENDIF.

" Read Table - V
ls_data = CORRESPONDING #( lt_data[ name = 'X' ] ).

" Read Table - VI
ls_data = VALUE #( lt_data[ 1 ] OPTIONAL ).

" SORT & DELETE DUPLICATE DATA
SORT lt_data BY name.
DELETE ADJACENT DUPLICATES FROM lt_data COMPARING name.

" Table Records Countf
DATA(lv_records_count) = lines( gt_table ).
