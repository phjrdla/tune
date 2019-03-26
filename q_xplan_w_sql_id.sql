set lines 500
set pages 5000

spool plan.out
select *
 from table ( dbms_xplan.display_cursor('6tjbr689ff8js',1,'ALLSTATS LAST +PEEKED_BINDS –ROWS'));
 
 spool off;