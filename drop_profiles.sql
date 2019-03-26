rem select 'exec dbms_sqltune.drop_sql_profile ( name=> '||''''||name||''');' 
select 'exec dbms_sqltune.drop_sql_profile ( name=> '||''''||name||''');'
from  DBA_SQL_PROFILES;

