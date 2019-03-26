begin
 dbms_stats.gather_schema_stats( USER, degree=>DBMS_STATS.DEFAULT_DEGREE, cascade=>DBMS_STATS.AUTO_CASCADE, options=>'GATHER', no_invalidate=>False, method_opt=>'FOR ALL COLUMNS SIZE SKEWONLY' );
end;