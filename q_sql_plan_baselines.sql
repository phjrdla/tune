set lines 300
set pages 1000
set long 1000000
column sql_handle format a30
column plan_name format a42
column sql_text format a100 wrap

rem where sql_handle = 'SQL_ea7d155a1b387d74';

spool q_sql_plan_baselines.lst;
  select sql_handle, plan_name, sql_text, enabled, accepted, fixed, executions, elapsed_time
    from dba_sql_plan_baselines;
spool off;
