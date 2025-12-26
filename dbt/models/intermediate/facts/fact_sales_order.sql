{{ config(materialized='table') }}

with sales_order_header as (
    select
        salesorderid,
        revisionnumber,
        orderdate,
        duedate,
        shipdate,
        status,
        onlineorderflag,
        purchaseordernumber,
        accountnumber,
        customerid,
        salespersonid,
        territoryid,
        billtoaddressid,
        shiptoaddressid,
        shipmethodid,
        creditcardid,
        creditcardapprovalcode,
        currencyrateid,
        subtotal,
        taxamt,
        freight,
        totaldue,
        comment,
        rowguid,
        modifieddate
    from {{ ref('stg_salesorderheader') }}
),

sales_order_totals as (
    select
        salesorderid,
        sum(orderqty) as total_quantity,
        sum(orderqty * unitprice * (1 - unitpricediscount)) as total_line_amount,
        sum(orderqty * unitprice * unitpricediscount) as total_discount_amount,
        count(*) as number_of_line_items,
        sum(case when specialofferid is not null then 1 else 0 end) as items_with_special_offer
    from {{ ref('stg_salesorderdetail') }}
    group by salesorderid
),

currency_rate_info as (
    select
        currencyrateid,
        currencyratedate,
        fromcurrencycode,
        tocurrencycode,
        averagerate,
        endofdayrate
    from {{ ref('stg_currencyrate') }}
)

select
    soh.salesorderid,
    -- Date keys
    cast(to_char(soh.orderdate, 'YYYYMMDD') as integer) as order_date_key,
    cast(to_char(soh.duedate, 'YYYYMMDD') as integer) as due_date_key,
    cast(to_char(soh.shipdate, 'YYYYMMDD') as integer) as ship_date_key,
    -- Dimension keys
    soh.customerid as customer_key,
    soh.salespersonid as employee_key,
    soh.territoryid as territory_key,
    soh.shipmethodid as ship_method_key,
    soh.creditcardid as credit_card_key,
    soh.currencyrateid as currency_rate_key,
    -- Order attributes
    soh.revisionnumber,
    soh.status,
    soh.onlineorderflag,
    soh.purchaseordernumber,
    soh.accountnumber,
    soh.creditcardapprovalcode,
    soh.comment,
    -- Financial measures
    soh.subtotal,
    soh.taxamt,
    soh.freight,
    soh.totaldue,
    sot.total_quantity,
    sot.total_line_amount,
    sot.total_discount_amount,
    sot.number_of_line_items,
    sot.items_with_special_offer,
    -- Calculated measures
    (soh.totaldue - soh.subtotal - soh.taxamt - soh.freight) as discount_amount,
    (soh.subtotal + soh.taxamt + soh.freight) as gross_amount,
    soh.totaldue as net_amount,
    -- Time measures
    date_part('day', soh.shipdate - soh.orderdate) as days_to_ship,
    date_part('day', soh.duedate - soh.orderdate) as days_until_due,
    -- Currency information
    cr.fromcurrencycode,
    cr.tocurrencycode,
    cr.averagerate,
    cr.endofdayrate,
    -- Metadata
    soh.rowguid,
    soh.modifieddate
from sales_order_header soh
left join sales_order_totals sot on soh.salesorderid = sot.salesorderid
left join currency_rate_info cr on soh.currencyrateid = cr.currencyrateid

