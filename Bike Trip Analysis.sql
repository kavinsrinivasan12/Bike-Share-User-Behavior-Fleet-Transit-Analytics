
-- 1. Which 5 stations have the highest morning departure volume (7-9 AM), and what is the average trip duration?
WITH am_departures AS (
    SELECT start_station_name, COUNT(ride_id) AS am_trips,
           ROUND(AVG(ride_length_mins), 2) AS avg_duration_mins,
           DENSE_RANK() OVER (ORDER BY COUNT(ride_id) DESC) AS drnk
    FROM bike_trips
    WHERE EXTRACT(HOUR FROM started_at) BETWEEN 7 AND 9 
      AND start_station_name != 'On-Street / Dockless Lock'
    GROUP BY start_station_name
)
SELECT start_station_name, am_trips, avg_duration_mins
FROM am_departures
WHERE drnk <= 5;


-- 2. What percentage of trips are circular leisure loops (start = end station), broken down by day of the week?
SELECT day_name,
       COUNT(ride_id) AS total_trips,
       ROUND((COUNT_IF(is_round_trip = 1) / COUNT(ride_id)) * 100, 2) AS round_trip_pct
FROM bike_trips
GROUP BY day_name, day_of_week
ORDER BY day_of_week;


-- 3. Calculate total rides, electric bike ratio, and average duration for members vs casual riders.
SELECT member_casual,
       COUNT(ride_id) AS total_rides,
       ROUND((COUNT_IF(rideable_type = 'electric_bike') / COUNT(ride_id)) * 100, 2) AS electric_bike_pct,
       ROUND(AVG(ride_length_mins), 2) AS avg_duration_mins
FROM bike_trips
GROUP BY member_casual;


-- 4. Segment trips into duration categories and find the casual user proportion per band.
SELECT duration_category,
       COUNT(ride_id) AS total_rides,
       ROUND((COUNT_IF(member_casual = 'casual') / COUNT(ride_id)) * 100, 2) AS casual_rider_pct
FROM bike_trips
GROUP BY duration_category
ORDER BY total_rides DESC;


-- 5. Which start station has the highest ratio of casual riders to annual member riders?
WITH rider_ratio AS (
    SELECT start_station_name,
           ROUND(COUNT_IF(member_casual = 'casual') / NULLIF(COUNT_IF(member_casual = 'member'), 0), 2) AS casual_member_ratio,
           DENSE_RANK() OVER (ORDER BY COUNT_IF(member_casual = 'casual') / NULLIF(COUNT_IF(member_casual = 'member'), 0) DESC) AS drnk
    FROM bike_trips
    WHERE start_station_name != 'On-Street / Dockless Lock'
    GROUP BY start_station_name
    HAVING COUNT(ride_id) >= 500
)
SELECT start_station_name, casual_member_ratio FROM rider_ratio WHERE drnk = 1;


-- 6. What is the average time (in minutes) between trip start and trip end during peak commute windows?
SELECT is_commute_window,
       COUNT(ride_id) AS trip_count,
       ROUND(AVG(ride_length_mins), 2) AS avg_duration_mins
FROM bike_trips
WHERE is_weekend = 0
GROUP BY is_commute_window;


-- 7. Find high-traffic route pairs that have more than 1,000 total trips - flag as high-density corridors.
WITH route_density AS (
    SELECT CONCAT(start_station_name, ' ➔ ', end_station_name) AS corridor,
           COUNT(ride_id) AS trip_cnt,
           CASE WHEN COUNT(ride_id) > 1000 THEN 'Yes' ELSE 'No' END AS is_high_density
    FROM bike_trips
    WHERE start_station_name != 'On-Street / Dockless Lock' AND end_station_name != 'On-Street / Dockless Lock'
    GROUP BY start_station_name, end_station_name
)
SELECT * FROM route_density WHERE is_high_density = 'Yes' ORDER BY trip_cnt DESC;


-- 8. Identify stations with more than 100 trips that had rides lasting over 2 hours (extended rides).
SELECT start_station_name,
       COUNT_IF(ride_length_mins > 120.0) AS extended_trip_cnt
FROM bike_trips
WHERE start_station_name != 'On-Street / Dockless Lock'
GROUP BY start_station_name
HAVING extended_trip_cnt > 100
ORDER BY extended_trip_cnt DESC;


-- 9. Which day of the week experiences the fastest day-over-day growth in casual rider volume?
WITH daily_casual AS (
    SELECT day_name, day_of_week, COUNT(ride_id) AS casual_trips,
           LAG(COUNT(ride_id)) OVER (ORDER BY day_of_week) AS prev_day_trips
    FROM bike_trips
    WHERE member_casual = 'casual'
    GROUP BY day_name, day_of_week
)
SELECT day_name, casual_trips, prev_day_trips,
       ROUND(((casual_trips - prev_day_trips) / prev_day_trips) * 100, 2) AS dod_growth_pct
FROM daily_casual
ORDER BY dod_growth_pct DESC NULLS LAST;


-- 10. Find stations that have had no departures recorded in the latest 7 days of the dataset.
WITH latest_departure AS (
    SELECT start_station_name, MAX(DATE(started_at)) AS last_active_date,
           DATEDIFF(day, MAX(DATE(started_at)), (SELECT MAX(DATE(started_at)) FROM bike_trips)) AS inactive_days
    FROM bike_trips
    WHERE start_station_name != 'On-Street / Dockless Lock'
    GROUP BY start_station_name
)
SELECT start_station_name, last_active_date, inactive_days
FROM latest_departure
WHERE inactive_days >= 7
ORDER BY inactive_days DESC;


-- 11. Rank the top 3 destination stations within each hour of the day by arrival trip count.
WITH hourly_destinations AS (
    SELECT hour, end_station_name, COUNT(ride_id) AS arrival_cnt,
           DENSE_RANK() OVER (PARTITION BY hour ORDER BY COUNT(ride_id) DESC) AS drnk
    FROM bike_trips
    WHERE end_station_name != 'On-Street / Dockless Lock'
    GROUP BY hour, end_station_name
)
SELECT hour, end_station_name, arrival_cnt, drnk
FROM hourly_destinations
WHERE drnk <= 3
ORDER BY hour, drnk;


-- 12. Calculate a rolling 3-day average of daily trip volume across the dataset.
WITH daily_totals AS (
    SELECT DATE(started_at) AS trip_date, COUNT(ride_id) AS daily_trips
    FROM bike_trips
    GROUP BY DATE(started_at)
)
SELECT trip_date, daily_trips,
       ROUND(AVG(daily_trips) OVER (ORDER BY trip_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3day_avg
FROM daily_totals
ORDER BY trip_date;


-- 13. Using LAG, calculate the change in hourly demand between consecutive hours of the day.
WITH hourly_trips AS (
    SELECT hour, COUNT(ride_id) AS current_hour_trips
    FROM bike_trips
    GROUP BY hour
)
SELECT hour, current_hour_trips,
       (current_hour_trips - LAG(current_hour_trips) OVER (ORDER BY hour)) AS change_from_prev_hour
FROM hourly_trips
ORDER BY hour;


-- 14. What percentage of rides originating from dockless locations terminate at a designated physical station?
SELECT 
    COUNT(ride_id) AS total_dockless_starts,
    COUNT_IF(end_station_name != 'On-Street / Dockless Lock') AS docked_end_count,
    ROUND((COUNT_IF(end_station_name != 'On-Street / Dockless Lock') / COUNT(ride_id)) * 100, 2) AS docked_termination_pct
FROM bike_trips
WHERE start_station_name = 'On-Street / Dockless Lock';