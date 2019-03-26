rem 686,45628

EXEC DBMS_MONITOR.session_trace_enable(session_id =>&session_id, serial_num=>&serial_num, waits=>TRUE, binds=>TRUE);