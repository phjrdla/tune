set lines 250
set pages 1000
set serveroutput on
select *
from table(dbms_xplan.display_cursor (sql_id=>'fjjxubykbdtfx', format=>'+outline'));
