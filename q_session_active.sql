select sid
      ,username
	  ,command
	  ,state
	  ,status 
  from v$session
 where status = 'ACTIVE'
/
