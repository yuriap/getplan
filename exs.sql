set serveroutput off
@pars

set verify off
set feedback off
set timing off
column envr1 new_val envr2 noprint
select rtrim(decode('&envr.', '', 'na_','&envr.'),'_') envr1 from dual;
prompt Gathering statistics (snapshot 1)...
@statsnap2
prompt Starting execution of a target sql "&1." ...
set termout off
spool &envr.&1..res.txt
set feedback on
set timing on
@&1
spool off
set termout on
prompt Finished...
prompt Gathering statistics (snapshot 2)...
@_getllplan_stat &1.

undefine envr2