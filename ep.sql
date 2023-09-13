set echo on
spool &envr.&1._ep.txt
explain plan for
@&1
set termout off
@geteeplan
spool off
set echo off
set termout on