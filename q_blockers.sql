select /*+ ORDERED */
   blocker.sid blocker_sid
,  waiting.sid waiting_sid
,  TRUNC(waiting.ctime/60) min_waiting
,  waiting.request
from (select *
      from gv$lock
      where block != 0
      and type = 'TX') blocker
,    gv$lock            waiting
where waiting.type='TX' 
and waiting.block = 0
and waiting.id1 = blocker.id1