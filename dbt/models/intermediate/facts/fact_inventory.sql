{{ config(materialized='table') }}

with product_inventory as (
    select
        productid,
        locationid,
        quantity,
        rowguid,
        modifieddate
    from {{ ref('stg_productinventory') }}
),

location_info as (
    select
        locationid,
        name as location_name,
        costrate,
        availability
    from {{ ref('stg_location') }}
),

product_info as (
    select
        productid,
        name as product_name,
        standardcost,
        listprice,
        safetystocklevel,
        reorderpoint
    from {{ ref('stg_product') }}
),

inventory_status as (
    select
        pi.productid,
        pi.locationid,
        pi.quantity,
        p.safetystocklevel,
        p.reorderpoint,
        p.standardcost,
        l.location_name,
        l.costrate,
        l.availability,
        -- Inventory status
        case
            when pi.quantity <= 0 then 'Out of Stock'
            when pi.quantity <= p.safetystocklevel then 'Below Safety Stock'
            when pi.quantity <= p.reorderpoint then 'At Reorder Point'
            else 'In Stock'
        end as inventory_status,
        -- Inventory value
        (pi.quantity * p.standardcost) as inventory_value,
        -- Days of inventory (if we had sales data, we could calculate this)
        pi.quantity as current_stock_level,
        -- Metadata
        pi.rowguid,
        pi.modifieddate
    from product_inventory pi
    left join location_info l on pi.locationid = l.locationid
    left join product_info p on pi.productid = p.productid
)

select
    productid as product_key,
    locationid as location_key,
    quantity,
    location_name,
    costrate,
    availability,
    inventory_status,
    inventory_value,
    current_stock_level,
    safetystocklevel,
    reorderpoint,
    standardcost,
    -- Calculated measures
    (quantity - safetystocklevel) as quantity_above_safety_stock,
    case
        when reorderpoint > 0 then (quantity / reorderpoint) * 100
        else 0
    end as reorder_point_percentage,
    rowguid,
    modifieddate
from inventory_status

