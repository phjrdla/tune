set lines 250
set pages 1000
set trimspool on

spool q_exec_plan_history.out;
select * from TABLE(dbms_xplan.display_awr('&1', null, null, 'ALL'))
/
spool off
