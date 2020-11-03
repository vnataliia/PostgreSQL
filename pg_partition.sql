\dP
\dP+

SELECT * FROM pg_partition_tree('table');

SELECT pg_size_pretty(sum(pg_relation_size(relid))) AS total
  FROM pg_partition_tree('table');

SELECT pg_partition_root('part1v1v2') ;

SELECT pg_partition_ancestors('part1v1') ;
