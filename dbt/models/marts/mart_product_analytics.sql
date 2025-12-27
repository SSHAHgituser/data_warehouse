{{ config(materialized='table') }}

-- Product Analytics Mart
-- Supports: Product profitability, Sales trends, Inventory optimization, Product recommendations, BOM analysis

with product_base as (
    select
        productid,
        product_name,
        productnumber,
        category_name,
        subcategory_name,
        model_name,
        color,
        size,
        productline,
        class,
        style,
        listprice,
        standardcost,
        safetystocklevel,
        reorderpoint,
        total_revenue,
        total_quantity_sold,
        total_orders,
        profit_margin_percent,
        product_status,
        sales_performance,
        first_sale_date,
        last_sale_date
    from {{ ref('dim_product') }}
),

product_sales_trends as (
    select
        product_key,
        order_date_key,
        sum(net_line_amount) as daily_revenue,
        sum(orderqty) as daily_quantity,
        sum(total_profit) as daily_profit,
        count(distinct customer_key) as daily_unique_customers,
        count(distinct salesorderid) as daily_order_count
    from {{ ref('fact_sales_order_line') }}
    group by product_key, order_date_key
),

product_monthly_sales as (
    select
        product_key,
        dd.year,
        dd.month,
        sum(daily_revenue) as monthly_revenue,
        sum(daily_quantity) as monthly_quantity,
        sum(daily_profit) as monthly_profit,
        sum(daily_unique_customers) as monthly_unique_customers,
        sum(daily_order_count) as monthly_order_count
    from product_sales_trends pst
    join {{ ref('dim_date') }} dd on dd.date_key = pst.order_date_key
    group by product_key, dd.year, dd.month
),

product_seasonality as (
    select
        product_key,
        dd.season,
        avg(daily_revenue) as avg_seasonal_revenue,
        sum(daily_revenue) as total_seasonal_revenue,
        sum(daily_quantity) as total_seasonal_quantity
    from product_sales_trends pst
    join {{ ref('dim_date') }} dd on dd.date_key = pst.order_date_key
    group by product_key, dd.season
),

product_inventory as (
    select
        product_key,
        sum(quantity) as total_inventory_quantity,
        sum(inventory_value) as total_inventory_value,
        count(distinct location_key) as number_of_locations,
        max(case when inventory_status = 'Out of Stock' then 1 else 0 end) as has_out_of_stock_location,
        max(case when inventory_status = 'Below Safety Stock' then 1 else 0 end) as has_low_stock_location
    from {{ ref('fact_inventory') }}
    group by product_key
),

product_customer_analysis as (
    select
        product_key,
        count(distinct customer_key) as unique_customers,
        avg(net_line_amount) as avg_line_item_value,
        count(distinct case when has_discount then customer_key end) as customers_with_discount,
        count(distinct case when has_special_offer then customer_key end) as customers_with_special_offer
    from {{ ref('fact_sales_order_line') }}
    group by product_key
),

product_market_basket as (
    select
        fsol1.product_key as product_id,
        fsol2.product_key as related_product_id,
        count(distinct fsol1.salesorderid) as co_occurrence_count
    from {{ ref('fact_sales_order_line') }} fsol1
    join {{ ref('fact_sales_order_line') }} fsol2 
        on fsol1.salesorderid = fsol2.salesorderid 
        and fsol1.product_key != fsol2.product_key
    group by fsol1.product_key, fsol2.product_key
),

top_related_products as (
    select
        product_id,
        related_product_id,
        co_occurrence_count,
        row_number() over (partition by product_id order by co_occurrence_count desc) as rank
    from product_market_basket
),

top_related_product as (
    select
        product_id,
        related_product_id as top_related_product_id,
        co_occurrence_count as related_product_co_occurrence
    from top_related_products
    where rank = 1
)

select
    pb.*,
    
    -- Inventory metrics
    pi.total_inventory_quantity,
    pi.total_inventory_value,
    pi.number_of_locations,
    pi.has_out_of_stock_location,
    pi.has_low_stock_location,
    case
        when pi.total_inventory_quantity is null then 'No Inventory Data'
        when pi.has_out_of_stock_location = 1 then 'Out of Stock'
        when pi.has_low_stock_location = 1 then 'Low Stock'
        when pi.total_inventory_quantity <= pb.reorderpoint then 'At Reorder Point'
        else 'In Stock'
    end as inventory_status,
    
    -- Customer metrics
    pca.unique_customers,
    pca.avg_line_item_value,
    pca.customers_with_discount,
    pca.customers_with_special_offer,
    
    -- Market basket
    trp.top_related_product_id,
    trp.related_product_co_occurrence,
    
    -- Sales velocity
    case
        when pb.total_quantity_sold > 0 and date_part('day', pb.last_sale_date - pb.first_sale_date) > 0
        then pb.total_quantity_sold / (date_part('day', pb.last_sale_date - pb.first_sale_date) / 30.0)
        else 0
    end as monthly_sales_velocity,
    
    -- Inventory turnover
    case
        when pi.total_inventory_quantity > 0 
        then pb.total_quantity_sold / pi.total_inventory_quantity
        else null
    end as inventory_turnover_ratio,
    
    -- Days of inventory
    case
        when pb.total_quantity_sold > 0 and date_part('day', pb.last_sale_date - pb.first_sale_date) > 0
        then (pi.total_inventory_quantity / (pb.total_quantity_sold / (date_part('day', pb.last_sale_date - pb.first_sale_date) / 30.0))) * 30
        else null
    end as days_of_inventory,
    
    -- Profitability metrics
    (pb.total_revenue - (pb.standardcost * pb.total_quantity_sold)) as total_profit,
    case
        when pb.total_revenue > 0 
        then ((pb.total_revenue - (pb.standardcost * pb.total_quantity_sold)) / pb.total_revenue) * 100
        else 0
    end as profit_margin_percent_calculated,
    
    -- Product lifecycle
    date_part('day', current_date - pb.first_sale_date) as days_since_first_sale,
    date_part('day', current_date - pb.last_sale_date) as days_since_last_sale,
    case
        when pb.last_sale_date < current_date - interval '90 days' then 'Declining'
        when pb.last_sale_date < current_date - interval '30 days' then 'Stable'
        else 'Active'
    end as product_lifecycle_stage
    
from product_base pb
left join product_inventory pi on pb.productid = pi.product_key
left join product_customer_analysis pca on pb.productid = pca.product_key
left join top_related_product trp on pb.productid = trp.product_id

