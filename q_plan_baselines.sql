set linesize 300
set pages 500
set long 1000000
column sql_handle format a20
column plan_name format a52
column sql_text format a100 wrap
select sql_handle, plan_name, sql_text, enabled, accepted, fixed 
from dba_sql_plan_baselines;
