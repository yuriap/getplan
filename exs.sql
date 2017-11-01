set serveroutput off
@pars
@statsnap2
set termout off
spool &envr.&1..res.txt
@&1
spool off
set termout on
prompt Finished...
@_getllplan_stat &1.
