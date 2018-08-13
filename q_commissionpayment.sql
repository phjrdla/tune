WITH q0 as 
	(SELECT /*+ materialize */ 
	   DISTINCT (TT.EXTERNALID) 
	FROM BILL TT 
	INNER JOIN ENDPOLICY E ON E.TECHNICALIDENTIFIER = TT.Origin_TID 
	INNER JOIN current_policies cp ON E.technicalidentifier=cp.LAST_END_TID 
	LEFT JOIN CURRENCY C ON C.TECHNICALIDENTIFIER = TT.CURRENCY_TID  
	WHERE TT.BILLSTATUS_EID <> 'NEW' and TT.BILLSTATUS_EID <> 'SCHEDULED'  and TT.BILLSTATUS_EID <> 'ADJUSTED' and E.END_STATUS_EID='VALIDATED' 
	), finop_retro AS 
    (SELECT /*+ materialize */ 
	        finopacca.parent_oid, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_NAV' THEN finopacca.amount ELSE NULL END) AS retro_nav, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_UC' THEN finopacca.amount ELSE NULL END) AS retro_uc, 
            targetidentifier as retro_fund_number 
    FROM FINANCIALOP_ACCACTIONS finopacca 
    WHERE finopacca.amounttype_eid = 'RETRO' 
    AND finopacca.subamounttype_eid IN ('RETRO_NAV', 'RETRO_UC') 
    GROUP BY finopacca.parent_oid, targetidentifier), 
 FINOP_BASE_AND_RATES 
  AS 
    (SELECT /*+ materialize */
	        PARENT_OID, 
            AMOUNTTYPE_EID, 
            SUBAMOUNTTYPE_EID, 
            BASE_AMOUNT, 
            RATE 
       FROM (SELECT /*+ materialize */
	                FINANCIALOP_ACCACTIONS.PARENT_OID, 
                    FINANCIALOP_ACCACTIONS.AMOUNTTYPE_EID, 
                    CASE WHEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID NOT IN ('BASE_AMOUNT') THEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID ELSE NULL END 
                    AS SUBAMOUNTTYPE_EID, 
                    MAX (CASE FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID WHEN 'BASE_AMOUNT' THEN FINANCIALOP_ACCACTIONS.AMOUNT ELSE NULL END) OVER (PARTITION BY PARENT_OID) 
                    AS BASE_AMOUNT, 
                    CASE WHEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID NOT IN ('BASE_AMOUNT') THEN FINANCIALOP_ACCACTIONS.AMOUNT / 10000 ELSE NULL END 
                    AS RATE 
              FROM FINANCIALOP_ACCACTIONS 
              WHERE FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID IN ('BASE_AMOUNT', 'COMPANY_RATE', 'BROKER_RATE'))T 
      WHERE SUBAMOUNTTYPE_EID IS NOT NULL) 
