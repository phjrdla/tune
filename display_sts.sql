set long 1000000
set lines 1000
set pages 50
set trimspool on
break on sql_id

COLUMN SQL_TEXT        FORMAT a140 wrap   
COLUMN SCH             FORMAT a10
column "COST_K"        format 999,999
COLUMN "CPU_SEC"       format 9,999,999,999
COLUMN "ELAPSED_SEC"   FORMAT 999,999,999
column EXECUTIONS      format 999,999,999
column ROWS_PROCESSED  format 9,999,999,999
column "BUFFER_GETS_K" format 999,999

spool display_sts.out
SELECT SQL_ID, PARSING_SCHEMA_NAME AS "SCH",  
       executions,
       optimizer_cost/1000 "COST_K",
       cpu_time/1000000 AS "CPU_SEC",
       ELAPSED_TIME/1000000 AS "ELAPSED_SEC", 
       BUFFER_GETS/1000 "BUFFER_GETS_K",
       rows_processed,
       SQL_TEXT
FROM   TABLE( DBMS_SQLTUNE.SELECT_SQLSET( 'STS26' ) );
spool off