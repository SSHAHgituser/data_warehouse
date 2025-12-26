{{ config(materialized='table') }}

with purchase_order_header as (
    select
        purchaseorderid,
        revisionnumber,
        status,
        orderdate,
        shipdate,
        subtotal,
        taxamt,
        freight,
        (subtotal + taxamt + freight) as totaldue,
        vendorid,
        shipmethodid,
        employeeid,
        modifieddate
    from {{ ref('stg_purchaseorderheader') }}
),

purchase_order_totals as (
    select
        purchaseorderid,
        sum(orderqty) as total_quantity,
        sum(orderqty * unitprice) as total_line_amount,
        count(*) as number_of_line_items,
        sum(receivedqty) as total_received_quantity,
        sum(rejectedqty) as total_rejected_quantity
    from {{ ref('stg_purchaseorderdetail') }}
    group by purchaseorderid
)

select
    poh.purchaseorderid,
    -- Date keys
    cast(to_char(poh.orderdate, 'YYYYMMDD') as integer) as order_date_key,
    cast(to_char(poh.shipdate, 'YYYYMMDD') as integer) as ship_date_key,
    -- Dimension keys
    poh.vendorid as vendor_key,
    poh.shipmethodid as ship_method_key,
    poh.employeeid as employee_key,
    -- Order attributes
    poh.revisionnumber,
    poh.status,
    -- Financial measures
    poh.subtotal,
    poh.taxamt,
    poh.freight,
    poh.totaldue,
    pot.total_quantity,
    pot.total_line_amount,
    pot.number_of_line_items,
    pot.total_received_quantity,
    pot.total_rejected_quantity,
    -- Calculated measures
    (poh.subtotal + poh.taxamt + poh.freight) as gross_amount,
    poh.totaldue as net_amount,
    -- Time measures
    date_part('day', poh.shipdate - poh.orderdate) as days_to_ship,
    -- Quality measures
    case
        when pot.total_quantity > 0 then (pot.total_rejected_quantity / pot.total_quantity) * 100
        else 0
    end as rejection_rate_percent,
    case
        when pot.total_quantity > 0 then (pot.total_received_quantity / pot.total_quantity) * 100
        else 0
    end as fulfillment_rate_percent,
    -- Metadata
    poh.modifieddate
from purchase_order_header poh
left join purchase_order_totals pot on poh.purchaseorderid = pot.purchaseorderid

