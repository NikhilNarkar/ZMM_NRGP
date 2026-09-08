@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for RGP Names'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZC_RGP_NAMES
  as select from ZI_RGP_NAMES
{

      @ObjectModel.text.element: ['name']
      @UI.textArrangement: #TEXT_ONLY
  key id,

      @Semantics.text: true
      name
}
