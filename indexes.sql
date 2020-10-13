-- indexes size
SELECT -- s.schemaname,
       s.relname AS table_name,
       s.indexrelname AS idx_name,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS idx_size,
       pg_size_pretty(sum(pg_relation_size(s.indexrelid)) OVER ()) AS total,
       pg_size_pretty(sum(pg_relation_size(s.indexrelid)) OVER (PARTITION BY s.schemaname, s.relname)) AS by_table,
       idx_scan, -- : has the query planner used this index for an ‘Index Scan’, the number returned is the amount of times it was used
       idx_tup_read AS iread, --: how many tuples have been read by using the index
       idx_tup_fetch AS ifetch --: how many tuples have been fetch by using the index
       -- i.indisunique AS uniq,   -- is a UNIQUE index
       -- (SELECT count(conname) FROM pg_catalog.pg_constraint c WHERE c.conindid = s.indexrelid) AS con, -- enforce a constraint
  FROM pg_catalog.pg_stat_user_indexes s
  JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
/* WHERE
       NOT i.indisunique AND   -- is not a UNIQUE index (PK)
       s.idx_scan = 0      -- has never been scanned
       --AND NOT EXISTS          -- does not enforce a constraint??
         --(SELECT 1 FROM pg_catalog.pg_constraint c WHERE c.conindid = s.indexrelid)
       -- AND s.relname = 'v3_data_credit_score'
       --AND  s.indexrelname = 'index_v3_data_credit_score_on_ip_address' */
 ORDER BY --s.idx_scan,
          pg_relation_size(s.indexrelid) DESC;

-- PG12: Multi-column index sizes are now reduced by up to 40% by using space more efficiently, thereby saving on disk space. 

REINDEX (VERBOSE) DATABASE CONCURRENTLY <db_name>;

-- reindex progress
SELECT now()::time(0), a.query, p.phase,
       p.blocks_total, p.blocks_done, p.tuples_total, p.tuples_done
  FROM pg_stat_progress_create_index p
  JOIN pg_stat_activity a ON
       p.pid = a.pid;
       
