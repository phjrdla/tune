set lines 250
set pages 500
set trimspool on
set long 10000

select * 
  from table ( dbms_xplan.display_cursor('&sql_id',0) )
/
