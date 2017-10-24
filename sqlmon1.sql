set long 1000000
SET LONGC 1024
select dbms_sqltune.report_sql_monitor(sql_id=>'&1',report_level=>'ALL') from dual;


