spool &envr.&1..res.txt
@pars
set termout off
@&1
spool off
set termout on
prompt Finished...
@getllplan &1.
rollback;