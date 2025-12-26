{{ config(materialized='table') }}

with date_spine as (
    select date_day::date as date_day
    from (
        select generate_series(
            '2011-01-01'::date,
            '2014-12-31'::date,
            '1 day'::interval
        )::date as date_day
    ) dates
),

date_dimension as (
    select
        date_day as date_key,
        date_day,
        date_part('year', date_day) as year,
        date_part('quarter', date_day) as quarter,
        date_part('month', date_day) as month,
        date_part('week', date_day) as week_of_year,
        date_part('day', date_day) as day_of_month,
        date_part('dow', date_day) as day_of_week,
        date_part('doy', date_day) as day_of_year,
        to_char(date_day, 'Month') as month_name,
        to_char(date_day, 'Day') as day_name,
        to_char(date_day, 'YYYY-MM') as year_month,
        to_char(date_day, 'YYYY-Q') as year_quarter,
        case
            when date_part('month', date_day) in (12, 1, 2) then 'Winter'
            when date_part('month', date_day) in (3, 4, 5) then 'Spring'
            when date_part('month', date_day) in (6, 7, 8) then 'Summer'
            when date_part('month', date_day) in (9, 10, 11) then 'Fall'
        end as season,
        case
            when date_part('dow', date_day) in (0, 6) then 'Weekend'
            else 'Weekday'
        end as day_type,
        case
            when date_day = current_date then true
            else false
        end as is_current_date,
        case
            when date_day < current_date then true
            else false
        end as is_past_date,
        case
            when date_day > current_date then true
            else false
        end as is_future_date,
        date_part('year', current_date) - date_part('year', date_day) as years_ago
    from date_spine
)

select * from date_dimension

