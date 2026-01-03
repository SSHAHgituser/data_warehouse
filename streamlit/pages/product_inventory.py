"""
Product & Inventory Analytics Page
Supports: Product profitability, Inventory optimization, Product recommendations, BOM analysis
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pages.utils import format_dataframe

def render(conn):
    st.header("📦 Product & Inventory Analytics")
    st.markdown("Analyze product performance, profitability, and inventory optimization")
    
    # Show report date note
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT MAX(order_date) FROM mart_sales")
            result = cur.fetchone()
            if result and result[0]:
                st.info(f"📅 **Report Date:** All analyses are based on data up to {result[0].strftime('%B %d, %Y')} (most recent sales transaction date).")
    except Exception:
        pass
    
    tab1, tab2, tab3, tab4 = st.tabs([
        "💰 Product Profitability",
        "📊 Inventory Status",
        "🛒 Product Recommendations",
        "📈 Sales Performance"
    ])
    
    with tab1:
        st.subheader("Product Profitability Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    category_name,
                    product_name,
                    total_revenue,
                    total_quantity_sold,
                    profit_margin_percent,
                    CASE 
                        WHEN profit_margin_percent > 30 THEN 'High'
                        WHEN profit_margin_percent > 15 THEN 'Medium'
                        ELSE 'Low'
                    END as profitability_tier
                FROM mart_product_analytics
                WHERE category_name IS NOT NULL
                ORDER BY profit_margin_percent DESC
                LIMIT 50
            """)
            profit_data = pd.DataFrame(cur.fetchall(),
                                     columns=['Category', 'Product', 'Revenue', 'Quantity', 'Margin', 'Tier'])
            
            if not profit_data.empty:
                # Convert Quantity to numeric and handle None/NaN values
                # Fill NaN with 1 to ensure all points are visible (minimum size)
                profit_data['Quantity'] = pd.to_numeric(profit_data['Quantity'], errors='coerce').fillna(1)
                # Ensure Revenue and Margin are numeric
                profit_data['Revenue'] = pd.to_numeric(profit_data['Revenue'], errors='coerce')
                profit_data['Margin'] = pd.to_numeric(profit_data['Margin'], errors='coerce')
                # Filter out rows with invalid Revenue or Margin values
                profit_data = profit_data[
                    (profit_data['Revenue'].notna()) & 
                    (profit_data['Margin'].notna())
                ]
                
                col1, col2 = st.columns(2)
                
                with col1:
                    if not profit_data.empty:
                        fig = px.scatter(profit_data, x='Revenue', y='Margin',
                                       color='Tier', size='Quantity',
                                       hover_data=['Product', 'Category'],
                                       title='Product Profitability: Revenue vs Margin',
                                       labels={'Revenue': 'Total Revenue ($)', 'Margin': 'Profit Margin'})
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No valid data available for scatter plot")
                
                with col2:
                    tier_summary = profit_data.groupby('Tier').agg({
                        'Revenue': 'sum',
                        'Product': 'count',
                        'Margin': 'mean'
                    }).reset_index()
                    tier_summary.columns = ['Tier', 'Total Revenue', 'Product Count', 'Avg Margin']
                    fig = px.bar(tier_summary, x='Tier', y='Total Revenue',
                               color='Tier',
                               title='Total Revenue by Profitability Tier',
                               labels={'Total Revenue': 'Revenue ($)', 'Tier': 'Profitability Tier'})
                    st.plotly_chart(fig, use_container_width=True)
                
                # Format dataframe, then override Margin column to be regular number (not currency or percentage)
                profit_data_formatted = format_dataframe(profit_data.copy())
                if 'Margin' in profit_data_formatted.columns:
                    # Format Margin as regular number with comma separator, no % symbol
                    profit_data_formatted['Margin'] = profit_data['Margin'].apply(
                        lambda x: f"{x:,.0f}" if pd.notna(x) and not pd.isnull(x) else ""
                    )
                st.dataframe(profit_data_formatted, use_container_width=True)
    
    with tab2:
        st.subheader("Inventory Optimization")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    product_name,
                    category_name,
                    inventory_status,
                    total_inventory_quantity,
                    total_inventory_value,
                    monthly_sales_velocity,
                    days_of_inventory,
                    inventory_turnover_ratio
                FROM mart_product_analytics
                WHERE inventory_status IN ('Out of Stock', 'Below Safety Stock', 'At Reorder Point')
                ORDER BY total_inventory_value DESC
            """)
            inventory_data = pd.DataFrame(cur.fetchall(),
                                        columns=['Product', 'Category', 'Status', 'Quantity', 'Value', 
                                                'Sales Velocity', 'Days of Inventory', 'Turnover Ratio'])
            
            if not inventory_data.empty:
                st.warning(f"⚠️ Found {len(inventory_data)} products requiring attention")
                
                col1, col2 = st.columns(2)
                
                with col1:
                    status_counts = inventory_data['Status'].value_counts()
                    fig = px.pie(values=status_counts.values, names=status_counts.index,
                               title='Inventory Status Distribution')
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.bar(inventory_data.head(20), x='Value', y='Product',
                               orientation='h',
                               color='Status',
                               title='Top 20 Products by Inventory Value (Requiring Attention)',
                               labels={'Value': 'Inventory Value ($)', 'Product': 'Product Name'})
                    fig.update_layout(yaxis={'categoryorder': 'total ascending'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(inventory_data), use_container_width=True)
            else:
                st.success("✅ All products have adequate inventory levels")
    
    with tab3:
        st.subheader("Product Recommendations (Market Basket Analysis)")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    p1.product_name as product,
                    p2.product_name as related_product,
                    COUNT(*) as co_occurrence_count
                FROM mart_sales s1
                JOIN mart_sales s2 ON s1.salesorderid = s2.salesorderid 
                    AND s1.product_key != s2.product_key
                LEFT JOIN mart_product_analytics p1 ON s1.product_key = p1.productid
                LEFT JOIN mart_product_analytics p2 ON s2.product_key = p2.productid
                WHERE p1.product_name IS NOT NULL AND p2.product_name IS NOT NULL
                GROUP BY p1.product_name, p2.product_name
                ORDER BY co_occurrence_count DESC
                LIMIT 50
            """)
            basket_data = pd.DataFrame(cur.fetchall(),
                                     columns=['Product', 'Related Product', 'Co-occurrence'])
            
            if not basket_data.empty:
                # Product selector
                products = sorted(basket_data['Product'].unique().tolist())
                selected_product = st.selectbox("Select a product to see recommendations", products)
                
                recommendations = basket_data[basket_data['Product'] == selected_product].head(10)
                
                if not recommendations.empty:
                    st.subheader(f"Top 10 Products Frequently Bought With: {selected_product}")
                    fig = px.bar(recommendations, x='Co-occurrence', y='Related Product',
                               orientation='h',
                               title=f'Products Frequently Bought With {selected_product}',
                               labels={'Co-occurrence': 'Times Bought Together', 'Related Product': 'Product'})
                    fig.update_layout(yaxis={'categoryorder': 'total ascending'})
                    st.plotly_chart(fig, use_container_width=True)
                    
                    st.dataframe(format_dataframe(recommendations[['Related Product', 'Co-occurrence']]), use_container_width=True)
                else:
                    st.info("No recommendations found for this product")
    
    with tab4:
        st.subheader("Product Sales Performance")
        
        # Category filter
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT category_name FROM mart_product_analytics WHERE category_name IS NOT NULL ORDER BY category_name")
            categories = [row[0] for row in cur.fetchall()]
        
        selected_category = st.selectbox("Select Category", ["All"] + categories, key="prod_cat")
        
        # Sort option
        sort_option = st.selectbox("Sort by", ["Revenue (Descending)", "Revenue (Ascending)", "Quantity (Descending)", "Quantity (Ascending)", "Orders (Descending)", "Orders (Ascending)"], key="prod_sort")
        
        # Map sort option to SQL ORDER BY clause
        sort_mapping = {
            "Revenue (Descending)": "total_revenue DESC NULLS LAST",
            "Revenue (Ascending)": "total_revenue ASC NULLS LAST",
            "Quantity (Descending)": "total_quantity_sold DESC NULLS LAST",
            "Quantity (Ascending)": "total_quantity_sold ASC NULLS LAST",
            "Orders (Descending)": "total_orders DESC NULLS LAST",
            "Orders (Ascending)": "total_orders ASC NULLS LAST"
        }
        order_by_clause = sort_mapping.get(sort_option, "total_revenue DESC NULLS LAST")
        
        category_filter = f"AND category_name = '{selected_category}'" if selected_category != "All" else ""
        
        try:
            with conn.cursor() as cur:
                cur.execute(f"""
                    SELECT 
                        category_name,
                        product_name,
                        total_revenue,
                        total_quantity_sold,
                        total_orders,
                        product_status,
                        sales_performance
                    FROM mart_product_analytics
                    WHERE category_name IS NOT NULL {category_filter}
                    ORDER BY {order_by_clause}
                    LIMIT 50
                """)
                sales_data = pd.DataFrame(cur.fetchall(),
                                        columns=['Category', 'Product', 'Revenue', 'Quantity', 'Orders', 'Status', 'Performance'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading product sales data: {e}")
            sales_data = pd.DataFrame()
        
        if not sales_data.empty:
            # Convert numeric columns and handle NULL values
            sales_data['Revenue'] = pd.to_numeric(sales_data['Revenue'], errors='coerce')
            sales_data['Quantity'] = pd.to_numeric(sales_data['Quantity'], errors='coerce')
            sales_data['Orders'] = pd.to_numeric(sales_data['Orders'], errors='coerce')
            
            # Show info about NULL values
            null_revenue = sales_data['Revenue'].isna().sum()
            null_quantity = sales_data['Quantity'].isna().sum()
            null_orders = sales_data['Orders'].isna().sum()
            if null_revenue > 0 or null_quantity > 0 or null_orders > 0:
                st.warning(f"⚠️ Some products have missing data: {null_revenue} with NULL revenue, {null_quantity} with NULL quantity, {null_orders} with NULL orders")
            
            # Filter out rows where all metrics are NULL
            sales_data_filtered = sales_data[
                (sales_data['Revenue'].notna()) | 
                (sales_data['Quantity'].notna()) | 
                (sales_data['Orders'].notna())
            ]
            
            if not sales_data_filtered.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    performance_counts = sales_data_filtered['Performance'].value_counts()
                    if not performance_counts.empty:
                        fig = px.pie(values=performance_counts.values, names=performance_counts.index,
                                   title='Product Sales Performance Distribution')
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No performance data available")
                
                with col2:
                    status_counts = sales_data_filtered['Status'].value_counts()
                    if not status_counts.empty:
                        fig = px.bar(x=status_counts.index, y=status_counts.values,
                                   title='Product Status Distribution',
                                   labels={'x': 'Status', 'y': 'Count'})
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No status data available")
                
                # Display the filtered data (keep numeric values for proper sorting/filtering)
                st.dataframe(format_dataframe(sales_data_filtered), use_container_width=True)
            else:
                st.warning("No products found with sales data (revenue, quantity, or orders)")
                # Diagnostic query
                try:
                    with conn.cursor() as cur:
                        cur.execute(f"""
                            SELECT 
                                COUNT(*) as total_products,
                                COUNT(CASE WHEN total_revenue IS NOT NULL THEN 1 END) as has_revenue,
                                COUNT(CASE WHEN total_quantity_sold IS NOT NULL THEN 1 END) as has_quantity,
                                COUNT(CASE WHEN total_orders IS NOT NULL THEN 1 END) as has_orders,
                                COUNT(CASE WHEN total_revenue IS NOT NULL OR total_quantity_sold IS NOT NULL OR total_orders IS NOT NULL THEN 1 END) as has_any_metric
                            FROM mart_product_analytics
                            WHERE category_name IS NOT NULL {category_filter}
                        """)
                        diag = cur.fetchone()
                        st.info(f"**Data Availability:** Total products: {diag[0]}, Has revenue: {diag[1]}, Has quantity: {diag[2]}, Has orders: {diag[3]}, Has any metric: {diag[4]}")
                except Exception:
                    pass
        else:
            st.info("No product data available")

