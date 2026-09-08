@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo:{
    typeName: 'Gate Out',
    typeNamePlural: 'Gate Out',
    title:{ type: #STANDARD, value: 'Zgate' } }

define root view entity ZC_NRGP
  as projection on ZI_NRGP
{
      @UI.facet: [
        {
          id:       'ZGATE',
          purpose:  #STANDARD,
          type:     #IDENTIFICATION_REFERENCE,
          label:    'Gate Entry',
          position: 10
        },
        {
          id:              'ATTACHMENT',
          purpose:         #STANDARD,
          type:            #FIELDGROUP_REFERENCE,
          targetQualifier: 'PDF',
          label:           'PDF Attachment',
          position:        20
        }
      ]

      @UI.lineItem:       [{ position: 10, label: 'Gate Out document No.' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
      @UI.identification: [{ position: 10, label: 'Material Document' }]
      @UI.selectionField: [{ position: 10 }]
      @EndUserText.label: 'Gate Out Document No.'
  key Zgate,

      @UI.lineItem:       [{ position: 20, label: 'Plant' }]
      @UI.identification: [{ position: 20, label: 'Plant' }]
      @UI.selectionField: [{ position: 20 }]
      Plant,

      @UI.lineItem:       [{ position: 30, label: 'gateindate' }]
      @UI.identification: [{ position: 30, label: 'gateindate' }]
      @UI.selectionField: [{ position: 30 }]
      @EndUserText.label: 'Gate In Date'
      @Consumption.filter            : { selectionType: #INTERVAL }
      Gateindt,

      @UI.lineItem:       [{ position: 40, label: 'Gate In Time' }]
      @UI.identification: [{ position: 40, label: 'Gate In Time' }]
      Gateinout,

      @UI.lineItem:       [{ position: 50, label: 'gateoutdate' }]
      @UI.identification: [{ position: 50, label: 'gateoutdate' }]
      @UI.selectionField: [{ position: 50 }]
      @EndUserText.label: 'Gate Out Date'
      @Consumption.filter            : { selectionType: #INTERVAL }
      Gateoutdt,

      @UI.lineItem:       [{ position: 60, label: 'Gate Out Time' }]
      @UI.identification: [{ position: 60, label: 'Gate Out Time' }]
      Gateoutout,

      @UI.lineItem:       [{ position: 70, label: 'Type' }]
      @UI.identification: [{ position: 70, label: 'Type' }]
      Type,
      base64_3,
      m_ind,

      @Consumption.valueHelpDefinition: [{
      entity: { name: 'ZC_RGP_NAMES', element: 'id' }
      }]
      @UI.hidden: true
      gatetype,

      @UI.fieldGroup: [{ qualifier: 'PDF', position: 10, label: 'PDF' }]
      @Semantics.largeObject: {
          mimeType:    'MimeType',
          fileName:    'FileName',
          contentDispositionPreference: #INLINE
      }

      Attachments,

      @UI.hidden: true
      @Semantics.mimeType: true
      MimeType,

      @UI.hidden: true
      FileName
}
