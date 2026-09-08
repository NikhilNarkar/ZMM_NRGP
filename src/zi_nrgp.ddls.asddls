@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'NRGP Gate Pass : Interface Root View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
@ObjectModel.resultSet.sizeCategory: #XS

define root view entity ZI_NRGP
  as select from ZI_GATEENTRY_hdr_R as a
  left outer join zdb_nrgp          as b
    on  a.Zgate = b.zgate
  association [0..1] to zita_nrgp   as _att
    on $projection.Zgate = _att.zgate
{
  key a.Zgate,
      a.Plant,
      a.Gateindt,
      a.Gateinout,
      a.Gateoutdt,
      a.Gateoutout,
      a.Type,
       a.Remark,
      b.base64_3,
      b.m_ind,
      b.gatetype,

//      // Attachment fields — same pattern as debit note
//      @Semantics.largeObject:{
//          mimeType:    'MimeType',
//          fileName:    'FileName',
//          contentDispositionPreference: #INLINE
//      }
      _att.attachment as Attachments,
      _att.mimetype   as MimeType,
      _att.filename   as FileName,

      // Association
      _att

}
