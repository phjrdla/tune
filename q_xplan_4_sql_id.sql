set lines 400
set pages 1000
set trimspool on
set long 10000000

-- select * 
--   from table ( dbms_xplan.display_cursor('&sql_id', null, 'ALLSTATS ALL ROWS ') );


spool plan.out
select * 
  from table ( dbms_xplan.display_cursor('&sql_id', null, 'ALLSTATS +peeked_binds') );
spool off