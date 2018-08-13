explain plan for
SELECT DISTINCT (TT.EXTERNALID) 
	FROM BILL TT 
	INNER JOIN ENDPOLICY E ON E.TECHNICALIDENTIFIER = TT.Origin_TID 
	INNER JOIN current_policies cp ON E.technicalidentifier=cp.LAST_END_TID 
	LEFT JOIN CURRENCY C ON C.TECHNICALIDENTIFIER = TT.CURRENCY_TID  
	WHERE TT.BILLSTATUS_EID <> 'NEW' and TT.BILLSTATUS_EID <> 'SCHEDULED'  and TT.BILLSTATUS_EID <> 'ADJUSTED' and E.END_STATUS_EID='VALIDATED' 
/

explain plan for
SELECT finopacca.parent_oid, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_NAV' THEN finopacca.amount ELSE NULL END) AS retro_nav, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_UC' THEN finopacca.amount ELSE NULL END) AS retro_uc, 
            targetidentifier as retro_fund_number 
    FROM FINANCIALOP_ACCACTIONS finopacca 
    WHERE finopacca.amounttype_eid = 'RETRO' 
    AND finopacca.subamounttype_eid IN ('RETRO_NAV', 'RETRO_UC') 
    GROUP BY finopacca.parent_oid, targetidentifier
/