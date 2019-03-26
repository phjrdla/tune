/* 
sqltext.sql
Example @sqltext.sql 6rv5za4tfnjs8
Copyright dbaparadise.com
*/
 
set define '&'
set verify off
define sqlid=&1
 
col sql_text for a100 word_wrapped
col inst_id for 9
break on inst_id
set linesize 200
set pagesize 0
set trimspool on
 
select inst_id, sql_text 
from gv$sqltext 
where sql_id = '&sqlid'
order by inst_id,piece
/