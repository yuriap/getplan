column CHILD_NUMBER format 999 HEA 'CHLD#'
column POLICY format a10
column OPERATION_ID format 999 HEA 'OPER'
column OPERATION_TYPE format a30 word_wrap HEA 'OPERATION'
column estimated_optimal_size HEA 'EST_OPTIM'
column estimated_onepass_size HEA 'EST_ONEPA'
column last_memory_used HEA 'MEM_USED'
column last_execution format a10 HEA 'LST_EXE'
column last_degree format 999 HEA 'LST_DEGREE'
column total_executions format 999g999g999 HEA 'TOT_EXE'
column optimal_executions format 999g999g999 HEA 'OPT_EXE'
column onepass_executions format 999g999g999 HEA 'ONEP_EXE'
column multipasses_executions format 999g999g999 HEA 'MULT_EXE'
column active_time HEA 'ACTIVE_TIM'
column max_tempseg_size HEA 'MAX_TMP'
column last_tempseg_size HEA 'LAST_TMP'

BREAK on inst_id ON child_number on policy

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

