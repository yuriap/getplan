set pages 9999
set lines 500
set trimspool on
set termout off
set echo off

set verify off
define SQLID=&1
spool sqlid_&SQLID..txt

@getplan_base

spool off

@recurs_sql getplan



undefine SQLID
undefine 1
undefine rt

set termout on
set verify on
