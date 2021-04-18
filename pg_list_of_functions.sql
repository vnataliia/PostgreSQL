SELECT n.nspname as schema,
       p.proname as fname,
       left(u.usename,10) as owner,
       left(CASE p.prokind WHEN 'a' THEN 'agg' WHEN 'w' THEN 'window' WHEN 'p' THEN 'proc'
            ELSE CASE WHEN t.tgfoid IS NOT NULL THEN 'tr_' || coalesce((NOT tgisinternal)::text,'---') ELSE 'func' END END,4) as type,
       left(CASE WHEN array_upper(ts.tables,1) > 1 THEN array_upper(ts.tables,1)::text ELSE ts.tables::text END,10) as trgtables,
       -- t.tgisinternal,
       calls,
       CASE WHEN total_time > 1000 THEN date_trunc('second',total_time*'1ms'::interval)::text ELSE total_time::text END as totaltime,
       CASE WHEN self_time > 1000 THEN date_trunc('second',self_time*'1ms'::interval)::text ELSE self_time::text END as self_time,
       CASE WHEN self_time/calls > 1000 THEN date_trunc('second',(self_time/calls)*'1ms'::interval)::text ELSE round((self_time/calls)::numeric,2)::text END as one,
       left(pg_catalog.pg_get_function_result(p.oid),10) as result,
       left(pg_catalog.pg_get_function_arguments(p.oid),10) as arguments
       -- pg_get_functiondef(p.oid) as def
  FROM pg_catalog.pg_proc p
  LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  LEFT JOIN pg_user u ON u.usesysid = p.proowner
  LEFT JOIN pg_stat_user_functions s ON s.funcid = p.oid
  LEFT JOIN (SELECT t.tgfoid, t.tgisinternal FROM pg_trigger t GROUP BY 1, 2) AS t ON t.tgfoid = p.oid
  LEFT JOIN (
         SELECT replace(replace(action_statement,'EXECUTE FUNCTION ',''),'()','') AS func_name,
                array_agg(DISTINCT CASE WHEN ts.event_object_schema <> 'public' THEN ts.event_object_schema || '.' || event_object_table ELSE event_object_table END) AS tables
           FROM information_schema.triggers ts
          GROUP BY 1
       ) ts ON func_name = p.proname
 WHERE u.usename NOT IN ('rdsadmin', 'redcarpetadmin')
       -- AND t.tgfoid IS NULL -- triggers
       -- p.proname OPERATOR(pg_catalog.~) '^(my_function_name)$' COLLATE pg_catalog.default
       -- pg_catalog.pg_function_is_visible(p.oid)
       -- n.nspname NOT IN ('pg_catalog')
 ORDER BY 1, 2
;
