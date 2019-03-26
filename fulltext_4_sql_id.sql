set long 10000000
set pages 0
column SQL_FULLTEXT format a300 wrap

-- column SQL_FULLTEXT format a300 wrap
select SQL_FULLTEXT
from v$sql
where sql_id = '&sql_id'
/
