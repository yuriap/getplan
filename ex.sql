spool &envr.&1..res.txt


exec DBMS_APPLICATION_INFO.SET_MODULE ( module_name => 'SQL*PLUS', action_name => 'Exec: &1.'); 

set timing off
@pars
prompt Started...
set termout off
set timing on
TIMING START SQL_TIMER

@&1

spool off
set termout on

prompt Finished.
TIMING STOP

prompt Gathering statistics...
@getllplanh &1.
set feedback on
rollback;