set long 10000000
set pages 9999
column sql_fulltext format a200 word_wrapped
select sql_fulltext "Full query text" from v$sql where sql_id='&1' and rownum=1;
