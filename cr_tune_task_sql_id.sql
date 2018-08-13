declare sts_task VARCHAR2(80);
BEGIN
  -- Create a tuning task, sort on elapsed time
  sts_task := DBMS_SQLTUNE.CREATE_TUNING_TASK( sql_id => '' ,time_limit => 7200,scope => DBMS_SQLTUNE.scope_comprehensive,task_name => 'Tune_f6h31x9wp2akv',description => 'tune query on orlsol08');
end;
/