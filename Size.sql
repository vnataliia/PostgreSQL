SELECT table_schema, table_name,
       -- row_estimate,
       CASE WHEN row_estimate/10^6 > 1 THEN (round((row_estimate/10^6)::numeric,2))::text || ' M' ELSE row_estimate::text END AS tuples,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS INDEX,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS TABLE,
       pg_size_pretty(sum(table_bytes + toast_bytes) OVER()) AS WO_ids,
       pg_size_pretty(sum(total_bytes) OVER()) AS DB_size
  FROM (
         SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
           FROM (
                  SELECT c.oid, nspname AS table_schema, relname AS table_name,
                         c.reltuples AS row_estimate,
                         pg_total_relation_size(c.oid) AS total_bytes,
                         pg_indexes_size(c.oid) AS index_bytes,
                         pg_total_relation_size(reltoastrelid) AS toast_bytes
                    FROM pg_class c
                    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                   WHERE relkind = 'r' AND relname ~ ''
                ) a
       ) a
ORDER BY total_bytes DESC;


\l+
\dt+
SELECT pg_size_pretty(pg_database_size(current_database()));
SELECT pg_size_pretty(sum(pg_database_size(datname))) from pg_database;

select pg_size_pretty(pg_relation_size('table_name')); --only table
select pg_size_pretty(pg_indexes_size('table_name')); --only indexes
select pg_size_pretty(pg_total_relation_size('table_name')); -- table + index + toast

                                             
