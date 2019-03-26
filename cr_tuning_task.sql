-- SQL Tuning Advisor
variable sts_task datatype varchar2(30)

declare
sts_task VARCHAR2(64);

BEGIN
  -- Create a tuning task, sort on elapsed time
  sts_task := DBMS_SQLTUNE.CREATE_TUNING_TASK( sqlset_name => 'STS25' 
                                              ,rank1 => 'ELAPSED_TIME'
                                              ,time_limit => 900
											  ,scope => DBMS_SQLTUNE.scope_comprehensive
                                              ,description => 'tune my workload ordered by elapsed time');
                                              
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK( task_name => sts_task );
  DBMS_output.put_line('sts_task is '||to_char(sts_task) );
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
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('TASK_9875'  , 'TEXT', 'TYPICAL', 'ALL')
FROM DUAL;

rem Scripts pour implémenter les recommandations
SELECT dbms_sqltune.script_tuning_task('TASK_9856', 'ALL') FROM dual;



SELECT TASK_NAME
FROM DBA_ADVISOR_LOG
order by task_name;
where task_name like 'TASK%' order by 1;

exec DBMS_SQLTUNE.DROP_TUNING_TASK('TASK_13098');