SELECT /*+ parallel,star_transformation*/ * 
FROM ( SELECT 
	    endpol.pol_number AS IDPOLICE, 
	    endpol.end_number as NOPOLAVENANT, 
	    pro.code AS CODEPRODUIT, 
	    FINANCIALOP_PAYMTACT.amounttype_eid as TYPECOMMISSION, 
	    'BROKER' as SOUSTYPECOMMISSION, 
	    TP.externalid as IDAPP, 
	    case 
	    when bi.externalid  is not null then bi.externalid 
	    else null 
	    end AS IDQUITTANCE, 
	    currency.ISOCODE as DEVISE, 
	    compay.amount_value as MONTANT, 
	    finop_retro.retro_nav AS VNI, 
	    finop_retro.retro_uc AS UC, 
	    finop_retro.retro_fund_number as FONDS, 
	    fi.Fund_IsinCode as ISIN, 
	    brkpay.SENDINGDATE as DATEENVOIBANQUE, 
	    brkpay.RECONCILIATIONDATE AS DATECONFIRMEBANQUE, 
	    brkpay.RELEASEDATE AS DATELIBERATION, 
	    brkpay.STATUS_EID AS STATUT, 
	    endpolcf.poStrBulletinSous_VAL  as BULLETINSOUSCRIPTION, 
	    FINOP_BASE_AND_RATES.RATE AS TAUX 
	FROM commissionpayment compay 
	    LEFT OUTER JOIN BROKERPAYMENTINSTRUCTION brkpay ON (brkpay.technicalidentifier = compay.brokerpaymtinstr_tid) 
	    JOIN financialop finop ON (finop.technicalidentifier = compay.origin_tid) 
	    LEFT OUTER JOIN bill bi ON (bi.technicalidentifier = finop.bill_tid) 
	    LEFT OUTER JOIN endpolicy endpol ON (endpol.technicalidentifier = COALESCE (finop.endorsedpolicy_tid, bi.origin_tid)) 
		INNER JOIN current_policies cp ON endpol.technicalidentifier=cp.LAST_END_TID 
	    LEFT OUTER JOIN endcoverage endcov ON (endcov.endorsedpolicy_tid = endpol.technicalidentifier AND endcov.maincoverage = 'true') 
	    LEFT OUTER JOIN coveragedefinition covdef ON (endcov.technicalidentifier = endcov.invcov_definition_tid) 
	    LEFT OUTER JOIN ENDPOLICY_CF endpolcf ON (endpolcf.parent_oid = endpol.TECHNICALIDENTIFIER) 
	    LEFT OUTER JOIN product pro ON (pro.technicalidentifier = endpol.pol_product_tid) 
	    LEFT OUTER JOIN FINANCIALOP_PAYMTACT FINANCIALOP_PAYMTACT 
	        ON (FINANCIALOP_PAYMTACT.parent_oid = finop.technicalidentifier AND FINANCIALOP_PAYMTACT.subamounttype_eid <> 'COMPANY') 
	    LEFT JOIN CURRENCY currency ON compay.AMOUNT_CURRENCY_TID = CURRENCY.TECHNICALIDENTIFIER 
	    LEFT JOIN ENDPOLICY_CF ECF ON ECF.PARENT_OID = endpol.TECHNICALIDENTIFIER 
	    LEFT OUTER JOIN finop_retro ON (finop_retro.parent_oid = finop.technicalidentifier) 
	    LEFT OUTER JOIN FINOP_BASE_AND_RATES 
	         ON (FINOP_BASE_AND_RATES.PARENT_OID = finop.TECHNICALIDENTIFIER 
	             AND FINANCIALOP_PAYMTACT.AMOUNTTYPE_EID = FINOP_BASE_AND_RATES.AMOUNTTYPE_EID 
	             AND ((FINANCIALOP_PAYMTACT.SUBAMOUNTTYPE_EID = 'COMPANY' AND FINOP_BASE_AND_RATES.SUBAMOUNTTYPE_EID = 'COMPANY_RATE') 
	                  OR (FINANCIALOP_PAYMTACT.SUBAMOUNTTYPE_EID IN ('BROKER', 'MASTER_BROKER') AND FINOP_BASE_AND_RATES.SUBAMOUNTTYPE_EID = 'BROKER_RATE'))) 
	    LEFT OUTER JOIN financialinstrument fi ON finop_retro.retro_fund_number = fi.fund_number AND fi.STATUS_BID='5323:0' 
	    LEFT OUTER JOIN broker brk ON (brk.technicalidentifier = compay.distributionpartner_tid) 
	    INNER JOIN THIRDPARTY TP ON TP.TECHNICALIDENTIFIER = brk.ThirdParty_TID 
	    UNION ALL 
	SELECT 
	    endpol.pol_number AS IDPOLICE, 
	    endpol.end_number as NOPOLAVENANT, 
	    pro.code AS CODEPRODUIT, 
	    comdef.TYPE_EID as TYPECOMMISSION, 
	    'BROKER' as SOUSTYPECOMMISSION, 
	    TP.externalid as IDAPP, 
	    bi.externalid AS IDQUITTANCE, 
	    currency.ISOCODE as DEVISE, 
	    compay.amount_value AS MONTANT, 
	    NULL AS VNI, 
	    NULL AS UC, 
	    NULL AS FONDS, 
	    NULL AS ISIN, 
	    brkpay.SendingDate AS DATEENVOIBANQUE, 
	    brkpay.RECONCILIATIONDATE AS DATECONFIRMEBANQUE, 
	    brkpay.RELEASEDATE AS DATELIBERATION, 
	    brkpay.STATUS_EID AS STATUT, 
	    endpolcf.poStrBulletinSous_VAL as BULLETINSOUSCRIPTION, 
	     CASE 
	          WHEN endcovrcd.COSTRPRODUCTCODE_VAL LIKE '%PRFI%' OR endcovrcd.COSTRCURRENTPRODUCTCODE_VAL LIKE '%PRFI%' THEN 
	            COALESCE (endcovrcd.COPERCEBROKER_VAL, tecbasepar.TBPERCEBROKERPRFI_VAL) 
	          ELSE 
	            COALESCE (endcovrcd.COPERCEBROKER_VAL, tecbasepar.TBPERCEBROKER_VAL) 
	        END 
	     AS TAUX 
	FROM commissionpayment compay 
	    JOIN COMMISSIONDEFINITION comdef ON (comdef.technicalidentifier = compay.commissiondefinition_tid) 
	    JOIN BROKERPAYMENTINSTRUCTION brkpay ON (brkpay.technicalidentifier = compay.brokerpaymtinstr_tid) 
	    JOIN BILL bi ON (bi.technicalidentifier = compay.bill_tid) 
	    inner join BILL_BILLCOMPONENTS bbcomp on(bi.TECHNICALIDENTIFIER=bbcomp.PARENT_OID) 
	    inner join BILLCOMPONENT bcomp on(bbcomp.BILLCOMPONENT_TID=bcomp.TECHNICALIDENTIFIER) 
	    JOIN ENDPOLICY endpol ON (endpol.technicalidentifier = bi.origin_tid) 
		INNER JOIN current_policies cp ON endpol.technicalidentifier=cp.LAST_END_TID 
	    LEFT OUTER JOIN ENDPOLICY_CF endpolcf ON (endpolcf.parent_oid = endpol.technicalidentifier) 
	    INNER JOIN PRODUCT pro on(endpol.POL_PRODUCT_TID=pro.TECHNICALIDENTIFIER) 
	    LEFT OUTER JOIN BROKER brk ON (brk.technicalidentifier = compay.distributionpartner_tid) 
	    INNER JOIN THIRDPARTY TP ON TP.TECHNICALIDENTIFIER = brk.ThirdParty_TID 
	    LEFT OUTER JOIN THIRDPARTY_AFFINITYGROUPS thdaff ON (thdaff.parent_oid = brk.thirdparty_tid) 
	    LEFT OUTER JOIN COVERAGESLICE_COMMISSIONS covslicom ON (covslicom.commissionpayment_tid = compay.technicalidentifier) 
	    LEFT OUTER JOIN COVERAGESLICE covsli ON (covsli.technicalidentifier = covslicom.parent_oid) 
	    LEFT OUTER JOIN COVERAGESLICE_PREMIUMVALUES covsliprem ON (covsliprem.parent_oid = covsli.technicalidentifier) 
	    LEFT OUTER JOIN technicalbase tecbase ON (tecbase.technicalidentifier = covsli.technicalbase_tid) 
	    LEFT OUTER JOIN technicalbase_par tecbasepar ON (tecbasepar.parent_oid = tecbase.technicalidentifier) 
	    LEFT OUTER JOIN endcoverage endcov ON (endcov.coverage_sid = covsli.coverage_tid AND endcov.endorsedpolicy_tid = endpol.technicalidentifier) 
	    LEFT OUTER JOIN endcoverage_rcdpar endcovrcd ON (endcovrcd.parent_oid = endcov.technicalidentifier) 
	    LEFT JOIN CURRENCY currency ON compay.AMOUNT_CURRENCY_TID = CURRENCY.TECHNICALIDENTIFIER 
	    WHERE compay.STATUS_EID IN ('ALLOCATED', 'RELEASED') 
	UNION ALL 
	SELECT 
	    endpol.POL_NUMBER AS IDPOLICE, 
	    endpol.END_NUMBER AS NOPOLAVENANT, 
	    P.CODE AS CODEPRODUIT, 
	    comdef.TYPE_EID AS TYPECOMMISSION, 
	    'COMPANY' AS SOUSTYPECOMMISSION, 
	    TP.externalid as IDAPP, 
	    bill.externalid AS IDQUITTANCE, 
	    currency.ISOCODE as DEVISE, 
	    billcomponent.totalamount_value * 
	    (CASE 
	    WHEN endcoverage_rcdpar.costrproductcode_val LIKE '%PRFI%' OR endcoverage_rcdpar.costrcurrentproductcode_val LIKE '%PRFI%' 
	    THEN COALESCE (coverageslice_par.copercecardif_val, 
	    technicalbase_par.tbpercecardifprfi_val) 
	    ELSE COALESCE (coverageslice_par.copercecardif_val, 
	    technicalbase_par.tbpercecardif_val) 
	    END) AS MONTANT, 
	    NULL AS VNI, 
	    NULL AS UC, 
	    NULL AS FONDS, 
	    NULL AS ISIN, 
	    NULL AS DATEENVOIBANQUE, 
	    NULL AS DATECONFIRMEBANQUE, 
	    NULL AS DATELIBERATION, 
	    NULL AS STATUT, 
	    endpolcf.poStrBulletinSous_VAL as BULLETINSOUSCRIPTION, 
	    CASE 
	       WHEN ENDCOVERAGE_RCDPAR.COSTRPRODUCTCODE_VAL LIKE '%PRFI%' OR ENDCOVERAGE_RCDPAR.COSTRCURRENTPRODUCTCODE_VAL LIKE '%PRFI%' THEN 
	         COALESCE (coverageslice_par.copercecardif_val, TECHNICALBASE_PAR.tbpercecardifprfi_val) 
	       ELSE 
	         COALESCE (coverageslice_par.copercecardif_val, TECHNICALBASE_PAR.tbpercecardif_val) 
	     END 
	       AS TAUX 
	FROM commissionpayment 
	    JOIN commissiondefinition ON (commissiondefinition.technicalidentifier = commissionpayment.commissiondefinition_tid) 
	    JOIN brokerpaymentinstruction ON (brokerpaymentinstruction.technicalidentifier = commissionpayment.brokerpaymtinstr_tid) 
	    JOIN bill ON (bill.technicalidentifier = commissionpayment.bill_tid) 
	    JOIN bill_billcomponents ON (bill_billcomponents.parent_oid = bill.technicalidentifier) 
	    JOIN billcomponent ON (billcomponent.technicalidentifier = bill_billcomponents.billcomponent_tid) 
	    JOIN endpolicy endpol ON (endpol.technicalidentifier = bill.origin_tid) 
		INNER JOIN current_policies cp ON endpol.technicalidentifier=cp.LAST_END_TID 
	    LEFT OUTER JOIN  ENDPOLICY_CF endpolcf ON (endpolcf.parent_oid = endpol.TECHNICALIDENTIFIER) 
	    LEFT OUTER JOIN coverageslice_commissions ON (coverageslice_commissions.commissionpayment_tid = commissionpayment.technicalidentifier) 
	    LEFT OUTER JOIN coverageslice ON (coverageslice.technicalidentifier = coverageslice_commissions.parent_oid) 
	    LEFT OUTER JOIN coverageslice_par ON (coverageslice_par.parent_oid = coverageslice.technicalidentifier) 
	    LEFT OUTER JOIN coverageslice_premiumvalues ON (coverageslice_premiumvalues.parent_oid = coverageslice.technicalidentifier) 
	    LEFT OUTER JOIN technicalbase ON (technicalbase.technicalidentifier = coverageslice.technicalbase_tid) 
	    LEFT OUTER JOIN technicalbase_par ON (technicalbase_par.parent_oid = technicalbase.technicalidentifier) 
	    LEFT OUTER JOIN endcoverage ON (endcoverage.technicalidentifier = billcomponent.technicalidentifier) 
	    LEFT OUTER JOIN endcoverage_rcdpar ON (endcoverage_rcdpar.parent_oid = endcoverage.technicalidentifier) 
	    LEFT JOIN CURRENCY currency ON commissionpayment.AMOUNT_CURRENCY_TID = CURRENCY.TECHNICALIDENTIFIER 
	    LEFT JOIN PRODUCT P ON P.TECHNICALIDENTIFIER = endpol.POL_PRODUCT_TID 
	    JOIN COMMISSIONDEFINITION comdef ON (comdef.technicalidentifier = commissionpayment.commissiondefinition_tid) 
	    LEFT JOIN BROKER BK ON BK.technicalidentifier = CommissionPayment.distributionpartner_tid 
	    INNER JOIN THIRDPARTY TP ON TP.TECHNICALIDENTIFIER = BK.ThirdParty_TID 
	WHERE commissionpayment.STATUS_EID IN ('ALLOCATED', 'RELEASED') 
	UNION ALL 
	SELECT 
	    NULL AS IDPOLICE, 
	    NULL AS NOPOLAVENANT, 
	    NULL AS CODEPRODUIT, 
	    case 
	         when inst.MANUALCAUSE_EID='COM_ADVANCE' and inst.source_eid = 'MANUAL_INSTANCE_CREATION' then 'MAN' 
	     when inst.CAUSE_HID='6014:10007' and inst.source_eid = 'FROM_PARTNER_ACCOUNT' then 'MAN' 
	         else 'N/A' 
	    end  AS TYPECOMMISSION, 
	    case 
	         when inst.MANUALCAUSE_EID ='COM_EXC' and inst.source_eid = 'MANUAL_INSTANCE_CREATION' THEN 'EXC' 
	     when inst.source_eid = 'FROM_PARTNER_ACCOUNT' THEN inst.MANUALCAUSE_EID 
	         else 'N/A' 
	         end AS SOUSTYPECOMMISSION, 
	    TP.externalid as IDAPP, 
	    null AS IDQUITTANCE, 
	    inst.totalamount_currency_TID AS DEVISE, 
	    instaff.quantity AS MONTANT, 
	    NULL AS VNI, 
	    NULL AS UC, 
	    NULL AS FONDS, 
	    NULL AS ISIN, 
	    NULL AS DATEENVOIBANQUE, 
	    NULL AS DATECONFIRMEBANQUE, 
	    NULL AS DATELIBERATION, 
	    NULL AS STATUT, 
	    NULL AS BULLETINSOUSCRIPTION, 
	    NULL AS TAUX 
	FROM INSTANCE inst 
	     LEFT OUTER JOIN INSTANCE_AFFECTATIONS instaff ON (instaff.parent_oid = inst.technicalidentifier) 
	     JOIN BROKER brk ON (brk.technicalidentifier = instaff.distpartaff_distribpartnr_tid) 
	     INNER JOIN THIRDPARTY TP ON TP.TECHNICALIDENTIFIER = brk.ThirdParty_TID 
	WHERE inst.source_eid = 'MANUAL_INSTANCE_CREATION' OR inst.source_eid = 'FROM_PARTNER_ACCOUNT' 
	AND instaff.splitstatus_eid = 'PROCESSED') 
WHERE IDQUITTANCE in (SELECT q0.EXTERNALID from q0);

