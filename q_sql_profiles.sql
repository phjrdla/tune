set lines 200
set trimspool on
set pages 500

clear breaks
clear computes

break on name skip page

COLUMN category FORMAT a10
COLUMN sql_text FORMAT a100 wrap
column name format a30 wrap

spool sqk_profiles.out
SELECT NAME, CATEGORY, STATUS, SQL_TEXT
FROM   DBA_SQL_PROFILES;
spool off