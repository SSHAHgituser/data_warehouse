{{ config(materialized='table') }}

{#
    Metrics Dimension Table
    =======================
    Documents all metrics in the global metrics table with:
    - Business definitions and meaning
    - Targets and goals
    - Alert criteria for monitoring
    - Recommended follow-up actions
    - Related metrics for impact tracking
    - Ownership information
    
    This enables:
    - Self-service analytics with clear metric definitions
    - Metrics governance and accountability
    - Automated alerting and monitoring
    - Impact analysis across related metrics
#}

with metrics_catalog as (
    select * from (
        values
        -- ============================================
        -- SALES ORDER METRICS (SO_*)
        -- ============================================
        (
            'SO_REVENUE',
            'Sales Order Revenue',
            'Sales',
            'Total revenue from sales orders including tax and freight. Represents the final amount due from customers.',
            'YoY growth >= 10%',
            'ALERT if: MoM decline > 15% OR YoY decline > 10%',
            'If declining: Review pricing strategy, analyze customer segments, check for seasonal patterns. If increasing: Identify top-performing territories and replicate success.',
            'SO_QUANTITY, SOL_PROFIT, EQ_SALES_YTD',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SO_SUBTOTAL',
            'Sales Order Subtotal',
            'Sales',
            'Order subtotal before tax and freight charges. Useful for analyzing base sales performance.',
            'Maintain 85-90% of SO_REVENUE',
            'ALERT if: Ratio to SO_REVENUE < 80% (high tax/freight burden)',
            'Compare with SO_REVENUE to understand tax/freight impact. Monitor ratio changes over time.',
            'SO_REVENUE, SO_TAX, SO_FREIGHT',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SO_TAX',
            'Sales Order Tax',
            'Sales',
            'Tax amount collected on sales orders. Varies by territory and product category.',
            'Maintain compliance (territory-specific)',
            'ALERT if: Tax rate variance > 2% from expected by territory',
            'Ensure compliance with tax regulations. Review by territory for anomalies.',
            'SO_REVENUE, SO_SUBTOTAL',
            'Michael Chen',
            'michael.chen@adventureworks.com'
        ),
        (
            'SO_FREIGHT',
            'Sales Order Freight',
            'Sales',
            'Shipping and freight charges for sales orders. Impacts customer satisfaction and margins.',
            'Freight <= 5% of SO_SUBTOTAL',
            'ALERT if: Freight > 8% of subtotal OR avg freight per order increases > 20%',
            'If high: Negotiate carrier rates, optimize shipping routes. Compare against competitors.',
            'SO_REVENUE, SO_DAYS_TO_SHIP',
            'Michael Chen',
            'michael.chen@adventureworks.com'
        ),
        (
            'SO_QUANTITY',
            'Sales Order Quantity',
            'Sales',
            'Total quantity of items ordered. Indicates volume of business activity.',
            'YoY growth >= 5%',
            'ALERT if: Daily quantity < 50% of 30-day avg OR sudden spike > 200%',
            'Track trends for demand forecasting. Compare with inventory levels to prevent stockouts.',
            'SO_REVENUE, INV_QUANTITY, SOL_QUANTITY',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SO_LINE_ITEMS',
            'Sales Order Line Items',
            'Sales',
            'Number of distinct line items per order. Indicates order complexity and cross-selling effectiveness.',
            'Avg >= 3 line items per order',
            'ALERT if: Avg line items per order < 2 (cross-sell opportunity)',
            'Low values may indicate cross-sell opportunities. High values may require fulfillment optimization.',
            'SO_REVENUE, SOL_REVENUE',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SO_DISCOUNT',
            'Sales Order Discount',
            'Sales',
            'Total discount amount applied to orders. Impacts revenue and profit margins.',
            'Discount <= 10% of gross revenue',
            'ALERT if: Discount rate > 15% OR MoM increase > 5 percentage points',
            'Monitor discount trends. High discounts may indicate pricing issues or aggressive sales tactics.',
            'SO_REVENUE, SOL_PROFIT, SOL_PROFIT_MARGIN',
            'David Williams',
            'david.williams@adventureworks.com'
        ),
        (
            'SO_DAYS_TO_SHIP',
            'Days to Ship',
            'Sales',
            'Number of days from order placement to shipment. Key customer satisfaction metric.',
            'Avg <= 3 days',
            'ALERT if: Avg > 5 days OR any order > 10 days',
            'If increasing: Review warehouse operations, staffing levels, carrier performance. Target < 3 days.',
            'SO_FREIGHT, PO_DAYS_TO_SHIP',
            'Lisa Martinez',
            'lisa.martinez@adventureworks.com'
        ),
        
        -- ============================================
        -- SALES LINE ITEM METRICS (SOL_*)
        -- ============================================
        (
            'SOL_REVENUE',
            'Line Item Revenue',
            'Sales',
            'Net revenue per line item after discounts. Granular view of product-level sales.',
            'Positive growth by product category',
            'ALERT if: Top 10 products show > 20% decline MoM',
            'Identify top-selling products. Analyze by category for portfolio optimization.',
            'SO_REVENUE, SOL_PROFIT, SOL_QUANTITY',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SOL_GROSS_AMOUNT',
            'Line Item Gross Amount',
            'Sales',
            'Gross amount before discounts. Compare with net to understand discount impact.',
            'Gross-to-net ratio >= 90%',
            'ALERT if: Gross-to-net ratio < 85% (heavy discounting)',
            'High gross-to-net variance indicates heavy discounting. Review pricing strategy.',
            'SOL_REVENUE, SOL_DISCOUNT',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SOL_QUANTITY',
            'Line Item Quantity',
            'Sales',
            'Quantity ordered per line item. Used for demand analysis and inventory planning.',
            'Align with demand forecast ±10%',
            'ALERT if: Actual vs forecast variance > 25%',
            'Feed into demand forecasting models. Monitor for unusual spikes or drops.',
            'SO_QUANTITY, INV_QUANTITY',
            'Sarah Johnson',
            'sarah.johnson@adventureworks.com'
        ),
        (
            'SOL_PROFIT',
            'Line Item Profit',
            'Sales',
            'Profit per line item (revenue minus cost). Key profitability metric.',
            'Positive profit on all line items',
            'ALERT if: Any product shows negative profit OR profit decline > 30% MoM',
            'Negative profit requires immediate attention. Review product costs and pricing.',
            'SOL_REVENUE, SOL_PROFIT_MARGIN, WO_ACTUAL_COST',
            'David Williams',
            'david.williams@adventureworks.com'
        ),
        (
            'SOL_PROFIT_MARGIN',
            'Line Item Profit Margin',
            'Sales',
            'Profit margin percentage per line item. Target varies by product category.',
            '>= 25% overall, >= 15% minimum',
            'ALERT if: Margin < 15% OR margin decline > 10 points MoM',
            'Below 20%: Review costs or pricing. Above 50%: Validate data accuracy.',
            'SOL_PROFIT, SOL_REVENUE',
            'David Williams',
            'david.williams@adventureworks.com'
        ),
        (
            'SOL_DISCOUNT',
            'Line Item Discount',
            'Sales',
            'Discount amount per line item. Impacts profitability at product level.',
            'Discount <= 12% of line item gross',
            'ALERT if: Product discount > 20% OR special offer ROI negative',
            'Analyze by product to identify over-discounted items. Review special offer effectiveness.',
            'SO_DISCOUNT, SOL_PROFIT',
            'David Williams',
            'david.williams@adventureworks.com'
        ),
        (
            'SOL_UNIT_PRICE',
            'Unit Price',
            'Sales',
            'Selling price per unit. May vary from list price due to discounts or negotiations.',
            'Maintain >= 95% of list price avg',
            'ALERT if: Avg selling price < 90% of list price',
            'Compare with list price to understand discounting patterns. Monitor price erosion.',
            'SOL_PROFIT_MARGIN, INV_VALUE',
            'David Williams',
            'david.williams@adventureworks.com'
        ),
        
        -- ============================================
        -- INVENTORY METRICS (INV_*)
        -- ============================================
        (
            'INV_QUANTITY',
            'Inventory Quantity',
            'Inventory',
            'Current stock quantity per product/location. Critical for fulfillment and planning.',
            'Between safety stock and 2x reorder point',
            'ALERT if: Quantity <= 0 (stockout) OR quantity < safety stock level',
            'Below reorder point: Trigger purchase order. Above safety stock: Review for excess.',
            'SOL_QUANTITY, INV_REORDER_PCT, PO_QUANTITY',
            'Robert Taylor',
            'robert.taylor@adventureworks.com'
        ),
        (
            'INV_VALUE',
            'Inventory Value',
            'Inventory',
            'Total inventory value (quantity × standard cost). Impacts balance sheet and cash flow.',
            'Inventory turnover >= 6x annually',
            'ALERT if: Inventory value increases > 20% without corresponding sales increase',
            'High values may indicate slow-moving inventory. Review aging and consider markdowns.',
            'INV_QUANTITY, WO_ACTUAL_COST',
            'Robert Taylor',
            'robert.taylor@adventureworks.com'
        ),
        (
            'INV_ABOVE_SAFETY',
            'Quantity Above Safety Stock',
            'Inventory',
            'Units above safety stock level. Indicates buffer against demand variability.',
            'Positive value (above safety stock)',
            'ALERT if: Value <= 0 (at or below safety stock)',
            'Negative values require immediate replenishment. Very high values indicate excess.',
            'INV_QUANTITY, INV_REORDER_PCT',
            'Robert Taylor',
            'robert.taylor@adventureworks.com'
        ),
        (
            'INV_REORDER_PCT',
            'Reorder Point Percentage',
            'Inventory',
            'Current stock as percentage of reorder point. Below 100% triggers reorder.',
            'Between 100% and 200%',
            'ALERT if: < 100% (needs reorder) OR > 300% (potential overstock)',
            'Below 100%: Create purchase order. Above 200%: Review for overstock.',
            'INV_QUANTITY, PO_QUANTITY',
            'Robert Taylor',
            'robert.taylor@adventureworks.com'
        ),
        
        -- ============================================
        -- PURCHASE ORDER METRICS (PO_*)
        -- ============================================
        (
            'PO_AMOUNT',
            'Purchase Order Amount',
            'Procurement',
            'Total purchase order value including tax and freight. Represents procurement spend.',
            'Within budget ±5%',
            'ALERT if: Monthly spend > 110% of budget OR single PO > $100K',
            'Track against budget. Analyze by vendor for negotiation opportunities.',
            'PO_QUANTITY, INV_VALUE',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_SUBTOTAL',
            'Purchase Order Subtotal',
            'Procurement',
            'Purchase order subtotal before tax and freight. Base cost for procurement analysis.',
            'Achieve 3-5% YoY cost reduction',
            'ALERT if: Unit cost increases > 10% for any vendor',
            'Compare across vendors for same products. Identify cost savings opportunities.',
            'PO_AMOUNT, PO_TAX, PO_FREIGHT',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_TAX',
            'Purchase Order Tax',
            'Procurement',
            'Tax amount on purchase orders. Varies by vendor location and product type.',
            'Proper tax treatment per jurisdiction',
            'ALERT if: Tax rate anomaly detected vs expected',
            'Ensure proper tax treatment. Review for exemption opportunities.',
            'PO_AMOUNT, PO_SUBTOTAL',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_FREIGHT',
            'Purchase Order Freight',
            'Procurement',
            'Inbound freight costs. Impacts total landed cost of inventory.',
            'Freight <= 3% of PO subtotal',
            'ALERT if: Freight > 5% of subtotal',
            'Negotiate freight terms with vendors. Consider consolidation for savings.',
            'PO_AMOUNT, PO_DAYS_TO_SHIP',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_QUANTITY',
            'Purchase Order Quantity',
            'Procurement',
            'Total quantity ordered from vendors. Drives inventory replenishment.',
            'Match demand forecast ±15%',
            'ALERT if: Order quantity variance > 30% from forecast',
            'Align with demand forecasts. Consider economic order quantities.',
            'INV_QUANTITY, PO_RECEIVED_QTY',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_RECEIVED_QTY',
            'Received Quantity',
            'Procurement',
            'Quantity actually received from vendors. May differ from ordered quantity.',
            '>= 98% of ordered quantity',
            'ALERT if: Received < 95% of ordered for any vendor',
            'Variances indicate vendor reliability issues. Track by vendor.',
            'PO_QUANTITY, PO_FULFILLMENT_RATE',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_REJECTED_QTY',
            'Rejected Quantity',
            'Procurement',
            'Quantity rejected due to quality issues. Impacts vendor relationships.',
            '< 2% of received quantity',
            'ALERT if: Rejection > 5% for any shipment OR any critical item rejected',
            'High rejection: Review vendor quality, consider alternative suppliers.',
            'PO_REJECTION_RATE, PO_RECEIVED_QTY',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_REJECTION_RATE',
            'Rejection Rate',
            'Procurement',
            'Percentage of received items rejected. Key vendor quality metric.',
            '< 2%',
            'ALERT if: Rate > 5% OR increasing trend over 3 months',
            'Above 5%: Escalate to vendor. Above 10%: Consider supplier change.',
            'PO_REJECTED_QTY, WO_SCRAP_RATE',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_FULFILLMENT_RATE',
            'Fulfillment Rate',
            'Procurement',
            'Percentage of ordered quantity received. Measures vendor reliability.',
            '>= 98%',
            'ALERT if: Rate < 95% OR vendor falls below 90%',
            'Below 95%: Review vendor performance. Consider backup suppliers.',
            'PO_RECEIVED_QTY, PO_QUANTITY',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        (
            'PO_DAYS_TO_SHIP',
            'Purchase Days to Ship',
            'Procurement',
            'Vendor lead time from order to shipment. Critical for inventory planning.',
            'Within agreed lead time ±2 days',
            'ALERT if: Lead time > agreed + 5 days OR increasing trend',
            'Long lead times: Increase safety stock or find alternative vendors.',
            'SO_DAYS_TO_SHIP, INV_QUANTITY',
            'Jennifer Brown',
            'jennifer.brown@adventureworks.com'
        ),
        
        -- ============================================
        -- WORK ORDER METRICS (WO_*)
        -- ============================================
        (
            'WO_ORDER_QTY',
            'Work Order Quantity',
            'Production',
            'Quantity to be produced in work order. Drives production planning.',
            'Align with demand forecast',
            'ALERT if: Backlog > 2 weeks of demand',
            'Align with sales forecasts and inventory targets.',
            'WO_GOOD_QTY, INV_QUANTITY',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_GOOD_QTY',
            'Good Quantity Produced',
            'Production',
            'Quantity of acceptable products produced. Excludes scrapped items.',
            '>= 95% of order quantity',
            'ALERT if: Good qty < 90% of order qty',
            'Compare with order qty to assess production efficiency.',
            'WO_ORDER_QTY, WO_SCRAPPED_QTY',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_SCRAPPED_QTY',
            'Scrapped Quantity',
            'Production',
            'Quantity scrapped due to defects or issues. Direct cost impact.',
            '< 5% of order quantity',
            'ALERT if: Scrap > 10% OR sudden increase > 100%',
            'Analyze by scrap reason. Implement corrective actions for top causes.',
            'WO_SCRAP_RATE, WO_GOOD_QTY',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_SCRAP_RATE',
            'Scrap Rate',
            'Production',
            'Percentage of production scrapped. Key quality metric.',
            '< 3%',
            'ALERT if: Rate > 5% OR rate increases > 2 points MoM',
            'Above 5%: Review process controls. Implement Six Sigma if persistent.',
            'WO_SCRAPPED_QTY, PO_REJECTION_RATE',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_PLANNED_COST',
            'Planned Cost',
            'Production',
            'Budgeted/standard cost for work order. Baseline for variance analysis.',
            'Accurate within 5% of actual',
            'ALERT if: Planned vs actual variance > 15% consistently',
            'Use for job costing and pricing decisions.',
            'WO_ACTUAL_COST, WO_COST_VARIANCE',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_ACTUAL_COST',
            'Actual Cost',
            'Production',
            'Actual production cost incurred. Includes labor, materials, overhead.',
            '<= 105% of planned cost',
            'ALERT if: Actual > 115% of planned',
            'Compare with planned cost. Investigate significant variances.',
            'WO_PLANNED_COST, WO_COST_VARIANCE, SOL_PROFIT',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_COST_VARIANCE',
            'Cost Variance',
            'Production',
            'Difference between actual and planned cost. Positive = over budget.',
            '<= 5% of planned cost',
            'ALERT if: Variance > 10% OR negative trend over 3 periods',
            'Positive variance: Investigate causes (labor, materials, inefficiency).',
            'WO_ACTUAL_COST, WO_PLANNED_COST',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_COST_VARIANCE_PCT',
            'Cost Variance Percent',
            'Production',
            'Cost variance as percentage of planned cost. Normalizes for comparison.',
            '<= 5%',
            'ALERT if: > 10% OR > 20% for any single work order',
            'Above 10%: Requires management attention. Above 20%: Escalate.',
            'WO_COST_VARIANCE',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_PRODUCTION_DAYS',
            'Production Days',
            'Production',
            'Days to complete production. Measures manufacturing cycle time.',
            'Within standard cycle time ±10%',
            'ALERT if: Cycle time > 150% of standard',
            'Long cycle times: Review bottlenecks, staffing, equipment capacity.',
            'WO_ACTUAL_HOURS, SO_DAYS_TO_SHIP',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_ACTUAL_HOURS',
            'Actual Production Hours',
            'Production',
            'Total labor hours for work order. Key input for capacity planning.',
            'Within standard hours ±15%',
            'ALERT if: Overtime > 20% of total hours OR hours > 130% of standard',
            'Compare with standard hours. Overtime may indicate capacity issues.',
            'WO_HOURS_PER_UNIT, WO_PRODUCTION_DAYS',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        (
            'WO_HOURS_PER_UNIT',
            'Hours per Unit',
            'Production',
            'Labor hours per unit produced. Measures production efficiency.',
            '<= standard hours per unit',
            'ALERT if: Hours/unit > 120% of standard OR increasing trend',
            'Increasing trend: Review process, training, equipment condition.',
            'WO_ACTUAL_HOURS, WO_GOOD_QTY',
            'James Anderson',
            'james.anderson@adventureworks.com'
        ),
        
        -- ============================================
        -- EMPLOYEE QUOTA METRICS (EQ_*)
        -- ============================================
        (
            'EQ_QUOTA',
            'Sales Quota',
            'HR',
            'Sales target assigned to salesperson for the period. Basis for performance evaluation.',
            '80-120% achievement rate across team',
            'ALERT if: < 50% of team on track OR quota utilization < 70%',
            'Review quota setting methodology. Ensure quotas are achievable but challenging.',
            'EQ_SALES_YTD, EQ_ACHIEVEMENT_PCT',
            'Amanda White',
            'amanda.white@adventureworks.com'
        ),
        (
            'EQ_SALES_YTD',
            'Sales Year to Date',
            'HR',
            'Cumulative sales achieved year-to-date. Progress toward annual quota.',
            'On pace for 100% quota achievement',
            'ALERT if: YTD < 80% of prorated quota',
            'Below pace: Provide coaching, review territory. Above pace: Recognize and reward.',
            'EQ_QUOTA, SO_REVENUE',
            'Amanda White',
            'amanda.white@adventureworks.com'
        ),
        (
            'EQ_SALES_LAST_YEAR',
            'Sales Last Year',
            'HR',
            'Sales achieved in prior year. Baseline for year-over-year comparison.',
            'YoY growth >= 5%',
            'ALERT if: Current YTD < last year same period by > 10%',
            'Use for trend analysis and quota setting. Adjust for market changes.',
            'EQ_SALES_YTD, EQ_QUOTA',
            'Amanda White',
            'amanda.white@adventureworks.com'
        ),
        (
            'EQ_ACHIEVEMENT_PCT',
            'Quota Achievement Percent',
            'HR',
            'Percentage of quota achieved. Primary sales performance metric.',
            '>= 100%',
            'ALERT if: < 70% OR declining for 3 consecutive periods',
            'Below 80%: Performance improvement plan. Above 100%: Bonus/recognition.',
            'EQ_QUOTA, EQ_SALES_YTD',
            'Amanda White',
            'amanda.white@adventureworks.com'
        ),
        (
            'EQ_QUOTA_VARIANCE',
            'Quota Variance',
            'HR',
            'Dollar variance from quota (positive = exceeded). Used for compensation.',
            'Positive (exceeded quota)',
            'ALERT if: Negative variance > 20% of quota',
            'Large negative: Coaching needed. Large positive: May indicate sandbagging.',
            'EQ_ACHIEVEMENT_PCT',
            'Amanda White',
            'amanda.white@adventureworks.com'
        ),
        (
            'EQ_BONUS',
            'Employee Bonus',
            'HR',
            'Bonus amount for salesperson. Tied to quota achievement.',
            'Aligned with achievement level',
            'ALERT if: Bonus paid without corresponding achievement',
            'Review bonus structure for alignment with company goals.',
            'EQ_ACHIEVEMENT_PCT, EQ_QUOTA_VARIANCE',
            'Amanda White',
            'amanda.white@adventureworks.com'
        )
        
    ) as t(
        metric_key,
        metric_name,
        metric_category,
        metric_description,
        metric_target,
        alert_criteria,
        recommended_actions,
        reference_metrics,
        owner_name,
        owner_email
    )
)

select
    row_number() over (order by metric_category, metric_key) as metric_id,
    metric_key,
    metric_name,
    metric_category,
    metric_description,
    metric_target,
    alert_criteria,
    recommended_actions,
    reference_metrics,
    owner_name,
    owner_email,
    current_timestamp as created_at,
    current_timestamp as updated_at
from metrics_catalog
