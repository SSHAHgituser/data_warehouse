"""
Result Visualizer
=================
Auto-generates appropriate visualizations for SQL query results.
Analyzes result structure to determine the best chart type.
"""

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from typing import Optional, Tuple, List


class ResultVisualizer:
    """Automatically generates visualizations for query results."""
    
    # Column name patterns for different data types
    CURRENCY_PATTERNS = ['revenue', 'sales', 'amount', 'value', 'cost', 'price', 
                        'profit', 'total', 'sum', 'avg_order', 'lifetime']
    DATE_PATTERNS = ['date', 'year', 'month', 'quarter', 'day', 'week', 'period']
    CATEGORY_PATTERNS = ['name', 'category', 'segment', 'status', 'type', 'group',
                        'territory', 'region', 'country']
    COUNT_PATTERNS = ['count', 'quantity', 'qty', 'number', 'orders', 'customers', 'products']
    PERCENT_PATTERNS = ['percent', 'rate', 'ratio', 'pct', '%', 'achievement']
    
    def __init__(self):
        """Initialize the visualizer."""
        self.color_palette = px.colors.qualitative.Set2
    
    def analyze_and_visualize(self, df: pd.DataFrame, question: str = "") -> Tuple[Optional[go.Figure], str]:
        """
        Analyze query results and generate appropriate visualization.
        
        Args:
            df: DataFrame with query results
            question: Original question for context
            
        Returns:
            Tuple of (plotly figure or None, chart type description)
        """
        if df.empty or len(df) == 0:
            return None, "No data to visualize"
        
        if len(df) == 1 and len(df.columns) == 1:
            return None, "Single value result - displayed as metric"
        
        # Analyze columns
        numeric_cols = self._get_numeric_columns(df)
        categorical_cols = self._get_categorical_columns(df)
        date_cols = self._get_date_columns(df)
        
        # Determine best visualization
        if date_cols and numeric_cols:
            # Time series
            return self._create_time_series(df, date_cols[0], numeric_cols, question)
        
        elif categorical_cols and numeric_cols:
            # Category comparison
            return self._create_category_chart(df, categorical_cols, numeric_cols, question)
        
        elif len(numeric_cols) >= 2:
            # Scatter plot for numeric correlations
            return self._create_scatter(df, numeric_cols)
        
        elif len(categorical_cols) >= 2:
            # Grouped bar or heatmap
            return self._create_grouped_chart(df, categorical_cols, numeric_cols)
        
        else:
            # Default to table display
            return None, "Best displayed as table"
    
    def _get_numeric_columns(self, df: pd.DataFrame) -> List[str]:
        """Get columns that are numeric."""
        numeric_cols = []
        for col in df.columns:
            if df[col].dtype in ['int64', 'float64', 'Int64', 'Float64']:
                numeric_cols.append(col)
            else:
                # Try to convert
                try:
                    pd.to_numeric(df[col], errors='raise')
                    numeric_cols.append(col)
                except:
                    pass
        return numeric_cols
    
    def _get_categorical_columns(self, df: pd.DataFrame) -> List[str]:
        """Get columns that are categorical."""
        categorical_cols = []
        for col in df.columns:
            col_lower = col.lower()
            if df[col].dtype == 'object' or any(p in col_lower for p in self.CATEGORY_PATTERNS):
                if df[col].nunique() <= 50:  # Reasonable number of categories
                    categorical_cols.append(col)
        return categorical_cols
    
    def _get_date_columns(self, df: pd.DataFrame) -> List[str]:
        """Get columns that represent dates or time periods."""
        date_cols = []
        for col in df.columns:
            col_lower = col.lower()
            if any(p in col_lower for p in self.DATE_PATTERNS):
                date_cols.append(col)
            elif df[col].dtype == 'datetime64[ns]':
                date_cols.append(col)
        return date_cols
    
    def _create_time_series(self, df: pd.DataFrame, date_col: str, 
                           numeric_cols: List[str], question: str) -> Tuple[go.Figure, str]:
        """Create a time series chart."""
        # Use first numeric column as primary metric
        value_col = numeric_cols[0]
        
        # Sort by date
        df_sorted = df.sort_values(date_col)
        
        # Create line chart
        fig = px.line(
            df_sorted, 
            x=date_col, 
            y=value_col,
            title=f'{self._humanize(value_col)} Over Time',
            labels={date_col: self._humanize(date_col), value_col: self._humanize(value_col)}
        )
        
        # Add markers
        fig.update_traces(mode='lines+markers')
        
        # Style
        fig.update_layout(
            hovermode='x unified',
            xaxis_title=self._humanize(date_col),
            yaxis_title=self._humanize(value_col),
            template='plotly_white'
        )
        
        # Format y-axis for currency
        if any(p in value_col.lower() for p in self.CURRENCY_PATTERNS):
            fig.update_yaxes(tickprefix='$', tickformat=',.0f')
        
        return fig, "Time series line chart"
    
    def _create_category_chart(self, df: pd.DataFrame, categorical_cols: List[str],
                               numeric_cols: List[str], question: str) -> Tuple[go.Figure, str]:
        """Create a category comparison chart."""
        cat_col = categorical_cols[0]
        value_col = numeric_cols[0]
        
        # Determine chart type based on data
        n_categories = df[cat_col].nunique()
        
        if n_categories <= 8:
            # Pie chart for few categories
            fig = px.pie(
                df, 
                names=cat_col, 
                values=value_col,
                title=f'{self._humanize(value_col)} by {self._humanize(cat_col)}',
                color_discrete_sequence=self.color_palette
            )
            fig.update_traces(textposition='inside', textinfo='percent+label')
            chart_type = "Pie chart"
        
        else:
            # Horizontal bar for many categories
            df_sorted = df.sort_values(value_col, ascending=True)
            
            # Limit to top 20 for readability
            if len(df_sorted) > 20:
                df_sorted = df_sorted.tail(20)
            
            fig = px.bar(
                df_sorted,
                x=value_col,
                y=cat_col,
                orientation='h',
                title=f'Top {len(df_sorted)} by {self._humanize(value_col)}',
                labels={cat_col: self._humanize(cat_col), value_col: self._humanize(value_col)},
                color_discrete_sequence=self.color_palette
            )
            
            # Format x-axis for currency
            if any(p in value_col.lower() for p in self.CURRENCY_PATTERNS):
                fig.update_xaxes(tickprefix='$', tickformat=',.0f')
            
            chart_type = "Horizontal bar chart"
        
        fig.update_layout(template='plotly_white')
        return fig, chart_type
    
    def _create_scatter(self, df: pd.DataFrame, numeric_cols: List[str]) -> Tuple[go.Figure, str]:
        """Create a scatter plot for numeric correlations."""
        x_col = numeric_cols[0]
        y_col = numeric_cols[1]
        
        fig = px.scatter(
            df,
            x=x_col,
            y=y_col,
            title=f'{self._humanize(x_col)} vs {self._humanize(y_col)}',
            labels={x_col: self._humanize(x_col), y_col: self._humanize(y_col)},
            trendline='ols' if len(df) > 10 else None
        )
        
        # Format axes for currency
        if any(p in x_col.lower() for p in self.CURRENCY_PATTERNS):
            fig.update_xaxes(tickprefix='$', tickformat=',.0f')
        if any(p in y_col.lower() for p in self.CURRENCY_PATTERNS):
            fig.update_yaxes(tickprefix='$', tickformat=',.0f')
        
        fig.update_layout(template='plotly_white')
        return fig, "Scatter plot with trend line"
    
    def _create_grouped_chart(self, df: pd.DataFrame, categorical_cols: List[str],
                              numeric_cols: List[str]) -> Tuple[go.Figure, str]:
        """Create a grouped chart for multiple categories."""
        if not numeric_cols:
            return None, "No numeric data to visualize"
        
        x_col = categorical_cols[0]
        color_col = categorical_cols[1] if len(categorical_cols) > 1 else None
        value_col = numeric_cols[0]
        
        fig = px.bar(
            df,
            x=x_col,
            y=value_col,
            color=color_col,
            barmode='group',
            title=f'{self._humanize(value_col)} by {self._humanize(x_col)}',
            labels={x_col: self._humanize(x_col), value_col: self._humanize(value_col)},
            color_discrete_sequence=self.color_palette
        )
        
        # Format y-axis for currency
        if any(p in value_col.lower() for p in self.CURRENCY_PATTERNS):
            fig.update_yaxes(tickprefix='$', tickformat=',.0f')
        
        fig.update_layout(template='plotly_white')
        return fig, "Grouped bar chart"
    
    def _humanize(self, column_name: str) -> str:
        """Convert column name to human-readable format."""
        # Replace underscores with spaces
        result = column_name.replace('_', ' ')
        
        # Title case
        result = result.title()
        
        # Fix common abbreviations
        replacements = {
            'Qty': 'Quantity',
            'Pct': 'Percent',
            'Amt': 'Amount',
            'Num': 'Number',
            'Avg': 'Average',
            'Ytd': 'YTD',
            'Mtd': 'MTD',
            'Yoy': 'YoY',
            'Id': 'ID'
        }
        
        for old, new in replacements.items():
            result = result.replace(old, new)
        
        return result
    
    def create_metric_cards(self, df: pd.DataFrame) -> List[dict]:
        """
        Create metric card data for single-row results.
        
        Args:
            df: DataFrame with results
            
        Returns:
            List of dicts with label, value, and optional delta
        """
        if len(df) != 1:
            return []
        
        cards = []
        row = df.iloc[0]
        
        for col in df.columns:
            value = row[col]
            
            # Format value based on column type
            col_lower = col.lower()
            is_numeric = isinstance(value, (int, float)) and pd.notna(value)
            
            if is_numeric and any(p in col_lower for p in self.CURRENCY_PATTERNS):
                formatted = f"${value:,.2f}"
            elif is_numeric and any(p in col_lower for p in self.PERCENT_PATTERNS):
                formatted = f"{value:.1f}%"
            elif is_numeric and any(p in col_lower for p in self.COUNT_PATTERNS):
                formatted = f"{int(value):,}"
            elif is_numeric:
                formatted = f"{value:,.2f}"
            elif pd.isna(value):
                formatted = "N/A"
            else:
                formatted = str(value)
            
            cards.append({
                'label': self._humanize(col),
                'value': formatted
            })
        
        return cards
