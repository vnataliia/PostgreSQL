CREATE OR REPLACE FUNCTION space_size_pretty (n int8) RETURNS varchar(14) AS $f$
  WITH x AS (SELECT pg_size_pretty(n) AS s)
  SELECT lpad(CASE WHEN s = '8192 bytes' THEN '8 KB' WHEN s = '0 bytes' THEN '0 b' ELSE coalesce(s,'0') END,7,' ') FROM x
$f$
LANGUAGE SQL
IMMUTABLE;


SELECT table_schema,
       table_name,
       -- row_estimate,
       CASE WHEN row_estimate/10^6 > 1 THEN 
                 lpad((round((row_estimate/10^6)::numeric,2))::text,7,' ') || ' M'
            ELSE lpad(row_estimate::text,9, ' ')
            END AS tuples,
       space_size_pretty(total_bytes) AS total,
       space_size_pretty(table_bytes) AS table,
       -- space_size_pretty(heap_table_size) AS heap,
       space_size_pretty(index_bytes) AS index,
       space_size_pretty(toast_bytes) AS toast,
       -- space_size_pretty(toast_table_size) AS toast_table,
       -- space_size_pretty(toast_index_size) AS toast_idx,
       -- space_size_pretty(fsm_size) AS fsm,
       -- space_size_pretty(vm_size) AS vm
       -- pg_size_pretty(sum(table_bytes + toast_bytes) OVER()) AS WO_ids,
       pg_size_pretty(sum(total_bytes) OVER()) AS DB_size
  FROM (
         SELECT *,
                total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
           FROM (
                  SELECT c.oid,
                         nspname AS table_schema,
                         relname AS table_name,
                         c.reltuples AS row_estimate,
                         pg_total_relation_size(c.oid) AS total_bytes,
                         -- pg_relation_size(c.oid, 'main') as heap_table_size
                         pg_indexes_size(c.oid) AS index_bytes,
                         pg_total_relation_size(reltoastrelid) AS toast_bytes
                         -- pg_relation_size(c.oid, 'fsm') as fsm_size,
                         -- pg_relation_size(c.oid, 'vm') as vm_size,
                         -- pg_relation_size(c.reltoastrelid) as toast_table_size,
                         -- pg_relation_size(i.indexrelid) as toast_index_size
                    FROM pg_class c
                    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                    LEFT JOIN pg_index i ON c.reltoastrelid=i.indrelid
                   WHERE relkind = 'r' AND relname ~ ''
                ) a
       ) a
ORDER BY total_bytes DESC;

=== Disk space
\l+
\dt+
SELECT pg_size_pretty(pg_database_size(current_database()));
SELECT pg_size_pretty(sum(pg_database_size(datname))) from pg_database;

select pg_size_pretty(pg_relation_size('table_name')); --only table
select pg_size_pretty(pg_indexes_size('table_name')); --only indexes
select pg_size_pretty(pg_total_relation_size('table_name')); -- table + index + toast
                                             
-- TOAST stands for The Oversize Attribute Storage Technique
SELECT nspname || '.' || relname AS table,
       space_size_pretty(pg_relation_size(c.oid)) AS size,
       (SELECT relname FROM pg_class WHERE reltoastrelid = c.oid) AS owner
  FROM pg_class c 
  LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace) 
 WHERE nspname NOT IN ('pg_catalog', 'information_schema') 
 ORDER BY pg_relation_size(c.oid) DESC 
 LIMIT 20;
