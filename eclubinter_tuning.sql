set timing on
set echo on
set serveroutput on

variable stmt_task VARCHAR2(64);

 -- Create a tuning task for a sql_id
exec  :stmt_task := DBMS_SQLTUNE.CREATE_TUNING_TASK( sql_id => 'ba9uxvnyqzn89',time_limit => 7200, scope => DBMS_SQLTUNE.scope_comprehensive, task_name=>'eclubinter');
                                               
select :stmt_task from dual;

exec DBMS_SQLTUNE.EXECUTE_TUNING_TASK( task_name => :stmt_task );

rem Résultats de la tache de Tuning avec recommendations
SET LONG 1000000
SET LONGCHUNKSIZE 100
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('eclubinter'  , 'TEXT', 'TYPICAL', 'ALL')
FROM DUAL;


exec DBMS_SQLTUNE.DROP_TUNING_TASK(:stmt_task);