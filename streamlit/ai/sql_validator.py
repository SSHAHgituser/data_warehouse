"""
SQL Validator
=============
Validates and sanitizes generated SQL queries for safety.
Ensures only SELECT queries are executed and prevents SQL injection.
"""

import re
from typing import Tuple, Optional


class SQLValidator:
    """Validates SQL queries for safety before execution."""
    
    # Dangerous keywords that should never appear in generated queries
    FORBIDDEN_KEYWORDS = [
        'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE',
        'GRANT', 'REVOKE', 'EXECUTE', 'EXEC', 'CALL', 'INTO OUTFILE',
        'INTO DUMPFILE', 'LOAD_FILE', 'BENCHMARK', 'SLEEP', 'WAITFOR',
        'SHUTDOWN', 'KILL', 'COPY', 'VACUUM', 'REINDEX', 'CLUSTER'
    ]
    
    # Allowed tables (whitelist approach for extra safety)
    ALLOWED_TABLES = [
        'mart_sales', 'mart_customer_analytics', 'mart_product_analytics',
        'mart_operations', 'mart_employee_territory_performance',
        'fact_global_metrics', 'fact_sales_order', 'fact_sales_order_line',
        'fact_inventory', 'fact_purchase_order', 'fact_work_order',
        'fact_employee_quota', 'dim_customer', 'dim_product', 'dim_date',
        'dim_employee', 'dim_territory', 'dim_vendor', 'dim_metric'
    ]
    
    def __init__(self, strict_mode: bool = True):
        """
        Initialize validator.
        
        Args:
            strict_mode: If True, only allows queries on whitelisted tables
        """
        self.strict_mode = strict_mode
    
    def validate(self, sql: str) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Validate a SQL query for safety.
        
        Args:
            sql: The SQL query to validate
            
        Returns:
            Tuple of (is_valid, cleaned_sql, error_message)
        """
        if not sql or not sql.strip():
            return False, None, "Empty query"
        
        # Clean the query
        cleaned = self._clean_query(sql)
        
        # Check if it's an error response from LLM
        if cleaned.upper().startswith('-- ERROR:'):
            return False, None, cleaned.replace('-- ERROR:', '').strip()
        
        # Check for forbidden keywords
        forbidden_check = self._check_forbidden_keywords(cleaned)
        if forbidden_check:
            return False, None, f"Query contains forbidden keyword: {forbidden_check}"
        
        # Ensure it's a SELECT query
        if not self._is_select_query(cleaned):
            return False, None, "Only SELECT queries are allowed"
        
        # Check for multiple statements
        if self._has_multiple_statements(cleaned):
            return False, None, "Multiple SQL statements are not allowed"
        
        # Check for comment-based injection
        if self._has_suspicious_comments(cleaned):
            return False, None, "Query contains suspicious patterns"
        
        # In strict mode, verify tables
        if self.strict_mode:
            table_check = self._check_tables(cleaned)
            if table_check:
                return False, None, f"Query references unauthorized table: {table_check}"
        
        # Add safety limit if not present
        cleaned = self._add_safety_limit(cleaned)
        
        return True, cleaned, None
    
    def _clean_query(self, sql: str) -> str:
        """Clean and normalize the query."""
        # Remove markdown code blocks if present
        sql = re.sub(r'```sql\s*', '', sql)
        sql = re.sub(r'```\s*', '', sql)
        
        # Remove leading/trailing whitespace
        sql = sql.strip()
        
        # Remove any trailing semicolons
        sql = sql.rstrip(';')
        
        return sql
    
    def _check_forbidden_keywords(self, sql: str) -> Optional[str]:
        """Check for forbidden keywords."""
        sql_upper = sql.upper()
        
        for keyword in self.FORBIDDEN_KEYWORDS:
            # Use word boundary to avoid false positives
            pattern = r'\b' + keyword + r'\b'
            if re.search(pattern, sql_upper):
                return keyword
        
        return None
    
    def _is_select_query(self, sql: str) -> bool:
        """Check if query starts with SELECT."""
        # Remove leading comments
        sql_clean = re.sub(r'^--.*$', '', sql, flags=re.MULTILINE)
        sql_clean = re.sub(r'/\*.*?\*/', '', sql_clean, flags=re.DOTALL)
        sql_clean = sql_clean.strip()
        
        # Check if it starts with SELECT or WITH (CTEs)
        return sql_clean.upper().startswith(('SELECT', 'WITH'))
    
    def _has_multiple_statements(self, sql: str) -> bool:
        """Check for multiple SQL statements."""
        # Remove strings to avoid false positives
        sql_no_strings = re.sub(r"'[^']*'", '', sql)
        sql_no_strings = re.sub(r'"[^"]*"', '', sql_no_strings)
        
        # Check for semicolons (statement separators)
        return ';' in sql_no_strings
    
    def _has_suspicious_comments(self, sql: str) -> bool:
        """Check for suspicious comment patterns (potential injection)."""
        # Check for inline comments that might hide malicious code
        suspicious_patterns = [
            r'--\s*$',  # Comment at end of line (might hide code)
            r'/\*.*?(DROP|DELETE|INSERT|UPDATE|TRUNCATE).*?\*/',  # Hidden keywords in comments
            r'UNION\s+ALL\s+SELECT.*?FROM\s+pg_',  # System table access
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, sql, re.IGNORECASE | re.DOTALL):
                return True
        
        return False
    
    def _check_tables(self, sql: str) -> Optional[str]:
        """Check if query only uses allowed tables."""
        # Extract table names from FROM and JOIN clauses
        sql_upper = sql.upper()
        
        # Find all potential table references
        # This is a simplified check - may have false positives with aliases
        table_pattern = r'\b(?:FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_]*)'
        matches = re.findall(table_pattern, sql, re.IGNORECASE)
        
        for table in matches:
            if table.lower() not in self.ALLOWED_TABLES:
                # Could be an alias, do additional check
                if not self._is_likely_alias(sql, table):
                    return table
        
        return None
    
    def _is_likely_alias(self, sql: str, name: str) -> bool:
        """Check if a name is likely a table alias."""
        # Check if it appears after a table name with optional AS
        alias_pattern = rf'\b(?:{"|".join(self.ALLOWED_TABLES)})\s+(?:AS\s+)?{name}\b'
        return bool(re.search(alias_pattern, sql, re.IGNORECASE))
    
    def _add_safety_limit(self, sql: str, max_rows: int = 1000) -> str:
        """Add a LIMIT clause if not present to prevent huge result sets."""
        if 'LIMIT' not in sql.upper():
            return f"{sql}\nLIMIT {max_rows}"
        return sql
    
    def sanitize_for_display(self, sql: str) -> str:
        """
        Sanitize SQL for display in the UI.
        
        Args:
            sql: The SQL query
            
        Returns:
            Formatted SQL string safe for display
        """
        # Clean the query
        cleaned = self._clean_query(sql)
        
        # Basic formatting
        keywords = ['SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 
                   'HAVING', 'LIMIT', 'JOIN', 'LEFT JOIN', 'RIGHT JOIN',
                   'INNER JOIN', 'ON', 'AND', 'OR', 'AS', 'CASE', 'WHEN',
                   'THEN', 'ELSE', 'END', 'WITH', 'UNION', 'ALL']
        
        result = cleaned
        for kw in keywords:
            # Add newline before major clauses
            if kw in ['SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 
                     'HAVING', 'LIMIT', 'WITH', 'UNION']:
                result = re.sub(rf'\b{kw}\b', f'\n{kw}', result, flags=re.IGNORECASE)
        
        # Clean up multiple newlines
        result = re.sub(r'\n\s*\n', '\n', result)
        
        return result.strip()
