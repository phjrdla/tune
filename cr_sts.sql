-- Drop the sqlset.
EXEC DBMS_SQLTUNE.DROP_SQLSET ('STS02');

-- Create SQL Tuning Set
BEGIN
DBMS_SQLTUNE.CREATE_SQLSET(
sqlset_name => 'STS02',
description => 'To investigate SOLIFE long query');
END;
/

-- Select all statements in the shared SQL area.
DECLARE
cur sys_refcursor;
BEGIN
  OPEN cur FOR
    SELECT value(P)
      FROM table(DBMS_SQLTUNE.SELECT_CURSOR_CACHE('parsing_schema_name <> ''SYS'' AND elapsed_time > 1000000000')) P;
    -- Process 
    DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => 'STS02', populate_cursor => cur);
  CLOSE cur;
END;
/
