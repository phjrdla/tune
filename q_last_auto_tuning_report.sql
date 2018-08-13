BEGIN
:l_report := DBMS_SQLTUNE.report_auto_tuning_task(
begin_exec => NULL,
end_exec => NULL,
type => DBMS_SQLTUNE.type_text,
level => DBMS_SQLTUNE.level_typical,
section => DBMS_SQLTUNE.section_all,
object_id => NULL,
result_limit => NULL
);
END;
/

SET LONG 1000000
PRINT :l_report