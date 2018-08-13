set timing on
set echo on
set autotrace on
select  /*+ STAR_TRANSFORMATION */ 
		distinct cp.oid commission_oid, bpi.oid bpi_oid, masterdp.oid master_oid, mov.oid movement_oid, masterdpsubpos.oid master_subpos, anamov.oid anamov_oid, anapos.oid anapos_oid, masterdpacc.oid master_account
		from commission_payment cp
		join broker_payment_instruction bpi on bpi.oid = cp.payment_instruction_oid
		join distribution_partner dp on dp.oid = cp.distribution_partner_oid
		join account dpacc on dpacc.oid = dp.distrib_part_account_oid
		join network_structure ns on ns.broker_oid = dp.oid
		join distribution_network dn on dn.oid = ns.network_oid and dn.end_validity is null
		join network_structure masterns on masterns.network_oid = dn.oid and masterns.node_level = 0
		join distribution_partner masterdp on masterdp.oid = masterns.broker_oid
		join account masterdpacc on masterdpacc.oid = masterdp.distrib_part_account_oid
		join position masterdppos on masterdppos.account_oid = masterdpacc.oid and masterdppos.fininst_oid = cp.currency_oid
		join sub_position masterdpsubpos on masterdpsubpos.position_oid = masterdppos.oid
		join commercial_agreement ca on ca.id = (case when ns.custom_agreement is not null then ns.custom_agreement else dn.commercial_agreement end)
		join investment_commission_pay icp on icp.oid = cp.oid
		join fstore_pay_action fspa on fspa.oid = icp.fee_payment_action_oid
		join fee_store_action fsa on fsa.oid = fspa.oid
		join amount_type amtype on amtype.codeid = fspa.sub_amount_type_codeid
		join fee_amount fam on fam.oid = fsa.fee_amount_oid
		join fee_amt_to_fee_amt_origin fatfo on fatfo.fee_amount_oid = fam.oid
		join financial_operation finop on finop.oid = fatfo.fee_amount_origin_oid
		join policy pol on pol.policy_number = fsa.policy_number
		join fee_definition fd on fd.identifier = fsa.fee_definition_identifier
		join global_operation go on go.global_op_startable_oid = finop.oid
		join client_order co on co.global_operation_oid = go.oid
		join accounting_transaction atr on atr.accountable_oid = co.oid
		left outer join movement mov on mov.accounting_transaction_oid = atr.oid and (mov.amount = cp.nominal_amount or mov.amount - 100 = cp.nominal_amount)
		left outer join sub_position sp on mov.sub_position_oid = sp.oid 
		left outer join position p on sp.position_oid = p.oid
		left outer join account posacc on posacc.oid = p.account_oid 
		left outer join analytic_movement anamov on anamov.movement_oid = mov.oid
		left outer join analytic_position anapos on anapos.oid = anamov.analytic_position_oid
		where ca.name = 'StandardTete'
		and amtype.external_id = 'BROKER'
		and ns.node_level > 0
		and (posacc.oid is null or posacc.oid = dpacc.oid)
		and (p.fininst_oid is null or p.fininst_oid = cp.currency_oid)
		and (anapos.currency_oid is null or anapos.currency_oid = cp.currency_oid)
		and exists (select broker_movement.oid from movement broker_movement where broker_movement.sub_amount_type_codeid = 10469 and broker_movement.accounting_transaction_oid = atr.oid)
		fetch first 1000000 rows only
		;