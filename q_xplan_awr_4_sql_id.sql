select * from table(dbms_xplan.display_awr('&1', null, null, 'ALLSTATS +PEEKED_BINDS'));

 
