SELECT client_name, task_name
FROM   dba_autotask_task;

COLUMN parameter_name FORMAT A25
COLUMN parameter_value FORMAT a15

SELECT parameter_name, parameter_value
FROM   dba_advisor_parameters
WHERE  task_name = 'SYS_AUTO_SPM_EVOLVE_TASK'
AND    parameter_value != 'UNUSED'
ORDER BY parameter_name;

