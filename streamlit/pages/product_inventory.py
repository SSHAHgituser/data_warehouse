"""
Product & Inventory Analytics Page
Supports: Product profitability, Inventory optimization, Product recommendations, BOM analysis
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

def render(conn):
    st.header("📦 Product & Inventory Analytics")
    st.markdown("Analyze product performance, profitability, and inventory optimization")
    
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
                                     columns=['Category', 'Product', 'Revenue', 'Quantity', 'Margin %', 'Tier'])
            
            if not profit_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.scatter(profit_data, x='Revenue', y='Margin %',
                                   color='Tier', size='Quantity',
                                   hover_data=['Product', 'Category'],
                                   title='Product Profitability: Revenue vs Margin',
                                   labels={'Revenue': 'Total Revenue ($)', 'Margin %': 'Profit Margin (%)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    tier_summary = profit_data.groupby('Tier').agg({
                        'Revenue': 'sum',
                        'Product': 'count',
                        'Margin %': 'mean'
                    }).reset_index()
                    tier_summary.columns = ['Tier', 'Total Revenue', 'Product Count', 'Avg Margin %']
                    fig = px.bar(tier_summary, x='Tier', y='Total Revenue',
                               color='Tier',
                               title='Total Revenue by Profitability Tier',
                               labels={'Total Revenue': 'Revenue ($)', 'Tier': 'Profitability Tier'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(profit_data, use_container_width=True)
    
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
                
                st.dataframe(inventory_data, use_container_width=True)
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
                    
                    st.dataframe(recommendations[['Related Product', 'Co-occurrence']], use_container_width=True)
                else:
                    st.info("No recommendations found for this product")
    
    with tab4:
        st.subheader("Product Sales Performance")
        
        # Category filter
        with conn.cursor() as cur:
            cur.execute("SELECT DISTINCT category_name FROM mart_product_analytics WHERE category_name IS NOT NULL ORDER BY category_name")
            categories = [row[0] for row in cur.fetchall()]
        
        selected_category = st.selectbox("Select Category", ["All"] + categories, key="prod_cat")
        
        category_filter = f"AND category_name = '{selected_category}'" if selected_category != "All" else ""
        
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
                ORDER BY total_revenue DESC
                LIMIT 50
            """)
            sales_data = pd.DataFrame(cur.fetchall(),
                                    columns=['Category', 'Product', 'Revenue', 'Quantity', 'Orders', 'Status', 'Performance'])
            
            if not sales_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    performance_counts = sales_data['Performance'].value_counts()
                    fig = px.pie(values=performance_counts.values, names=performance_counts.index,
                               title='Product Sales Performance Distribution')
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    status_counts = sales_data['Status'].value_counts()
                    fig = px.bar(x=status_counts.index, y=status_counts.values,
                               title='Product Status Distribution',
                               labels={'x': 'Status', 'y': 'Count'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(sales_data, use_container_width=True)

