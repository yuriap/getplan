set timing off
set heading on
prompt ========================================= FULL SQL TEXT =========================================
@__getftxt &SQLID
prompt ====================================== NON SHARED REASON ========================================
@__nonshared1 &SQLID
select banner from v$version where banner like 'Oracle Database%';
prompt ===================================== RUNTIME STAT FROM V$SQL ===================================
define VSQL=gv$sql
alter session set nls_numeric_characters='. ';
set serveroutput on
@__vsql_stat.sql &SQLID
/
set serveroutput off
prompt ============================================= Exadata Statistics ================================
@__offload_percent1 &SQLID
@__offload_percent2 &SQLID
prompt ======================================== SQL MONITOR(11g+) ======================================
set serveroutput on
@__sqlmon1 &SQLID
/
set serveroutput off
prompt =============================================== SQL WorkArea ====================================
@__sqlwarea &SQLID
prompt ================================================== CBO Env ======================================
@__optenv &SQLID
prompt ====================================== DISPLAY_CURSOR (LAST) ====================================
select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ALLSTATS +peeked_binds'));
prompt ====================================== DISPLAY_CURSOR (RAC)  ====================================
@__rac_plans
prompt ====================================== DISPLAY_CURSOR (LAST ADVANCED) ===========================
select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ADVANCED'));
prompt ====================================== DISPLAY_CURSOR (ALL) =====================================
select * from table(dbms_xplan.display_cursor('&SQLID', null, 'ALL ALLSTATS +peeked_binds'));
prompt ====================================== DISPLAY_CURSOR (Adaptive) ================================
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive LAST ALLSTATS +peeked_binds'));
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'));
prompt ===================================== SQL MONITOR Hist(12c+) ====================================
set serveroutput on
@__sqlmon_hist
/
set serveroutput off
set timing on