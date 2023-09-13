/*
* WAITS
*  Control tracing of the operating system calls that your Oracle kernel process makes.
*   • TRUE (the default) enables syscall tracing (page 97).
*   • FALSE suppresses syscall tracing.
* 
* BINDS
*  Control tracing of the BINDS operations that bind values to SQL text placeholders.
*   • TRUE enables binds tracing (page 100).
*   • FALSE (the default) suppresses binds tracing.
* 
* PLAN_STAT
*  The PLAN_STAT argument controls how often Oracle prints an execution plan for your session.
*   • 'FIRST_EXECUTION' (the default) prints a plan for only the first EXEC of each SQL statement.
*   • 'ALL_EXECUTIONS' prints a plan for each EXEC of each SQL statement.
*   • 'NEVER' disables execution plan tracing.
*/

alter session set tracefile_identifier=&1.;
@trfile

begin
  DBMS_SESSION.SESSION_TRACE_ENABLE(WAITS => &2., BINDS => &3., PLAN_STAT => '&4.');
end;
/

prompt Extended SQL Trace started: WAITS => &2., BINDS => &3., PLAN_STAT => '&4.'