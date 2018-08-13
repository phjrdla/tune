explain plan for
SELECT CP.pol_number AS IDPOLICE, 
    REFERENCE, 
    RiskType_EID AS TYPERISK, 
    Type_EID AS TYPECLAUSE, 
    CASE 
        WHEN (RiskType_EID='DEATH_ALL_CAUSES' or RiskType_EID='LIFE_AT_TERM') AND (Type_EID='AUTO_BEN' OR Type_EID='MANUAL_BEN') THEN 'true' 
        ELSE 'false' 
    END 
    AS AFFICHE, 
    CASE 
        WHEN RiskType_EID like '%DEATH%' THEN 'true' 
        ELSE 'false' 
    END 
    AS ISDECES, 
    CASE 
       WHEN RiskType_EID not like '%DEATH%' THEN 'true' 
       ELSE 'false' 
    END 
    AS ISVIETERME, 
    TEXT AS TEXTECLAUSE 
    FROM CURRENT_POLICIES CP 
    LEFT JOIN ENDPOLICY_PCCLAUSES epc ON epc.Parent_OID = CP.STRUCTURAL_END_TID 
    LEFT JOIN clause ON clause.TECHNICALIDENTIFIER = epc.Clause_TID 
    LEFT JOIN Clause_ClauseTexts cct ON cct.Parent_OID = clause.technicalidentifier 
    LEFT JOIN clauseText ct ON ClauseText_TID = ct.technicalidentifier AND Locale_EID = 'FR';
