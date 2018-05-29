set pagesize 500
set lines 200

spool xplan_display.txt
select *
 from table ( dbms_xplan.display('plan_table',null,'TYPICAL +note'));
spool off