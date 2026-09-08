@EndUserText.label: 'RGP Names'
define abstract entity ZABS_RGP_NAMES

{
  @Consumption.valueHelpDefinition: [{
    entity : { name: 'ZC_RGP_NAMES', element: 'id' }
  }]
  @UI.textArrangement: #TEXT_ONLY
  GATETYPE : abap.char( 10 );

}
