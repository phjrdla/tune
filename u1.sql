set pages 100
set lines 250
explain plan for
update endorsed_fee
					set P3_VK_FE_BOO_INP_FEE_IN_BOO = 0,
					P3_XU_FE_DEC_CAL_DERO_TOTA_DEC = 0,
					P3_X2_FE_DEC_INP_DERO_COMP_DEC = 0,
					P3_UZ_FE_DEC_INP_DERO_BROK_DEC = 0
				where oid in (select 
					fee.oid 
					from endorsed_fee fee
					inner join endorsed_policy pol on pol.oid = fee.fee_owner_oid
					inner join endorsement endo on endo.endorsed_policy_oid = pol.oid
					inner join fee_target_to_fee_def target on target.oid = fee.fee_target_to_fee_def_oid
					inner join fee_definition fd on (fd.oid = target.fee_definition_oid and fd.IDENTIFIER = 'WEALTH_PREMIUM')
					where pol.policy_number = '000000100004430');
					
@q_xplan_display.sql			