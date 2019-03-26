set pages 100
set lines 250
set trimspool on

column "LAT" format A19
column sql_text format a80 wrap


select to_char(LAST_ACTIVE_TIME, 'HH24:MI:SS DD/MM/YYYY') "LAT"
      ,sql_id
      ,executions
      ,elapsed_time
      ,sql_text
from v$sql 
where sql_id in ( select distinct sql_id
                      from v$session
                      where schemaname in ( 'CLV61PRD','SQLODSUSE','SOLIFE_IT0_ODS_CURVER')
                  )
order by last_active_time
/
