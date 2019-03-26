
alter session set current_schema=solife_it0_ods_curver;

-- explain plan for
WITH last_payer_by_pol AS(
    SELECT *
    FROM
        (
            SELECT
                roletoroletarget.role_target_tid   AS policy_sid,
                rolepayer.technicalidentifier      AS payer_tid,
                ROW_NUMBER()OVER(
                    PARTITION BY roletoroletarget.role_target_tid
                    ORDER BY
                        coalesce(rolepayer.modification_datetime,rolepayer.creation_datetime)DESC
                )AS rn
            FROM
                roletoroletarget
                INNER JOIN rolepayer ON(rolepayer.technicalidentifier = roletoroletarget.role_tid)
        )
    WHERE
        rn = 1
)
SELECT /*+ noparallel */
    all_end_pol.pol_number,
    cr.classefondsinvesti,
    p.code,
    endpar.prstrproductline_val                  AS lignemetier,
    full_6601_end_pol.pol_status_eid             AS externalid,
    c.isocode,
    full_6601_end_pol.paymentmode_eid            AS value,
    full_6601_end_pol.pol_effectivedate,
    full_6601_end_pol.pol_termdate,
    CASE
        WHEN full_6601_end_pol.periodicity_eid = 'MON' THEN add_months(max_date.bill_date,1)
        WHEN full_6601_end_pol.periodicity_eid = 'QUA' THEN add_months(max_date.bill_date,3)
        WHEN full_6601_end_pol.periodicity_eid = 'SEM' THEN add_months(max_date.bill_date,6)
        WHEN full_6601_end_pol.periodicity_eid = 'ANN' THEN add_months(max_date.bill_date,12)
    END AS modifieddate,
    full_6601_end_pol.pol_countryoflaw_eid       AS fiscalite,
    endpar.duration_val,
    endpar.durationunit_eid                      AS uniteduree,
    ecf.postriddistributor_val,
    ecf.poboomandatintermediation_val,
    ecf.postrcircularletter_val,
    DECODE(full_6601_end_pol.pol_signeddate,NULL,'false','true')AS cpsignee,
    psd.datecpsignee                             AS datecpsignee,
    ecf.postrmodeenvcourrier_val,
    (
        SELECT
            eacc.iban
        FROM
            externalaccount eacc
        WHERE
            eacc.owner_tid = lpbp.payer_tid
            AND eacc.isdefault = 'true'
        FETCH FIRST ROW ONLY
    )AS iban,
    paystat.remind_status                        AS statutpayment,
    policy_eval.eval                             AS eval,
    ecf.postrbulletinsous_val,
    CASE
        WHEN full_6601_end_pol.pol_enddate BETWEEN current_date AND add_months(current_date,- 6)
             AND all_end_pol.pol_status_eid IN(
            'CANC',
            'CLAIMED',
            'CLOSE',
            'DEATH_CL',
            'INAC',
            'NOTPROC',
            'RENUNC',
            'SURREN',
            'TERM',
            'TRANSF'
        )THEN 'false'
        WHEN full_6601_end_pol.pol_enddate BETWEEN current_date AND add_months(current_date,- 6)
             AND all_end_pol.pol_status_eid IN(
            'SURREN'
        )THEN 'true'
        WHEN all_end_pol.pol_status_eid IN(
            'FORCE'
        )THEN 'true'
        ELSE 'false'
    END AS visibleexterieur,
    CASE
        WHEN ei.indexationtype_eid = 'FISCAL_GAIN' THEN 'true'
        ELSE 'false'
    END AS maximumdeductible,
    endpar.prstrproductcode_val                  AS oldcodeproduit,
    id.identifier                                AS strategieinvestissement,
    coalesce(ecf.postrcommerciallabel_val,(
        SELECT
            distributionnetwork_product.commercialname
        FROM
            distributionnetwork_struct,distributionnetwork,distributionnetwork_product
        WHERE
            distributionnetwork_struct.distributionpartner_tid = b.technicalidentifier
            AND distributionnetwork.technicalidentifier = distributionnetwork_struct.parent_oid
            AND distributionnetwork_product.parent_oid = distributionnetwork.technicalidentifier
            AND distributionnetwork_product.product_tid = p.technicalidentifier
        FETCH FIRST ROW ONLY
    ),p.name)AS libelleproduitlabellise,
    taxfwk.name                                  AS mandatfiscaltype,
    taxcalchist_par.tuboofiscalwithmandate_val   AS mandatfiscalvaleur
FROM
    current_policies cp
    INNER JOIN endpolicy all_end_pol ON cp.last_end_tid = all_end_pol.technicalidentifier
    INNER JOIN endpolicy full_6601_end_pol ON(full_6601_end_pol.technicalidentifier = cp.structural_end_tid)
    LEFT OUTER JOIN endpolicy_cf ecf ON(ecf.parent_oid = full_6601_end_pol.technicalidentifier)
    LEFT OUTER JOIN endpolicy_productpar endpar ON(endpar.parent_oid = full_6601_end_pol.technicalidentifier)
    LEFT OUTER JOIN product p ON(p.technicalidentifier = full_6601_end_pol.pol_product_tid)
    LEFT OUTER JOIN currency c ON c.technicalidentifier = full_6601_end_pol.pol_currency_tid
    LEFT OUTER JOIN last_payer_by_pol lpbp ON lpbp.policy_sid = cp.pol_policy_sid
    LEFT OUTER JOIN pol_sign_date psd ON psd.pol_number = cp.pol_number
    LEFT OUTER JOIN paystat ON cp.pol_policy_sid = paystat.policy_tid
    LEFT OUTER JOIN policy_eval ON cp.pol_number = policy_eval.idpolice
    LEFT OUTER JOIN endpolicy_indexsetting ei ON ei.parent_oid = full_6601_end_pol.technicalidentifier
    LEFT OUTER JOIN classesresultat cr ON cr.id_police = full_6601_end_pol.technicalidentifier
    LEFT OUTER JOIN endcoverage ON(endcoverage.endorsedpolicy_tid = cp.structural_end_tid
                                   AND invcov_investmentstrategy_tid IS NOT NULL)
    LEFT OUTER JOIN invstrat ON(endcoverage.invcov_investmentstrategy_tid = invstrat.technicalidentifier)
    LEFT OUTER JOIN invstratdef id ON(investstrategydefinition_tid = id.technicalidentifier)
    INNER JOIN roletoroletarget rt2 ON(rt2.role_target_tid = full_6601_end_pol.technicalidentifier)
    INNER JOIN broker b ON(b.technicalidentifier = rt2.role_tid)
    LEFT OUTER JOIN max_date ON cp.pol_policy_sid = max_date.tech_id_pol
    LEFT OUTER JOIN taxframework taxfwk ON full_6601_end_pol.taxframework_tid = taxfwk.technicalidentifier
    LEFT OUTER JOIN taxcalchist ON taxcalchist.owner_tid = full_6601_end_pol.technicalidentifier
    LEFT OUTER JOIN taxcalchist_par ON taxcalchist_par.parent_oid = taxcalchist.technicalidentifier
WHERE
    all_end_pol.end_internal_nbr IS NOT NULL
/
--set pagesize 500
--set lines 200

--spool plan.txt
--select *
-- from table ( dbms_xplan.display('plan_table',null,'ALLSTATS'));
--spool off