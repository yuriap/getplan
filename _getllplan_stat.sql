set pages 9999
set lines 500
set trimspool on
set termout off

column psqlid NEW_V SQLID noprint
select prev_sql_id psqlid from v$session where sid=(select sid from v$mystat where rownum=1);

column fn NEW_V filename noprint
select case when '&1.' is not null then '&1._sqlid_&SQLID..txt' else 'sqlid_&SQLID..txt' end fn from dual;

@_tmp_sesstat_&envr2._&1..sql

set pages 9999
set lines 500
set trimspool on
set termout off

set verify off
--define SQLID=&1
spool &envr2._&filename

@_getplan_base
@__pq_state
@_recurs_sql

spool off

undefine SQLID
undefine 1
set termout on
set verify on
