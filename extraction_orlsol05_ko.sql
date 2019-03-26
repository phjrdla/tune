SET colsep ,
SET pagesize 0
SET trimspool ON
SET linesize 200
set timing on
set autotrace on
set echo on


spool extraction_orlsol05.csv
alter session set current_schema=SQLODSUSE
/
WITH  
	                LE AS (SELECT /*+ materialize */ POL_NUMBER AS PN, MAX(END_NUMBER) AS EN  
	                FROM ENDPOLICY  
	                WHERE ODS$CURRENT_VERSION='Y' GROUP BY POL_NUMBER),  
	                CURRENT_POLICIES AS (  
	                SELECT /*+ materialize */ EP.POL_NUMBER , EP.END_STATUS_HID,EP.END_NUMBER, EP.POL_POLICY_SID, EP.TECHNICALIDENTIFIER AS LAST_END_TID, 
	                               COALESCE (EP.FULL_PREVIOUS_TID, EP.TECHNICALIDENTIFIER) AS STRUCTURAL_END_TID 
	                FROM ENDPOLICY EP  
	                INNER JOIN LE  
	                ON EP.POL_NUMBER = LE.PN AND EP.END_NUMBER = LE.EN  
	            ), 
	                 CURRENT_POLICIES2 as ( 
	                           select  /*+ materialize */ 
	                           E.POL_NUMBER, E.End_EffectiveDate, P.ProductFamily_EID as ProductFamily_BID , E.END_STATUS_HID,E.END_NUMBER, E.POL_POLICY_SID,E.Pol_Status_BID, STRUCTURAL_END_TID 
	                           from CURRENT_POLICIES CP 
	                           inner join  endpolicy E on CP.STRUCTURAL_END_TID = E.TECHNICALIDENTIFIER  
	                            LEFT JOIN Product P  
	                ON E.Pol_Product_TID = P.TechnicalIdentifier  
	                WHERE E.ODS$CURRENT_VERSION='Y' AND E.END_STATUS_HID='com.bsb.is.endorsement.structure.EndorsementStatus:3' 
	                AND (E.Pol_Status_BID IN ('5323:0', '5323:25', '5323:19', '5323:20')) 
	                OR (E.Pol_Status_BID IN ('5323:2', '5323:5', '5323:6', '5323:9', '5323:10', '5323:12', '5323:13', '5323:21', '5323:23', '5323:24') AND E.End_EffectiveDate > sysdate - interval '3' year OR E.End_EffectiveDate is null) 
	                           ), 
	            -- Apporteurs 
	             tblParent(DISTRIBUTIONPARTNER_TID, PARENTDISTRIBUTIONPARTNER_TID, DISTRPARTN_EXTERNALID, LVL, POL_NUMBER, EXTERNALID, End_EffectiveDate, ProductFamily_BID, Pol_Status_BID) AS  
	                    (  
	                    SELECT DISTRIBUTIONPARTNER_TID, PARENTDISTRIBUTIONPARTNER_TID, DISTRPARTN_EXTERNALID, LVL, E.POL_NUMBER, T.EXTERNALID, E.End_EffectiveDate, P.ProductFamily_EID as ProductFamily_BID, E.Pol_Status_BID  
	                        FROM DISTRIBUTIONNETWORK DN  
	                        INNER JOIN distributionnetwork_struct DNS ON DNS.PARENT_OID = DN.TECHNICALIDENTIFIER AND DN.ODS$CURRENT_VERSION = 'Y' and DNS.ODS$CURRENT_VERSION = 'Y'  
	                        INNER JOIN BROKER B ON B.TECHNICALIDENTIFIER = DNS.distributionpartner_tid AND B.ODS$CURRENT_VERSION = 'Y'  
	                        INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = B.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                        LEFT JOIN RoleToThirdParty RTP ON RTP.ThirdParty_TID = T.TECHNICALIDENTIFIER AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                        LEFT JOIN RoleToRoleTarget RT ON RT.Role_TID = RTP.Role_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                        LEFT JOIN ENDPOLICY E ON E.TECHNICALIDENTIFIER = RT.Role_Target_TID AND E.ODS$CURRENT_VERSION = 'Y'  
	                   LEFT JOIN Product P ON E.Pol_Product_TID = P.TECHNICALIDENTIFIER AND E.ODS$CURRENT_VERSION = 'Y'  
	                        INNER JOIN CURRENT_POLICIES2 CP ON CP.STRUCTURAL_END_TID = E.TECHNICALIDENTIFIER  
	                        UNION ALL  
	                        SELECT previous_level.DISTRIBUTIONPARTNER_TID, previous_level.PARENTDISTRIBUTIONPARTNER_TID, previous_level.DISTRPARTN_EXTERNALID, previous_level.LVL, current_level.POL_NUMBER, thirdparty.externalid, current_level.End_EffectiveDate, current_level.ProductFamily_BID, current_level.Pol_Status_BID  
	                        FROM distributionnetwork_struct previous_level  
	                        JOIN tblParent current_level ON previous_level.DISTRIBUTIONPARTNER_TID = current_level.PARENTDISTRIBUTIONPARTNER_TID  
	                         LEFT OUTER JOIN distributionnetwork_conv  
	                            ON (distributionnetwork_conv.parent_oid = previous_level.technicalidentifier  
	                                AND previous_level.category_bid = distributionnetwork_conv.brokercategory_bid) AND distributionnetwork_conv.ODS$CURRENT_VERSION = 'Y'  
	                          LEFT OUTER JOIN BROKER  
	                            ON (broker.technicalidentifier = previous_level.distributionpartner_tid) AND BROKER.ODS$CURRENT_VERSION = 'Y'  
	                          LEFT OUTER JOIN THIRDPARTY  
	                            ON (THIRDPARTY.technicalidentifier = BROKER.thirdparty_tid) AND THIRDPARTY.ODS$CURRENT_VERSION = 'Y'  
	                         WHERE previous_level.ODS$CURRENT_VERSION = 'Y'  
	                    )  
	                    CYCLE PARENTDISTRIBUTIONPARTNER_TID SET cycle TO 1 DEFAULT 0  
	                    SELECT DISTINCT  
	                    tblParent.EXTERNALID,  
	                    tblParent.POL_NUMBER,  
	                    tblParent.End_EffectiveDate,  
	                    CONCAT('AP',tblParent.lvl) AS CODE,  
	                    tblParent.ProductFamily_BID,  
	                    tblParent.Plkol_Status_BID 
	                    FROM tblParent  
	                    WHERE tblParent.POL_NUMBER IS NOT NULL  
	            UNION 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                CONCAT('CO',RTP.ROLEORDER) AS CODE,  
	                 CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:39'  
	            UNION 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'CST' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:67'  
	            UNION 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'LR' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:83'  
	            UNION 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'HAD' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:82'  
	            UNION 
	                -- Beneficiaires 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'BF' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:58'  
	            UNION 
	                -- Payer 
	            SELECT 
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'PA' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP    
	                INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN RoleToThirdParty RTP ON RTP.Role_TID = RT.Role_TID AND RTP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	                WHERE RTP.ROLEORDER IS NOT NULL and  
	                RTP.RoleType_BID  = '5152:77'  
	            UNION 
	                -- Beneficiaires 
	            SELECT  
	                    T1.EXTERNALID,  
	                    CP.POL_NUMBER,  
	                 CP.End_EffectiveDate,  
	                    CONCAt('BE', row_number() over(partition by CP.POL_NUMBER order by T1.EXTERNALID )) AS CODE, --Vérifier si on peut pas remplacer par roleorder 
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                    FROM CURRENT_POLICIES2 CP  
	                    INNER JOIN RoleToRoleTarget RT ON RT.Role_Target_TID = CP.STRUCTURAL_END_TID AND RT.ODS$CURRENT_VERSION='Y'  
	                    INNER JOIN RoleToThirdParty RTP ON (RTP.Role_TID = RT.Role_TID  AND RTP.ODS$CURRENT_VERSION='Y'  AND RTP.roletype_bid = '5152:39'  /* HOLD */) 
	                    --INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = RTP.ThirdParty_TID  AND T.ODS$CURRENT_VERSION='Y'  
	                    INNER JOIN Links L ON (L.origin_tid = RTP.thirdparty_tid AND L.destinationdescriptor_bid = '5112:164'  /* ECOBEN */ AND L.ODS$CURRENT_VERSION='Y' ) 
	                    INNER JOIN THIRDPARTY T1 ON T1.TECHNICALIDENTIFIER = L.DESTINATION_TID  AND T1.ODS$CURRENT_VERSION='Y'  
	                    WHERE L.OriginDescriptor_BID IS NOT NULL -- AND L.OriginDescriptor_BID = '5112:164'         
	            UNION 
	            -- Assures 
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'AS1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.lifeAssured1_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,   
	                CP.End_EffectiveDate,  
	                'AS2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.lifeAssured2_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,   
	                CP.End_EffectiveDate,  
	                'AS3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.prTieLifeAssured3_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,   
	                CP.End_EffectiveDate,  
	                'AS4' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.prTieLifeAssured4_TID AND T.ODS$CURRENT_VERSION = 'Y' UNION 
	            -- Cessionnaires 
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'CS1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit1_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'CS2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit2_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'CS3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit3_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION 
	            -- Mandataires 
	            SELECT DISTINCT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MD1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio1_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT DISTINCT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MD2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio2_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT DISTINCT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MD3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio3_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION 
	            -- Mandataires Tiers 
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MT1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireInfo1_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MT2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireInfo2_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION  
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'MT3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP  
	                INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireInfo3_TID AND T.ODS$CURRENT_VERSION = 'Y'  
	            UNION 
	            -- Enfants 
	            SELECT  
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'EN1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.PRTHIBENEFICIARYCHILD_TID AND T.ODS$CURRENT_VERSION = 'Y' 
	            UNION 
	            -- Mandataires Arbitrages 
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'MI1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.PoThiSwitchAllowed_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- Proxy 1
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'MD1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio1_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- Proxy 2
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'MD2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio1_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- Proxy 3
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'MD3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiMandataireProcuratio1_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- Assuré 3
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'AS3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_PRODUCTPAR EPR ON EPR.PARENT_OID = CP.STRUCTURAL_END_TID AND EPR.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EPR.prTieLifeAssured3_TID AND T.ODS$CURRENT_VERSION = 'Y' 
	            UNION 
	            -- Assure 4
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'AS4' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_PRODUCTPAR EPR ON EPR.PARENT_OID = CP.STRUCTURAL_END_TID AND EPR.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EPR.prTieLifeAssured4_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- CC1
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'CC1' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit1_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- CS2
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'CS2' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit2_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- CS3
	             SELECT  
	                 T.EXTERNALID,  
	                 CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                 'CS3' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                 FROM CURRENT_POLICIES2 CP 
	                 INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID AND EC.ODS$CURRENT_VERSION = 'Y'  
	                 INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCessionDroit3_TID AND T.ODS$CURRENT_VERSION = 'Y'
	            UNION 
	            -- Conjoint 
	            SELECT  /*+ parallel(20) */
	                T.EXTERNALID,  
	                CP.POL_NUMBER,  
	                CP.End_EffectiveDate,  
	                'CJ' AS CODE,  
	                  CP.ProductFamily_BID,  
	               CP.Pol_Status_BID 
	                FROM CURRENT_POLICIES2 CP 
	                INNER JOIN ENDPOLICY_PRODUCTPAR EP ON EP.PARENT_OID = CP.STRUCTURAL_END_TID AND EP.ODS$CURRENT_VERSION = 'Y'  
	                INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EP.PRTHIRIDERFAMSPOUSE_TID AND T.ODS$CURRENT_VERSION = 'Y'
/					
spool off

