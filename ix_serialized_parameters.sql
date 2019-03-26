create index ix_serialized_parameters on fee_store_action_ctxt_params
(
extractValue(xmltype(serialized_parameters), '/map/entry[string=''feStrCommPaymLvl'']/string[2]/text()')
)
/
