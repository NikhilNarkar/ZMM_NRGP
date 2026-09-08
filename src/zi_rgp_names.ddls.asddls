@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for rgp names'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_RGP_NAMES as select from zdb_rgp_nrgp
{
    key id ,
    name 
}
