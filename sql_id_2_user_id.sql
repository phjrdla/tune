set lines 200
set pages 10
column username format a30 trunc

select distinct h.user_id, u.username, h.sql_id, s.BEGIN_INTERVAL_TIME
from dba_hist_active_sess_history  h
    ,dba_users u
    ,dba_hist_snapshot s
where h.sql_id='58uykq0cbcvrm'
  and h.user_id = u.user_id
order by s.BEGIN_INTERVAL_TIME
/
select distinct username, sql_id
from v$session s
where s.sql_id='58uykq0cbcvrm'
/
