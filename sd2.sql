define selfscriptname=sd2.sql

set pages 0
set lines 2000
set define "&"
set echo off
set feedback off

set verify off
define SQLID=&1

set trimspool on
set termout off

spool sql_perf_data_&SQLID..html


set timing off
set define ~

set serveroutput on
declare
  l_sql_id varchar2(32) := '~SQLID';
  
  --Sections Visibility Config
  l_sect_sql_text     boolean := true;
  l_sect_db_desc      boolean := true;
  l_sect_vsql         boolean := true;
  l_sect_exadata      boolean := true;
  l_sect_workarea     boolean := true;
  l_sect_non_shared   boolean := true;
  l_sect_cbo_env      boolean := true;
  l_sect_dcl          boolean := true;
  l_sect_dcrac        boolean := true;
  l_sect_dcladv       boolean := true; 
  l_sect_dcall        boolean := true;
  l_sect_dc_adapt     boolean := true;
  l_sect_awr_plans    boolean := true;
  l_sect_explain      boolean := true;
  l_sect_sqlmon       boolean := true;
  l_sect_sqlmonh      boolean := true;
  l_sect_sql_stat     boolean := true;
  l_sect_binds        boolean := true;
  l_sect_vashsum      boolean := true;
  l_sect_vashesum     boolean := true;
  l_sect_plsql_v      boolean := true;
  l_sect_plsql        boolean := false;
  l_sect_ash_summ     boolean := true;
  l_sect_ash_p1       boolean := true;
  l_sect_ash_p2       boolean := true;
  l_sect_ash_p3       boolean := true;
   
  l_time number;
  l_cpu_tim number;
  l_tot_time number:=0;
  l_tot_cpu_tim number:=0;   
  l_timing boolean := true;
  
  l_sql clob;
  l_plsql_output clob;

  l_crsr sys_refcursor;
  
  l_css clob:=
