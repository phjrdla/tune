/* Formatted on 3/20/2020 12:22:49 PM (QP5 v5.336) */
set lines 200
col username format a20 trunc
col osuser format a20 trunc
  SELECT S.sid || ',
         ' || S.serial# sid_serial,
         S.username,
         S.sql_id,
         S.osuser,
         P.spid,
         S.module,
         S.program,
         SUM (T.blocks) * TBS.block_size / 1024 / 1024     mb_used,
         T.tablespace,
         COUNT (*)  sort_ops
    FROM v$sort_usage   T,
         v$session      S,
         dba_tablespaces TBS,
         v$process      P
   WHERE     T.session_addr = S.saddr
         AND S.paddr = P.addr
         AND T.tablespace = TBS.tablespace_name
GROUP BY S.sid,
         S.serial#,
         S.username,
         S.sql_id,
         S.osuser,
         P.spid,
         S.module,
         S.program,
         TBS.block_size,
         T.tablespace
ORDER BY sid_serial;