spool &envr.&1..res.txt
set echo on
alter session set optimizer_use_invisible_indexes=true;
set echo off
@pars
set termout off
@&1

set echo on
alter session set optimizer_use_invisible_indexes=false;
set echo off

spool off

set termout on
prompt Finished...
@getllplanh &1.
rollback;