set timing off
set define ~

set serveroutput on
declare
  l_css clob:=
q'{
@@awr.css
}';

  l_plsql_output clob;
  
  l_getftxt clob := 
q'{
@@getftxt
}';

  l_nonshared1 clob := 
q'{
@@nonshared1
}';

  l_vsql_stat clob := 
q'[
@@vsql_stat
]';

  l_offload_percent1 clob := 
q'[
@@offload_percent1
]';

  l_offload_percent2 clob := 
q'[
@@offload_percent2
]';

  l_sqlmon1 clob := 
q'[
@@sqlmon1
]';

  l_sqlwarea clob := 
q'[
@@sqlwarea
]';

  l_optenv clob := 
q'[
@@optenv
]';

  l_sql clob;
  
  l_rac_plans clob := 
q'[
@@rac_plans
]';

  l_sqlmon_hist clob := 
q'[
@@sqlmon_hist
]';

  

procedure prompt(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;
procedure p(p_msg varchar2) is begin dbms_output.put_line(p_msg); end;
procedure prepare_script(p_script in out clob, p_sqlid varchar2, p_plsql boolean default false) is 
  l_scr clob := p_script;
  l_line varchar2(32765);
  l_eof number;
  l_iter number := 1;
begin
  if instr(l_scr,chr(10))=0 then raise_application_error(-20000,'Put at least one EOL into script.');end if;
  --set variable
  p_script:=replace(replace(replace(replace(replace(p_script,'&SQLID.',p_sqlid),'&SQLID',p_sqlid),'&1.',p_sqlid),'&1',p_sqlid),'&VSQL.','gv$sql'); 
  --remove sqlplus settings
  l_scr := p_script;
  p_script:=null;
  loop
    l_eof:=instr(l_scr,chr(10));
    l_line:=substr(l_scr,1,l_eof);
    
    if upper(l_line) like 'SET%' or 
       upper(l_line) like 'COL%' or
       upper(l_line) like 'BREAK%' or
       upper(l_line) like 'ALTER SESSION%' or
       upper(l_line) like 'SERVEROUTPUT%' or
       upper(l_line) like 'REM%' or
       upper(l_line) like '--%' 
    then
      null;
    else
      p_script:=p_script||l_line||chr(10);
    end if;
    
    l_scr:=substr(l_scr,l_eof+1);
    l_iter:=l_iter+1;
    exit when l_iter>1000 or dbms_lob.getlength(l_scr)=0;
  end loop;
  if not p_plsql then p_script:=replace(p_script,';'); end if;
end;

procedure print_table_html(p_query in varchar2, p_width number, p_summary varchar2, p_search varchar2 default null, p_replacement varchar2 default null) is
  l_theCursor   integer default dbms_sql.open_cursor;
  l_columnValue varchar2(32767);
  l_status      integer;
  l_descTbl     dbms_sql.desc_tab2;
  l_colCnt      number;
  l_rn          number := 0;
begin
  p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_summary||'"'));

  dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
  dbms_sql.describe_columns2(l_theCursor, l_colCnt, l_descTbl);

  for i in 1 .. l_colCnt loop
    dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
  end loop;

  l_status := dbms_sql.execute(l_theCursor);

  --column names
  p(HTF.TABLEROWOPEN);
  for i in 1 .. l_colCnt loop
    p(HTF.TABLEHEADER(cvalue=>l_descTbl(i).col_name,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
  end loop;
  p(HTF.TABLEROWCLOSE);

  while (dbms_sql.fetch_rows(l_theCursor) > 0) loop
    p(HTF.TABLEROWOPEN);
    l_rn := l_rn + 1;
    for i in 1 .. l_colCnt loop
      dbms_sql.column_value(l_theCursor, i, l_columnValue);
	  l_columnValue:=replace(replace(l_columnValue,chr(13)||chr(10),chr(10)||'<br/>'),chr(10),chr(10)||'<br/>');
	  if p_search is not null and regexp_instr(l_columnValue,p_search)>0 then
	    l_columnValue:=REGEXP_REPLACE(l_columnValue,p_search,p_replacement);
		p(HTF.TABLEDATA(cvalue=>l_columnValue,calign=>'left',cattributes=>'class="'|| case when mod(l_rn,2)=0 then 'awrc1' else 'awrnc1' end ||'"'));
	  else
        p(HTF.TABLEDATA(cvalue=>replace(l_columnValue,'  ','&nbsp;&nbsp;'),calign=>'left',cattributes=>'class="'|| case when mod(l_rn,2)=0 then 'awrc1' else 'awrnc1' end ||'"'));
	  end if;
    end loop;
    p(HTF.TABLEROWCLOSE);
  end loop;
  dbms_sql.close_cursor(l_theCursor);
  p(HTF.TABLECLOSE);
end;
    
procedure print_text_as_table(p_text clob, p_t_header varchar2,p_width number, p_search varchar2 default null, p_replacement varchar2 default null) is
  l_line varchar2(32765);  l_eof number;  l_iter number := 1; 
  l_text clob := p_text;
begin
  p(HTF.TABLEOPEN(cborder=>0,cattributes=>'width="'||p_width||'" class="tdiff" summary="'||p_t_header||'"'));
  p(HTF.TABLEROWOPEN);
  p(HTF.TABLEHEADER(cvalue=>p_t_header,calign=>'left',cattributes=>'class="awrbg" scope="col"'));
  p(HTF.TABLEROWCLOSE);

  loop
    l_eof:=instr(l_text,chr(10));
    p(HTF.TABLEROWOPEN);
	l_line:=substr(l_text,1,l_eof);
	if p_search is not null and regexp_instr(l_line,p_search)>0 then
	  l_line:=REGEXP_REPLACE(l_line,p_search,p_replacement);
	  p(HTF.TABLEDATA(cvalue=>l_line,calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then 'awrc1' else 'awrnc1' end ||'"'));
	else
	  p(HTF.TABLEDATA(cvalue=>replace(l_line,' ','&nbsp;'),calign=>'left',cattributes=>'class="'|| case when mod(l_iter,2)=0 then 'awrc1' else 'awrnc1' end ||'"'));
	end if;
	p(HTF.TABLEROWCLOSE);
    l_text:=substr(l_text,l_eof+1);  l_iter:=l_iter+1;
    exit when l_iter>1000 or dbms_lob.getlength(l_text)=0;
  end loop;

  p(HTF.TABLECLOSE);
end;
   
begin
   p(HTF.HTMLOPEN);
   p(HTF.HEADOPEN);
   p(HTF.TITLE('~SQLID'));   
   --p('<link rel="stylesheet" type="text/css" href="awr.css">');
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
   print_table_html(l_getftxt,1000,'Full sql text');
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
   execute immediate l_vsql_stat using in out l_plsql_output;
   l_plsql_output:=replace(replace(l_plsql_output,'&_USER.','~_USER.'),'&_CONNECT_IDENTIFIER.','~_CONNECT_IDENTIFIER.');
   
   --l_plsql_output:=REGEXP_REPLACE(l_plsql_output,'CHILD_NUMBER=([[:digit:]])',HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
   
   print_text_as_table(p_text=>l_plsql_output,p_t_header=>'V$SQL',p_width=>600, p_search=>'CHILD_NUMBER=([[:digit:]])',p_replacement=>HTF.ANCHOR (curl=>'#child_last_\1',ctext=>'CHILD_NUMBER=\1',cattributes=>'class="awr"'));
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
   print_table_html(l_sql,1000,'Display cursor (last)','child number ([[:digit:]])',HTF.ANCHOR(curl=>'#child_all_\1',ctext=>'child number \1',cname=>'child_last_\1',cattributes=>'class="awr"'));
   p(HTF.BR);
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);  
   
   --Display cursor (RAC)
   p(HTF.header (3,cheader=>HTF.ANCHOR (curl=>'',ctext=>'Display cursor (RAC)',cname=>'dp_rac',cattributes=>'class="awr"'),cattributes=>'class="awr"'));
   p(HTF.BR);
   prepare_script(l_rac_plans,'~SQLID');
   print_table_html(l_rac_plans,1000,'Display cursor (RAC)');
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
   print_table_html(l_sql,1000,'Display cursor (last)');
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
   print_table_html(l_sql,1000,'Display cursor (last)','child number ([[:digit:]])',HTF.ANCHOR(curl=>'',ctext=>'child number \1',cname=>'child_all_\1',cattributes=>'class="awr"'));
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
   print_table_html(l_sql,1000,'Display cursor (last)');
   p(HTF.BR);   
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont_plans',ctext=>'Back to Execution plans',cattributes=>'class="awr"')));
   p(HTF.LISTITEM(cattributes=>'class="awr"',ctext=>HTF.ANCHOR (curl=>'#tblofcont',ctext=>'Back to top',cattributes=>'class="awr"')));
   p(HTF.BR);
   p(HTF.BR);
   l_sql:=q'[SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&SQLID', null, format => 'adaptive ALL ALLSTATS +peeked_binds'))]'||chr(10);
   prepare_script(l_sql,'~SQLID');
   print_table_html(l_sql,1000,'Display cursor (last)');   
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