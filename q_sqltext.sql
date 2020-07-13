--> Purpose:    Script to display the SQL text  for a specific SQL_ID. 
-->             It returns the SQL_TEXT.
--> Parameters: sql_id
--> To Run:     @sqltext.sql sql_id 
--> Example:    @sqltext.sql 27b3qfm5x89xn
--> 
--> Copyright 2019@dbaparadise.com


set echo off
set define '&'
set verify off
define _sql_id=&1

set verify off 
set feedback off 
set linesize 200 
set heading on 
set termout on

col sql_text format a100 word_wrapped

select  inst_id, sql_text "SQL TEXT"
from gv$sqltext 
where sql_id = '&_sql_id'
order by piece;


/* Sample output

   INST_ID SQL TEXT
---------- ----------------------------------------------------------------
         1 select count(*) from dual

*/