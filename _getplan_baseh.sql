set timing off
set define ~

set serveroutput on
declare

  l_sql clob;
  l_plsql_output clob;

  l_crsr sys_refcursor;
  
  l_css clob:=
q'{
@@awr.css
}';
  
  l_getftxt clob := 
q'{
@@__getftxt
}';

  l_nonshared1 clob := 
q'{
@@__nonshared1
}';

  l_vsql_stat clob := 
q'[
@@__vsql_stat
]';

  l_offload_percent1 clob := 
q'[
@@__offload_percent1
]';

  l_offload_percent2 clob := 
q'[
@@__offload_percent2
]';

  l_sqlmon1 clob := 
q'[
@@__sqlmon1
]';

  l_sqlwarea clob := 
q'[
@@__sqlwarea
]';

  l_optenv clob := 
q'[
@@__optenv
]';

  l_rac_plans clob := 
q'[
@@__rac_plans
]';

  l_sqlmon_hist clob := 
q'[
@@__sqlmon_hist
]';

@@__procs.sql
   
begin
   p(HTF.HTMLOPEN);
   p(HTF.HEADOPEN);
   p(HTF.TITLE('~SQLID'));   

   p('<style type="text/css">');
   p(l_css);
   p('</style>');
   p(HTF.HEADCLOSE);
   p(HTF.BODYOPEN(cattributes=>'class="awr"'));
   
   p(HTF.header (1,'SQL Report for SQL_ID=~SQLID',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.BR);
   p(HTF.header (2,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Table of contents',cname=>'tblofcont',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_text',ctext=>'SQL text',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#non_shared',ctext=>'Non shared reason',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#v_sql_stat',ctext=>'V$SQL statistics',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#exadata',ctext=>'Exadata statistics',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon',ctext=>'SQL Monitor report',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_workarea',ctext=>'SQL Workarea',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#cbo_env',ctext=>'CBO environment',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#sql_mon_hist',ctext=>'SQL Monitor report history',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR); 
   
   --SQL TEXT
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL text',cname=>'sql_text',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_getftxt,'~SQLID');
   open l_crsr for l_getftxt;
   fetch l_crsr into l_plsql_output;
   close l_crsr;
   
   --print_table_html(l_getftxt,1000,'Full sql text');
   print_text_as_table(p_text=>l_plsql_output,p_t_header=>'SQL text',p_width=>500);
   
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);  
   
   --Non shared
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Non shared reason',cname=>'non_shared',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_nonshared1,'~SQLID');
   print_table_html(l_nonshared1,1000,'Non shared reason');
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   
   --V$SQL statistics
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'V$SQL statistics',cname=>'v_sql_stat',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_vsql_stat,'~SQLID', p_plsql=>true);
   l_vsql_stat:=replace(l_vsql_stat,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
   l_plsql_output:=null;
   execute immediate l_vsql_stat using in out l_plsql_output;
   l_plsql_output:=replace(replace(l_plsql_output,'&_USER.','~_USER.'),'&_CONNECT_IDENTIFIER.','~_CONNECT_IDENTIFIER.');
   
   --l_plsql_output:=REGEXP_REPLACE(l_plsql_output,'CHILD_NUMBER=([[:digit:]])',HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
   
   print_text_as_table(p_text=>l_plsql_output,p_t_header=>'V$SQL',p_width=>600, p_search=>'CHILD_NUMBER=([[:digit:]]*)',p_replacement=>HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   
   --Exadata statistics
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Exadata statistics',cname=>'exadata',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_offload_percent1,'~SQLID');
   print_table_html(l_offload_percent1,1000,'Exadata statistics #1');
   p(HTF.BR);
   prepare_script(l_offload_percent2,'~SQLID');
   print_table_html(l_offload_percent2,1000,'Exadata statistics #2'); 
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);   
   
   --SQL Monitor report
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report (11g+)',cname=>'sql_mon',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_sqlmon1,'~SQLID', p_plsql=>true);
   l_sqlmon1:=replace(l_sqlmon1,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
   l_plsql_output:=null;
   execute immediate l_sqlmon1 using in out l_plsql_output;
   print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report',p_width=>600);
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);   
   
   --SQL Workarea
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Workarea',cname=>'sql_workarea',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_sqlwarea,'~SQLID');
   print_table_html(l_sqlwarea,1000,'SQL Workarea');
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);   
   
   --CBO environment
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'CBO environment',cname=>'cbo_env',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_optenv,'~SQLID');
   print_table_html(l_optenv,1000,'CBO environment');
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);  
   
   --Execution plans
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Execution plans',cname=>'tblofcont_plans',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last',ctext=>'Display cursor (last)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_rac',ctext=>'Display cursor (RAC)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_last_adv',ctext=>'Display cursor (LAST ADVANCED)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_all',ctext=>'Display cursor (ALL)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#dp_adaptive',ctext=>'Display cursor (ADAPTIVE)',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   
   --Display cursor (last)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (last)',cname=>'dp_last',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ALLSTATS +peeked_binds'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,1500,'Display cursor (last)','child number ([[:digit:]]*)',HTF.ANCHOR(curl=>'#child_all_\1',ctext=>'child number \1',cname=>'child_last_\1',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);  
   
   --Display cursor (RAC)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (RAC)',cname=>'dp_rac',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_rac_plans,'~SQLID');
   print_table_html(l_rac_plans,1500,'Display cursor (RAC)');
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);   
   
   --Display cursor (LAST ADVANCED)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (LAST ADVANCED)',cname=>'dp_last_adv',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'LAST ADVANCED'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,1500,'Display cursor (LAST ADVANCED)');
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);   
   
   --Display cursor (ALL)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ALL)',cname=>'dp_all',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   l_sql:=q'[select * from table(dbms_xplan.display_cursor('&SQLID', null, 'ALL ALLSTATS +peeked_binds'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,2000,'Display cursor (ALL)','child number ([[:digit:]]*)',HTF.ANCHOR(curl=>'',ctext=>'child number \1',cname=>'child_all_\1',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   
   --Display cursor (ADAPTIVE)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (ADAPTIVE)',cname=>'dp_adaptive',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   l_sql:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive LAST ALLSTATS +peeked_binds'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,1500,'Display cursor (ADAPTIVE)');
   p(HTF.BR);   
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   l_sql:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,2000,'Display cursor (ADAPTIVE)');   
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR); 
   
   --SQL Monitor report history
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'SQL Monitor report history (12c+)',cname=>'sql_mon_hist',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_sqlmon_hist,'~SQLID',true);
   l_sqlmon_hist:=replace(l_sqlmon_hist,'procedure p(msg varchar2) is begin dbms_output.put_line(msg);end;','procedure p(msg varchar2) is begin :l_res:=:l_res||msg||chr(10);end;');
   --p(l_sqlmon1);
   l_plsql_output:=null;
   begin
     execute immediate l_sqlmon_hist using in out l_plsql_output;
   exception
     when others then l_plsql_output:=sqlerrm;
   end;
   print_text_as_table(p_text=>l_plsql_output||chr(10),p_t_header=>'SQL Monitor report history',p_width=>600);
   p(HTF.BR);   
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   
   p(HTF.BR);
   p(HTF.BR);
   p((HTF.BODYCLOSE));
   p((HTF.HTMLCLOSE));
end;
/
set serveroutput off
set define &
set timing on