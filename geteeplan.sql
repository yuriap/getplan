set pages 9999
set lines 300
--set termout on
select * from table(dbms_xplan.display());
select * from table(dbms_xplan.display(null,null,'ADVANCED',null));
--set termout on
rollback;
