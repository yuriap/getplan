prompt ============================================ Recursive SQLs ==========================================
select sql_id, count(1) cnt from v$active_session_history where top_level_sql_id='&SQLID'
group by sql_id
order by 2 desc;

set heading off
set echo off
set verify off
set timing off
set feedback off

spool _tmp_vsql_rec_sql_&SQLID..sql
select 'host mkdir sqlid_&SQLID._recursive_sqls'||chr(10)||'@&1. ' ||sql_id||chr(10)||'set termout off'||chr(10)||'host move sqlid_'||sql_id||'*.'||case when '&1.'='getplanh' then 'html' else 'txt' end||' .\sqlid_&SQLID._recursive_sqls'
  from (select sql_id, count(1) cnt
          from v$active_session_history
         where top_level_sql_id = '&SQLID'
           and sql_id<>top_level_sql_id
         group by sql_id
        having count(1) > 60
         order by cnt desc)
where sql_id<>'&SQLID';

prompt define SQLID=&SQLID

spool off

@_tmp_vsql_rec_sql_&SQLID..sql

host del _tmp_vsql_rec_sql_&SQLID..sql
host rm _tmp_vsql_rec_sql_&SQLID..sql

set heading on
set verify on
set timing on
set feedback on