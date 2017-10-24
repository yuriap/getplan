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

select inst_id,child_number,policy,operation_id,operation_type,
estimated_optimal_size,estimated_onepass_size,last_memory_used,last_execution,last_degree,
total_executions,optimal_executions,onepass_executions,multipasses_executions,active_time,max_tempseg_size,last_tempseg_size
 from gv$sql_workarea where sql_id='&1'
order by  inst_id,child_number,operation_id;
