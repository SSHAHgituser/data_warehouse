{{ config(materialized='table') }}

with territory_base as (
    select
        st.territoryid,
        st.name as territory_name,
        st.countryregioncode,
        st."group" as territory_group,
        st.salesytd as sales_year_to_date,
        st.saleslastyear as sales_last_year,
        st.costytd as cost_year_to_date,
        st.costlastyear as cost_last_year,
        st.rowguid,
        st.modifieddate
    from {{ ref('stg_salesterritory') }} st
),

territory_sales_summary as (
    select
        territoryid,
        count(distinct customerid) as total_customers,
        count(distinct salesorderid) as total_orders,
        sum(totaldue) as total_revenue,
        avg(totaldue) as avg_order_value,
        min(orderdate) as first_order_date,
        max(orderdate) as last_order_date,
        count(distinct salespersonid) as number_of_salespeople
    from {{ ref('stg_salesorderheader') }}
    where territoryid is not null
    group by territoryid
),

territory_profitability as (
    select
        tbs.territoryid,
        tbs.total_revenue,
        tbs.total_orders,
        tb.cost_year_to_date,
        tb.cost_last_year,
        tb.sales_year_to_date,
        tb.sales_last_year,
        (tb.sales_year_to_date - tb.cost_year_to_date) as profit_ytd,
        (tb.sales_last_year - tb.cost_last_year) as profit_last_year,
        case
            when tb.cost_year_to_date > 0 then ((tb.sales_year_to_date - tb.cost_year_to_date) / tb.cost_year_to_date) * 100
            else 0
        end as profit_margin_percent_ytd
    from territory_base tb
    left join territory_sales_summary tbs on tb.territoryid = tbs.territoryid
)

select
    tb.*,
    tss.total_customers,
    tss.total_orders,
    tss.total_revenue,
    tss.avg_order_value,
    tss.first_order_date,
    tss.last_order_date,
    tss.number_of_salespeople,
    tp.profit_ytd,
    tp.profit_last_year,
    tp.profit_margin_percent_ytd,
    case
        when tss.total_revenue is null then 'No Sales'
        when tss.total_revenue < 1000000 then 'Low Performance'
        when tss.total_revenue < 5000000 then 'Medium Performance'
        else 'High Performance'
    end as performance_category
from territory_base tb
left join territory_sales_summary tss on tb.territoryid = tss.territoryid
left join territory_profitability tp on tb.territoryid = tp.territoryid

