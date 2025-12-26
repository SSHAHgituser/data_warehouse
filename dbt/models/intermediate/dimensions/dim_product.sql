{{ config(materialized='table') }}

with product_base as (
    select
        p.productid,
        p.name as product_name,
        p.productnumber,
        p.makeflag,
        p.finishedgoodsflag,
        p.color,
        p.safetystocklevel,
        p.reorderpoint,
        p.standardcost,
        p.listprice,
        p.size,
        p.sizeunitmeasurecode,
        p.weightunitmeasurecode,
        p.weight,
        p.daystomanufacture,
        p.productline,
        p.class,
        p.style,
        p.productsubcategoryid,
        p.productmodelid,
        p.sellstartdate,
        p.sellenddate,
        p.discontinueddate,
        p.rowguid,
        p.modifieddate,
        -- Subcategory
        psc.name as subcategory_name,
        psc.productcategoryid,
        -- Category
        pc.name as category_name,
        -- Model
        pm.name as model_name,
        pm.catalogdescription,
        pm.instructions,
        -- Current cost
        pch.standardcost as current_standard_cost,
        pch.enddate as cost_end_date,
        -- Current list price
        plph.listprice as current_list_price,
        plph.enddate as price_end_date
    from {{ ref('stg_product') }} p
    left join {{ ref('stg_productsubcategory') }} psc on p.productsubcategoryid = psc.productsubcategoryid
    left join {{ ref('stg_productcategory') }} pc on psc.productcategoryid = pc.productcategoryid
    left join {{ ref('stg_productmodel') }} pm on p.productmodelid = pm.productmodelid
    left join lateral (
        select standardcost, enddate
        from {{ ref('stg_productcosthistory') }} pch
        where pch.productid = p.productid
        order by pch.startdate desc
        limit 1
    ) pch on true
    left join lateral (
        select listprice, enddate
        from {{ ref('stg_productlistpricehistory') }} plph
        where plph.productid = p.productid
        order by plph.startdate desc
        limit 1
    ) plph on true
),

product_sales_summary as (
    select
        sod.productid,
        count(distinct sod.salesorderid) as total_orders,
        sum(sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount)) as total_revenue,
        sum(sod.orderqty) as total_quantity_sold,
        avg(sod.unitprice) as avg_selling_price,
        sum(sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount)) as total_revenue_after_discount,
        min(soh.orderdate) as first_sale_date,
        max(soh.orderdate) as last_sale_date
    from {{ ref('stg_salesorderdetail') }} sod
    left join {{ ref('stg_salesorderheader') }} soh on sod.salesorderid = soh.salesorderid
    group by sod.productid
),

product_inventory_summary as (
    select
        productid,
        sum(quantity) as total_inventory_quantity,
        count(distinct locationid) as number_of_locations
    from {{ ref('stg_productinventory') }}
    group by productid
),

product_profitability as (
    select
        pbs.productid,
        pbs.standardcost,
        pbs.listprice,
        pss.avg_selling_price,
        pss.total_revenue,
        pss.total_quantity_sold,
        (pss.avg_selling_price - pbs.standardcost) as profit_per_unit,
        (pss.avg_selling_price - pbs.standardcost) * pss.total_quantity_sold as total_profit,
        case
            when pbs.standardcost > 0 then ((pss.avg_selling_price - pbs.standardcost) / pbs.standardcost) * 100
            else 0
        end as profit_margin_percent
    from product_base pbs
    left join product_sales_summary pss on pbs.productid = pss.productid
)

select
    pb.*,
    pss.total_orders,
    pss.total_revenue,
    pss.total_quantity_sold,
    pss.avg_selling_price,
    pss.total_revenue_after_discount,
    pss.first_sale_date,
    pss.last_sale_date,
    pis.total_inventory_quantity,
    pis.number_of_locations,
    pp.profit_per_unit,
    pp.total_profit,
    pp.profit_margin_percent,
    case
        when pb.sellenddate is not null then 'Discontinued'
        when pb.discontinueddate is not null then 'Discontinued'
        when pb.sellstartdate > current_date then 'Not Yet Available'
        else 'Active'
    end as product_status,
    case
        when pss.total_quantity_sold is null or pss.total_quantity_sold = 0 then 'No Sales'
        when pss.total_quantity_sold < 10 then 'Low Sales'
        when pss.total_quantity_sold < 100 then 'Medium Sales'
        else 'High Sales'
    end as sales_performance
from product_base pb
left join product_sales_summary pss on pb.productid = pss.productid
left join product_inventory_summary pis on pb.productid = pis.productid
left join product_profitability pp on pb.productid = pp.productid