q'{
body.awr {font:bold 10pt Arial,Helvetica,Geneva,sans-serif;color:black; background:White;}
pre.awr    {font:8pt Courier;color:black; background:White;}
h1.awr     {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-bottom:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
h2.awr     {font:bold 18pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h3.awr     {font:bold 16pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h4.awr     {font:bold 12pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h5.awr     {font:bold 10pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h6.awr     {font:6pt Arial,Helvetica,Geneva,sans-serif;color:black;background-color:White;margin-top:10pt; margin-bottom:10pt;}
li.awr        {font: 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;}
th.awrbg  {font-family: monospace; font-size: 11px; color:White; background:#0066CC;padding-left:4px; padding-right:4px;padding-bottom:2px}
td.awrnc1{font-family: monospace; font-size: 11px; color:black;background:White;   vertical-align:top;}
td.awrc1  {font-family: monospace; font-size: 11px; color:black;background:#FFFFCC; vertical-align:top;}
td.awrncc1{font-family: monospace; font-size: 11px; color:red;background:White;   vertical-align:top;}
td.awrcc1  {font-family: monospace; font-size: 11px; color:red;background:#FFFFCC; vertical-align:top;}
a.awr        {font:bold 8pt Arial,Helvetica,sans-serif;color:#663300; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
a.awr1      {font:font-family: monospace; font-size: 11px;color:#663300; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
td.awrncbbt  {font-family: monospace; font-size: 11px;color:black;background:White;vertical-align:top;border-style: ridge;border-width: 1px;}
td.awrcbbt    {font-family: monospace; font-size: 11px;color:black;background:#FFFFCC; vertical-align:top;border-style: ridge;border-width: 1px;}
table.tdiff   {  border_collapse: collapse; border-spacing: 0px}
.hidden    {position:absolute;left:-10000px;top:auto;width:1px;height:1px;overflow:hidden;}
.pad           {margin-left:17px;}
.doublepad  {margin-left:34px;}
span.nm    {background-color:#cceeff;color:red;}
}';
  
  l_getftxt clob := 
q'{
select sql_fulltext "Full query text"
  from (select sql_fulltext
          from gv$sql
         where sql_id = '&1'
        union all
        select sql_fulltext
          from gv$sqlarea
         where sql_id = '&1'
        union all
        select sql_fulltext from gv$sqlstats where sql_id = '&1')
 where rownum = 1;
}';

  l_nonshared1 clob := 
q'{
rem https://timurakhmadeev.wordpress.com/2012/03/15/vsql-is_obsolete/
select * from
(select INST_ID, sql_id, nonshared_reason, count(*) "Count" from gv$sql_shared_cursor
unpivot
(nonshared_value for nonshared_reason in (
UNBOUND_CURSOR as 'UNBOUND_CURSOR',
SQL_TYPE_MISMATCH as 'SQL_TYPE_MISMATCH',
OPTIMIZER_MISMATCH as 'OPTIMIZER_MISMATCH',
OUTLINE_MISMATCH as 'OUTLINE_MISMATCH',
STATS_ROW_MISMATCH as 'STATS_ROW_MISMATCH',
LITERAL_MISMATCH as 'LITERAL_MISMATCH',
FORCE_HARD_PARSE as 'FORCE_HARD_PARSE',
EXPLAIN_PLAN_CURSOR as 'EXPLAIN_PLAN_CURSOR',
BUFFERED_DML_MISMATCH as 'BUFFERED_DML_MISMATCH',
PDML_ENV_MISMATCH as 'PDML_ENV_MISMATCH',
INST_DRTLD_MISMATCH as 'INST_DRTLD_MISMATCH',
SLAVE_QC_MISMATCH as 'SLAVE_QC_MISMATCH',
TYPECHECK_MISMATCH as 'TYPECHECK_MISMATCH',
AUTH_CHECK_MISMATCH as 'AUTH_CHECK_MISMATCH',
BIND_MISMATCH as 'BIND_MISMATCH',
DESCRIBE_MISMATCH as 'DESCRIBE_MISMATCH',
LANGUAGE_MISMATCH as 'LANGUAGE_MISMATCH',
TRANSLATION_MISMATCH as 'TRANSLATION_MISMATCH',
BIND_EQUIV_FAILURE as 'BIND_EQUIV_FAILURE',
INSUFF_PRIVS as 'INSUFF_PRIVS',
INSUFF_PRIVS_REM as 'INSUFF_PRIVS_REM',
REMOTE_TRANS_MISMATCH as 'REMOTE_TRANS_MISMATCH',
LOGMINER_SESSION_MISMATCH as 'LOGMINER_SESSION_MISMATCH',
INCOMP_LTRL_MISMATCH as 'INCOMP_LTRL_MISMATCH',
OVERLAP_TIME_MISMATCH as 'OVERLAP_TIME_MISMATCH',
EDITION_MISMATCH as 'EDITION_MISMATCH',
MV_QUERY_GEN_MISMATCH as 'MV_QUERY_GEN_MISMATCH',
USER_BIND_PEEK_MISMATCH as 'USER_BIND_PEEK_MISMATCH',
TYPCHK_DEP_MISMATCH as 'TYPCHK_DEP_MISMATCH',
NO_TRIGGER_MISMATCH as 'NO_TRIGGER_MISMATCH',
FLASHBACK_CURSOR as 'FLASHBACK_CURSOR',
ANYDATA_TRANSFORMATION as 'ANYDATA_TRANSFORMATION',
PDDL_ENV_MISMATCH as 'PDDL_ENV_MISMATCH',
TOP_LEVEL_RPI_CURSOR as 'TOP_LEVEL_RPI_CURSOR',
DIFFERENT_LONG_LENGTH as 'DIFFERENT_LONG_LENGTH',
LOGICAL_STANDBY_APPLY as 'LOGICAL_STANDBY_APPLY',
DIFF_CALL_DURN as 'DIFF_CALL_DURN',
BIND_UACS_DIFF as 'BIND_UACS_DIFF',
PLSQL_CMP_SWITCHS_DIFF as 'PLSQL_CMP_SWITCHS_DIFF',
CURSOR_PARTS_MISMATCH as 'CURSOR_PARTS_MISMATCH',
STB_OBJECT_MISMATCH as 'STB_OBJECT_MISMATCH',
CROSSEDITION_TRIGGER_MISMATCH as 'CROSSEDITION_TRIGGER_MISMATCH',
PQ_SLAVE_MISMATCH as 'PQ_SLAVE_MISMATCH',
TOP_LEVEL_DDL_MISMATCH as 'TOP_LEVEL_DDL_MISMATCH',
MULTI_PX_MISMATCH as 'MULTI_PX_MISMATCH',
BIND_PEEKED_PQ_MISMATCH as 'BIND_PEEKED_PQ_MISMATCH',
MV_REWRITE_MISMATCH as 'MV_REWRITE_MISMATCH',
ROLL_INVALID_MISMATCH as 'ROLL_INVALID_MISMATCH',
OPTIMIZER_MODE_MISMATCH as 'OPTIMIZER_MODE_MISMATCH',
PX_MISMATCH as 'PX_MISMATCH',
MV_STALEOBJ_MISMATCH as 'MV_STALEOBJ_MISMATCH',
FLASHBACK_TABLE_MISMATCH as 'FLASHBACK_TABLE_MISMATCH',
LITREP_COMP_MISMATCH as 'LITREP_COMP_MISMATCH',
PLSQL_DEBUG as 'PLSQL_DEBUG',
LOAD_OPTIMIZER_STATS as 'LOAD_OPTIMIZER_STATS',
ACL_MISMATCH as 'ACL_MISMATCH',
FLASHBACK_ARCHIVE_MISMATCH as 'FLASHBACK_ARCHIVE_MISMATCH',
LOCK_USER_SCHEMA_FAILED as 'LOCK_USER_SCHEMA_FAILED',
REMOTE_MAPPING_MISMATCH as 'REMOTE_MAPPING_MISMATCH',
LOAD_RUNTIME_HEAP_FAILED as 'LOAD_RUNTIME_HEAP_FAILED',
HASH_MATCH_FAILED as 'HASH_MATCH_FAILED',
PURGED_CURSOR as 'PURGED_CURSOR',
BIND_LENGTH_UPGRADEABLE as 'BIND_LENGTH_UPGRADEABLE',
USE_FEEDBACK_STATS as 'USE_FEEDBACK_STATS'
))
where nonshared_value = 'Y'
group by INST_ID,sql_id, nonshared_reason
)
where sql_id = '&1.'
order by 1;
}';

  l_vsql_stat clob := 
q'[
declare
l_on varchar2(512);
procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;
  /*---------------------------------------------------
    -- function for converting large numbers to human-readable format
    ---------------------------------------------------*/
    function tptformat( p_num in number,
                        p_stype in varchar2 default 'STAT',
                        p_precision in number default 2,
                        p_base in number default 10,    -- for KiB/MiB formatting use
                        p_grouplen in number default 3  -- p_base=2 and p_grouplen=10
                      )
                      return varchar2
    is
    begin
        if p_num=0 then return '0'; end if;
        if p_stype in ('WAIT','TIME') then
            return
                round(
                    p_num / power( p_base , trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) ), p_precision
                )
                || case trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen))
                       when 0            then 'us'
                       when 1            then 'us'
                       when p_grouplen*1 then 'ms'
                       when p_grouplen*2 then 's'
                       when p_grouplen*3 then 'ks'
                       when p_grouplen*4 then 'Ms'
                       else '*'||p_base||'e'||to_char( trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) )||' us'
                    end;
        else
            return
                round(
                    p_num / power( p_base , trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) ), p_precision
                )
                || case trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen))
                       when 0            then ''
                       when 1            then ''
                       when p_grouplen*1 then 'k'
                       when p_grouplen*2 then 'M'
                       when p_grouplen*3 then 'G'
                       when p_grouplen*4 then 'T'
                       when p_grouplen*5 then 'P'
                       when p_grouplen*6 then 'E'
                       else '*'||p_base||'e'||to_char( trunc(log(p_base,abs(p_num)))-trunc(mod(log(p_base,abs(p_num)),p_grouplen)) )
                    end;
        end if;
    end; -- tptformat
begin
  p(' ');
  p('DB: &_USER.@&_CONNECT_IDENTIFIER.');
  for i in (select * from &VSQL. where sql_id='&1.' order by inst_id) loop
    p(' ');
    p('-------------------------------------------------------------------------------------------------');
    p('SQL_ID='||i.sql_id||'; CHILD_NUMBER='||i.child_number||'; PLAN HASH: '||i.PLAN_HASH_VALUE||'; Opt Env Hash: '||i.OPTIMIZER_ENV_HASH_VALUE||';'||' INST_ID: '||i.inst_id);
	p('FORCE_MATCHING_SIGN: '||i.force_matching_signature||'; OLD_HASH_VALUE: '||i.OLD_HASH_VALUE);
	begin
	  select object_type||': '||owner||'.'||object_name into l_on from dba_objects s where s.object_id=i.program_id;
	  p(l_on||', line number: '||i.program_line#);
	  exception when no_data_found then null;
	end;
    p('=================================================================================================');
    p('Parsing Schema, Module, Action: '||nvl(i.parsing_schema_name,'<NULL>')||', '||nvl(i.module,'<NULL>')||', '||nvl(i.action,'<NULL>'));
    p('Load_time, First: '||i.first_load_time||', Last: '||i.last_load_time||', Active: '||to_char(i.last_active_time,'dd/mm/yyyy hh24:mi:ss'));
    $IF DBMS_DB_VERSION.version<11 $THEN
      p('SQL Profile: '||nvl(i.sql_profile,'<NULL>'));
    $ELSE
      p('IS_OBSOLETE, IS_BIND_SENSITIVE,IS_BIND_AWARE, IS_SHARABLE: '||nvl(i.IS_OBSOLETE,'<NULL>')||','||nvl(i.IS_BIND_SENSITIVE,'<NULL>')||','||nvl(i.IS_BIND_AWARE,'<NULL>')||','||nvl(i.is_shareable,'<NULL>'));
      p('SQL Profile, SQL Patch, SQL Plan BaseLine: '||nvl(i.sql_profile,'<NULL>')||','||nvl(i.sql_patch,'<NULL>')||','||nvl(i.sql_plan_baseline,'<NULL>'));
    $END    
	p('PX_SERVERS_EXECUTIONS: '||tptformat(i.PX_SERVERS_EXECUTIONS));
    p('PHY_READ_REQ, PHY_READ_BYTES: '||tptformat(i.physical_read_requests)||'; '||tptformat(i.physical_read_bytes));
	p('PHY_WRI_REQ, PHY_WRI_BYTES: '||tptformat(i.physical_write_requests)||'; '||tptformat(i.physical_write_bytes));
    p('Calls: Parse, Exec, Fetch, Rows, EndOfFetch '||i.parse_calls||'; '||i.executions||'; '||i.fetches||'; '||i.ROWS_PROCESSED||'; '||i.end_of_fetch_count);
    p('CPU Time, Elapsed Time: '||tptformat(i.cpu_time,'TIME')||'; '||tptformat(i.elapsed_time,'TIME'));
    p('PIO, LIO, Direct WR: '||tptformat(i.disk_reads)||'; '||tptformat(i.buffer_gets)||'; '||tptformat(i.DIRECT_WRITES));
	p('WAIT: APP, CONCURR, CLUSTER, USER_IO, PL/SQL, JAVA: '||tptformat(i.application_wait_time,'TIME')||'; '||tptformat(i.concurrency_wait_time,'TIME')||'; '||tptformat(i.cluster_wait_time,'TIME')||'; '||tptformat(i.user_io_wait_time,'TIME')||'; '||tptformat(i.PLSQL_EXEC_TIME,'TIME')||'; '||tptformat(i.JAVA_EXEC_TIME,'TIME'));
	if i.disk_reads>0 then p('Avg IO time: '||tptformat(i.user_io_wait_time/i.disk_reads,'TIME'));end if;
	if i.buffer_gets>0 then p('CPU sec/1M LIO: '||tptformat(i.cpu_time/i.buffer_gets));end if;
    p('=================================================================================================');    
    if i.executions>0 then 
      p('LIO/Exec, PIO/Exec, CPU/EXEC, ROWS/EXEC, ELA/EXEC: '||tptformat(round(i.buffer_gets/i.executions,3))||'; '||
	                                                tptformat(round((i.disk_reads+i.DIRECT_WRITES)/i.executions,3))||'; '||
													tptformat(round(i.cpu_time/i.executions,3),'TIME')||'; '||
													tptformat(round(i.ROWS_PROCESSED/i.executions,3))||'; '||
													tptformat(round(i.elapsed_time/i.executions,3),'TIME'));	
    else
      p('LIO/Exec, PIO/Exec, CPU/EXEC, ELA/EXEC: '||tptformat(round(i.buffer_gets))||'; '||tptformat(round(i.disk_reads+i.DIRECT_WRITES))||'; '||tptformat(round(i.cpu_time),'TIME')||'; '||tptformat(round(i.elapsed_time),'TIME'));	
    end if;
    if i.ROWS_PROCESSED>0 then 
      p('LIO/Row, PIO/Row, CPU/Row, ELA/Row, Rows/Sec: '||tptformat(round(i.buffer_gets/i.ROWS_PROCESSED,3))||'; '||tptformat(round((i.disk_reads+i.DIRECT_WRITES)/i.ROWS_PROCESSED,3))||'; '||tptformat(round(i.cpu_time/i.ROWS_PROCESSED,3),'TIME')||'; '||tptformat(round(i.elapsed_time/i.ROWS_PROCESSED,3),'TIME')||'; '||tptformat(round(1e6*i.ROWS_PROCESSED/case when i.elapsed_time=0 then 1 else i.elapsed_time end,3)));	
    else
      p('LIO/Row, PIO/Row, CPU/Row, ELA/Row: '||tptformat(round(i.buffer_gets))||'; '||tptformat(round(i.disk_reads+i.DIRECT_WRITES))||'; '||tptformat(round(i.cpu_time),'TIME')||'; '||tptformat(round(i.elapsed_time),'TIME'));	
    end if;  
    $IF DBMS_DB_VERSION.version>=11 $THEN
	  if i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES>0 then
	    p('=================================================================================================');
		p('Saved %: '||round(100 * (i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES - i.IO_INTERCONNECT_BYTES) / case when i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES=0 then 1 else i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES end,2));
        p('IO_CELL_OFFLOAD_ELIGIBLE_BYTES: '||tptformat(i.IO_CELL_OFFLOAD_ELIGIBLE_BYTES));
	    p('IO_INTERCONNECT_BYTES:          '||tptformat(i.IO_INTERCONNECT_BYTES));
	    p('OPTIMIZED_PHY_READ_REQUESTS:    '||tptformat(i.OPTIMIZED_PHY_READ_REQUESTS));
	    p('IO_CELL_UNCOMPRESSED_BYTES:     '||tptformat(i.IO_CELL_UNCOMPRESSED_BYTES));
	    p('IO_CELL_OFFLOAD_RETURNED_BYTES: '||tptformat(i.IO_CELL_OFFLOAD_RETURNED_BYTES));
        p('=================================================================================================');    	  
	  end if;
    $END 
  end loop;
end;
]';

----------------------------------------------------------------------------------------
--
-- File name:   offload_percent.sql
--
-- Purpose:     Caclulate % of long running statements that were offloaded. 
--
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for three values.
--
--              sql_text: a piece of a SQL statement like %select col1, col2 from skew%
--                        The default is to return all statements.
--
--              min_etime: the minimum avg. elapsed time in seconds
--                         This parameter allows limiting the output to long running statements.
--                         The default is 0 which returns all statements.
--
--              min_avg_lio: the minimum avg. elapsed time in seconds
--                           This parameter allows limiting the output to long running statements.
--                           The default is 500,000.
--
-- Description:
--
--              This script can be used to provide a quick check on whether statements 
--              are being offloaded or not on Exadata platforms.
--
--              It is based on the observation that the IO_CELL_OFFLOAD_ELIGIBLE_BYTES
--              column in V$SQL is only greater than 0 when a statement is executed
--              using a Smart Scan. 
--
--              The default values will aggregate data for all statements that have an
--              avg_lio value of greater than 500,000. You can change this minimum value
--              or further limit the set of statements that will be evaluated by providing
--              a piece of SQL text, 'select%' for example, or setting a minimum avg. 
--              elapsed time value. 
--
--              See kerryosborne.oracle-guy.com for additional information.
---------------------------------------------------------------------------------------
  l_offload_percent1 clob := 
q'[
select inst_id,offloaded + not_offloaded total, offloaded, lpad(to_char(round(100 * offloaded / (offloaded + not_offloaded), 2)) || '%', 11, ' ') "OFFLOADED_%"
  from (select inst_id,sum(decode(offload, 'Yes', 1, 0)) offloaded, sum(decode(offload, 'No', 1, 0)) not_offloaded
          from (select *
                  from (select inst_id,sql_id,
                               child_number child,
                               plan_hash_value plan_hash,
                               executions execs,
                               (elapsed_time / 1000000) / decode(nvl(executions, 0), 0, 1, executions) /
                               decode(px_servers_executions, 0, 1, px_servers_executions / decode(nvl(executions, 0), 0, 1, executions)) avg_etime,
                               px_servers_executions / decode(nvl(executions, 0), 0, 1, executions) avg_px,
                               decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES, 0, 'No', 'Yes') Offload,
                               decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,
                                      0,
                                      0,
                                      100 * (IO_CELL_OFFLOAD_ELIGIBLE_BYTES - IO_INTERCONNECT_BYTES) /
                                      decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES, 0, 1, IO_CELL_OFFLOAD_ELIGIBLE_BYTES)) "IO_SAVED_%",
                               -- buffer_gets lio,
                               buffer_gets / decode(nvl(executions, 0), 0, 1, executions) avg_lio,
                               sql_text
                          from gv$sql s
                         where sql_id = '&1.')) group by inst_id)
