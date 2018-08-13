
-- SQL Tuning Advisor
variable sts_task datatype varchar2(30);

set serveroutput on
declare
sts_task VARCHAR2(64);
BEGIN
  -- Create a tuning task, sort on elapsed time
  sts_task := DBMS_SQLTUNE.CREATE_TUNING_TASK( sql_id => '8q90sh07xrdf5' 
                                              ,time_limit => 7200
											  ,scope => DBMS_SQLTUNE.scope_comprehensive
                                              ,description => 'tune query on orlsol08');
                                              
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK( task_name => sts_task );
  dbms_Output.put_line(sts_task);
end;
/
-- Task name
print sts_task

select :sts_task from dual;

exit
SELECT TASK_NAME
FROM DBA_ADVISOR_LOG
where task_name like 'TASK%' order by 1;

rem Résultats de la tache de Tuning avec recommendations
SET LONG 10000000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(upper('TASK_6354')  , 'TEXT', 'TYPICAL', 'ALL')
FROM DUAL;

rem Scripts pour implémenter les recommandations
SELECT dbms_sqltune.script_tuning_task(upper('TASK_4908'), 'ALL') FROM dual;

SELECT TASK_NAME
FROM user_ADVISOR_LOG
where task_name like 'TASK%' order by 1;

exec DBMS_SQLTUNE.DROP_TUNING_TASK(upper('&task'));