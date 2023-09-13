spool &envr.&1..res.txt

set echo on
alter session set optimizer_use_invisible_indexes=true;
set echo off

@pars
set termout off
TIMING START SQL_TIMER
@&1
spool off
set termout on
prompt Finished.
TIMING STOP
prompt Gathering statistics...

set echo on
alter session set optimizer_use_invisible_indexes=false;
set echo off

@getllplanh &1.
rollback;