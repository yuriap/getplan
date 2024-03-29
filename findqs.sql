define hver=2

alter session set nls_date_format='YYYY-MON-DD HH24:mi:ss';
column INST_ID format a7
column INST_NAME format a20
select SYS_CONTEXT ('USERENV','INSTANCE') INST_ID, SYS_CONTEXT ('USERENV','INSTANCE_NAME') INST_NAME from dual;
set verify off
--set echo off
define fscope=&2
set long 100
set timing off
column f_scope new_v fscope noprint
select decode('&fscope.','','fast',null,'fast','fast','fast','awr','awr','full','full') f_scope from dual;

column sqltext format a90
column LAST_ACTIVE_TIME format a21
set timing on
prompt Mode is &fscope
column INST_ID format 9999
rem prompt Fast search 
set heading off
set feedback off
set timing off
spool _tmp_findqs.sql
select cmd --, LAST_ACTIVE_TIME, inst_id,substr(sqltext,1,90) sqltext 
from (
select /*+qb_name(findq)*/ '@getplan'||decode(&hver.,1,'h',null)||' '||sql_id cmd, to_char(LAST_ACTIVE_TIME,'yyyy-mm-dd hh24:mi:ss') LAST_ACTIVE_TIME, inst_id,replace(replace(sql_text,chr(13),' '),chr(13),' ') sqltext 
  from gv$sqlstats
 where upper(sql_fulltext) like upper('&1') 
   and upper(sql_text) not like '%QB_NAME(FINDQ)%' 
   and upper(sql_text) not like 'EXPLAIN PLAN%' 
   and upper(sql_text) not like '%QB_NAME(NOMONITORME)%' 
   and '&fscope'='fast'
union all
select /*+qb_name(findq)*/ '@getplanawr'||decode(&hver.,1,'h',null)||' '||sql_id,(select to_char(min(snap_id)) ||' '|| to_char(max(snap_id)) ma_snap_id from dba_hist_sqlstat s where s.sql_id=t.sql_id) LAST_ACTIVE_TIME,null,null --cast(substr(sql_text,1,1000) as varchar2(1000))  
  from dba_hist_sqltext t
 where upper(sql_text) like upper('&1') 
   and upper(sql_text) not like '%QB_NAME(FINDQ)%' 
   and upper(sql_text) not like 'EXPLAIN PLAN%' 
   and upper(sql_text) not like '%QB_NAME(NOMONITORME)%' 
   and '&fscope'='awr'
union all
select /*+qb_name(findq)*/ '@getplan'||decode(&hver.,1,'h',null)||' '||sql_id, to_char(LAST_ACTIVE_TIME,'yyyy-mm-dd hh24:mi:ss') LAST_ACTIVE_TIME, inst_id,replace(replace(sql_text,chr(13),' '),chr(13),' ')  
  from gv$sql 
 where upper(sql_fulltext) like upper('&1') 
   and upper(sql_text) not like '%QB_NAME(FINDQ)%' 
   and upper(sql_text) not like 'EXPLAIN PLAN%' 
   and upper(sql_text) not like '%QB_NAME(NOMONITORME)%' 
   and '&fscope'='full'
order by LAST_ACTIVE_TIME nulls first
);   
spool off
set verify on
set heading on
set feedback on
set timing on

undefine 1
undefine fscope

@_tmp_findqs.sql