set pages 0
set heading off
set feedback off
set linesize 200
set trimspool on

spool drop_sql_plan_baseline.tmp
select distinct 'drop_result := dbms_spm.drop_sql_plan_baseline(sql_handle => '||''''||sql_handle||''');'
  from dba_sql_plan_baselines
  order by 1;
spool off
