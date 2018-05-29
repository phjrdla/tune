set echo on
set timing on
execute dbms_stats.gather_schema_stats(user, degree=>DBMS_STATS.DEFAULT_DEGREE, cascade=>DBMS_STATS.AUTO_CASCADE, options=>'GATHER', no_invalidate=>False );