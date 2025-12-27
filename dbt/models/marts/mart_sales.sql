{{ config(materialized='table') }}

-- Consolidated Sales Mart
-- Supports: Sales performance, Customer analytics, Product sales, Territory analysis, Employee performance, Time series, Market basket

with sales_line_items as (
    select
        fsol.salesorderid,
        fsol.salesorderdetailid,
        fsol.order_date_key,
        fsol.customer_key,
        fsol.employee_key,
        fsol.territory_key,
        fsol.product_key,
        fsol.special_offer_key,
        -- Line item metrics
        fsol.orderqty,
        fsol.unitprice,
        fsol.unitpricediscount,
        fsol.net_line_amount,
        fsol.gross_line_amount,
        fsol.discount_amount,
        fsol.total_profit,
        fsol.profit_margin_percent,
        fsol.has_discount,
        fsol.has_special_offer,
        -- Product info
        fsol.standardcost,
        fsol.listprice,
        -- Special offer info
        fsol.offer_description,
        fsol.offer_discount_percent,
        fsol.offer_type,
        fsol.offer_category
    from {{ ref('fact_sales_order_line') }} fsol
),

sales_orders as (
    select
        fso.salesorderid,
        fso.order_date_key,
        fso.due_date_key,
        fso.ship_date_key,
        fso.customer_key,
        fso.employee_key,
        fso.territory_key,
        fso.ship_method_key,
        fso.credit_card_key,
        -- Order metrics
        fso.subtotal,
        fso.taxamt,
        fso.freight,
        fso.totaldue,
        fso.total_quantity,
        fso.total_line_amount,
        fso.total_discount_amount,
        fso.number_of_line_items,
        fso.items_with_special_offer,
        fso.days_to_ship,
        fso.days_until_due,
        fso.onlineorderflag,
        fso.status
    from {{ ref('fact_sales_order') }} fso
),

customer_dim as (
    select
        customerid,
        personid,
        storeid,
        territoryid,
        firstname,
        lastname,
        emailpromotion,
        store_name,
        territory_name,
        countryregioncode,
        territory_group,
        lifetime_value,
        total_orders,
        customer_segment,
        customer_status,
        purchase_frequency,
        avg_order_value
    from {{ ref('dim_customer') }}
),

product_dim as (
    select
        productid,
        product_name,
        productnumber,
        category_name,
        subcategory_name,
        model_name,
        color,
        size,
        listprice,
        standardcost,
        productline,
        class,
        style,
        total_revenue,
        total_quantity_sold,
        profit_margin_percent,
        product_status,
        sales_performance
    from {{ ref('dim_product') }}
),

employee_dim as (
    select
        employee_id,
        jobtitle,
        department_name,
        territory_name as emp_territory_name,
        sales_year_to_date,
        quota_achievement_percent,
        total_orders_managed,
        total_sales_revenue,
        years_of_service
    from {{ ref('dim_employee') }}
),

territory_dim as (
    select
        territoryid,
        territory_name,
        countryregioncode,
        territory_group,
        total_revenue as territory_total_revenue,
        total_customers,
        total_orders as territory_total_orders,
        performance_category
    from {{ ref('dim_territory') }}
),

date_dim as (
    select
        date_key,
        date_day,
        year,
        quarter,
        month,
        week_of_year,
        day_of_week,
        month_name,
        day_name,
        year_month,
        year_quarter,
        season,
        day_type
    from {{ ref('dim_date') }}
)

select
    -- Keys
    sli.salesorderid,
    sli.salesorderdetailid,
    sli.order_date_key,
    so.due_date_key,
    so.ship_date_key,
    sli.customer_key,
    sli.employee_key,
    sli.territory_key,
    sli.product_key,
    so.ship_method_key,
    so.credit_card_key,
    sli.special_offer_key,
    
    -- Date dimensions
    dd.date_day as order_date,
    dd.year as order_year,
    dd.quarter as order_quarter,
    dd.month as order_month,
    dd.month_name as order_month_name,
    dd.year_quarter as order_year_quarter,
    dd.season as order_season,
    dd.day_type as order_day_type,
    
    -- Customer dimensions
    cd.firstname || ' ' || cd.lastname as customer_name,
    cd.store_name,
    cd.customer_segment,
    cd.customer_status,
    cd.purchase_frequency,
    cd.lifetime_value as customer_lifetime_value,
    cd.total_orders as customer_total_orders,
    cd.avg_order_value as customer_avg_order_value,
    
    -- Product dimensions
    pd.product_name,
    pd.category_name,
    pd.subcategory_name,
    pd.model_name,
    pd.color,
    pd.size,
    pd.productline,
    pd.class,
    pd.style,
    pd.product_status,
    pd.sales_performance as product_sales_performance,
    
    -- Employee dimensions
    ed.jobtitle,
    ed.department_name,
    ed.emp_territory_name,
    ed.sales_year_to_date,
    ed.quota_achievement_percent,
    ed.years_of_service,
    
    -- Territory dimensions
    td.territory_name,
    td.countryregioncode,
    td.territory_group,
    td.performance_category as territory_performance,
    
    -- Sales metrics (line item level)
    sli.orderqty,
    sli.unitprice,
    sli.unitpricediscount,
    sli.net_line_amount,
    sli.gross_line_amount,
    sli.discount_amount,
    sli.total_profit,
    sli.profit_margin_percent,
    sli.has_discount,
    sli.has_special_offer,
    
    -- Order metrics (order level)
    so.subtotal,
    so.taxamt,
    so.freight,
    so.totaldue as order_total,
    so.total_quantity as order_total_quantity,
    so.total_line_amount as order_total_line_amount,
    so.total_discount_amount as order_total_discount,
    so.number_of_line_items,
    so.items_with_special_offer,
    so.days_to_ship,
    so.days_until_due,
    so.onlineorderflag,
    so.status as order_status,
    
    -- Calculated metrics
    (sli.net_line_amount / nullif(so.totaldue, 0)) * 100 as line_item_pct_of_order,
    (sli.total_profit / nullif(sli.net_line_amount, 0)) * 100 as line_item_profit_margin,
    case
        when so.days_to_ship <= 3 then 'Fast'
        when so.days_to_ship <= 7 then 'Normal'
        else 'Slow'
    end as shipping_speed_category
    
from sales_line_items sli
inner join sales_orders so on sli.salesorderid = so.salesorderid
left join customer_dim cd on sli.customer_key = cd.customerid
left join product_dim pd on sli.product_key = pd.productid
left join employee_dim ed on sli.employee_key = ed.employee_id
left join territory_dim td on sli.territory_key = td.territoryid
left join date_dim dd on dd.date_key = sli.order_date_key

