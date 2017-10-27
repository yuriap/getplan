set lines 1000
set pages 9999
COL asqlmon_operation FOR a100
COL asqlmon_predicates FOR a100 word_wrap
COL options   FOR a30
COL projection FOR A500 noprint

col LAST_STARTS head "Starts" for 9999999
col LAST_OUTPUT_ROWS  head "A-rows" for 99999999
col LAST_CR_BUFFER_GETS head "Buffers" for 999999999
col LAST_CU_BUFFER_GETS head "Current" for 999999999
col LAST_DISK_READS head "Disk" for 9999999
col LAST_DISK_WRITES head "Writes" for 9999999
col LAST_ELAPSED_TIME_SEC head "Ela" for 99999D99
col obj_alias_qbc_name for a55 word_wrap
col id for 999

BREAK ON asqlmon_operation

--spool flat_&1._&2..txt
--set termout off
SELECT
   plan.id
  , LPAD(' ', depth) || plan.operation ||' '|| plan.options || NVL2(plan.object_name, ' ['||plan.object_name ||']', null) asqlmon_operation
  , plan.LAST_STARTS , plan.LAST_OUTPUT_ROWS , plan.LAST_CR_BUFFER_GETS , plan.LAST_CU_BUFFER_GETS
  , plan.LAST_DISK_READS , plan.LAST_DISK_WRITES
  , round(plan.LAST_ELAPSED_TIME/1000000, 2) LAST_ELAPSED_TIME_SEC
  , plan.object_alias || CASE WHEN plan.qblock_name IS NOT NULL THEN ' ['|| plan.qblock_name || ']' END obj_alias_qbc_name
  , CASE WHEN plan.access_predicates IS NOT NULL THEN '[A:] '|| plan.access_predicates END || CASE WHEN plan.filter_predicates IS NOT NULL THEN ' [F:]' || plan.filter_predicates END asqlmon_predicates
  , plan.projection
FROM
    v$sql_plan_statistics_all plan
WHERE
plan.sql_id LIKE '&1'
AND plan.child_number = &2
ORDER BY
    plan.child_number
  , plan.plan_hash_value
  , plan.id;
--spool off
--set termout on