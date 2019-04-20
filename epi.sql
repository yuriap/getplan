set echo on
spool &envr.&1._ep.txt
explain plan for
@&1
set termout off
@geteeplan
spool off
set echo off
set termout on

set echo on
alter session set optimizer_use_invisible_indexes=true;
set echo off

set echo on
spool &envr.&1._ep_invisible_indx.txt
explain plan for
@&1
set termout off
@geteeplan
spool off
set echo off
set termout on

set echo on
alter session set optimizer_use_invisible_indexes=false;
set echo off