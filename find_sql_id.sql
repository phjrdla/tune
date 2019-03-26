rem find sql_id for a specific sql statement
set autotrace off
set lines 240
set trimspool on
column sql_text format a80 wrap

select sql_id
      ,plan_hash_value
	  ,exact_matching_signature
	  ,sql_plan_baseline
	  ,sql_text 
from v$sql 
where sql_text like '%&sqlstmt%';