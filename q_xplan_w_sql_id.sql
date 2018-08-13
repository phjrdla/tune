set lines 500
set pages 5000

spool plan.out
select *
 from table ( dbms_xplan.display_cursor('8qmqqfa3q0u5a',1,'+ALLSTATS'));
 spool off;