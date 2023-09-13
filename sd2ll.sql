column psqlid NEW_V SQLID1 noprint
select prev_sql_id psqlid from v$session where sid=(select sid from v$mystat where rownum=1);
rollback;

@sd2 &SQLID1.