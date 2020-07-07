-- WITH data AS (
SELECT a.*
     , b.id as db_id
     , b.route_id as db_route_id
     , b.created_at As db_created_at
     , b.path as db_path
     , b.descriptors as db_descriptors
  FROM route_images AS a, route_images AS b
 WHERE b.created_at < a.created_at
   AND b.route_id IS NOT NULL
   AND CAST(a.created_at AS DATE) BETWEEN '{START_AT}' AND '{END_AT}'
    -- imagining we have only 30 routes
   AND a.route_id < 30
   AND b.route_id < 30
--     )
--
-- SELECT COUNT(*)
-- FRom data