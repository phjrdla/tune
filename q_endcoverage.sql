explain plan for
WITH current_cap_amount AS 
    (SELECT endcoverage_capamountdet.parent_oid AS endcov_tid, endcoverage_capamountdet_amt.amount 
       FROM endcoverage_capamountdet 
            JOIN endcoverage_capamountdet_amt ON (endcoverage_capamountdet_amt.parent_oid = endcoverage_capamountdet.technicalidentifier) 
      WHERE SYSDATE BETWEEN endcoverage_capamountdet_amt.datefrom AND endcoverage_capamountdet_amt.dateto) 
SELECT 
    EG.TECHNICALIDENTIFIER, 
    EPAR.COBOOACTIVEONSECONDDEATH_VAL, 
     coalesce(EPAR.PAYMENTPERIODICITY_EID,EIPAR.PAYMENTPERIODICITY_EID) as PERIODICITE, 
    EG.RISKCOV_OPTIONID AS OPTIONID, 
    EPAR.coPerPremiumPercentage_VAL AS POURCENTAGEPRIME, 
    case 
        when COALESCE(EPAR.PREMIUMTYPE_EID, EIPAR.PREMIUMTYPE_EID) = 'REGULPREM'  
        then COALESCE (EPAR.PAYMENTDURATION_VAL, EIPAR.PAYMENTDURATION_VAL) 
        else 0 
    end as DUREEPAYMENT, 
    case 
       when COALESCE(EPAR.PREMIUMTYPE_EID, EIPAR.PREMIUMTYPE_EID) = 'REGULPREM' 
       then COALESCE(EG.InvCov_ExpPremAmt_Value, 0) 
       else 0 
    end as PRIMEPERIODIQUE, 
    0 AS PRIMEPERIODIQUEANNUELLE,  
    case 
        when PIS.INDEXATIONTYPE_EID = 'NONE' 
            OR PIS.INDEXATIONTYPE_HID IS NULL 
        then 'false' 
        else 'true' 
    end as INDEXEE, 
    case 
        when COALESCE(EPAR.PREMIUMTYPE_EID, EIPAR.PREMIUMTYPE_EID) = 'UNIQUEPREM' 
        then COALESCE(EG.InvCov_ExpPremAmt_Value, 0) 
        else 0 
    end as PRIMEUNIQUE, 
    CD.IDENTIFIER as CODEGARANTIE, 
     case 
        when  CD.IDENTIFIER like 'VER_DEATH_RESERVE%'  or CD.IDENTIFIER='VER_LIFE_TERM_UCPP' then 'true' 
        else 'false' 
    end as MASQUER, 
    EG.COVEREDPERIODENDDATE, 
    COALESCE(EG.INVCOV_PAYMENTENDDATE,EG.RISKCOV_PAYMENTENDDATE) as RISKCOV_PAYMENTENDDATE, 
    C.ISOCODE, 
    EG.MAINCOVERAGE, 
    Coalesce(EPAR.coDecDeathCapital_val * EPAR.coDecRatioLife_val, EPAR.coDecLifeCapital_val, 0) as CAPITAL, 
    case 
        when cd.identifier IN ('AGI_DEATH_FORFAIT','RSK_DEATHACC_CAP','AGI_DEATH_COMP_FLOOR','RSK_UCPP_DEATHACC_CAP','AGI_DEATH_COMP_MAJ','RSK_DEATH_FAM','RSK_DEATHDISACC_CAP') THEN epar.ref_capital_val 
        when cd.identifier LIKE '%SRD%' THEN current_cap_amount.amount 
        when epar.codecdeathcapital_val IS NOT NULL THEN epar.codecdeathcapital_val 
        else 0 
    end as CAPITALDECES, 
    Coalesce(EPAR.coRefCapital_VAL, EPAR.CODECWAIVEDCAPITAL_VAL, 0) as CAPITALTERME, 
    E.POL_NUMBER, 
    CW.TEXT, 
    EPAR.COPERPREMIUMPERCENTAGE_VAL AS POURCENTAGEPRIME, 
    EPAR.COINTPREDURATION_VAL 
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

