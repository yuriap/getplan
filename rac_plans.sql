BREAK on inst_id ON CH#

column inst_id format 999 heading "INST"
column CH# format 999
select i.inst_id,i.CHILD_NUMBER CH#,y.plan_table_output
  from gv$sql i,
       table(dbms_xplan.display('gv$sql_plan_statistics_all',
                                null,
                                'LAST ALLSTATS +peeked_binds',
                                'inst_id=' || i.inst_id || ' and sql_id=''' ||
                                i.sql_id || ''' and CHILD_NUMBER=' ||
                                i.CHILD_NUMBER)) y
 where sql_id = '&SQLID'
;