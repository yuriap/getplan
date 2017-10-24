set pages 9999
set lines 300
--set termout on
rem prompt dbms_xplan.display()
select * from table(dbms_xplan.display());
rem prompt dbms_xplan.display(null,null,'+metrics')
rem select * from table(dbms_xplan.display(null,null,'+metrics'));
prompt dbms_xplan.display(null,null,'ADVANCED',null)
select * from table(dbms_xplan.display(null,null,'ADVANCED',null));
--set termout on
