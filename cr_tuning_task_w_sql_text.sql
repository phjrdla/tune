-- SQL Tuning Advisor
variable sts_task datatype varchar2(80);

set serveroutput on
declare
sts_task VARCHAR2(80);
sql_stmt clob;
BEGIN
sql_stmt := '
WITH 
    LE AS (SELECT /*+ materialize */ POL_NUMBER AS PN, MAX(END_NUMBER) AS EN 
		FROM ENDPOLICY 
		WHERE END_STATUS_EID=''VALIDATED'' GROUP BY POL_NUMBER), 
    CURRENT_POLICIES_2 AS ( 
		SELECT /*+ materialize */ EP.POL_NUMBER, EP.END_STATUS_HID,EP.END_NUMBER, EP.POL_POLICY_SID, EP.TECHNICALIDENTIFIER AS LAST_END_TID, COALESCE (EP.FULL_PREVIOUS_TID, EP.TECHNICALIDENTIFIER) AS STRUCTURAL_END_TID 
		FROM ENDPOLICY EP 
		INNER JOIN LE ON EP.POL_NUMBER = LE.PN AND EP.END_NUMBER = LE.EN 
		INNER JOIN current_policies cp ON EP.technicalidentifier=cp.LAST_END_TID 
		WHERE EP.END_STATUS_EID=''VALIDATED''), 
	PART_COM AS (
		SELECT /*+ materialize */ T.EXTERNALID, 
		CP.POL_NUMBER, 
		''PC1'' AS CODE 
		FROM CURRENT_POLICIES_2 CP 
		INNER JOIN ENDPOLICY_CF EC ON EC.PARENT_OID = CP.STRUCTURAL_END_TID 
		INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = EC.poThiCommercialBrk_TID
		),
	tblParent(DISTRIBUTIONPARTNER_TID, PARENTDISTRIBUTIONPARTNER_TID, DISTRPARTN_EXTERNALID, LVL, POL_NUMBER, EXTERNALID) AS 
        ( 
        SELECT DISTRIBUTIONPARTNER_TID, PARENTDISTRIBUTIONPARTNER_TID, DISTRPARTN_EXTERNALID, LVL, E.POL_NUMBER, T.EXTERNALID 
            FROM DISTRIBUTIONNETWORK DN 
            INNER JOIN distributionnetwork_struct DNS ON DNS.PARENT_OID = DN.TECHNICALIDENTIFIER 
            INNER JOIN BROKER B ON B.TECHNICALIDENTIFIER = DNS.distributionpartner_tid 
            INNER JOIN THIRDPARTY T ON T.TECHNICALIDENTIFIER = B.ThirdParty_TID 
            LEFT JOIN RoleToThirdParty RTP ON RTP.ThirdParty_TID = T.TECHNICALIDENTIFIER 
            LEFT JOIN RoleToRoleTarget RT ON RT.Role_TID = RTP.Role_TID 
            LEFT JOIN ENDPOLICY E ON E.TECHNICALIDENTIFIER = RT.Role_Target_TID 
            INNER JOIN CURRENT_POLICIES_2 CP ON CP.STRUCTURAL_END_TID = E.TECHNICALIDENTIFIER 
		UNION ALL 
            SELECT previous_level.DISTRIBUTIONPARTNER_TID, previous_level.PARENTDISTRIBUTIONPARTNER_TID, previous_level.DISTRPARTN_EXTERNALID, previous_level.LVL, current_level.POL_NUMBER, thirdparty.externalid 
            FROM distributionnetwork_struct previous_level 
            JOIN tblParent current_level ON previous_level.DISTRIBUTIONPARTNER_TID = current_level.PARENTDISTRIBUTIONPARTNER_TID 
             LEFT OUTER JOIN distributionnetwork_conv 
                ON (distributionnetwork_conv.parent_oid = previous_level.technicalidentifier 
                    AND previous_level.category_bid = distributionnetwork_conv.brokercategory_bid) 
              LEFT OUTER JOIN BROKER 
                ON (broker.technicalidentifier = previous_level.distributionpartner_tid) 
              LEFT OUTER JOIN THIRDPARTY 
                ON (THIRDPARTY.technicalidentifier = BROKER.thirdparty_tid) 
        ) 
	CYCLE PARENTDISTRIBUTIONPARTNER_TID SET cycle TO 1 DEFAULT 0 
	SELECT DISTINCT 
	tblParent.EXTERNALID, 
	tblParent.POL_NUMBER, 
	CONCAT(''AP'',tblParent.lvl) AS CODE 
	FROM tblParent 
	WHERE tblParent.POL_NUMBER IS NOT NULL
	AND tblParent.POL_NUMBER in (
	Select POL_NUMBER from PART_COM)
';

  -- Create a tuning task, sort on elapsed time
  
  
  sts_task := DBMS_SQLTUNE.CREATE_TUNING_TASK( sql_text => sql_stmt 
                                              ,time_limit => 7200
											  ,scope => DBMS_SQLTUNE.scope_comprehensive
                                              ,description => 'tune query on orlsol00');
                                              
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK( task_name => sts_task );
  dbms_Output.put_line(sts_task);
end;
/
