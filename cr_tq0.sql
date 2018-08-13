set timing on
create table tq0 as 
	(SELECT DISTINCT (TT.EXTERNALID) 
	FROM BILL TT 
	INNER JOIN ENDPOLICY E ON E.TECHNICALIDENTIFIER = TT.Origin_TID 
	INNER JOIN current_policies cp ON E.technicalidentifier=cp.LAST_END_TID 
	LEFT JOIN CURRENCY C ON C.TECHNICALIDENTIFIER = TT.CURRENCY_TID  
	WHERE TT.BILLSTATUS_EID <> 'NEW' and TT.BILLSTATUS_EID <> 'SCHEDULED'  and TT.BILLSTATUS_EID <> 'ADJUSTED' and E.END_STATUS_EID='VALIDATED' 
	), finop_retro AS 
    (SELECT finopacca.parent_oid, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_NAV' THEN finopacca.amount ELSE NULL END) AS retro_nav, 
            MAX (CASE finopacca.subamounttype_eid WHEN 'RETRO_UC' THEN finopacca.amount ELSE NULL END) AS retro_uc, 
            targetidentifier as retro_fund_number 
    FROM FINANCIALOP_ACCACTIONS finopacca 
    WHERE finopacca.amounttype_eid = 'RETRO' 
    AND finopacca.subamounttype_eid IN ('RETRO_NAV', 'RETRO_UC') 
    GROUP BY finopacca.parent_oid, targetidentifier), 
 FINOP_BASE_AND_RATES 
  AS 
    (SELECT PARENT_OID, 
            AMOUNTTYPE_EID, 
            SUBAMOUNTTYPE_EID, 
            BASE_AMOUNT, 
            RATE 
       FROM (SELECT FINANCIALOP_ACCACTIONS.PARENT_OID, 
                    FINANCIALOP_ACCACTIONS.AMOUNTTYPE_EID, 
                    CASE WHEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID NOT IN ('BASE_AMOUNT') THEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID ELSE NULL END 
                    AS SUBAMOUNTTYPE_EID, 
                    MAX (CASE FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID WHEN 'BASE_AMOUNT' THEN FINANCIALOP_ACCACTIONS.AMOUNT ELSE NULL END) OVER (PARTITION BY PARENT_OID) 
                    AS BASE_AMOUNT, 
                    CASE WHEN FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID NOT IN ('BASE_AMOUNT') THEN FINANCIALOP_ACCACTIONS.AMOUNT / 10000 ELSE NULL END 
                    AS RATE 
              FROM FINANCIALOP_ACCACTIONS 
              WHERE FINANCIALOP_ACCACTIONS.SUBAMOUNTTYPE_EID IN ('BASE_AMOUNT', 'COMPANY_RATE', 'BROKER_RATE'))T 
      WHERE SUBAMOUNTTYPE_EID IS NOT NULL) ;
