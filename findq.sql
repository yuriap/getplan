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

column sqltext format a200 word_wrap
column LAST_ACTIVE_TIME format a21
set timing on
prompt Mode is &fscope
column INST_ID format 9999
rem prompt Fast search 
select cmd, LAST_ACTIVE_TIME, inst_id,sqltext from (
select /*+qb_name(findq)*/ '@getplan '||sql_id cmd, to_char(LAST_ACTIVE_TIME,'yyyy-mm-dd hh24:mi:ss') LAST_ACTIVE_TIME, inst_id,replace(replace(sql_text,chr(13),' '),chr(13),' ') sqltext 
  from gv$sqlstats
 where upper(sql_fulltext) like upper('&1') 
   and sql_text not like '%qb_name(findq)%' 
   and sql_text not like 'explain plan%' 
   and '&fscope'='fast'
union all
select /*+qb_name(findq)*/ '@getplanawr '||sql_id,(select to_char(min(snap_id)) ||' '|| to_char(max(snap_id)) ma_snap_id from dba_hist_sqlstat s where s.sql_id=t.sql_id) LAST_ACTIVE_TIME,null,null --cast(substr(sql_text,1,1000) as varchar2(1000))  
  from dba_hist_sqltext t
 where upper(sql_text) like upper('&1') 
   and '&fscope'='awr'
union all
select /*+qb_name(findq)*/ '@getplan '||sql_id, to_char(LAST_ACTIVE_TIME,'yyyy-mm-dd hh24:mi:ss') LAST_ACTIVE_TIME, inst_id,replace(replace(sql_text,chr(13),' '),chr(13),' ')  
  from gv$sql 
 where upper(sql_fulltext) like upper('&1') 
   and sql_text not like '%qb_name(findq)%' 
   and sql_text not like 'explain plan%' 
   and '&fscope'='full'
order by LAST_ACTIVE_TIME);   
set verify on

undefine 1
undefine fscope