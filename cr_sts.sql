-- Drop the sqlset.
EXEC DBMS_SQLTUNE.DROP_SQLSET ('STS26');

-- Create SQL Tuning Set
BEGIN
DBMS_SQLTUNE.CREATE_SQLSET(
sqlset_name => 'STS26',
description => 'To investigate CLV61PRD long query');
END;
/

-- Select all statements in the shared SQL area.
DECLARE
cur sys_refcursor;
BEGIN
  OPEN cur FOR
    SELECT value(P)
      FROM table(DBMS_SQLTUNE.SELECT_CURSOR_CACHE('parsing_schema_name = ''CLV61PRD'' AND elapsed_time/1000000 > 900')) P;
    -- Process 
    DBMS_SQLTUNE.LOAD_SQLSET(sqlset_name => 'STS26', populate_cursor => cur);
  CLOSE cur;
END;
/
