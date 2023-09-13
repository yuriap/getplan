set timing off
@pars

set verify off
@start10046 &1 TRUE TRUE ALL_EXECUTIONS

prompt .
prompt .
prompt .
prompt Query started...
set termout off
set timing on
TIMING START SQL_TIMER


@&1

set termout on

prompt .
TIMING STOP
prompt .
prompt Query finished.
prompt .
prompt .
prompt .

set timing off

@stop10046

rollback;

set verify on
set timing on