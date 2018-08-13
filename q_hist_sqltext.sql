SELECT sql_id, sql_text FROM dba_hist_sqltext
WHERE sql_id IN (SELECT attr1 FROM dba_advisor_objects
WHERE execution_name = '&execution_name'
AND task_name = 'SYS_AUTO_SQL_TUNING_TASK'
AND type = 'SQL' AND bitand(attr7,64) <> 0 )
/
