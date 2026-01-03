"""
HR & Employee Performance Analytics Page
Supports: Employee performance, Compensation analysis, Workforce planning
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pages.utils import format_dataframe

def render(conn):
    st.header("👔 HR & Employee Performance Analytics")
    st.markdown("Analyze employee performance, sales quotas, and compensation")
    
    # Show report date note
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT MAX(order_date) FROM mart_sales")
            result = cur.fetchone()
            if result and result[0]:
                st.info(f"📅 **Report Date:** All analyses are based on data up to {result[0].strftime('%B %d, %Y')} (most recent sales transaction date).")
    except Exception:
        pass
    
    tab1, tab2, tab3 = st.tabs([
        "📊 Employee Performance",
        "🎯 Quota Achievement",
        "💰 Compensation Analysis"
    ])
    
    with tab1:
        st.subheader("Employee Performance Overview")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        jobtitle,
                        department_name,
                        territory_name,
                        COUNT(DISTINCT performance_id) as employee_count,
                        AVG(sales_year_to_date) as avg_sales_ytd,
                        AVG(quota_achievement_percent) as avg_quota_achievement,
                        SUM(monthly_revenue) as total_revenue
                    FROM mart_employee_territory_performance
                    WHERE performance_type = 'employee'
                    GROUP BY jobtitle, department_name, territory_name
                    ORDER BY total_revenue DESC
                """)
                emp_data = pd.DataFrame(cur.fetchall(),
                                      columns=['Job Title', 'Department', 'Territory', 'Count', 'Avg Sales YTD', 'Avg Quota %', 'Total Revenue'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading employee performance data: {e}")
            emp_data = pd.DataFrame()
        
        if not emp_data.empty:
            # Convert numeric columns and handle None/NaN values
            emp_data['Count'] = pd.to_numeric(emp_data['Count'], errors='coerce').fillna(1)
            emp_data['Avg Sales YTD'] = pd.to_numeric(emp_data['Avg Sales YTD'], errors='coerce')
            emp_data['Avg Quota %'] = pd.to_numeric(emp_data['Avg Quota %'], errors='coerce')
            emp_data['Total Revenue'] = pd.to_numeric(emp_data['Total Revenue'], errors='coerce')
            # Filter out rows with invalid values
            emp_data = emp_data[
                (emp_data['Avg Sales YTD'].notna()) & 
                (emp_data['Avg Quota %'].notna())
            ]
            
            if not emp_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    dept_revenue = emp_data.groupby('Department')['Total Revenue'].sum().reset_index()
                    fig = px.bar(dept_revenue, x='Department', y='Total Revenue',
                               title='Total Revenue by Department',
                               labels={'Total Revenue': 'Revenue ($)', 'Department': 'Department'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.scatter(emp_data, x='Avg Sales YTD', y='Avg Quota %',
                                   size='Count', color='Department',
                                   hover_data=['Job Title', 'Territory'],
                                   title='Employee Performance: Sales vs Quota Achievement',
                                   labels={'Avg Sales YTD': 'Average Sales YTD ($)', 'Avg Quota %': 'Average Quota Achievement (%)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(emp_data), use_container_width=True)
            else:
                st.info("No valid data available for visualization")
    
    with tab2:
        st.subheader("Sales Quota Achievement")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        territory_name,
                        AVG(quota_achievement_percent) as avg_quota_achievement,
                        COUNT(CASE WHEN quota_status = 'Achieved' THEN 1 END) as achieved_count,
                        COUNT(CASE WHEN quota_status = 'Near Target' THEN 1 END) as near_target_count,
                        COUNT(CASE WHEN quota_status = 'Below Target' THEN 1 END) as below_target_count
                    FROM mart_employee_territory_performance
                    WHERE performance_type = 'employee' AND quota_achievement_percent IS NOT NULL
                    GROUP BY territory_name
                    ORDER BY avg_quota_achievement DESC
                """)
                quota_data = pd.DataFrame(cur.fetchall(),
                                        columns=['Territory', 'Avg Achievement %', 'Achieved', 'Near Target', 'Below Target'])
                
                # If no data with territory grouping, try without territory
                if quota_data.empty:
                    cur.execute("""
                        SELECT 
                            'All Territories' as territory_name,
                            AVG(quota_achievement_percent) as avg_quota_achievement,
                            COUNT(CASE WHEN quota_status = 'Achieved' THEN 1 END) as achieved_count,
                            COUNT(CASE WHEN quota_status = 'Near Target' THEN 1 END) as near_target_count,
                            COUNT(CASE WHEN quota_status = 'Below Target' THEN 1 END) as below_target_count
                        FROM mart_employee_territory_performance
                        WHERE performance_type = 'employee' AND quota_achievement_percent IS NOT NULL
                        ORDER BY avg_quota_achievement DESC
                    """)
                    quota_data = pd.DataFrame(cur.fetchall(),
                                            columns=['Territory', 'Avg Achievement %', 'Achieved', 'Near Target', 'Below Target'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading quota data: {e}")
            quota_data = pd.DataFrame()
        
        if not quota_data.empty:
            # Convert numeric columns
            quota_data['Avg Achievement %'] = pd.to_numeric(quota_data['Avg Achievement %'], errors='coerce')
            quota_data['Achieved'] = pd.to_numeric(quota_data['Achieved'], errors='coerce').fillna(0)
            quota_data['Near Target'] = pd.to_numeric(quota_data['Near Target'], errors='coerce').fillna(0)
            quota_data['Below Target'] = pd.to_numeric(quota_data['Below Target'], errors='coerce').fillna(0)
            
            col1, col2 = st.columns(2)
            
            with col1:
                if quota_data['Avg Achievement %'].notna().any():
                    fig = px.bar(quota_data, x='Territory', y='Avg Achievement %',
                               title='Average Quota Achievement by Territory',
                               labels={'Avg Achievement %': 'Average Achievement (%)', 'Territory': 'Territory Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No quota achievement percentage data available")
            
            with col2:
                status_data = pd.melt(quota_data, 
                                    id_vars=['Territory'],
                                    value_vars=['Achieved', 'Near Target', 'Below Target'],
                                    var_name='Status', value_name='Count')
                if not status_data.empty and status_data['Count'].sum() > 0:
                    fig = px.bar(status_data, x='Territory', y='Count', color='Status',
                               title='Quota Status Distribution by Territory',
                               labels={'Count': 'Number of Employees', 'Territory': 'Territory Name'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No quota status data available")
            
            st.dataframe(format_dataframe(quota_data), use_container_width=True)
        else:
            # Diagnostic query to help understand why there's no data
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT 
                            COUNT(*) as total_records,
                            COUNT(CASE WHEN performance_type = 'employee' THEN 1 END) as employee_records,
                            COUNT(CASE WHEN quota_achievement_percent IS NOT NULL THEN 1 END) as has_quota_percent,
                            COUNT(CASE WHEN quota_status IS NOT NULL THEN 1 END) as has_quota_status,
                            COUNT(CASE WHEN territory_name IS NOT NULL THEN 1 END) as has_territory
                        FROM mart_employee_territory_performance
                    """)
                    diag = cur.fetchone()
                    st.warning(f"**Data Availability:** Total records: {diag[0]}, Employee records: {diag[1]}, Has quota_achievement_percent: {diag[2]}, Has quota_status: {diag[3]}, Has territory: {diag[4]}")
            except Exception as e:
                st.info("Unable to run diagnostic query")
    
    with tab3:
        st.subheader("Compensation Analysis")
        
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        department_name,
                        jobtitle,
                        AVG(current_pay_rate) as avg_pay_rate,
                        AVG(sales_year_to_date) as avg_sales_ytd,
                        AVG(years_of_service) as avg_years_service,
                        COUNT(DISTINCT performance_id) as employee_count
                    FROM mart_employee_territory_performance
                    WHERE performance_type = 'employee' AND current_pay_rate IS NOT NULL
                    GROUP BY department_name, jobtitle
                    ORDER BY avg_pay_rate DESC
                """)
                comp_data = pd.DataFrame(cur.fetchall(),
                                       columns=['Department', 'Job Title', 'Avg Pay Rate', 'Avg Sales YTD', 'Avg Years Service', 'Count'])
        except Exception as e:
            conn.rollback()
            st.error(f"Error loading compensation data: {e}")
            comp_data = pd.DataFrame()
        
        if not comp_data.empty:
            # Convert numeric columns and handle None/NaN values
            comp_data['Avg Pay Rate'] = pd.to_numeric(comp_data['Avg Pay Rate'], errors='coerce')
            comp_data['Avg Sales YTD'] = pd.to_numeric(comp_data['Avg Sales YTD'], errors='coerce').fillna(1)
            comp_data['Avg Years Service'] = pd.to_numeric(comp_data['Avg Years Service'], errors='coerce')
            # Filter out rows with invalid values
            comp_data = comp_data[
                (comp_data['Avg Years Service'].notna()) & 
                (comp_data['Avg Pay Rate'].notna())
            ]
            
            if not comp_data.empty:
                col1, col2 = st.columns(2)
                
                with col1:
                    fig = px.bar(comp_data.head(20), x='Job Title', y='Avg Pay Rate',
                               color='Department',
                               title='Average Pay Rate by Job Title',
                               labels={'Avg Pay Rate': 'Pay Rate ($)', 'Job Title': 'Job Title'})
                    fig.update_xaxes(tickangle=45)
                    st.plotly_chart(fig, use_container_width=True)
                
                with col2:
                    fig = px.scatter(comp_data, x='Avg Years Service', y='Avg Pay Rate',
                                   size='Avg Sales YTD', color='Department',
                                   hover_data=['Job Title'],
                                   title='Compensation vs Experience',
                                   labels={'Avg Years Service': 'Years of Service', 'Avg Pay Rate': 'Pay Rate ($)'})
                    st.plotly_chart(fig, use_container_width=True)
                
                st.dataframe(format_dataframe(comp_data), use_container_width=True)
            else:
                st.info("No valid data available for visualization")

