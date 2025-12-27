{{ config(materialized='table') }}

-- Customer Analytics Mart
-- Supports: CLV, Customer segmentation, Churn prediction, RFM analysis, Customer journey, Cohort analysis

with customer_base as (
    select
        customerid,
        personid,
        storeid,
        territoryid,
        firstname,
        lastname,
        title,
        emailpromotion,
        store_name,
        territory_name,
        countryregioncode,
        territory_group,
        customer_segment,
        customer_status,
        purchase_frequency,
        lifetime_value,
        total_orders,
        avg_order_value,
        first_order_date,
        last_order_date,
        customer_tenure_days
    from {{ ref('dim_customer') }}
),

customer_sales_summary as (
    select
        customer_key,
        count(distinct salesorderid) as order_count,
        count(distinct order_date_key) as unique_order_days,
        sum(net_line_amount) as total_revenue,
        sum(total_profit) as total_profit,
        sum(orderqty) as total_quantity,
        avg(net_line_amount) as avg_line_item_value,
        min(order_date_key) as first_purchase_date_key,
        max(order_date_key) as last_purchase_date_key,
        count(distinct product_key) as unique_products_purchased,
        count(distinct case when has_discount then salesorderdetailid end) as discounted_items_count,
        sum(case when has_special_offer then 1 else 0 end) as special_offer_items_count
    from {{ ref('fact_sales_order_line') }}
    group by customer_key
),

customer_product_preferences as (
    select
        customer_key,
        category_name,
        sum(net_line_amount) as category_revenue,
        sum(orderqty) as category_quantity
    from {{ ref('fact_sales_order_line') }} fsol
    join {{ ref('dim_product') }} dp on fsol.product_key = dp.productid
    group by customer_key, category_name
),

top_category_per_customer as (
    select
        customer_key,
        category_name as favorite_category,
        category_revenue as favorite_category_revenue
    from (
        select
            customer_key,
            category_name,
            category_revenue,
            row_number() over (partition by customer_key order by category_revenue desc) as rn
        from customer_product_preferences
    ) ranked
    where rn = 1
),

date_dim as (
    select
        date_key,
        year,
        quarter,
        month,
        year_quarter,
        year_month
    from {{ ref('dim_date') }}
),

customer_cohorts as (
    select
        cb.customerid,
        dd_first.year as cohort_year,
        dd_first.quarter as cohort_quarter,
        dd_first.year_quarter as cohort_period
    from customer_base cb
    left join date_dim dd_first on dd_first.date_key = cast(to_char(cb.first_order_date, 'YYYYMMDD') as integer)
),

rfm_analysis as (
    select
        customerid,
        -- Recency: Days since last order
        date_part('day', current_date - last_order_date) as recency_days,
        -- Frequency: Number of orders
        total_orders as frequency,
        -- Monetary: Total lifetime value
        lifetime_value as monetary_value,
        -- RFM Scores (1-5 scale)
        case
            when date_part('day', current_date - last_order_date) <= 30 then 5
            when date_part('day', current_date - last_order_date) <= 60 then 4
            when date_part('day', current_date - last_order_date) <= 90 then 3
            when date_part('day', current_date - last_order_date) <= 180 then 2
            else 1
        end as recency_score,
        case
            when total_orders >= 20 then 5
            when total_orders >= 10 then 4
            when total_orders >= 5 then 3
            when total_orders >= 2 then 2
            else 1
        end as frequency_score,
        case
            when lifetime_value >= 50000 then 5
            when lifetime_value >= 20000 then 4
            when lifetime_value >= 10000 then 3
            when lifetime_value >= 5000 then 2
            else 1
        end as monetary_score
    from customer_base
)

select
    cb.*,
    
    -- Sales summary
    css.order_count,
    css.unique_order_days,
    css.total_revenue,
    css.total_profit,
    css.total_quantity,
    css.avg_line_item_value,
    css.unique_products_purchased,
    css.discounted_items_count,
    css.special_offer_items_count,
    
    -- Product preferences
    tcp.favorite_category,
    tcp.favorite_category_revenue,
    
    -- Cohort information
    cc.cohort_year,
    cc.cohort_quarter,
    cc.cohort_period,
    
    -- RFM Analysis
    rfm.recency_days,
    rfm.recency_score,
    rfm.frequency_score,
    rfm.monetary_score,
    rfm.recency_score::text || rfm.frequency_score::text || rfm.monetary_score::text as rfm_segment,
    case
        when rfm.recency_score >= 4 and rfm.frequency_score >= 4 and rfm.monetary_score >= 4 then 'Champions'
        when rfm.recency_score >= 3 and rfm.frequency_score >= 3 and rfm.monetary_score >= 3 then 'Loyal Customers'
        when rfm.recency_score >= 4 and rfm.frequency_score <= 2 then 'New Customers'
        when rfm.recency_score <= 2 and rfm.frequency_score >= 3 then 'At Risk'
        when rfm.recency_score <= 2 and rfm.frequency_score <= 2 then 'Lost'
        else 'Potential'
    end as rfm_category,
    
    -- Churn indicators
    case
        when date_part('day', current_date - cb.last_order_date) > 180 then 'High Risk'
        when date_part('day', current_date - cb.last_order_date) > 90 then 'Medium Risk'
        else 'Low Risk'
    end as churn_risk,
    
    -- Customer value metrics
    (css.total_revenue / nullif(css.order_count, 0)) as revenue_per_order,
    (css.total_profit / nullif(css.total_revenue, 0)) * 100 as customer_profit_margin,
    case
        when cb.customer_tenure_days > 0 then css.total_revenue / (cb.customer_tenure_days / 365.0)
        else 0
    end as annual_revenue_rate
    
from customer_base cb
left join customer_sales_summary css on cb.customerid = css.customer_key
left join top_category_per_customer tcp on cb.customerid = tcp.customer_key
left join customer_cohorts cc on cb.customerid = cc.customerid
left join rfm_analysis rfm on cb.customerid = rfm.customerid

