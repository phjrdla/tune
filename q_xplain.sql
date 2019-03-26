set pagesize 500
set lines 200

spool plan.txt
select *
 from table ( dbms_xplan.display('plan_table',null,'ALLSTATS LAST +PEEKED_BINDS –ROWS'));
spool off