"""
AI Analytics Assistant Page
===========================
Natural language interface for querying the data warehouse.
Converts questions to SQL and displays results with auto-generated visualizations.
"""

import streamlit as st
import pandas as pd
from datetime import datetime
import os
import sys

# Get the streamlit directory path (parent of pages/)
STREAMLIT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Add streamlit directory to path for imports (must be before ai imports)
if STREAMLIT_DIR not in sys.path:
    sys.path.insert(0, STREAMLIT_DIR)

# Load environment variables from .env file
try:
    from dotenv import load_dotenv
    env_path = os.path.join(STREAMLIT_DIR, '.env')
    load_dotenv(env_path)
except ImportError:
    pass  # python-dotenv not installed, rely on system environment variables

from pages.utils import format_dataframe

# Import AI modules
AI_AVAILABLE = False
AI_IMPORT_ERROR = ""

try:
    from ai.sql_generator import SQLGenerator
    from ai.visualizer import ResultVisualizer
    from ai.sql_validator import SQLValidator
    AI_AVAILABLE = True
except ImportError as e:
    AI_IMPORT_ERROR = str(e)


def render(conn):
    """Render the AI Analytics Assistant page."""
    
    st.header("🤖 AI Analytics Assistant")
    st.markdown("Ask questions about your data in plain English. I'll translate them into SQL and show you the results.")
    
    # Check if AI modules are available
    if not AI_AVAILABLE:
        st.error(f"AI modules could not be loaded: {AI_IMPORT_ERROR}")
        st.info("Please ensure all AI dependencies are installed.")
        return
    
    # Check for API key
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("ANTHROPIC_API_KEY")
    provider = "openai" if os.getenv("OPENAI_API_KEY") else "anthropic"
    
    # Sidebar configuration
    with st.sidebar:
        st.markdown("---")
        st.subheader("🔧 AI Settings")
        
        # API Key management
        if api_key:
            provider_name = "OpenAI GPT-4" if provider == "openai" else "Anthropic Claude"
            st.success(f"✓ Using {provider_name}")
            
            # Button to update API key
            if st.button("🔑 Update API Key", key="update_api_key"):
                st.session_state.show_api_form = True
        else:
            st.warning("⚠️ No API key detected")
            st.session_state.show_api_form = True
        
        # Show API key form
        if st.session_state.get('show_api_form', False) or not api_key:
            with st.form(key="api_key_form"):
                api_provider = st.selectbox(
                    "Select AI Provider",
                    ["OpenAI (GPT-4)", "Anthropic (Claude)"],
                    key="ai_provider_select"
                )
                
                api_key_input = st.text_input(
                    "Enter API Key",
                    type="password",
                    help="Your API key will be stored in session state only",
                    key="api_key_field"
                )
                
                submitted = st.form_submit_button("💾 Save API Key")
                
                if submitted and api_key_input:
                    if "OpenAI" in api_provider:
                        os.environ["OPENAI_API_KEY"] = api_key_input
                        # Clear anthropic key if switching
                        if "ANTHROPIC_API_KEY" in os.environ:
                            del os.environ["ANTHROPIC_API_KEY"]
                        provider = "openai"
                    else:
                        os.environ["ANTHROPIC_API_KEY"] = api_key_input
                        # Clear openai key if switching
                        if "OPENAI_API_KEY" in os.environ:
                            del os.environ["OPENAI_API_KEY"]
                        provider = "anthropic"
                    
                    api_key = api_key_input
                    st.session_state.show_api_form = False
                    
                    # Reset SQL generator with new key
                    if 'sql_generator' in st.session_state:
                        del st.session_state.sql_generator
                    
                    st.success(f"✓ {api_provider.split()[0]} API key saved!")
                    st.rerun()
        
        # Clear conversation button
        if st.button("🗑️ Clear Conversation", key="clear_conv"):
            if 'messages' in st.session_state:
                st.session_state.messages = []
            if 'sql_generator' in st.session_state:
                st.session_state.sql_generator.clear_conversation()
            st.rerun()
    
    # Initialize session state
    if 'messages' not in st.session_state:
        st.session_state.messages = []
    
    if 'sql_generator' not in st.session_state and api_key:
        try:
            st.session_state.sql_generator = SQLGenerator(conn, provider=provider)
            st.session_state.visualizer = ResultVisualizer()
        except Exception as e:
            st.error(f"Failed to initialize AI: {e}")
            return
    
    # Show suggested questions for new users
    if not st.session_state.messages:
        st.markdown("### 💡 Try asking:")
        
        suggestions = [
            "What is our total revenue by territory?",
            "Show me the top 10 customers by lifetime value",
            "What is the monthly revenue trend?",
            "Which products have the highest profit margin?",
            "Show me customers at risk of churning"
        ]
        
        cols = st.columns(2)
        for i, suggestion in enumerate(suggestions):
            with cols[i % 2]:
                if st.button(f"📊 {suggestion}", key=f"suggest_{i}", use_container_width=True):
                    st.session_state.pending_question = suggestion
                    st.rerun()
        
        st.markdown("---")
    
    # Display chat history
    for message in st.session_state.messages:
        with st.chat_message(message["role"], avatar="🧑‍💼" if message["role"] == "user" else "🤖"):
            if message["role"] == "user":
                st.markdown(message["content"])
            else:
                # Assistant message contains SQL, results, and visualization
                if "error" in message:
                    st.error(message["error"])
                else:
                    # Show SQL in expander
                    if message.get("sql"):
                        with st.expander("🔍 View SQL Query", expanded=False):
                            st.code(message["sql"], language="sql")
                    
                    # Show analysis if available
                    if message.get("analysis"):
                        st.markdown("### 💡 Analysis")
                        st.markdown(message["analysis"])
                        st.divider()
                    
                    # Show results
                    if message.get("dataframe") is not None:
                        df = message["dataframe"]
                        
                        # Show visualization if available
                        if message.get("figure"):
                            st.plotly_chart(message["figure"], use_container_width=True)
                        
                        # Show metric cards for single-row results
                        if message.get("metric_cards"):
                            cols = st.columns(len(message["metric_cards"]))
                            for i, card in enumerate(message["metric_cards"]):
                                with cols[i]:
                                    st.metric(label=card["label"], value=card["value"])
                        
                        # Show data table
                        st.markdown(f"**Results:** {len(df):,} rows")
                        st.dataframe(
                            format_dataframe(df.head(100)), 
                            use_container_width=True,
                            hide_index=True
                        )
                        
                        # Download button
                        csv = df.to_csv(index=False)
                        st.download_button(
                            label="📥 Download CSV",
                            data=csv,
                            file_name=f"query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                            mime="text/csv",
                            key=f"download_{message.get('timestamp', datetime.now().timestamp())}"
                        )
    
    # Check for pending question from suggestion buttons
    if hasattr(st.session_state, 'pending_question'):
        question = st.session_state.pending_question
        del st.session_state.pending_question
        process_question(conn, question)
    
    # Chat input
    if prompt := st.chat_input("Ask a question about your data...", key="chat_input"):
        if not api_key:
            st.error("Please enter an API key in the sidebar first.")
        else:
            process_question(conn, prompt)


