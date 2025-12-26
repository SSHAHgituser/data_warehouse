{{ config(materialized='table') }}

with sales_order_detail as (
    select
        salesorderid,
        salesorderdetailid,
        carriertrackingnumber,
        orderqty,
        productid,
        specialofferid,
        unitprice,
        unitpricediscount,
        (orderqty * unitprice * (1 - unitpricediscount)) as linetotal,
        rowguid,
        modifieddate
    from {{ ref('stg_salesorderdetail') }}
),

sales_order_header as (
    select
        salesorderid,
        orderdate,
        customerid,
        salespersonid,
        territoryid,
        totaldue
    from {{ ref('stg_salesorderheader') }}
),

product_info as (
    select
        productid,
        standardcost,
        listprice
    from {{ ref('stg_product') }}
),

special_offer_info as (
    select
        specialofferid,
        description as offer_description,
        discountpct,
        type as offer_type,
        category as offer_category,
        startdate as offer_start_date,
        enddate as offer_end_date,
        minqty,
        maxqty
    from {{ ref('stg_specialoffer') }}
)

select
    sod.salesorderid,
    sod.salesorderdetailid,
    -- Date key
    cast(to_char(soh.orderdate, 'YYYYMMDD') as integer) as order_date_key,
    -- Dimension keys
    soh.customerid as customer_key,
    soh.salespersonid as employee_key,
    soh.territoryid as territory_key,
    sod.productid as product_key,
    sod.specialofferid as special_offer_key,
    -- Line item attributes
    sod.carriertrackingnumber,
    sod.orderqty,
    sod.unitprice,
    sod.unitpricediscount,
    sod.linetotal,
    -- Product cost information
    p.standardcost,
    p.listprice,
    -- Special offer information
    so.offer_description,
    so.discountpct as offer_discount_percent,
    so.offer_type,
    so.offer_category,
    -- Financial measures
    (sod.orderqty * sod.unitprice) as gross_line_amount,
    (sod.orderqty * sod.unitprice * sod.unitpricediscount) as discount_amount,
    sod.linetotal as net_line_amount,
    -- Profitability measures
    (sod.unitprice - p.standardcost) as profit_per_unit,
    ((sod.unitprice - p.standardcost) * sod.orderqty) as total_profit,
    case
        when p.standardcost > 0 then ((sod.unitprice - p.standardcost) / p.standardcost) * 100
        else 0
    end as profit_margin_percent,
    -- Discount analysis
    case
        when sod.unitpricediscount > 0 then true
        else false
    end as has_discount,
    case
        when sod.specialofferid is not null then true
        else false
    end as has_special_offer,
    -- Metadata
    sod.rowguid,
    sod.modifieddate
from sales_order_detail sod
left join sales_order_header soh on sod.salesorderid = soh.salesorderid
left join product_info p on sod.productid = p.productid
left join special_offer_info so on sod.specialofferid = so.specialofferid

