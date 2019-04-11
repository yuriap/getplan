set pages 9999
set lines 2000
set trimspool on
set termout off

column psqlid NEW_V SQLID noprint
select prev_sql_id psqlid from v$session where sid=(select sid from v$mystat where rownum=1);

column fn NEW_V filename noprint
select case when '&1.' is not null then '&1._sqlid_&SQLID.' else 'sqlid_&SQLID.' end fn from dual;

set verify off

column envr1 new_val envr2 noprint
select rtrim(decode('&envr.', '', 'na_','&envr.'),'_') envr1 from dual;

--========================================
spool &envr2._&filename..html
prompt Environment &envr2.
@_getplan_baseh

spool off

@_recurs_sql getplanh

set verify off
--========================================
spool &envr2._&filename..txt

@_getplan_base

spool off

@_recurs_sql getplan
--========================================

spool sqlid_&SQLID._active.html
@__sqlmon_active &SQLID.
spool off

undefine SQLID
undefine 1
set termout on
set verify on
