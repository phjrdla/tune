select inst_id inst
  , sid 
  , serial# 
  , username 
  , osuser 
  , machine  
  , program 
  , decode(lockwait,NULL,' ','L') as locks
  , status 
  , to_char(to_date(mod(last_call_et,86400), 'sssss'), 'hh24:mi:ss') "hh:mm:ss"
  , sql_id
  , seq#
  , event
  , decode(state,'WAITING','WAITING '||lpad(to_char(mod(SECONDS_IN_WAIT,86400),'99990'),6)
    ,'WAITED SHORT TIME','ON CPU','WAITED KNOWN TIME','ON CPU',state) state
  , substr(module,1,18) module
  ,'alter system kill session '''||to_char(sid)||','||to_char(serial#)||''';' "kill_cmd"
from GV$SESSION s
where type = 'USER'
and s.audsid != 0  -- 0 is for internal processes
and (status = 'ACTIVE' or SQL_HASH_VALUE <> 0 or s.lockwait is not null)
order by username;