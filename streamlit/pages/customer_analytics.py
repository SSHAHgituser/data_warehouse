"""
Customer Analytics Page
Supports: Customer churn prediction, Customer journey mapping, RFM analysis, Cohort analysis
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

def render(conn):
    st.header("👥 Customer Analytics")
    st.markdown("Analyze customer behavior, segmentation, and lifetime value")
    
    tab1, tab2, tab3, tab4 = st.tabs([
        "📊 Customer Overview",
        "🎯 RFM Analysis",
        "⚠️ Churn Prediction",
        "📈 Cohort Analysis"
    ])
    
    with tab1:
        st.subheader("Customer Overview")
        
        col1, col2, col3, col4 = st.columns(4)
        
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
        
        # Customer segmentation
        st.subheader("Customer Segmentation")
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    customer_segment,
                    customer_status,
                    purchase_frequency,
                    COUNT(*) as customer_count,
                    AVG(lifetime_value) as avg_clv,
                    AVG(total_orders) as avg_orders
                FROM mart_customer_analytics
                GROUP BY customer_segment, customer_status, purchase_frequency
                ORDER BY customer_segment, customer_status
            """)
            segment_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Segment', 'Status', 'Frequency', 'Count', 'Avg CLV', 'Avg Orders'])
            
            if not segment_data.empty:
                fig = px.sunburst(segment_data, path=['Segment', 'Status', 'Frequency'], values='Count',
                                title='Customer Distribution by Segment, Status, and Frequency')
                st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(segment_data, use_container_width=True)
    
    with tab2:
        st.subheader("RFM Analysis")
        
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    rfm_category,
                    rfm_segment,
                    COUNT(*) as customer_count,
                    AVG(lifetime_value) as avg_clv,
                    AVG(recency_days) as avg_recency,
                    AVG(frequency) as avg_frequency,
                    AVG(monetary_value) as avg_monetary
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
                                   labels={'Avg Frequency': 'Average Frequency', 'Avg Monetary': 'Average Monetary Value ($)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(rfm_data, use_container_width=True)
    
    with tab3:
        st.subheader("Churn Risk Analysis")
        
        with conn.cursor() as cur:
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
                
                st.dataframe(churn_data, use_container_width=True)
                
                # High-risk customers
                st.subheader("High-Risk Customers (Top 20)")
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
                    st.dataframe(high_risk, use_container_width=True)
    
    with tab4:
        st.subheader("Cohort Analysis")
        
        with conn.cursor() as cur:
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
            
            if not cohort_data.empty:
                # Cohort retention heatmap
                cohort_pivot = cohort_data.pivot_table(
                    index='Cohort',
                    columns='Segment',
                    values='Count',
                    aggfunc='sum'
                ).fillna(0)
                
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
                
                st.dataframe(cohort_data, use_container_width=True)

