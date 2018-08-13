@statsnap2_flt.sql

set feedback off
set heading off
set termout off
set timing off
set verify off

column a1 format a80
column a2 format a80
column a3 format a80
column a4 format a80

spool _tmp_sesstat_&envr2._&1..sql

set define off
prompt spool &envr2._&1._sqlid_&SQLID._sesstat.txt append
set define on
prompt set feedback off
prompt set timing off
prompt set termout off

prompt set serveroutput on

prompt column start_ts format a40
prompt column end_ts format a40
prompt column sid format a7
prompt column username format a74

prompt prompt Filters ============================================================================================================================================================
prompt prompt Statistics filter: "&stat_flt."
prompt prompt Events filter:     "&ev_flt."
prompt prompt ====================================================================================================================================================================

select 'select '''||systimestamp||''' start_ts, systimestamp end_ts, sys_context(''USERENV'',''SID'') sid, user username from dual;' from dual;

prompt declare
prompt   type t_stat is table of number index by varchar2(100);;
prompt   snap1 t_stat;;
prompt   snap2 t_stat;;
prompt   totwait1 t_stat;;
prompt   totwait2 t_stat;;
prompt   avgwait1 t_stat;;
prompt   avgwait2 t_stat;;
prompt   maxwait1 t_stat;;
prompt   maxwait2 t_stat;;
prompt   timwait1 t_stat;;
prompt   timwait2 t_stat;;
prompt   indx varchar2(100);;
prompt   l_row varchar2(4000);;
prompt procedure init
prompt is
prompt begin
select 'snap1('''||replace(name,'''','"')||'''):='||value||';' a from v$statname n, v$sesstat s 
where s.statistic#=n.statistic#
and sid=sys_context('USERENV','SID') and value>0 &stat_flt.
order by name;
select 
'totwait1('''||replace(event,'''','"')||'''):='||total_waits||';' a1 ,
'avgwait1('''||replace(event,'''','"')||'''):='||average_wait||';' a2 ,
'maxwait1('''||replace(event,'''','"')||'''):='||max_wait||';' a3 ,
'timwait1('''||replace(event,'''','"')||'''):='||time_waited_micro||';' a4
from V$SESSION_EVENT 
where sid=sys_context('USERENV','SID') &ev_flt.
order by event;
prompt end;;
prompt procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg);end;;
prompt begin
prompt   init();;
prompt   for i in (select replace(name,'''','"')name,value from v$statname n, v$sesstat s where s.statistic#=n.statistic# and sid=sys_context('USERENV','SID') and value>0 &stat_flt.)
prompt   loop
prompt     snap2(i.name):=i.value;;
prompt   end loop;;
prompt   for i in (select replace(event,'''','"')event,total_waits,average_wait,max_wait,time_waited_micro from V$SESSION_EVENT where sid=sys_context('USERENV','SID') &ev_flt.)
prompt   loop
prompt     totwait2(i.event):=i.total_waits;;
prompt     avgwait2(i.event):=i.average_wait;;
prompt     maxwait2(i.event):=i.max_wait;;
prompt     timwait2(i.event):=i.time_waited_micro;;
prompt   end loop;;
prompt   p('====================================================================================================================================================================');;
prompt   indx:=snap2.first;;
prompt   while indx is not null loop
prompt     if snap1.exists(indx) then
prompt       if snap2(indx)-snap1(indx)>0 then
prompt         p(rpad(indx,60,'.')||':'||lpad(to_char(snap2(indx)-snap1(indx)),25,' '));;
prompt       end if;;
prompt     else
prompt       p(rpad(indx,60,'.')||':'||lpad(to_char(snap2(indx)),25,' '));;
prompt     end if;;
prompt     indx:=snap2.next(indx);;
prompt   end loop;;
prompt   p('====================================================================================================================================================================');;
prompt   p(rpad('Event',60,' ')||' '||lpad('Total waits',25,' ')||' '||lpad('Average wait, sec',25,' ')||' '||lpad('Max wait, sec',25,' ')||' '||lpad('Total time wait, sec',25,' '));;
prompt   p(rpad('-',60,'-')||' '||lpad('-',25,'-')||' '||lpad('-',25,'-')||' '||lpad('-',25,'-')||' '||lpad('-',25,'-'));;
prompt   indx:=totwait2.first;;
prompt   while indx is not null loop
prompt--     if totwait1.exists(indx) then
prompt--       if totwait2(indx)-totwait1(indx)>0 or timwait2(indx)-timwait1(indx)>0 then
prompt--         l_row:=rpad(indx,60,'.')||':'||lpad(to_char((totwait2(indx)-totwait1(indx))),25,' ')||' '||
prompt--                                        lpad(to_char(avgwait2(indx)/100),25,' ')||' '||
prompt--                                        lpad(to_char(maxwait2(indx)/100),25,' ')||' '||
prompt--                                        lpad(to_char((timwait2(indx)-timwait1(indx))/1e6),25,' ');;
prompt--       end if;;
prompt--     else
prompt--       l_row:=rpad(indx,60,'.')||':'||lpad(to_char(totwait2(indx)),25,' ')||' '||
prompt--                                      lpad(to_char(avgwait2(indx)/100),25,' ')||' '||
prompt--                                      lpad(to_char(maxwait2(indx)/100),25,' ')||' '||
prompt--                                      lpad(to_char(timwait2(indx)/1e6),25,' ');;
prompt--     end if;;
prompt     l_row:=rpad(indx,60,'.')||':'||lpad(to_char( case when totwait1.exists(indx) and totwait2(indx)-totwait1(indx)>0 then (totwait2(indx)-totwait1(indx)) else totwait2(indx) end ),25,' ')||' '||
prompt                                    lpad(to_char(avgwait2(indx)/100),25,' ')||' '||
prompt                                    lpad(to_char(maxwait2(indx)/100),25,' ')||' '||
prompt                                    lpad(to_char(( case when timwait1.exists(indx) and timwait2(indx)-timwait1(indx)>0 then (timwait2(indx)-timwait1(indx)) else timwait2(indx) end )/1e6),25,' ');;
prompt     p(l_row);;
prompt     indx:=totwait2.next(indx);;
prompt   end loop;;
prompt     p(rpad('-',164,'-'));;
prompt exception
prompt   when others then raise_application_error(-20000,indx||chr(10)||sqlerrm);;
prompt end;;
prompt /
--************************************************
prompt spool off
prompt set feedback on
prompt set heading on
prompt set termout on
prompt set timing on
prompt set serveroutput off
spool off
set feedback on
set heading on
set termout on
set timing on
set verify on

