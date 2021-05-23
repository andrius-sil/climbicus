WITH user_images_count AS (
  SELECT user_id
       , COUNT(*) AS count_images
    FROM route_images
  GROUP BY user_id
)
, user_log_count AS (
  SELECT user_route_log.user_id
       , COUNT(*) AS count_route_logs
       , COUNT(DISTINCT DATE(user_route_log.created_at)) AS distinct_log_days
       , MAX(user_route_log.created_at) AS latest_log_timestamp
       -- TODO: limit to last logs
       -- , ARRAY_AGG(CONCAT(areas.name, '_', routes.lower_grade)) recent_logs
    FROM user_route_log
    JOIN routes ON routes.id = user_route_log.route_id
    JOIN areas ON areas.id = routes.area_id
  GROUP BY user_route_log.user_id
)
, user_vote_count AS (
  SELECT user_id
       , COUNT(*) AS count_route_votes
    FROM user_route_votes
  GROUP BY user_id
)
, user_route_count AS (
  SELECT user_id
       , COUNT(*) AS count_routes_added
    FROM routes
  GROUP BY user_id
)
, user_data AS (
  SELECT users.id
       , users.name
       , users.email
       , COALESCE(count_route_logs, 0)   count_route_logs
       , COALESCE(distinct_log_days, 0)  distinct_log_days
       , latest_log_timestamp
       , COALESCE(count_route_votes, 0)  count_route_votes
       , COALESCE(count_routes_added, 0) count_routes_added
       , COALESCE(count_images, 0)       count_images
       -- , recent_logs
  FROM users
         LEFT JOIN user_images_count
                   ON user_images_count.user_id = users.id
         LEFT JOIN user_log_count
                   ON user_log_count.user_id = users.id
         LEFT JOIN user_vote_count
                   ON user_vote_count.user_id = users.id
         LEFT JOIN user_route_count
                   ON user_route_count.user_id = users.id
)
SELECT *
  FROM user_data
 WHERE count_route_logs + count_routes_added + count_images > 0
   AND name NOT IN ('Andrius', 'Liucija', 't')
 ORDER BY latest_log_timestamp DESC
