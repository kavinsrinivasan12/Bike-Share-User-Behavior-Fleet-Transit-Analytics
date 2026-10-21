# Bike Share: User Behavior & Fleet Transit Analytics

[![Platform: Snowflake](https://img.shields.io/badge/Data%20Warehouse-Snowflake-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![Language: Snowflake SQL](https://img.shields.io/badge/Query%20Engine-Snowflake%20SQL-00758F?logo=sql&logoColor=white)]()
[![Environment: Snowflake Notebooks](https://img.shields.io/badge/Environment-Snowflake%20Notebooks-29B5E8?logo=snowflake&logoColor=white)]()
[![Language: Python](https://img.shields.io/badge/Language-Python%203.10-3776AB?logo=python&logoColor=white)](https://www.python.org/)

---

## 📌 Executive Summary & Project Overview

This project implements an end-to-end data engineering and analytical pipeline targeting over **2.5 million raw Divvy/Cyclistic bike-share trips** in Greater Chicago. 

By unifying Python data processing within **Snowflake Notebooks** and executing warehouse-native **Snowflake SQL**, this analysis cleans unorganized trip logs, engineers temporal and spatial features, and answers 14 high-impact business metrics. The study isolates behavioral dynamics between annual subscribers (`member`) and pay-per-ride users (`casual`), uncovering critical fleet deficits, transit corridor bottlenecks, and membership conversion opportunities.

```
                              DATA PIPELINE ARCHITECTURE
                                                                    
  [ Raw Data Ingestion ] ──────> [ Snowflake Notebooks ] ──────> [ Curated Silver Mart ] ──────> [ Business SQL Queries ]
   • 2,507,804 Records            • Schema Normalization           • clean_month_data               • 14 Real-World Cases
   • Inconsistent Timestamps      • Timestamp Nanosecond Fix       • 2,443,933 Clean Records        • Window Functions
   • 21%+ Missing Stations        • Spatial & Outlier Trimming     • 97.45% Retention Rate          • Fleet Rebalancing
```

---

## 💼 Problem, Solution & Impact

* **Problem:** Over 2.5M raw monthly bike trip records were unorganized with over 21% missing station attributes and extreme duration outliers, making it hard to separate high-frequency daily commuter routes from leisure loops or pinpoint fleet shortages.
* **Solution:** Engineered an end-to-end data pipeline across Python and Snowflake SQL to filter down to 2.44M clean records (retaining 97.45% of valid data), standardizing schema types, engineering duration categories, tagging commute windows, and applying spatial coordinate filters. Developed 14 business-focused SQL queries utilizing window functions (`DENSE_RANK`, `LAG`, rolling averages) to isolate station imbalances, demand velocity, and user transit patterns.
* **Impact:** Revealed that annual members drive sharp bimodal weekday commuter peaks, whereas casual riders surge on weekends, isolating the top 10 transit corridors that account for heavy commuter traffic and identifying high-deficit morning stations to optimize rebalancing operations.

---

## 📊 Dataset & Pipeline Engineering

### 1. Data Cleaning & Feature Engineering (Python in Snowflake Notebooks)
* **Nanosecond Epoch Resolution:** Converted 19-digit Unix nanosecond timestamps into Snowflake-native `TIMESTAMP_NTZ` datatypes via $10^9$ scaling.
* **Spatial Trimming:** Filtered coordinates outside Greater Chicago using spatial bounding boxes ($\text{lat} \in [41.60, 42.10]$, $\text{lng} \in [-87.95, -87.50]$).
* **Duration Filtering:** Removed corrupted records with trip durations under 1 minute or exceeding 24 hours.
* **Station Imputation:** Flagged dockless bike terminations as `'On-Street / Dockless Lock'` to prevent data loss while preserving route geometry.

### 2. Final Data Dictionary

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ride_id` | `VARCHAR` | Unique trip identifier |
| `rideable_type` | `VARCHAR` | Vehicle classification (`classic_bike`, `electric_bike`) |
| `started_at` | `TIMESTAMP_NTZ` | Trip start timestamp |
| `ended_at` | `TIMESTAMP_NTZ` | Trip completion timestamp |
| `start_station_name` | `VARCHAR` | Origin station name or `'On-Street / Dockless Lock'` |
| `end_station_name` | `VARCHAR` | Destination station name or `'On-Street / Dockless Lock'` |
| `start_lat`, `start_lng` | `FLOAT` | Origin geographic coordinates |
| `end_lat`, `end_lng` | `FLOAT` | Destination geographic coordinates |
| `member_casual` | `VARCHAR` | Customer tier (`member` or `casual`) |
| `ride_length_mins` | `FLOAT` | Total ride duration calculated in minutes |
| `duration_category` | `VARCHAR` | Binned duration (`Short (<10m)`, `Medium (10-20m)`, `Long (20-45m)`, `Extended (>45m)`) |
| `is_commute_window` | `INTEGER` | Binary flag for rush hours (`7-9 AM` and `4-6 PM` on weekdays) |
| `is_round_trip` | `INTEGER` | Binary flag indicating identical start and end stations |
| `hour` | `INTEGER` | Starting hour of the trip (0–23) |
| `day_of_week` | `INTEGER` | Day index (1 = Monday, 7 = Sunday) |
| `day_name` | `VARCHAR` | Day name (`Monday`, `Tuesday`, etc.) |
| `is_weekend` | `INTEGER` | Binary flag for Saturday and Sunday |

---

## 📈 Key Analytical Insights

1. **Bimodal Commute Patterns:** Annual members drive distinct morning (7–9 AM) and evening (4–6 PM) spikes on weekdays, averaging 11.8 minutes per trip.
2. **Weekend Leisure Surges:** Casual rider demand surges by over 140% on Saturdays and Sundays, with median trip lengths doubling (24.3 minutes) and circular leisure loops (`is_round_trip = 1`) increasing threefold along waterfront parks.
3. **Station Inflow/Outflow Imbalances:** Identified top net-deficit transit stations in the downtown loop where outbound morning trips exceed inbound arrivals by more than 3:1, causing severe dock depletion.
4. **Subscriber Conversion Cohorts:** Casual riders logging repeated weekday commute-window trips of 10–20 minutes represent high-intent targets for annual membership subscription campaigns.

---


---

## 💻 Tech Stack & Tools

* **Data Platform:** Snowflake (Data Cloud, Compute WH, Snowflake Notebooks)
* **Query Language:** Snowflake SQL (CTEs, Windowing, Haversine spatial math, Aggregations)
* **Scripting / Data Prep:** Python 3.10, Pandas, Snowpark
* **Version Control:** Git, GitHub
