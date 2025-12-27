{{ config(materialized='table') }}

-- Operations Mart
-- Supports: Vendor performance, Production efficiency, Inventory management, Supply chain optimization

with purchase_orders as (
    select
        purchaseorderid,
        order_date_key,
        ship_date_key,
        vendor_key,
        employee_key,
        subtotal,
        taxamt,
        freight,
        totaldue,
        total_quantity,
        total_line_amount,
        number_of_line_items,
        total_received_quantity,
        total_rejected_quantity,
        rejection_rate_percent,
        fulfillment_rate_percent,
        days_to_ship
    from {{ ref('fact_purchase_order') }}
),

work_orders as (
    select
        workorderid,
        start_date_key,
        end_date_key,
        due_date_key,
        product_key,
        scrap_reason_key,
        orderqty,
        scrappedqty,
        number_of_operations,
        production_days,
        days_until_due,
        days_early_or_late,
        total_planned_cost,
        total_actual_cost,
        cost_variance,
        cost_variance_percent,
        total_actual_hours,
        hours_per_unit,
        scrap_rate_percent,
        good_quantity,
        delivery_status
    from {{ ref('fact_work_order') }}
),

inventory_summary as (
    select
        product_key,
        sum(quantity) as total_quantity,
        sum(inventory_value) as total_inventory_value,
        count(distinct location_key) as number_of_locations,
        max(case when inventory_status = 'Out of Stock' then 1 else 0 end) as has_out_of_stock,
        max(case when inventory_status = 'Below Safety Stock' then 1 else 0 end) as has_low_stock,
        max(case when inventory_status = 'At Reorder Point' then 1 else 0 end) as at_reorder_point
    from {{ ref('fact_inventory') }}
    group by product_key
),

vendor_performance as (
    select
        vendor_key,
        count(distinct purchaseorderid) as total_purchase_orders,
        sum(totaldue) as total_purchase_amount,
        sum(total_quantity) as total_quantity_purchased,
        avg(days_to_ship) as avg_delivery_days,
        avg(rejection_rate_percent) as avg_rejection_rate,
        avg(fulfillment_rate_percent) as avg_fulfillment_rate,
        min(order_date_key) as first_purchase_date_key,
        max(order_date_key) as last_purchase_date_key
    from purchase_orders
    group by vendor_key
),

production_summary as (
    select
        product_key,
        count(distinct workorderid) as total_work_orders,
        sum(orderqty) as total_production_quantity,
        sum(scrappedqty) as total_scrapped_quantity,
        sum(good_quantity) as total_good_quantity,
        avg(production_days) as avg_production_days,
        avg(cost_variance_percent) as avg_cost_variance_percent,
        avg(scrap_rate_percent) as avg_scrap_rate,
        sum(total_actual_hours) as total_production_hours,
        sum(total_actual_cost) as total_production_cost,
        count(distinct case when delivery_status = 'On Time' then workorderid end) as on_time_orders,
        count(distinct case when delivery_status = 'Late' then workorderid end) as late_orders
    from work_orders
    group by product_key
),

product_info as (
    select
        productid,
        product_name,
        category_name,
        standardcost,
        safetystocklevel,
        reorderpoint
    from {{ ref('dim_product') }}
),

vendor_info as (
    select
        vendor_id,
        vendor_name,
        creditrating,
        preferredvendorstatus,
        activeflag,
        total_purchase_amount,
        avg_delivery_days,
        number_of_products_supplied,
        vendor_status,
        vendor_type,
        vendor_size_category
    from {{ ref('dim_vendor') }}
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
)

-- Purchase Order Operations
select
    'purchase_order' as operation_type,
    po.purchaseorderid::varchar as operation_id,
    po.order_date_key,
    po.ship_date_key,
    dd_order.year as order_year,
    dd_order.quarter as order_quarter,
    dd_order.month as order_month,
    po.vendor_key,
    vi.vendor_name,
    vi.vendor_status,
    vi.vendor_type,
    po.employee_key,
    pod.productid as product_key,
    pi.product_name,
    pi.category_name,
    po.subtotal,
    po.taxamt,
    po.freight,
    po.totaldue,
    po.total_quantity,
    po.total_line_amount,
    po.number_of_line_items,
    po.total_received_quantity,
    po.total_rejected_quantity,
    po.rejection_rate_percent,
    po.fulfillment_rate_percent,
    po.days_to_ship,
    vp.avg_delivery_days as vendor_avg_delivery_days,
    vp.avg_rejection_rate as vendor_avg_rejection_rate,
    null::integer as production_days,
    null::numeric as cost_variance,
    null::numeric as scrap_rate_percent
from purchase_orders po
left join vendor_info vi on po.vendor_key = vi.vendor_id
left join (
    select distinct purchaseorderid, productid
    from {{ ref('stg_purchaseorderdetail') }}
) pod on po.purchaseorderid = pod.purchaseorderid
left join product_info pi on pod.productid = pi.productid
left join vendor_performance vp on po.vendor_key = vp.vendor_key
left join date_dim dd_order on dd_order.date_key = po.order_date_key

union all

-- Work Order Operations
select
    'work_order' as operation_type,
    wo.workorderid::varchar as operation_id,
    wo.start_date_key as order_date_key,
    wo.end_date_key as ship_date_key,
    dd_start.year as order_year,
    dd_start.quarter as order_quarter,
    dd_start.month as order_month,
    null::integer as vendor_key,
    null::varchar as vendor_name,
    null::varchar as vendor_status,
    null::varchar as vendor_type,
    null::integer as employee_key,
    wo.product_key,
    pi.product_name,
    pi.category_name,
    null::numeric as subtotal,
    null::numeric as taxamt,
    null::numeric as freight,
    wo.total_actual_cost as totaldue,
    wo.orderqty as total_quantity,
    wo.total_actual_cost as total_line_amount,
    wo.number_of_operations as number_of_line_items,
    wo.good_quantity as total_received_quantity,
    wo.scrappedqty as total_rejected_quantity,
    wo.scrap_rate_percent as rejection_rate_percent,
    ((wo.good_quantity / nullif(wo.orderqty, 0)) * 100) as fulfillment_rate_percent,
    wo.production_days as days_to_ship,
    null::numeric as vendor_avg_delivery_days,
    null::numeric as vendor_avg_rejection_rate,
    wo.production_days,
    wo.cost_variance,
    wo.scrap_rate_percent
from work_orders wo
left join product_info pi on wo.product_key = pi.productid
left join date_dim dd_start on dd_start.date_key = wo.start_date_key

