SQL execution plan analyzing pack
Version 2.1

History:
--------
Version 1.0 - baseline
Version 2.0 - HTML reports for getplan and getllplan with "h" suffix
Version 2.1 - Refactoring

1. ep.sql
Explains plan for some query in a file:

@ep <filename>[.sql]

2. geteplan.sql
Renders an execution plan from plan_table (use after explain plan for statement)

@geteplan

3. geteeplan.sql
Renders an execution plan with ADVANCED option from plan_table (use after explain plan for statement)

@geteeplan

4. ex.sql
Executes a query from a file and gathers sql runtime statistics. pars.sql can be used for bind variables (called automatically)

@ex <filename>[.sql]

5. ex1.sql
Executes a query from a file and gathers sql runtime statistics. pars.sql can be used for bind variables (called automatically). The difference from the previous is that it creates a table to store the query result.

@ex1 <filename>[.sql]

6. exs.sql
Executes a query from a file and gathers sql runtime statistics as well as session statistics. pars.sql can be used for bind variables (called automatically)

@exs <filename>[.sql]

7. getplan.sql getplanh.sql

Gathers sql execution statistics for given SQL_ID
File with "h" suffix creates HTML report

@getplan <SQL_ID>
@getplanh <SQL_ID>

8. getllplan.sql getllplanh.sql

Gathers sql execution statistics for last executed sql query, takes FILE_NAME_PREFIX for naming the output file
File with "h" suffix creates HTML report

@getllplan <FILE_NAME_PREFIX>
@getllplanh <FILE_NAME_PREFIX>

9. prntbl.sql

Prints a query result one row as a table

@prntbl "sql query"

10. findq.sql

Searches for queries in shared pool or AWR repository

@findq "%query text part%" fast|awr|full

- fast - gv$sqlstats
- awr  - dba_hist_sqltext
- full - gv$sql