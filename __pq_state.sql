select pdml_enabled, pdml_status, pddl_status, pq_status from v$session where sid=sys_context('USERENV','SID');

SELECT dfo_number dfo, tq_id, server_type, process, num_rows, ROUND(ratio_to_report(num_rows) OVER(PARTITION BY dfo_number, tq_id, server_type) * 100) AS "%"
  FROM v$pq_tqstat
 ORDER BY dfo_number, tq_id, server_type DESC;