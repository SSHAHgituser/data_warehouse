"""
Customer Analytics Page
Supports: Customer churn prediction, Customer journey mapping, RFM analysis, Cohort analysis
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pages.utils import format_dataframe

def render(conn):
    st.header("👥 Customer Analytics")
    st.markdown("Analyze customer behavior, segmentation, and lifetime value")
    
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
        "📊 Customer Overview",
        "🎯 RFM Analysis",
        "⚠️ Churn Prediction",
        "📈 Cohort Analysis"
    ])
    
    with tab1:
        st.subheader("Customer Overview")
        
        col1, col2, col3, col4 = st.columns(4)
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_customers,
                        AVG(lifetime_value) as avg_clv,
                        COUNT(CASE WHEN customer_status = 'Active' THEN 1 END) as active_customers,
                        COUNT(CASE WHEN customer_status = 'At Risk' THEN 1 END) as at_risk_customers
                    FROM mart_customer_analytics
                """)
                overview = cur.fetchone()
                
                with col1:
                    st.metric("Total Customers", f"{overview[0]:,}" if overview[0] else "0")
                with col2:
                    st.metric("Avg CLV", f"${overview[1]:,.2f}" if overview[1] else "$0")
                with col3:
                    st.metric("Active Customers", f"{overview[2]:,}" if overview[2] else "0")
                with col4:
                    st.metric("At Risk Customers", f"{overview[3]:,}" if overview[3] else "0")
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading customer overview: {e}")
        
        # Customer segmentation
        st.subheader("Customer Segmentation")
        try:
            with conn.cursor() as cur:
                # First try with all three dimensions
                cur.execute("""
                    SELECT 
                        customer_segment,
                        customer_status,
                        purchase_frequency,
                        COUNT(*) as customer_count,
                        AVG(lifetime_value) as avg_clv,
                        AVG(total_orders) as avg_orders
                    FROM mart_customer_analytics
                    WHERE customer_segment IS NOT NULL 
                        AND customer_status IS NOT NULL
                        AND purchase_frequency IS NOT NULL
                        AND customer_segment != ''
                        AND customer_status != ''
                        AND purchase_frequency != ''
                    GROUP BY customer_segment, customer_status, purchase_frequency
                    ORDER BY customer_segment, customer_status
                """)
                segment_data = pd.DataFrame(cur.fetchall(),
                                          columns=['Segment', 'Status', 'Frequency', 'Count', 'Avg CLV', 'Avg Orders'])
                
                # If no data with frequency, try without frequency
                if segment_data.empty:
                    cur.execute("""
                        SELECT 
                            customer_segment,
                            customer_status,
                            'All' as purchase_frequency,
                            COUNT(*) as customer_count,
                            AVG(lifetime_value) as avg_clv,
                            AVG(total_orders) as avg_orders
                        FROM mart_customer_analytics
                        WHERE customer_segment IS NOT NULL 
                            AND customer_status IS NOT NULL
                            AND customer_segment != ''
                            AND customer_status != ''
                        GROUP BY customer_segment, customer_status
                        ORDER BY customer_segment, customer_status
                    """)
                    segment_data = pd.DataFrame(cur.fetchall(),
                                              columns=['Segment', 'Status', 'Frequency', 'Count', 'Avg CLV', 'Avg Orders'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading segmentation data: {e}")
            segment_data = pd.DataFrame()
        
        if not segment_data.empty:
            # Additional filtering to ensure no empty strings or NaN values
            segment_data = segment_data[
                (segment_data['Segment'].notna()) & 
                (segment_data['Status'].notna()) &
                (segment_data['Frequency'].notna()) &
                (segment_data['Segment'] != '') & 
                (segment_data['Status'] != '') &
                (segment_data['Frequency'] != '')
            ]
            
            if not segment_data.empty:
                fig = px.sunburst(segment_data, path=['Segment', 'Status', 'Frequency'], values='Count',
                                title='Customer Distribution by Segment, Status, and Frequency')
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.info("No valid data available for sunburst chart (all rows have empty/null values)")
            
            st.dataframe(format_dataframe(segment_data), use_container_width=True)
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_customers,
                            COUNT(CASE WHEN customer_segment IS NOT NULL AND customer_segment != '' THEN 1 END) as has_segment,
                            COUNT(CASE WHEN customer_status IS NOT NULL AND customer_status != '' THEN 1 END) as has_status,
                            COUNT(CASE WHEN purchase_frequency IS NOT NULL AND purchase_frequency != '' THEN 1 END) as has_frequency,
                            COUNT(CASE WHEN customer_segment IS NOT NULL AND customer_segment != '' 
                                      AND customer_status IS NOT NULL AND customer_status != ''
                                      AND purchase_frequency IS NOT NULL AND purchase_frequency != '' THEN 1 END) as has_all
                        FROM mart_customer_analytics
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total customers: {diag[0]}, Has segment: {diag[1]}, Has status: {diag[2]}, Has frequency: {diag[3]}, Has all three: {diag[4]}")
            except Exception as e:
                st.info("Unable to run diagnostic query")
    
    with tab2:
        st.subheader("RFM Analysis")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        rfm_category,
                        rfm_segment,
                        COUNT(*) as customer_count,
                        AVG(lifetime_value) as avg_clv,
                        AVG(recency_days) as avg_recency,
                        AVG(frequency_score) as avg_frequency,
                        AVG(monetary_score) as avg_monetary
                    FROM mart_customer_analytics
                    WHERE rfm_category IS NOT NULL
                    GROUP BY rfm_category, rfm_segment
                    ORDER BY 
                        CASE rfm_category
                            WHEN 'Champions' THEN 1
                            WHEN 'Loyal Customers' THEN 2
                            WHEN 'Potential' THEN 3
                            WHEN 'New Customers' THEN 4
                            WHEN 'At Risk' THEN 5
                            WHEN 'Lost' THEN 6
                        END
                """)
                rfm_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Category', 'Segment', 'Count', 'Avg CLV', 'Avg Recency', 'Avg Frequency', 'Avg Monetary'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading RFM data: {e}")
            rfm_data = pd.DataFrame()
        
        if not rfm_data.empty:
            # Convert numeric columns and handle None/NaN values
            rfm_data['Count'] = pd.to_numeric(rfm_data['Count'], errors='coerce').fillna(1)
            rfm_data['Avg Frequency'] = pd.to_numeric(rfm_data['Avg Frequency'], errors='coerce')
            rfm_data['Avg Monetary'] = pd.to_numeric(rfm_data['Avg Monetary'], errors='coerce')
            # Filter out rows with invalid values
            rfm_data = rfm_data[
                (rfm_data['Avg Frequency'].notna()) & 
                (rfm_data['Avg Monetary'].notna())
            ]
            
            if not rfm_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.bar(rfm_data, x='Category', y='Count',
                               color='Category',
                               title='Customer Count by RFM Category',
                               labels={'Count': 'Number of Customers', 'Category': 'RFM Category'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.scatter(rfm_data, x='Avg Frequency', y='Avg Monetary',
                                   size='Count', color='Category',
                                   hover_data=['Segment'],
                                   title='RFM Analysis: Frequency vs Monetary Value',
                                   labels={'Avg Frequency': 'Average Frequency Score', 'Avg Monetary': 'Average Monetary Score'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(rfm_data), use_container_width=True)
            else:
                st.info("No valid data available for visualization")
    
    with tab3:
        st.subheader("Churn Risk Analysis")
        
        try:
            with conn.cursor() as cur:
                # First try with segment grouping
                cur.execute("""
                    SELECT 
                        churn_risk,
                        customer_segment,
                        COUNT(*) as customer_count,
                        AVG(lifetime_value) as avg_clv,
                        AVG(recency_days) as avg_days_since_last_order,
                        AVG(total_orders) as avg_orders
                    FROM mart_customer_analytics
                    WHERE churn_risk IS NOT NULL
                    GROUP BY churn_risk, customer_segment
                    ORDER BY 
                        CASE churn_risk
                            WHEN 'High Risk' THEN 1
                            WHEN 'Medium Risk' THEN 2
                            WHEN 'Low Risk' THEN 3
                        END
                """)
                churn_data = pd.DataFrame(cur.fetchall(),
                                        columns=['Churn Risk', 'Segment', 'Count', 'Avg CLV', 'Avg Days Since Last Order', 'Avg Orders'])
                
                # If no data with segment, try without segment
                if churn_data.empty:
                    cur.execute("""
                        SELECT 
                            churn_risk,
                            'All Segments' as customer_segment,
                            COUNT(*) as customer_count,
                            AVG(lifetime_value) as avg_clv,
                            AVG(recency_days) as avg_days_since_last_order,
                            AVG(total_orders) as avg_orders
                        FROM mart_customer_analytics
                        WHERE churn_risk IS NOT NULL
                        GROUP BY churn_risk
                        ORDER BY 
                            CASE churn_risk
                                WHEN 'High Risk' THEN 1
                                WHEN 'Medium Risk' THEN 2
                                WHEN 'Low Risk' THEN 3
                            END
                    """)
                    churn_data = pd.DataFrame(cur.fetchall(),
                                            columns=['Churn Risk', 'Segment', 'Count', 'Avg CLV', 'Avg Days Since Last Order', 'Avg Orders'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading churn data: {e}")
            churn_data = pd.DataFrame()
        
        if not churn_data.empty:
            col1, col2 = st.columns(2)
            
            with col1:
                risk_counts = churn_data.groupby('Churn Risk')['Count'].sum().reset_index()
                fig = px.bar(risk_counts, x='Churn Risk', y='Count',
                           color='Churn Risk',
                           title='Customer Count by Churn Risk Level',
                           labels={'Count': 'Number of Customers', 'Churn Risk': 'Risk Level'})
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                fig = px.bar(churn_data, x='Churn Risk', y='Avg CLV', color='Segment',
                           title='Average CLV by Churn Risk and Segment',
                           labels={'Avg CLV': 'Average CLV ($)', 'Churn Risk': 'Risk Level'})
                st.plotly_chart(fig, use_container_width=True)
            
            st.dataframe(format_dataframe(churn_data), use_container_width=True)
            
            # High-risk customers
            st.subheader("High-Risk Customers (Top 20)")
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            customerid,
                            firstname || ' ' || lastname as customer_name,
                            lifetime_value,
                            recency_days,
                            total_orders,
                            customer_segment,
                            churn_risk
                        FROM mart_customer_analytics
                        WHERE churn_risk = 'High Risk'
                        ORDER BY lifetime_value DESC
                        LIMIT 20
                    """)
                    high_risk = pd.DataFrame(cur.fetchall(),
                                           columns=['Customer ID', 'Name', 'CLV', 'Days Since Last Order', 'Orders', 'Segment', 'Risk'])
                    if not high_risk.empty:
                        st.dataframe(format_dataframe(high_risk), use_container_width=True)
                    else:
                        st.info("No high-risk customers found")
            except Exception as e:
                conn.rollback()
                st.error(f"Error loading high-risk customers: {e}")
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_customers,
                            COUNT(CASE WHEN churn_risk IS NOT NULL THEN 1 END) as has_churn_risk,
                            COUNT(CASE WHEN customer_segment IS NOT NULL AND customer_segment != '' THEN 1 END) as has_segment
                        FROM mart_customer_analytics
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total customers: {diag[0]}, Has churn_risk: {diag[1]}, Has segment: {diag[2]}")
            except Exception as e:
                st.info("Unable to run diagnostic query")
    
    with tab4:
        st.subheader("Cohort Analysis")
        
        try:
            with conn.cursor() as cur:
                # First try with segment grouping
                cur.execute("""
                    SELECT 
                        cohort_period,
                        customer_segment,
                        COUNT(*) as customer_count,
                        AVG(lifetime_value) as avg_clv,
                        AVG(total_orders) as avg_orders
                    FROM mart_customer_analytics
                    WHERE cohort_period IS NOT NULL
                    GROUP BY cohort_period, customer_segment
                    ORDER BY cohort_period, customer_segment
                """)
                cohort_data = pd.DataFrame(cur.fetchall(),
                                         columns=['Cohort', 'Segment', 'Count', 'Avg CLV', 'Avg Orders'])
                
                # If no data with segment, try without segment
                if cohort_data.empty:
                    cur.execute("""
                        SELECT 
                            cohort_period,
                            'All Segments' as customer_segment,
                            COUNT(*) as customer_count,
                            AVG(lifetime_value) as avg_clv,
                            AVG(total_orders) as avg_orders
                        FROM mart_customer_analytics
                        WHERE cohort_period IS NOT NULL
                        GROUP BY cohort_period
                        ORDER BY cohort_period
                    """)
                    cohort_data = pd.DataFrame(cur.fetchall(),
                                             columns=['Cohort', 'Segment', 'Count', 'Avg CLV', 'Avg Orders'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading cohort data: {e}")
            cohort_data = pd.DataFrame()
        
        if not cohort_data.empty:
            # Cohort retention heatmap
            cohort_pivot = cohort_data.pivot_table(
                index='Cohort',
                columns='Segment',
                values='Count',
                aggfunc='sum'
            ).fillna(0)
            
            if not cohort_pivot.empty:
                fig = px.imshow(cohort_pivot,
                              labels=dict(x="Segment", y="Cohort Period", color="Customer Count"),
                              title="Customer Count by Cohort and Segment",
                              aspect="auto")
                st.plotly_chart(fig, use_container_width=True)
            
            # Cohort CLV trend
            fig = px.line(cohort_data, x='Cohort', y='Avg CLV', color='Segment',
                        title='Average CLV by Cohort Period',
                        labels={'Avg CLV': 'Average CLV ($)', 'Cohort': 'Cohort Period'})
            fig.update_xaxes(tickangle=45)
            st.plotly_chart(fig, use_container_width=True)
            
            st.dataframe(format_dataframe(cohort_data), use_container_width=True)
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_customers,
                            COUNT(CASE WHEN cohort_period IS NOT NULL THEN 1 END) as has_cohort_period,
                            COUNT(CASE WHEN cohort_year IS NOT NULL THEN 1 END) as has_cohort_year,
                            COUNT(CASE WHEN first_order_date IS NOT NULL THEN 1 END) as has_first_order_date,
                            COUNT(CASE WHEN customer_segment IS NOT NULL AND customer_segment != '' THEN 1 END) as has_segment
                        FROM mart_customer_analytics
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total customers: {diag[0]}, Has cohort_period: {diag[1]}, Has cohort_year: {diag[2]}, Has first_order_date: {diag[3]}, Has segment: {diag[4]}")
            except Exception as e:
                st.info("Unable to run diagnostic query")

