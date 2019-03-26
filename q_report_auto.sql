set lines 400
set trimspool on
set pages 1000
set long 10000000

spool report_auto.out
SELECT DBMS_AUTO_SQLTUNE.REPORT_AUTO_TUNING_TASK FROM DUAL;
spool off