with data as (
  select users.id
       , users.name
       , users.email
       , max(user_route_log.created_at) max_date
       , count(distinct user_route_log.id) log_count
       , count(distinct date(user_route_log.created_at)) distinct_dates
       , count(distinct routes.id)                       routes_added_count
       , count(distinct ri.id) as                        image_count
       , count(distinct urv.id) as                       vote_count
       , array_agg(distinct concat(a.name, '_', log_routes.lower_grade)) routes_logged
  from users
         left join user_route_log on users.id = user_route_log.user_id
         left join routes log_routes on user_route_log.route_id = log_routes.id
         left join routes on users.id = routes.user_id
         left join route_images ri on users.id = ri.user_id
         left join areas a on log_routes.area_id = a.id
         left join user_route_votes urv on users.id = urv.user_id
  group by 1, 2, 3
)

select *
from data
where log_count + routes_added_count + image_count > 0
  and name not in ('Andrius', 'Liucija', 't')
ORDER BY max_date desc