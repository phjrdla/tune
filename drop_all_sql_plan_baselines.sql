set lines 300
set pages 0
set feedback off
set trimspool on
set heading off

spool drop_all_sql_plan_baselines.cmd
select 'var drop_result number;' from dual;
select 'exec :drop_result := dbms_spm.drop_sql_plan_baseline( sql_handle => '''||sql_handle||''','||' plan_name => '''||plan_name||''');'
from dba_sql_plan_baselines;
spool off