order by 1
;
]';

----------------------------------------------------------------------------------------
--
-- File name:   offload_percent.sql
--
-- Purpose:     Caclulate % of long running statements that were offloaded. 
--
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for three values.
--
--              sql_text: a piece of a SQL statement like %select col1, col2 from skew%
--                        The default is to return all statements.
--
--              min_etime: the minimum avg. elapsed time in seconds
--                         This parameter allows limiting the output to long running statements.
--                         The default is 0 which returns all statements.
--
--              min_avg_lio: the minimum avg. elapsed time in seconds
--                           This parameter allows limiting the output to long running statements.
--                           The default is 500,000.
--
-- Description:
--
--              This script can be used to provide a quick check on whether statements 
--              are being offloaded or not on Exadata platforms.
--
--              It is based on the observation that the IO_CELL_OFFLOAD_ELIGIBLE_BYTES
--              column in V$SQL is only greater than 0 when a statement is executed
--              using a Smart Scan. 
--
--              The default values will aggregate data for all statements that have an
--              avg_lio value of greater than 500,000. You can change this minimum value
--              or further limit the set of statements that will be evaluated by providing
--              a piece of SQL text, 'select%' for example, or setting a minimum avg. 
--              elapsed time value. 
--
--              See kerryosborne.oracle-guy.com for additional information.
---------------------------------------------------------------------------------------
  l_offload_percent2 clob := 
q'[
select --sql_id,
       inst_id,
       child_number child,
       plan_hash_value plan_hash,
       executions execs,
       round((elapsed_time / 1000000) / decode(nvl(executions, 0), 0, 1, executions) /
       decode(px_servers_executions, 0, 1, px_servers_executions / decode(nvl(executions, 0), 0, 1, executions)),3) avg_etime,
       round(px_servers_executions / decode(nvl(executions, 0), 0, 1, executions),1) avg_px,
       decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES, 0, 'No', 'Yes') Offload,
       round(decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,
              0,
              0,
              100 * (IO_CELL_OFFLOAD_ELIGIBLE_BYTES - IO_INTERCONNECT_BYTES) / decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES, 0, 1, IO_CELL_OFFLOAD_ELIGIBLE_BYTES)),2) "IO_SAVED_%",
       -- buffer_gets lio,
       round(buffer_gets / decode(nvl(executions, 0), 0, 1, executions)) avg_lio--,
       --sql_text
  from gv$sql s
 where sql_id = '&1.'
order by 1,2
;
]';

  l_sqlmon1 clob := 
q'[
declare
  procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;
  procedure print_text_as_table(p_text clob) is
  l_line varchar2(32765);  l_eof number;  l_iter number := 1; 
  l_text clob := p_text||chr(10);
begin
  loop
    l_eof:=instr(l_text,chr(10));
	p(rtrim(rtrim(substr(l_text,1,l_eof),chr(13)),chr(10)));
    l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
    exit when l_iter>10000000 or dbms_lob.getlength(l_text)=0;
  end loop;
end;
begin
  for i in (select dbms_sqltune.report_sql_monitor(sql_id=>'&1',report_level=>'ALL') x from dual) loop
    print_text_as_table(i.x);
  end loop;
end;
]';

  l_sqlwarea clob := 
q'[
select inst_id,
       child_number "CHLD#",
       policy,
       operation_id "OPER",
       operation_type "OPERATION",
       estimated_optimal_size "EST_OPTIM",
       estimated_onepass_size "EST_ONEPA",
       last_memory_used "MEM_USED",
       last_execution "LST_EXE",
       last_degree "LST_DEGREE",
       total_executions "TOT_EXE",
       optimal_executions "OPT_EXE",
       onepass_executions "ONEP_EXE",
       multipasses_executions "MULT_EXE",
       active_time "ACTIVE_TIM",
       max_tempseg_size "MAX_TMP",
       last_tempseg_size "LAST_TMP"
  from gv$sql_workarea
 where sql_id = '&1'
 order by inst_id, child_number, operation_id;
]';

  l_optenv clob := 
q'[
select inst_id,child_number,name,isdefault,value from gv$sql_optimizer_env where sql_id='&1.' order by inst_id,child_number,name;
]';

  l_rac_plans clob := 
