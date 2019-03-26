set lines 200
set pagesize 100
set trimspool on

col LOCK_TYPE       format a10 trunc
col MODE_HELD       format a20 trunc
col MODE_REQUESTED  format a20 trunc
col BLOCKING_OTHERS format a20 trunc
col LOCK_ID1        format a20 trunc
col LOCK_ID2        format a20 trunc

select *
from dba_lock
order by lock_type
/
