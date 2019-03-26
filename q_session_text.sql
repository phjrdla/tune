set lines 300
set pages 1000

column module format a20 trunc
column sql_text format a80 trunc
column osuser format a20 trunc
column machine format a30 trunc
column username format a20 trunc
column terminal format a12 trunc
column status format a8 trunc


SELECT sn.status, sn.sid, sn.serial#, S.MODULE, SQL_TEXT, SN.OSUSER, SN.MACHINE, SN.terminal, S.EXECUTIONS, U.USERNAME
      FROM SYS.V_$SQL S, SYS.ALL_USERS U, V$SESSION SN
     WHERE S.PARSING_USER_ID = U.USER_ID
       AND SN.sql_hash_value = S.hash_value
       AND SN.sql_address = S.address
       AND sn.status = 'ACTIVE'
       and sql_text like '%invcp.CID p0, invcp.OID p1,%'
     ORDER BY S.LAST_LOAD_TIME;