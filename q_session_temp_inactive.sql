set linesize 220
set trimspool on
set pages 0

SELECT b.tablespace,b.segfile#,b.segblk#,b.blocks,a.sid,a.serial#,
 a.username,a.osuser, a.status,
 'alter system kill session '||''''||to_char(a.sid)||','||to_char(a.serial#)||''';' kill_cmd
 FROM v$session a,v$sort_usage b
 WHERE a.saddr = b.session_addr
   and a.status = 'INACTIVE'
   and b.tablespace = 'TEMP2'
/
