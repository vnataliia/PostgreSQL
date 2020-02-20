WITH pg_activity AS (
  SELECT min(pid) FILTER (WHERE backend_type IN ('client backend', 'autovacuum worker')) AS pid,
         left(usename,9) AS users,
         date_trunc('seconds', now() - xact_start) AS trx,
         date_trunc('seconds', now() - query_start) AS run,
         length(query) AS qlen,
         coalesce('+' || nullif((count(*) FILTER (WHERE backend_type = 'background worker')), '0'), '') AS "||",
         left(state,7) AS state,
         substr(trim(regexp_replace(query, E'[\\n\\r\\s]+', ' ', 'g' )),1,80) AS query
    FROM pg_stat_activity
   WHERE state != 'idle' AND
         NOT (usename = 'rdsrepladmin' AND length(query)= 0) AND
         query ~ ''
   GROUP BY usename, xact_start, query_start, query, state
)
SELECT (
         SELECT string_agg(blocking_locks.pid::text, ',')
           FROM pg_catalog.pg_locks AS blocked_locks
           JOIN pg_catalog.pg_locks AS blocking_locks ON
                blocking_locks.locktype = blocked_locks.locktype AND
                blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database AND
                blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation AND
                blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page AND
                blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple AND
                blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid AND
                blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid AND
                blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid AND
                blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid AND
                blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid AND
                blocking_locks.pid != blocked_locks.pid
         WHERE blocked_locks.pid = pg_activity.pid AND
               NOT blocked_locks.granted
       ) AS l,
       *
  FROM pg_activity
 ORDER BY state,
       CASE WHEN users IS NULL THEN 2 ELSE 1 END,
       trx DESC NULLS LAST
-- \watch 10
;
