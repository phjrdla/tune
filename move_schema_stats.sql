exec DBMS_STATS.CREATE_STAT_TABLE('BIP','PROD_STATSTABLE','USERS');

rem exec dbms_stats.EXPORT_DATABASE_STATS('PROD_STATSTABLE','R12C1','BIP');

rem exec dbms_stats.import_database_stats(stattab=>'PROD_STATSTABLE', statown=> 'BIP', force=>true);

exec dbms_stats.import_schema_stats(ownname=>'CLV61IN1',stattab=>'CLV61PRD_STATSTABLE', statown=> 'CLV61IN1', force=>true);