def process_question(conn, question: str):
    """Process a user question and generate response."""
    
    # Add user message
    st.session_state.messages.append({
        "role": "user",
        "content": question
    })
    
    # Display user message
    with st.chat_message("user", avatar="🧑‍💼"):
        st.markdown(question)
    
    # Generate response
    with st.chat_message("assistant", avatar="🤖"):
        try:
            # Generate SQL with automatic retry
            sql_generator = st.session_state.sql_generator
            visualizer = st.session_state.visualizer
            
            # Status placeholder for retry updates
            status_placeholder = st.empty()
            
            def update_status(attempt, message):
                status_placeholder.info(message)
            
            # Generate with retry (up to 3 attempts)
            sql, is_valid, error, attempt_history = sql_generator.generate_with_retry(
                question, 
                conn, 
                max_retries=3,
                status_callback=update_status
            )
            
            # Clear status after completion
            status_placeholder.empty()
            
            # Show attempt history if there were retries
            if len(attempt_history) > 1:
                with st.expander(f"🔄 Attempted {len(attempt_history)} approaches", expanded=False):
                    for record in attempt_history:
                        attempt_num = record['attempt']
                        if record['success']:
                            st.success(f"✅ Attempt {attempt_num}: Success")
                        else:
                            st.warning(f"⚠️ Attempt {attempt_num}: {record.get('execution_error') or record.get('validation_error', 'Failed')[:100]}")
                        if record['sql']:
                            st.code(record['sql'][:300] + "..." if len(record['sql']) > 300 else record['sql'], language="sql")
            
            if not is_valid:
                error_msg = f"❌ {error}" if error else "Could not generate a valid SQL query after multiple attempts."
                st.error(error_msg)
                st.session_state.messages.append({
                    "role": "assistant",
                    "error": error_msg,
                    "attempts": len(attempt_history),
                    "timestamp": datetime.now().timestamp()
                })
                return
            
            # Show successful SQL
            with st.expander("🔍 View SQL Query", expanded=False):
                st.code(sql, language="sql")
            
            # Execute final query (already validated in retry loop)
            df = pd.read_sql(sql, conn)
            
            # Generate visualization
            figure, chart_type = visualizer.analyze_and_visualize(df, question)
            metric_cards = visualizer.create_metric_cards(df) if len(df) == 1 else None
            
            # Generate AI analysis of results
            analysis = None
            if len(df) > 0:
                with st.spinner("🧠 Analyzing results..."):
                    analysis = sql_generator.analyze_results(question, sql, df)
            
            # Display AI analysis first
            if analysis:
                st.markdown("### 💡 Analysis")
                st.markdown(analysis)
                st.divider()
            
            # Display visualization
            if figure:
                st.plotly_chart(figure, use_container_width=True)
            
            if metric_cards:
                cols = st.columns(len(metric_cards))
                for i, card in enumerate(metric_cards):
                    with cols[i]:
                        st.metric(label=card["label"], value=card["value"])
            
            # Show data table
            st.markdown(f"**Results:** {len(df):,} rows")
            st.dataframe(
                format_dataframe(df.head(100)),
                use_container_width=True,
                hide_index=True
            )
            
            # Download button
            csv = df.to_csv(index=False)
            timestamp = datetime.now().timestamp()
            st.download_button(
                label="📥 Download CSV",
                data=csv,
                file_name=f"query_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                mime="text/csv",
                key=f"download_{timestamp}"
            )
            
            # Store in session state
            st.session_state.messages.append({
                "role": "assistant",
                "sql": sql,
                "analysis": analysis,
                "dataframe": df,
                "figure": figure,
                "chart_type": chart_type,
                "metric_cards": metric_cards,
                "timestamp": timestamp
            })
            
        except Exception as e:
            error_msg = f"❌ Unexpected error: {str(e)}"
            st.error(error_msg)
            st.session_state.messages.append({
                "role": "assistant",
                "error": error_msg,
                "timestamp": datetime.now().timestamp()
            })


def show_capabilities():
    """Show what the AI assistant can do."""
    st.markdown("""
    ### What I can help with:
    
    📈 **Sales Analysis**
    - Revenue trends, breakdowns by territory/product/customer
    - Order analysis, average order value, discounts
    
    👥 **Customer Insights**  
    - Customer segmentation, lifetime value
    - Churn risk, RFM analysis
    - Cohort analysis
    
    📦 **Product Analytics**
    - Product performance, profit margins
    - Inventory status, turnover
    - Market basket / co-purchase analysis
    
    👔 **Employee Performance**
    - Quota achievement, sales by rep
    - Territory performance
    
    ⚙️ **Operations**
    - Vendor performance
    - Work order analysis
    - Supply chain metrics
    """)