q'[
select i.inst_id "INST",i.CHILD_NUMBER CH#,y.plan_table_output
  from gv$sql i,
       table(dbms_xplan.display('gv$sql_plan_statistics_all',
                                null,
                                'LAST ALLSTATS +peeked_binds',
                                'inst_id=' || i.inst_id || ' and sql_id=''' ||
                                i.sql_id || ''' and CHILD_NUMBER=' ||
                                i.CHILD_NUMBER)) y
 where sql_id = '&SQLID'
;
]';

  l_sqlmon_hist clob := 
q'[
declare
  procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;
  procedure print_text_as_table(p_text clob) is
  l_line varchar2(32765);  l_eof number;  l_iter number := 1;
  l_text clob := p_text||chr(10);
begin
  loop
    l_eof:=instr(l_text,chr(10));
    p(rtrim(rtrim(substr(l_text,1,l_eof),chr(13)),chr(10)));
    l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
    exit when l_iter>10000000 or dbms_lob.getlength(l_text)=0;
  end loop;
end;
begin
  if nvl('&start_sn.','0')<>'0' and nvl('&end_sn.','0')<>'0' then
    for i in (SELECT DBMS_AUTO_REPORT.REPORT_REPOSITORY_DETAIL(RID => report_id, TYPE => 'text') x
                FROM (with dts as (select min(begin_interval_time) btim, max(end_interval_time) etim from dba_hist_snapshot where snap_id between to_number('&start_sn.') and to_number('&end_sn.'))
                      select x.* from dba_hist_reports x, dts
                       WHERE component_name = 'sqlmonitor' 
                         and period_start_time >= dts.btim and period_end_time <= dts.etim
                         and key1='&1' order by PERIOD_START_TIME desc)
               where rownum<=30) loop
      print_text_as_table(i.x);
      p('.');
    end loop;  
  else
    for i in (SELECT DBMS_AUTO_REPORT.REPORT_REPOSITORY_DETAIL(RID => report_id, TYPE => 'text') x
                FROM (select x.* from dba_hist_reports x
                       WHERE component_name = 'sqlmonitor'
                         and key1='&1' order by PERIOD_START_TIME desc)
               where rownum<=30) loop
      print_text_as_table(i.x);
      p('.');
    end loop;
  end if;
end;
]';

  l_ash_p3 clob := 
q'[
select SQL_EXEC_START,
       to_char(max(sample_time) over(partition by SQL_EXEC_START, plan_hash_value) + 0, 'yyyy/mm/dd hh24:mi:ss') sql_exec_end,
       plan_hash_value, id, row_src, event, cnt,
       round(100 * cnt / sum(cnt) over(partition by SQL_EXEC_START, plan_hash_value), 2) tim_pct,
       round(100 * sum(cnt) over(partition by id, SQL_EXEC_START, plan_hash_value) / sum(cnt) over(partition by SQL_EXEC_START, plan_hash_value), 2) tim_id_pct,
       obj, tbs
  from (select to_char(SQL_EXEC_START, 'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
               sql_plan_hash_value plan_hash_value,
               sql_plan_line_id id,
               sql_plan_operation || ' ' || sql_plan_options row_src,
               obj,tbs,
               nvl(event, 'CPU') event,
               count(1) cnt,
               max(sample_time) sample_time
          from (select x.*,
                       case when CURRENT_OBJ#>0 then (select object_type||'.'||object_name from dba_objects where object_id=CURRENT_OBJ#) else to_char(CURRENT_OBJ#) end obj,     
                       case when CURRENT_FILE#>0 then (select TABLESPACE_NAME from dba_data_files where FILE_ID=CURRENT_FILE#) else null end tbs          
            from gv$active_session_history x)
         where sql_id = '&SQLID'
         group by SQL_EXEC_START,
                  sql_plan_hash_value,
                  sql_plan_line_id,
                  sql_plan_operation || ' ' || sql_plan_options,
                  nvl(event, 'CPU'),
                  obj,tbs) x
 order by SQL_EXEC_START, plan_hash_value, id, event; 
]';

  l_ash_p3_1 clob := 
q'[
select plan_hash_value, id, row_src "Row source", event, cnt "Time",
       round(100 * cnt / sum(cnt) over(partition by id), 2) "Time, %",
	   round(100 * sum(cnt) over(partition by id) / sum(cnt) over()) "Time by ID, %",
       obj "Object", tbs "Tablespace"
  from (select sql_plan_hash_value plan_hash_value,
               sql_plan_line_id id,
               sql_plan_operation || ' ' || sql_plan_options row_src,
               obj,tbs,
               nvl(event, 'CPU') event,
               count(1) cnt
          from (select x.*,
                       case when CURRENT_OBJ#>0 then (select object_type||'.'||object_name from dba_objects where object_id=CURRENT_OBJ#) else to_char(CURRENT_OBJ#) end obj,     
                       case when CURRENT_FILE#>0 then (select TABLESPACE_NAME from dba_data_files where FILE_ID=CURRENT_FILE#) else null end tbs          
            from gv$active_session_history x)
         where sql_id = '&SQLID'
         group by sql_plan_hash_value,
                  sql_plan_line_id,
                  sql_plan_operation || ' ' || sql_plan_options,
                  nvl(event, 'CPU'),
                  obj,tbs) x
 order by plan_hash_value, id, event; 
]';

  l_sqlstat clob:=
q'{
select 
       s.snap_id snap,to_char(sn.end_interval_time,'dd/mm/yyyy hh24:mi:ss') end_interval_time,
       --s.sql_id,
       s.plan_hash_value plan_hash   
      , EXECUTIONS_DELTA EXEC_DELTA
      , (round(s.ELAPSED_TIME_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as ela_poe
      , (round(s.BUFFER_GETS_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA))) as LIO_poe
      , (round(s.CPU_TIME_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as CPU_poe
      , (round(s.IOWAIT_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as IOWAIT_poe
      , (round(s.ccwait_delta/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as CCWAIT_poe
      , (round(s.APWAIT_delta/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as APWAIT_poe
      , (round(s.CLWAIT_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA)/1000)) as CLWAIT_poe
      , (round(s.DISK_READS_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA))) as PIO_poe
      , (round(s.ROWS_PROCESSED_DELTA/decode(s.EXECUTIONS_DELTA, null, 1,0,1, s.EXECUTIONS_DELTA))) as Rows_poe
      , ROUND(ELAPSED_TIME_DELTA/1000000) ELA_DELTA_SEC
      , ROUND(CPU_TIME_DELTA/1000000) CPU_DELTA_SEC
      , ROUND(IOWAIT_DELTA/1000000) IOWAIT_DELTA_SEC
      ,DISK_READS_DELTA
      ,BUFFER_GETS_DELTA
      ,ROWS_PROCESSED_DELTA
      ,round(BUFFER_GETS_DELTA/decode(ROWS_PROCESSED_DELTA,0,null,ROWS_PROCESSED_DELTA)) LIO_PER_ROW
      ,round(DISK_READS_DELTA/decode(ROWS_PROCESSED_DELTA,0,null,ROWS_PROCESSED_DELTA),2) IO_PER_ROW
      ,round(s.IOWAIT_DELTA/decode(s.DISK_READS_DELTA, null, 1,0,1, s.DISK_READS_DELTA)/1000, 3) as awg_IO_tim
from dba_hist_sqlstat s, 
     dba_hist_snapshot sn
where
    s.sql_id in ('&SQLID')
and s.snap_id = sn.snap_id
and sn.snap_id between &start_sn. and &end_sn.
and sn.instance_number = &INST_ID.
and s.instance_number = &INST_ID.
and s.dbid=&DBID.
and s.dbid=sn.dbid
order by sql_id,s.snap_id;
}';

  l_ash_summ clob := 
q'[
select INSTANCE_NUMBER INST, sql_id,
       top_level_sql_id,
       sql_plan_hash_value plan_hash,
       force_matching_signature force_matching_sign,
       sql_exec_id,
       to_char(sql_exec_start,'YYYY/MM/DD Hh24:mi:ss') sql_exec_start,
       to_char(min(sample_time),'YYYY/MM/DD Hh24:mi:ss')  start_tim,
       to_char(max(sample_time),'YYYY/MM/DD Hh24:mi:ss')  end_tim,
       plsql_entry_object_id plsql_entry,
       plsql_entry_subprogram_id plsql_subprog,
       program,
       machine,
       ecid,module,action,client_id, user_id
  from dba_hist_active_sess_history
 where sql_id = '&SQLID' and dbid=&DBID. and snap_id between &start_sn. and &end_sn.
 group by INSTANCE_NUMBER,sql_id,
          top_level_sql_id,
          sql_plan_hash_value,
          force_matching_signature,
          sql_exec_id,
          sql_exec_start,
          plsql_entry_object_id,
          plsql_entry_subprogram_id,
          program,
          machine,
          ecid,module,action,client_id, user_id
order by sql_exec_start,INSTANCE_NUMBER;
]';

  l_ash_p1_1 clob := 
q'[
select
  plan_hash_value,id,row_src "Row source",event,tim "Time",
  round(100 * tim / sum(tim) over(partition by id) , 2) "Time, %",
  round(100 * sum(tim) over(partition by id) / sum(tim) over(), 2) "Time by ID, %"
from (
select sql_plan_hash_value plan_hash_value,
       sql_plan_line_id id,
       sql_plan_operation|| ' '|| sql_plan_options row_src,
       nvl(event, 'CPU') event,
       count(1) * 10 tim
  from dba_hist_active_sess_history
 where sql_id = '&SQLID' and dbid=&DBID. and snap_id between &start_sn. and &end_sn.
 group by sql_plan_hash_value,
          sql_plan_line_id,
          sql_plan_operation,
          sql_plan_options,
          nvl(event, 'CPU')) x
 order by plan_hash_value, id;
]';

  l_ash_p2 clob := 
q'[
with summ as
 (select /*+materialize*/
   sql_id,
   sql_plan_hash_value,
   SQL_EXEC_START,
   sql_plan_line_id,
   event,
   count(1) smpl_cnt,
   min(sample_time) start_tim,
   max(sample_time) end_tim,
   GROUPING_ID(sql_id, sql_plan_hash_value, SQL_EXEC_START) g1,
   GROUPING_ID(sql_id, sql_plan_hash_value, SQL_EXEC_START, sql_plan_line_id, event) g2
    from dba_hist_active_sess_history
   where sql_id = '&SQLID'
     and dbid = &DBID.
     and snap_id between &start_sn. and &end_sn.
   group by GROUPING SETS((sql_id, sql_plan_hash_value, SQL_EXEC_START),(sql_id, sql_plan_hash_value, SQL_EXEC_START, sql_plan_line_id, event)))
SELECT s_tot.sql_plan_hash_value plan_hash_value,
       to_char(s_tot.SQL_EXEC_START, 'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
       to_char(s_tot.end_tim, 'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_END,
       plan.id,
       LPAD(' ', depth) || plan.operation || ' ' || plan.options ||
       NVL2(plan.object_name, ' (' || plan.object_name || ')', null) pl_operation,
       case when summ1.event is null and summ1.smpl_cnt is not null then 'CPU' else summ1.event
       end event,
       summ1.smpl_cnt * 10 tim,
       round(100 * summ1.smpl_cnt / s_tot.smpl_cnt, 2) tim_pct,
       to_char(summ1.start_tim, 'yyyy/mm/dd hh24:mi:ss') step_start, 
       to_char(summ1.end_tim, 'yyyy/mm/dd hh24:mi:ss') step_end
  FROM dba_hist_sql_plan plan,
       (select sql_id, sql_plan_hash_value, SQL_EXEC_START, smpl_cnt, end_tim from summ where g2 <> 0) s_tot,
       (select sql_id, sql_plan_hash_value, SQL_EXEC_START, smpl_cnt, start_tim, end_tim, event, sql_plan_line_id from summ where g2 = 0) summ1
 WHERE plan.sql_id = '&SQLID'
   and plan.dbid = &DBID.
   and s_tot.sql_id = plan.sql_id
   and s_tot.sql_plan_hash_value = plan.plan_hash_value
   and s_tot.SQL_EXEC_START = summ1.SQL_EXEC_START
   and nvl(summ1.sql_plan_line_id,0) = plan.id
   and summ1.sql_id = plan.sql_id
   and summ1.sql_plan_hash_value = plan.plan_hash_value
 ORDER BY summ1.SQL_EXEC_START, s_tot.sql_plan_hash_value, plan.id, nvl(summ1.event, 'CPU');
]';

  g_min number;
  g_max number;

procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;
procedure prepare_script(p_script in out clob, p_sqlid varchar2, p_plsql boolean default false, p_dbid varchar2 default null, p_inst_id varchar2 default null) is 
  l_scr clob := p_script;
  l_line varchar2(32765);
  l_eof number;
  l_iter number := 1;
begin
  if instr(l_scr,chr(10))=0 then 
    l_scr:=l_scr||chr(10);
    --raise_application_error(-20000,'Put at least one EOL into script.');
  end if;
  --set variable
  p_script:=replace(replace(replace(replace(replace(p_script,'&SQLID.',p_sqlid),'&SQLID',p_sqlid),'&1.',p_sqlid),'&1',p_sqlid),'&VSQL.','gv$sql'); 
  p_script:=replace(replace(replace(replace(p_script,'&INST_ID.',p_inst_id),'&INST_ID',p_inst_id),'&DBID.',p_dbid),'&DBID',p_dbid); 
  --remove sqlplus settings
  l_scr := p_script;
  p_script:=null;
  loop
    l_eof:=instr(l_scr,chr(10));
    l_line:=substr(l_scr,1,l_eof);
    
    if upper(l_line) like 'SET%' or 
       upper(l_line) like 'COL%' or
       upper(l_line) like 'BREAK%' or
       upper(l_line) like 'ALTER SESSION%' or
       upper(l_line) like 'SERVEROUTPUT%' or
       upper(l_line) like 'REM%' or
       upper(l_line) like '--%' 
    then
      null;
    else
      p_script:=p_script||l_line||chr(10);
    end if;
    
    if p_dbid is not null then
      if g_min is null or g_max is null then
        select nvl(min(snap_id),1) , nvl(max(snap_id),1e6)  into g_min, g_max from dba_hist_sqlstat where sql_id=p_sqlid and dbid=p_dbid;
      end if;
      p_script:=replace(replace(p_script,'&start_sn.',g_min),'&end_sn.',g_max);
    end if;
    
    l_scr:=substr(l_scr,l_eof+1);
    l_iter:=l_iter+1;
    exit when l_iter>1000000 or dbms_lob.getlength(l_scr)=0;
  end loop;
  if not p_plsql then p_script:=replace(p_script,';'); end if;
end;

procedure print_table_html(p_query in varchar2,
                           p_width number,
                           p_summary varchar2,
                           p_search varchar2 default null,
                           p_replacement varchar2 default null,
                           p_style1 varchar2 default 'awrc1',
                           p_style2  varchar2 default 'awrnc1',
                           p_header number default 0,
                           p_break_col varchar2 default null,
                           p_row_limit number default 10000) is
  l_theCursor   integer default dbms_sql.open_cursor;
  l_columnValue varchar2(32767);
  l_status      integer;
  l_descTbl     dbms_sql.desc_tab2;
  l_colCnt      number;
  l_rn          number := 0;
  l_style       varchar2(100);
  l_break_value varchar2(4000) := null;
  l_break_cnt   number := 1;
  type t_output_lines is table of varchar2(32767) index by pls_integer;
  l_output t_output_lines;
  l_widest number := 0;
  l_indx number := 1;
  procedure p(p_line varchar2) is
  begin
    l_output(l_indx):=p_line;
    l_indx := l_indx + 1;
  end;  
  procedure p1(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;
  procedure output is
  begin
    if l_output.count<=nvl(p_row_limit,1000) then
      for i in 1..l_output.count loop
        p1(l_output(i));
      end loop;
    else
      for i in 1..round(nvl(p_row_limit,1000)/2) loop
        p1(l_output(i));
      end loop;
      for i in l_output.count-round(nvl(p_row_limit,1000)/2)..l_output.count loop
        p1(l_output(i));
      end loop;   
      p1('Output is truncated: first and last '||round(nvl(p_row_limit,1000)/2)||' rows are shown');
    end if;    
  end;
begin
  p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="<width>" class="tdiff" summary="'||p_summary||'"'));

  dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
  dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

  for i in 1 .. l_colCnt loop
    dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
  end loop;

  l_status := dbms_sql.execute(l_theCursor);

  --column names
  p(HTF.TABLEROWOPEN);
  for i in 1 .. l_colCnt loop
    p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
  end loop;
  p(HTF.TABLEROWCLOSE);

  while (dbms_sql.fetch_rows(l_theCursor) > 0) loop
    p(HTF.TABLEROWOPEN);
    l_rn := l_rn + 1;
    --coloring for rows for breaking column value
    if p_break_col is null then
      l_style := case when mod(l_rn,2)=0 then p_style1 else p_style2 end;
    else
      for i in 1 .. l_colCnt loop
        dbms_sql.column_value(l_theCursor, i, l_columnValue);

        if p_break_col is not null and upper(p_break_col)=upper(l_descTbl(i).col_name) then
          if nvl(l_break_value,'$~') <> nvl(l_columnValue,'$~') then
            l_break_value:=l_columnValue;
            l_break_cnt:=l_break_cnt+1;
          end if;
        end if;

        if p_break_col is not null then
          l_style := case when mod(l_break_cnt,2)=0 then p_style1 else p_style2 end;
        end if;
      end loop;
    end if;
    -----------------------------------------------------------------------------
    for i in 1 .. l_colCnt loop
      dbms_sql.column_value(l_theCursor, i, l_columnValue);
      if l_colCnt = 1 and nvl(length(l_columnValue),0)>l_widest then l_widest:=length(l_columnValue); end if;
      l_columnValue:=replace(replace(l_columnValue,chr(13)||chr(10),chr(10)||'<br/>'),chr(10),chr(10)||'<br/>');
      if p_search is not null then
        if instr(l_descTbl(i).col_name,p_search)>0 then
          l_columnValue:=REGEXP_REPLACE(l_columnValue,'(.*)',p_replacement);
          p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        elsif regexp_instr(l_columnValue,p_search)>0 then
          l_columnValue:=REGEXP_REPLACE(l_columnValue,p_search,p_replacement);
          p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        else
          p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
        end if;
      else
        p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| l_style ||'"'));
      end if;
    end loop;
    p(HTF.TABLEROWCLOSE);
    if p_header > 0 then
      if mod(l_rn,p_header)=0 then
        p(HTF.TABLEROWOPEN);
        for i in 1 .. l_colCnt loop
          p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
        end loop;
        p(HTF.TABLEROWCLOSE);
      end if;
    end if;
  end loop;
  dbms_sql.close_cursor(l_theCursor);
  p(HTF.TABLECLOSE);
  if l_colCnt = 1 then
    l_output(1):=replace(l_output(1),'<width>',round(l_widest*8));
  end if;    
  l_output(1):=replace(l_output(1),'<width>',p_width);  
  output();
exception
  when others then
    if DBMS_SQL.IS_OPEN(l_theCursor) then dbms_sql.close_cursor(l_theCursor);end if;
    p(p_query);
    raise_application_error(-20000, 'print_table_html'||chr(10)||sqlerrm||chr(10)||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
end;

procedure print_text_as_table(p_text clob, p_t_header varchar2, p_width number, p_search varchar2 default null, p_replacement varchar2 default null, p_comparison boolean default false) is
  l_line varchar2(32765);  l_eof number;  l_iter number; l_length number;
  l_text clob;
  l_style1 varchar2(10) := 'awrc1';
  l_style2 varchar2(10) := 'awrnc1';
  
  l_style_comp1 varchar2(10) := 'awrcc1';
  l_style_comp2 varchar2(10) := 'awrncc1';  
  
  l_pref varchar2(10) := 'z';
  type t_output_lines is table of varchar2(32767) index by pls_integer;
  l_output t_output_lines;
  l_widest number := 0;
  l_indx number := 1;
  procedure p(p_line varchar2) is
  begin
    l_output(l_indx):=p_line;
    l_indx := l_indx + 1;
  end;    
  procedure p1(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;
  procedure output is
  begin
    for i in 1..l_output.count loop
      p1(l_output(i));
    end loop;
  end;  
begin
             
  p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="<width>" class="tdiff" summary="'||p_t_header||'"'));
  if p_t_header<>'#FIRST_LINE#' then
    p(HTF.TABLEROWOPEN);
    p(HTF.TABLEHEADER(cvalue=>replace(p_t_header,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
    p(HTF.TABLEROWCLOSE);
  end if;
  
  if instr(p_text,chr(10))=0 then
    l_iter := 1;
    l_length:=dbms_lob.getlength(p_text);
    loop
      l_text := l_text||substr(p_text,l_iter,200)||chr(10);
      l_iter:=l_iter+200;
      exit when l_iter>=l_length;
    end loop;
  else
    l_text := p_text||chr(10);
  end if;
  
  l_iter := 1; 
  loop
    l_eof:=instr(l_text,chr(10));
    l_line:=substr(l_text,1,l_eof);
    if nvl(length(l_line),0)>l_widest then l_widest:=length(l_line); end if;
    if p_t_header='#FIRST_LINE#' and l_iter = 1 then
      p(HTF.TABLEROWOPEN);
      p(HTF.TABLEHEADER(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="awrbg" scope="col"'));
      p(HTF.TABLEROWCLOSE);
    else
      p(HTF.TABLEROWOPEN);
      
      if p_comparison and substr(l_line,1,3)='~~*' then
        l_pref:=substr(l_line,1,7); 
        l_line:=substr(l_line,8);
        l_pref:=substr(l_pref,4,1);
      end if;
      
      if p_search is not null and regexp_instr(l_line,p_search)>0 then
        l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
      else
        l_line:=replace(l_line,' ','&nbsp;');
      end if;
      l_line:=replace(l_line,'`',' ');
      if p_comparison and l_pref in ('-') then
        p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style_comp1 else l_style_comp2 end ||'"'));
      else
        p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then l_style1 else l_style2 end ||'"'));
      end if;
      
      p(HTF.TABLEROWCLOSE);
    end if;
    l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
    exit when l_iter>10000000 or dbms_lob.getlength(l_text)=0;
  end loop;

  p(HTF.TABLECLOSE);
  
  if round(p_width/(l_widest*6.2))>1.1 then
    l_output(1):=replace(l_output(1),'<width>',round(l_widest*6.2));
  else
    l_output(1):=replace(l_output(1),'<width>',p_width);
  end if;
  output();  
end;

   procedure stim is
   begin
     if l_timing then
       l_time:=DBMS_UTILITY.GET_TIME;
       l_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME;
     end if;
   end;
   procedure etim(p_final boolean default false, p_marker varchar2 default null) is
   begin
     if l_timing then
       l_time:=DBMS_UTILITY.GET_TIME-l_time;l_tot_time:=l_tot_time+l_time;
       l_cpu_tim:=DBMS_UTILITY.GET_CPU_TIME-l_cpu_tim;l_tot_cpu_tim:=l_tot_cpu_tim+l_cpu_tim;
       p(HTF.header (6,cheader=>case when p_marker is not null then p_marker ||': ' else null end || 'Elapsed (sec): '||to_char(round((l_time)/100,2))||'; CPU (sec): '||to_char(round((l_cpu_tim)/100,2)),cattributes=>'class="awr"'));
       if p_final then
         p(HTF.header (6,cheader=>'TOTAL: Elapsed (sec): '||to_char(round((l_tot_time)/100,2))||'; CPU (sec): '||to_char(round((l_tot_cpu_tim)/100,2)),cattributes=>'class="awr"'));
       end if;
     end if;
   end;
   
begin
   p(HTF.HTMLOPEN);
   p(HTF.HEADOPEN);
   p(HTF.TITLE(l_sql_id));   
  
   p('<style type="text/css">');
   p(l_css);
   p('</style>');
   p(HTF.HEADCLOSE);
   p(HTF.BODYOPEN(cattributes=>'class="awr"'));
   
   p(HTF.header (1,'SQL Report for SQL_ID=~SQLID',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.BR);
   p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   if l_sect_sql_text or l_sect_db_desc or l_sect_vsql or l_sect_exadata or l_sect_workarea 
     then p(HTF.header (4,cheader=>'V$ performance data',cattributes=>'class="awr"')); end if;
   if l_sect_sql_text  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"'))); end if; 
   if l_sect_db_desc   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#db_desc',ctext=>'DB description',cattributes=>'class="awr"'))); end if;   
   if l_sect_vsql      then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#v_sql_stat',ctext=>'V$SQL statistics',cattributes=>'class="awr"'))); end if; 
   if l_sect_exadata   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"'))); end if; 
   if l_sect_workarea  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_workarea',ctext=>'SQL Workarea',cattributes=>'class="awr"'))); end if; 

   if l_sect_non_shared or l_sect_cbo_env
     then p(HTF.header (4,cheader=>'Optimizer',cattributes=>'class="awr"')); end if; 
   if l_sect_non_shared then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#non_shared',ctext=>'Non shared reason',cattributes=>'class="awr"'))); end if; 
   if l_sect_cbo_env   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#cbo_env',ctext=>'CBO environment',cattributes=>'class="awr"'))); end if; 

   if l_sect_dcl or l_sect_dcrac or l_sect_dcladv or l_sect_dcall or l_sect_dc_adapt or l_sect_awr_plans or l_sect_explain
     then p(HTF.header (4,cheader=>'Execution plans',cattributes=>'class="awr"')); end if; 
   if l_sect_dcl       then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"'))); end if; 
   if l_sect_dcrac     then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"'))); end if; 
   if l_sect_dcladv    then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"'))); end if; 
   if l_sect_dcall     then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"'))); end if; 
   if l_sect_dc_adapt  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"'))); end if; 
   if l_sect_awr_plans then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Display cursor AWR',cattributes=>'class="awr"'))); end if;
   if l_sect_explain   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Display Explain plan',cattributes=>'class="awr"'))); end if;  
   
   if l_sect_sqlmon or l_sect_sqlmonh
     then p(HTF.header (4,cheader=>'SQL Monitor',cattributes=>'class="awr"')); end if; 
   if l_sect_sqlmon    then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"'))); end if; 
   if l_sect_sqlmonh   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"'))); end if; 
   
   if l_sect_sql_stat or l_sect_binds 
     then p(HTF.header (4,cheader=>'AWR Statistics',cattributes=>'class="awr"')); end if;
   if l_sect_sql_stat  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_stat',ctext=>'SQL statistics',cattributes=>'class="awr"'))); end if;
   if l_sect_binds     then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#binds',ctext=>'Bind values',cattributes=>'class="awr"'))); end if;
   
   if l_sect_vashsum or l_sect_vashesum or l_sect_plsql_v or l_sect_plsql or l_sect_ash_summ or l_sect_ash_p1 or l_sect_ash_p2 or l_sect_ash_p3 
     then p(HTF.header (4,cheader=>'Active session history',cattributes=>'class="awr"')); end if;   
   if l_sect_vashsum   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_p3_1',ctext=>'V$ASH summary',cattributes=>'class="awr"'))); end if; 
   if l_sect_vashesum  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_p3',ctext=>'V$ASH execs summary',cattributes=>'class="awr"'))); end if; 
   if l_sect_plsql_v   then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_plsql',ctext=>'V$ASH PL/SQL callers',cattributes=>'class="awr"')));end if;   
   if l_sect_plsql     then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_plsql',ctext=>'AWR ASH PL/SQL callers',cattributes=>'class="awr"'))); end if;
   if l_sect_ash_summ  then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_summ',ctext=>'AWR ASH summary',cattributes=>'class="awr"')));  end if;  
   if l_sect_ash_p1    then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"'))); end if;
   if l_sect_ash_p2    then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p2',ctext=>'AWR ASH (SQL Monitor) P2',cattributes=>'class="awr"'))); end if;
   if l_sect_ash_p3    then p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'AWR ASH (SQL Monitor) P3',cattributes=>'class="awr"'))); end if;
   
   p(HTF.BR);    
   p(HTF.BR); 
--======================================================================================================================================================================================   
   if l_sect_sql_text or l_sect_db_desc or l_sect_vsql or l_sect_exadata or l_sect_workarea 
     then 
	  p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$ performance data',cname=>'tblofcont_vdata',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"'))); 
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#db_desc',ctext=>'DB description',cattributes=>'class="awr"')));    
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#v_sql_stat',ctext=>'V$SQL statistics',cattributes=>'class="awr"')));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"')));  
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_workarea',ctext=>'SQL Workarea',cattributes=>'class="awr"')));
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
   end if; 
   
   if l_sect_sql_text then
      --SQL TEXT   
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL text',cname=>'sql_text',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_getftxt,l_sql_id);
      open l_crsr for l_getftxt;
      fetch l_crsr into l_plsql_output;
      close l_crsr;
      print_text_as_table(p_text=>l_plsql_output,p_t_header=>'SQL text',p_width=>500);
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);  
   end if; 
   
   --DB description
   if l_sect_db_desc   then 
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'DB description',cname=>'db_desc',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
       p(HTF.BR);
       l_sql:=q'[select unique INSTANCE_NUMBER INST_ID, DB_NAME,dbid,version,host_name,platform_name from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=']'||l_sql_id||q'[')]'||chr(10);
       prepare_script(l_sql,l_sql_id);
       print_table_html(l_sql,1000,'DB description');
       etim();
       p(HTF.BR);
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
       p(HTF.BR);
       p(HTF.BR);     
   end if; 
   
   if l_sect_vsql then    
      --V$SQL statistics
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$SQL statistics',cname=>'v_sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_vsql_stat,l_sql_id, p_plsql=>true);
      l_vsql_stat:=replace(l_vsql_stat,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
      l_plsql_output:=null;
      execute immediate l_vsql_stat using in out l_plsql_output;
      l_plsql_output:=replace(replace(l_plsql_output,'&_USER.','~_USER.'),'&_CONNECT_IDENTIFIER.','~_CONNECT_IDENTIFIER.');
      
      --l_plsql_output:=REGEXP_REPLACE(l_plsql_output,'CHILD_NUMBER=([[:digit:]])',HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
      
      print_text_as_table(p_text=>l_plsql_output,p_t_header=>'V$SQL',p_width=>600, p_search=>'CHILD_NUMBER=([[:digit:]]*)',p_replacement=>HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);
   end if; 
   
   if l_sect_exadata then    
      --Exadata statistics
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Exadata statistics',cname=>'exadata',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_offload_percent1,l_sql_id);
      print_table_html(l_offload_percent1,1000,'Exadata statistics #1');
      p(HTF.BR);
      prepare_script(l_offload_percent2,l_sql_id);
      print_table_html(l_offload_percent2,1000,'Exadata statistics #2'); 
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);   
   end if;    
   
   if l_sect_workarea then    
      --SQL Workarea
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Workarea',cname=>'sql_workarea',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_sqlwarea,l_sql_id);
      print_table_html(l_sqlwarea,1000,'SQL Workarea');
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_vdata',ctext=>'Back to V$ performance data',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);   
   end if; 
--======================================================================================================================================================================================   
   if l_sect_non_shared or l_sect_cbo_env
     then 
	  p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Optimizer',cname=>'tblofcont_optimiz',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#non_shared',ctext=>'Non shared reason',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#cbo_env',ctext=>'CBO environment',cattributes=>'class="awr"')));
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
   end if; 
	
   if l_sect_non_shared then   
      --Non shared
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Non shared reason',cname=>'non_shared',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_optimiz',ctext=>'Back to Optimizer',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_nonshared1,l_sql_id);
      print_table_html(l_nonshared1,1000,'Non shared reason');
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_optimiz',ctext=>'Back to Optimizer',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);
   end if; 

   if l_sect_cbo_env then    
      --CBO environment
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'CBO environment',cname=>'cbo_env',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_optimiz',ctext=>'Back to Optimizer',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_optenv,l_sql_id);
      print_table_html(l_optenv,1000,'CBO environment');
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_optimiz',ctext=>'Back to Optimizer',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);  
   end if; 
--======================================================================================================================================================================================   
   if l_sect_dcl or l_sect_dcrac or l_sect_dcladv or l_sect_dcall or l_sect_dc_adapt or l_sect_awr_plans or l_sect_explain then    
      --Execution plans
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Execution plans',cname=>'tblofcont_plans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#awrplans',ctext=>'Display cursor AWR',cattributes=>'class="awr"')));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#epplan',ctext=>'Display Explain plan',cattributes=>'class="awr"')));
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
   end if; 
   
   if l_sect_dcl then    
      --Display cursor (last)
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (last)',cname=>'dp_last',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ALLSTATS +peeked_binds'))]'||chr(10);
      prepare_script(l_sql,l_sql_id);
      print_table_html(l_sql,1500,'Display cursor (last)','child number ([[:digit:]]*)',HTF.ANCHOR(curl=>'#child_all_\1',ctext=>'child number \1',cname=>'child_last_\1',cattributes=>'class="awr"'));
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);  
   end if; 
   
   if l_sect_dcrac then   
      --Display cursor (RAC)
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (RAC)',cname=>'dp_rac',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_rac_plans,l_sql_id);
      print_table_html(l_rac_plans,1500,'Display cursor (RAC)');
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);   
   end if; 
   
   if l_sect_dcladv then    
      --Display cursor (LAST ADVANCED)
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (LAST ADVANCED)',cname=>'dp_last_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ADVANCED'))]'||chr(10);
      prepare_script(l_sql,l_sql_id);
      print_table_html(l_sql,1500,'Display cursor (LAST ADVANCED)');
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);   
   end if; 
   
   if l_sect_dcall then    
      --Display cursor (ALL)
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ALL)',cname=>'dp_all',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'ALL ALLSTATS +peeked_binds'))]'||chr(10);
      prepare_script(l_sql,l_sql_id);
      print_table_html(l_sql,2000,'Display cursor (ALL)','child number ([[:digit:]]*)',HTF.ANCHOR(curl=>'',ctext=>'child number \1',cname=>'child_all_\1',cattributes=>'class="awr"'));
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);
   end if; 
   
   if l_sect_dc_adapt then    
      --Display cursor (ADAPTIVE)
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ADAPTIVE)',cname=>'dp_adaptive',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      l_sql:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive LAST ALLSTATS +peeked_binds'))]'||chr(10);
      prepare_script(l_sql,l_sql_id);
      print_table_html(l_sql,1500,'Display cursor (ADAPTIVE)');
      p(HTF.BR);   
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);
      l_sql:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'))]'||chr(10);
      prepare_script(l_sql,l_sql_id);
      print_table_html(l_sql,2000,'Display cursor (ADAPTIVE)');   
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR); 
   end if; 

   if l_sect_awr_plans then
       stim();
	   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor AWR',cname=>'awrplans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
       p(HTF.BR);   
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         l_sql:=q'[select * from table(dbms_xplan.display_awr(']'||l_sql_id||q'[', null, ]'||i.dbid||q'[, 'ADVANCED'))]'||chr(10);
         prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid);
         print_table_html(l_sql,1500,'AWR SQL execution plans','Plan hash value: ([[:digit:]]*)',HTF.ANCHOR(curl=>'#epplan_\1',ctext=>'Plan hash value: \1',cname=>'awrplan_\1',cattributes=>'class="awr"'));
         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);
   end if;
   
   --Explain plan
   if l_sect_explain   then
       stim();
       p(HTF.BR);
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display Explain plan',cname=>'tblofcont_epplan',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
       p(HTF.BR);
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ep_simple',ctext=>'Explain plan (simple)',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ep_adv',ctext=>'Explain plan (advanced)',cattributes=>'class="awr"')));

       p(HTF.BR);p(HTF.BR);
       
       begin
         select x.sql_text into l_sql from dba_hist_sqltext x where sql_id=l_sql_id and rownum=1;
         delete from plan_table;
         execute immediate 'explain plan for '||chr(10)||l_sql;
       exception
         when others then p(sqlerrm);
       end;
       
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Explain plan (simple)',cname=>'ep_simple',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
       l_sql:=q'[select * from table(dbms_xplan.display());]'||chr(10);
       prepare_script(l_sql,l_sql_id);
       print_table_html(l_sql,1500,'Explain plan','Plan hash value: ([[:digit:]]*)',HTF.ANCHOR(curl=>'#epplanadv_\1',ctext=>'Plan hash value: \1',cname=>'epplan_\1',cattributes=>'class="awr"'));
       p(HTF.BR);p(HTF.BR);
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_epplan',ctext=>'Back to Explain plan',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Execution plans',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
       p(HTF.BR);p(HTF.BR);
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Explain plan (advanced)',cname=>'ep_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
       l_sql:=q'[select * from table(dbms_xplan.display(null,null,'ADVANCED',null));]'||chr(10);
       prepare_script(l_sql,l_sql_id);
       print_table_html(l_sql,1500,'Explain plan','Plan hash value: ([[:digit:]]*)',HTF.ANCHOR(curl=>'',ctext=>'Plan hash value: \1',cname=>'epplanadv_\1',cattributes=>'class="awr"'));
       etim();
       p(HTF.BR);p(HTF.BR);
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_epplan',ctext=>'Back to Explain plan',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Execution plans',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
       p(HTF.BR);   
       p(HTF.BR);
       rollback;
   end if;
--======================================================================================================================================================================================
   if l_sect_sqlmon or l_sect_sqlmonh then
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor',cname=>'sqlmons',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"'))); 
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"'))); 
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);   
   end if; 
   
   if l_sect_sqlmon then    
      --SQL Monitor report
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report (11g+)',cname=>'sql_mon',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlmons',ctext=>'Back to SQL Monitor',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      prepare_script(l_sqlmon1,l_sql_id, p_plsql=>true);
      l_sqlmon1:=replace(l_sqlmon1,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
      l_plsql_output:=null;
      execute immediate l_sqlmon1 using in out l_plsql_output;
      print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report',p_width=>600);
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlmons',ctext=>'Back to SQL Monitor',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
      p(HTF.BR);   
   end if; 
   
   if l_sect_sqlmonh then    
      --SQL Monitor report history
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report history (12c+)',cname=>'sql_mon_hist',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlmons',ctext=>'Back to SQL Monitor',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      g_min := null;
      g_max := null;
      prepare_script(p_script => l_sqlmon_hist, p_sqlid => l_sql_id, p_plsql=> true, p_dbid => 0);
      l_sqlmon_hist:=replace(l_sqlmon_hist,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
      --p(l_sqlmon1);
      l_plsql_output:=null;
      begin
        execute immediate l_sqlmon_hist using in out l_plsql_output;
      exception
        when others then l_plsql_output:=sqlerrm;
      end;
      print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report history',p_width=>600);
      etim();
      p(HTF.BR);   
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sqlmons',ctext=>'Back to SQL Monitor',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   end if; 
--======================================================================================================================================================================================
   if l_sect_sql_stat or l_sect_binds then
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR Statistics',cname=>'tblofcont_sqlstats',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_stat',ctext=>'SQL statistics',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#binds',ctext=>'Bind values',cattributes=>'class="awr"'))); 
	  p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR); 
   end if;
   
   --SQL statistics
   if l_sect_sql_stat  then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL statistics',cname=>'sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_sqlstats',ctext=>'Back to AWR Statistics',cattributes=>'class="awr"')));
       p(HTF.BR);
       p('POE - per one exec, time in milliseconds (1/1000 of second)');
       p(HTF.BR);
       for i in (select unique dbid,INSTANCE_NUMBER from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1,2)
       loop
         p('DBID: '||i.dbid||'; INST_ID: '||i.INSTANCE_NUMBER);
         l_sql:=l_sqlstat;
         prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid,p_inst_id=>i.INSTANCE_NUMBER); 
         print_table_html(l_sql,1000,'SQL statistics',p_style1 =>'awrncbbt',p_style2 =>'awrcbbt',p_search=>'PLAN_HASH',p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),p_header=>50);

         p(HTF.BR);
		 p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_sqlstats',ctext=>'Back to AWR Statistics',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);
   end if;
   
   --Bind values
   if l_sect_binds     then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Bind values',cname=>'binds',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_sqlstats',ctext=>'Back to AWR Statistics',cattributes=>'class="awr"')));
       p(HTF.BR);
       l_sql:=q'[select snap_id snap, name, datatype_string,to_char(last_captured,'yyyy/mm/dd hh24:mi:ss') last_captured, value_string from dba_hist_sqlbind where sql_id=']'||l_sql_id||q'[' order by snap_id,position;]'||chr(10);
       prepare_script(l_sql,l_sql_id);
       print_table_html(l_sql,1000,'Bind values',p_header=>50);
       etim();
       p(HTF.BR);
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_sqlstats',ctext=>'Back to AWR Statistics',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
       p(HTF.BR);
       p(HTF.BR);   
   end if;
--======================================================================================================================================================================================   
   if l_sect_vashsum or l_sect_vashesum or l_sect_plsql_v or l_sect_plsql or l_sect_ash_summ or l_sect_ash_p1 or l_sect_ash_p2 or l_sect_ash_p3 then 
     p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Active session history',cname=>'tblofcont_ash',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
     p(HTF.BR);
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_p3_1',ctext=>'V$ASH summary',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_p3',ctext=>'V$ASH execs summary',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#vash_plsql',ctext=>'V$ASH PL/SQL callers',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_plsql',ctext=>'AWR ASH PL/SQL callers',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_summ',ctext=>'AWR ASH summary',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p1',ctext=>'AWR ASH (SQL Monitor) P1',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p2',ctext=>'AWR ASH (SQL Monitor) P2',cattributes=>'class="awr"')));
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#ash_p3',ctext=>'AWR ASH (SQL Monitor) P3',cattributes=>'class="awr"')));
	 p(HTF.BR);
     p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
     p(HTF.BR); 
   end if;
   
   if l_sect_vashsum then 
      --AWR ASH (SQL Monitor) P3_1
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$ASH summary',cname=>'vash_p3_1',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      p('V$ASH totals by PLAN STEP ID');
      p(HTF.BR);
      l_sql:=l_ash_p3_1;
      prepare_script(l_sql,l_sql_id); 
      print_table_html(l_sql,1500,'ASH summary',
                       p_style1 =>'awrncbbt',
						p_style2 =>'awrcbbt',
						--p_search=>'PLAN_HASH',
						--p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
						p_header=>50,
						p_break_col=>'ID');
      etim();
      p(HTF.BR);
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
   end if; 
   
   if l_sect_vashesum then    
      --AWR ASH (SQL Monitor) P3
      p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$ASH execs summary',cname=>'vash_p3',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	  p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
      p(HTF.BR);
      stim();
      p('V$ASH totals by EXEC START DATE and PLAN STEP ID');
      p(HTF.BR);
      l_sql:=l_ash_p3;
      prepare_script(l_sql,l_sql_id); 
      print_table_html(l_sql,1500,'ASH',
                       p_style1 =>'awrncbbt',
						p_style2 =>'awrcbbt',
						--p_search=>'PLAN_HASH',
						--p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),
						p_header=>50,
						p_break_col=>'SQL_EXEC_START');
      etim();
      p(HTF.BR);
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));	  
      p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
      p(HTF.BR);
   end if; 

   --V$ASH PL/SQL
   if l_sect_plsql_v     then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$ASH PL/SQL callers',cname=>'vash_plsql',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         if sys_context('USERENV','CON_ID')=0 then --in multitenant it runs forever
           l_sql:=q'[select * from dba_procedures where (object_id,subprogram_id) in (select unique plsql_entry_object_id,plsql_entry_subprogram_id from gv$active_session_history where sql_id = ']'||l_sql_id||q'[')]'||chr(10);
           prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid); 
           print_table_html(l_sql,1500,'ASH PL/SQL',p_style1 =>'awrc1',p_style2 =>'awrnc1');
         else
           p('No PL/SQL source data for multitenant DB.');
         end if;

         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);     
   end if;
   
   --AWR ASH PL/SQL
   if l_sect_plsql     then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH PL/SQL callers',cname=>'ash_plsql',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         if sys_context('USERENV','CON_ID')=0 then --in multitenant it runs forever
           l_sql:=q'[select * from dba_procedures where (object_id,subprogram_id) in (select unique plsql_entry_object_id,plsql_entry_subprogram_id from dba_hist_active_sess_history where instance_number between 1 and 255 and snap_id between &start_sn. and &end_sn. and sql_id = ']'||l_sql_id||q'[' and dbid= ]'||i.dbid||q'[)]'||chr(10);
           prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid); 
           print_table_html(l_sql,1500,'ASH PL/SQL',p_style1 =>'awrc1',p_style2 =>'awrnc1');
         else
           p('No PL/SQL source data for multitenant DB.');
         end if;

         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);     
   end if;

   --ASH summary
   if l_sect_ash_summ  then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH summary',cname=>'ash_summ',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         l_sql:=l_ash_summ;
         prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid); 
         print_table_html(l_sql,1500,'ASH summary',p_style1 =>'awrncbbt',p_style2 =>'awrcbbt',p_search=>'PLAN_HASH',p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),p_header=>50);

         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);   
   end if;   

   --AWR ASH (SQL Monitor) P1
   if l_sect_ash_p1    then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P1',cname=>'ash_p1',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       p('AWR ASH totals by PLAN_HASH and PLAN STEP ID');
       p(HTF.BR);
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         l_sql:=l_ash_p1_1;
         prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid); 
         print_table_html(l_sql,1500,'AWR ASH (SQL Monitor) P1',p_style1 =>'awrncbbt',p_style2 =>'awrcbbt',p_search=>'PLAN_HASH',p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),p_header=>50,p_break_col=>'ID');

         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);
   end if;
   
   --AWR ASH (SQL Monitor) P2
   if l_sect_ash_p2    then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P2',cname=>'ash_p2',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       p('AWR ASH totals by EXEC START DATE and PLAN STEP ID');
       p(HTF.BR);
       for i in (select unique dbid from dba_hist_database_instance where dbid in (select dbid from dba_hist_sqltext where sql_id=l_sql_id) order by 1)
       loop
         p('DBID: '||i.dbid);
         l_sql:=l_ash_p2;
         prepare_script(l_sql,l_sql_id,p_dbid=>i.dbid); 
         print_table_html(l_sql,1500,'AWR ASH (SQL Monitor) P2',p_style1 =>'awrncbbt',p_style2 =>'awrcbbt',p_search=>'PLAN_HASH',p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),p_header=>50,p_break_col=>'SQL_EXEC_START');

         p(HTF.BR);
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
         p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
         p(HTF.BR);
       end loop;
       etim();
       p(HTF.BR);
       p(HTF.BR);
   end if;

   --AWR ASH (SQL Monitor) P3
   if l_sect_ash_p1    then
       stim();
       p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'AWR ASH (SQL Monitor) P3',cname=>'ash_p3',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
	   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.BR);
       p('V$ASH totals by EXEC START DATE and PLAN STEP ID');
       p(HTF.BR);
       l_sql:=l_ash_p3;
       prepare_script(l_sql,l_sql_id); 
       print_table_html(l_sql,1500,'AWR ASH (SQL Monitor) P3',p_style1 =>'awrncbbt',p_style2 =>'awrcbbt',p_search=>'PLAN_HASH',p_replacement=>HTF.ANCHOR (curl=>'#awrplan_\1',ctext=>'\1',cattributes=>'class="awr"'),p_header=>50,p_break_col=>'SQL_EXEC_START');

       p(HTF.BR);
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_ash',ctext=>'Back to ASH',cattributes=>'class="awr"')));
       p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
       p(HTF.BR);
       etim(true);
       p(HTF.BR);
       p(HTF.BR);   
   end if;
--======================================================================================================================================================================================   
   p(HTF.BR);
   p(HTF.BR);
   p((HTF.BODYCLOSE));
   p((HTF.HTMLCLOSE));
end;
/
set serveroutput off
set define "&"
set timing on

spool off

set termout on
set verify on


--=====================
set define "&"
set verify off
set feedback on
prompt ============================================ Recursive SQLs ==========================================
select sql_id, count(1) cnt from gv$active_session_history where top_level_sql_id='&SQLID' and sql_id<>'&SQLID'
group by sql_id
order by 2 desc;

set heading off
set echo off
set timing off
set feedback off

spool _tmp_vsql_rec_sql_&SQLID..sql
select 'host mkdir sqlid_&SQLID._recursive_sqls'||chr(10)||'@&selfscriptname. ' ||sql_id||chr(10)||'set termout off'||chr(10)||
       'host move sql_data_*'||sql_id||'.html .\sqlid_&SQLID._recursive_sqls'||chr(10)||
	   'host mv sql_data_*'||sql_id||'.html .\sqlid_&SQLID._recursive_sqls'
  from (select sql_id, count(1) cnt
          from v$active_session_history
         where top_level_sql_id = '&SQLID'
           and sql_id<>top_level_sql_id
         group by sql_id
        having count(1) > 60
/*		 union all
        select sql_id, count(1)*10 cnt
          from dba_hist_active_sess_history
         where top_level_sql_id = '&SQLID'
         group by sql_id
        having count(1) >= 6*/
         order by cnt desc)
where sql_id<>'&SQLID';

prompt define SQLID=&SQLID

spool off

@_tmp_vsql_rec_sql_&SQLID..sql

--ignore OS depended errors
host del _tmp_vsql_rec_sql_&SQLID..sql
host rm _tmp_vsql_rec_sql_&SQLID..sql

set heading on
set verify on
set timing on
set feedback on

--=====================
undefine SQLID

SET SQLBL OFF
set termout on
set verify on
set feedback on
set timing on