set pages 9999
set lines 2000
set trimspool on
set termout off
set echo off
set feedback off

set verify off
define SQLID=&1
spool sqlid_&SQLID..html

set timing off
set define ~

set serveroutput on
@_getplan_baseh
/
set serveroutput off
set define &
set timing on

spool off

@_recurs_sql getplanh

undefine SQLID
undefine 1
undefine rt

set termout on
set verify on
