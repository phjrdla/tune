set lines 200
set trimspool on
column owner format a20 trunc
column job_name format a30 trunc
column "Elapsed" format a30 trunc
column "CPU" format a30 trunc

select owner, JOB_NAME
            , tO_char(ELAPSED_TIME) "Elapsed"
            , CPU_USED  "CPU"
from all_scheduler_running_jobs
order by job_name
/
