WITH current_cap_amount AS 
    (SELECT endcoverage_capamountdet.parent_oid AS endcov_tid, endcoverage_capamountdet_amt.amount 
       FROM endcoverage_capamountdet 
            JOIN endcoverage_capamountdet_amt ON (endcoverage_capamountdet_amt.parent_oid = endcoverage_capamountdet.technicalidentifier) 
      WHERE SYSDATE BETWEEN endcoverage_capamountdet_amt.datefrom AND endcoverage_capamountdet_amt.dateto) 
SELECT 
    count(1)
FROM 
    ENDCOVERAGE EG 
        INNER JOIN ENDPOLICY E 
            ON E.TECHNICALIDENTIFIER = EG.ENDORSEDPOLICY_TID 
		INNER JOIN current_policies cp 
			ON E.technicalidentifier=cp.structural_end_tid 
        LEFT join CURRENCY C 
            on C.TECHNICALIDENTIFIER = E.POL_CURRENCY_TID 
        LEFT JOIN ENDCOVERAGE_RCDPAR EPAR 
            ON EPAR.PARENT_OID = EG.TECHNICALIDENTIFIER 
        LEFT JOIN ENDCOVERAGE_ICDPAR EIPAR 
            ON EIPAR.PARENT_OID=EG.TECHNICALIDENTIFIER 
        LEFT JOIN COVERAGEDEFINITION CD 
            ON (CD.TECHNICALIDENTIFIER = EG.RISKCOV_DEFINITION_TID OR CD.TECHNICALIDENTIFIER=EG.INVCOV_DEFINITION_TID) 
        LEFT JOIN COVERAGEDEFINITION_WORD CW 
            ON CW.PARENT_OID = CD.TechnicalIdentifier 
        LEFT JOIN ENDPOLICY_INDEXSETTING PIS 
            ON PIS.PARENT_OID=E.TECHNICALIDENTIFIER 
        LEFT OUTER JOIN current_cap_amount ON (current_cap_amount.endcov_tid = EG.technicalidentifier) 
where CW.LANG = 'FR';

