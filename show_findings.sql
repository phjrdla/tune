set long 10000000 wrap
set pages 500
set lines 400

spool findings_&&1..lst;
select dbms_sqltune.report_tuning_task('TASK_2750', 'TEXT', 'TYPICAL','ALL', &&1) 
from dual
/
spool off
exit
