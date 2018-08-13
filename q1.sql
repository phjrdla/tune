set lines 200
set pages 100

explain plan for
select distinct p2.string_value 
				from endorsed_policy ep
				inner join endorsed_product_component epc on epc.policy_oid = ep.oid
				inner join abstract_product ap on ap.oid = epc.ABSTRACT_PRODUCT_OID
				join AOM_ENTITY ae on ae.oid = ap.aom_entity_oid
				join AOM_PROPERTY ap on ap.parent_entity_oid = ae.oid
				join AOM_ENTITY e2 on e2.oid =  ap.parent_entity_oid
				join AOM_PROPERTY p on p.parent_entity_oid = e2.oid
				join AOM_ENTITY e3 on e3.oid =  p.persistence_capable_value_oid
				join AOM_PROPERTY_TYPE pt on pt.parent_oid = e3.entity_type_oid and pt.name='Product Code'
				join AOM_PROPERTY p2 on p2.property_type_oid=pt.oid
				where ep.policy_number = '000000100004430';

@q_xplan_display.sql