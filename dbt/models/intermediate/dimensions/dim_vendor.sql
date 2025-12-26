{{ config(materialized='table') }}

with vendor_base as (
    select
        v.businessentityid as vendor_id,
        v.accountnumber,
        v.name as vendor_name,
        v.creditrating,
        v.preferredvendorstatus,
        v.activeflag,
        v.purchasingwebserviceurl,
        v.modifieddate,
        -- Address information
        a.addressline1,
        a.addressline2,
        a.city,
        a.postalcode,
        sp.name as state_province_name,
        sp.stateprovincecode,
        cr.name as country_region_name,
        cr.countryregioncode
    from {{ ref('stg_vendor') }} v
    left join {{ ref('stg_businessentityaddress') }} bea on v.businessentityid = bea.businessentityid
    left join {{ ref('stg_address') }} a on bea.addressid = a.addressid
    left join {{ ref('stg_stateprovince') }} sp on a.stateprovinceid = sp.stateprovinceid
    left join {{ ref('stg_countryregion') }} cr on sp.countryregioncode = cr.countryregioncode
),

vendor_purchase_summary as (
    select
        v.businessentityid as vendor_id,
        count(distinct poh.purchaseorderid) as total_purchase_orders,
        sum(pod.orderqty * pod.unitprice) as total_purchase_amount,
        sum(pod.orderqty) as total_quantity_purchased,
        avg(pod.unitprice) as avg_purchase_price,
        min(poh.orderdate) as first_purchase_date,
        max(poh.orderdate) as last_purchase_date,
        avg(poh.shipdate - poh.orderdate) as avg_delivery_days
    from {{ ref('stg_vendor') }} v
    left join {{ ref('stg_purchaseorderheader') }} poh on v.businessentityid = poh.vendorid
    left join {{ ref('stg_purchaseorderdetail') }} pod on poh.purchaseorderid = pod.purchaseorderid
    group by v.businessentityid
),

vendor_product_count as (
    select
        pv.businessentityid as vendorid,
        count(distinct pv.productid) as number_of_products_supplied,
        avg(pv.averageleadtime) as avg_lead_time,
        avg(pv.standardprice) as avg_standard_price,
        min(pv.lastreceiptcost) as min_receipt_cost,
        max(pv.lastreceiptcost) as max_receipt_cost
    from {{ ref('stg_productvendor') }} pv
    group by pv.businessentityid
)

select
    vb.*,
    vps.total_purchase_orders,
    vps.total_purchase_amount,
    vps.total_quantity_purchased,
    vps.avg_purchase_price,
    vps.first_purchase_date,
    vps.last_purchase_date,
    vps.avg_delivery_days,
    vpc.number_of_products_supplied,
    vpc.avg_lead_time,
    vpc.avg_standard_price,
    vpc.min_receipt_cost,
    vpc.max_receipt_cost,
    case
        when vb.activeflag = '1' then 'Active'
        else 'Inactive'
    end as vendor_status,
    case
        when vb.preferredvendorstatus = '1' then 'Preferred'
        else 'Standard'
    end as vendor_type,
    case
        when vps.total_purchase_amount is null then 'No Purchases'
        when vps.total_purchase_amount < 100000 then 'Small'
        when vps.total_purchase_amount < 500000 then 'Medium'
        else 'Large'
    end as vendor_size_category
from vendor_base vb
left join vendor_purchase_summary vps on vb.vendor_id = vps.vendor_id
left join vendor_product_count vpc on vb.vendor_id = vpc.vendorid

