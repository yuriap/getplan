spool &envr.&1..res.txt
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
rollback;