5dwwz70hx2sga      3074207202               1,2660E+19                                select sql_id    ,plan_hash_value    ,exact_matching_signature    ,sql_plan_b
                                                                                      aseline    ,sql_text from v$sql where sql_text like '%select /*+woindex */ * fro
                                                                                      m mytab where GENERATED%'


SQL> select /*+woindex */ * from mytab where GENERATED='FOR';

aucune ligne sÚlectionnÚe

SQL> SELECT * FROM TABLE(dbms_xplan.display_cursor('5dwwz70hx2sga'));

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------
SQL_ID  5dwwz70hx2sga, child number 0
-------------------------------------
select sql_id       ,plan_hash_value    ,exact_matching_signature
,sql_plan_baseline    ,sql_text from v$sql where sql_text like '%select
/*+woindex */ * from mytab where GENERATED%'

Plan hash value: 3074207202

---------------------------------------------------------------------------
| Id  | Operation        | Name              | Rows  | Bytes | Cost (%CPU)|
---------------------------------------------------------------------------

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------
|   0 | SELECT STATEMENT |                   |       |       |     1 (100)|
|*  1 |  FIXED TABLE FULL| X$KGLCURSOR_CHILD |     1 |   566 |     0   (0)|
---------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(("KGLNAOBJ" IS NOT NULL AND "KGLNAOBJ" LIKE '%select
              /*+woindex */ * from mytab where GENERATED%' AND
              "INST_ID"=USERENV('INSTANCE')))


22 lignes sÚlectionnÚes.

SQL> select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR';

aucune ligne sÚlectionnÚe

SQL> @find_sql_id
Entrez une valeur pour sqlstmt : select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED
ancien   7 : where sql_text like '%&sqlstmt%'
nouveau   7 : where sql_text like '%select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED%'

SQL_ID        PLAN_HASH_VALUE EXACT_MATCHING_SIGNATURE SQL_PLAN_BASELINE              SQL_TEXT
------------- --------------- ------------------------ ------------------------------ --------------------------------------------------------------------------------
5851umshmw0mv      3472527870               5,9203E+18                                select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'
4kjbs9mazwna3      3074207202               9,3466E+17                                select sql_id    ,plan_hash_value    ,exact_matching_signature    ,sql_plan_b
                                                                                      aseline    ,sql_text from v$sql where sql_text like '%select /*+index(mytab_idx2
                                                                                       mytab) */ * from mytab where GENERATED%'


SQL> SELECT * FROM TABLE(dbms_xplan.display_cursor('5851umshmw0mv'));

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------
SQL_ID  5851umshmw0mv, child number 0
-------------------------------------
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'

Plan hash value: 3472527870

--------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            |       |       |   329 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| MYTAB      | 15772 |  1740K|   329   (0)| 00:00:01 |

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------
|*  2 |   INDEX RANGE SCAN                  | MYTAB_IDX2 | 15772 |       |    29   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("GENERATED"='FOR')


19 lignes sÚlectionnÚes.

SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5851umshmw0mv', plan_hash_value => 3472527870);

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL> select sql_text, sql_handle, plan_name, enabled, accepted from dba_sql_plan_baselines;

SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7cefa91fe                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddada00620d                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddacefa91fe                                                                                           YES NO


SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => SQL_50969e88fdd635aa);
BEGIN :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => SQL_50969e88fdd635aa); END;

                                                                                                                             *
ERREUR Ó la ligne 1 :
ORA-06550: Ligne 1, colonne 126 :
PLS-00201: identifier 'SQL_50969E88FDD635AA' must be declared
ORA-06550: Ligne 1, colonne 7 :
PL/SQL: Statement ignored


SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => 'SQL_50969e88fdd635aa');

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL> select sql_text, sql_handle, plan_name, enabled, accepted from dba_sql_plan_baselines;

SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7cefa91fe                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddada00620d                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddacefa91fe                                                                                           YES NO


SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddab73cade2                                                                                           YES YES


SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => 'SQL_5229297eca7bb2c7');

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL> select sql_text, sql_handle, plan_name, enabled, accepted from dba_sql_plan_baselines;

SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7cefa91fe                                                                                           YES YES

select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7b73cade2                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddada00620d                                                                                           YES YES


SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddacefa91fe                                                                                           YES NO

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddab73cade2                                                                                           YES YES


SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => 'SQL_5229297eca7bb2c7');

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL> select sql_text, sql_handle, plan_name, enabled, accepted from dba_sql_plan_baselines;

SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7cefa91fe                                                                                           YES YES

select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7b73cade2                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddada00620d                                                                                           YES YES


SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddacefa91fe                                                                                           YES NO

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddab73cade2                                                                                           YES YES


SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5dwwz70hx2sga', plan_hash_value =>3074207202 , sql_handle => 'SQL_50969e88fdd635aa');

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL>

dbms_spm.load_plans_from_cursor_cache(sql_id => ‘<hinted_sqlid>’,plan_hash_value=><hinted_plan_value>,sql_handle=>'<sql handle of original query>’)

SQL> exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => '5851umshmw0mv', plan_hash_value => 3472527870 , sql_handle => 'SQL_50969e88fdd635aa');

ProcÚdure PL/SQL terminÚe avec succÞs.

SQL> select sql_text, sql_handle, plan_name, enabled, accepted from dba_sql_plan_baselines;

SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7cefa91fe                                                                                           YES YES

select /*+index(mytab_idx2 mytab) */ * from mytab where GENERATED='FOR'          SQL_5229297eca7bb2c7
SQL_PLAN_54a99gv57rcq7b73cade2                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddada00620d                                                                                           YES YES


SQL_TEXT                                                                         SQL_HANDLE
-------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------
---------
PLAN_NAME                                                                                                                ENA ACC
-------------------------------------------------------------------------------------------------------------------------------- --- ---
select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddacefa91fe                                                                                           YES YES

select /*+woindex */ * from mytab where GENERATED='FOR'                          SQL_50969e88fdd635aa
SQL_PLAN_515nyj3yxcddab73cade2                                                                                           YES YES


SQL> set autotrace on
SQL> select /*+woindex */ * from mytab where GENERATED='FOR';

aucune ligne sÚlectionnÚe


Plan d'exÚcution
----------------------------------------------------------
Plan hash value: 3472527870

--------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            | 15772 |  1740K|   329   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| MYTAB      | 15772 |  1740K|   329   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | MYTAB_IDX2 | 15772 |       |    29   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("GENERATED"='FOR')

Note
-----
   - SQL plan baseline "SQL_PLAN_515nyj3yxcddacefa91fe" used for this statement


Statistiques
----------------------------------------------------------
         17  recursive calls
         13  db block gets
         18  consistent gets
          0  physical reads
       3344  redo size
       1582  bytes sent via SQL*Net to client
        541  bytes received via SQL*Net from client
          1  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          0  rows processed

SQL>