"""
SQL Generator
=============
Converts natural language questions to SQL queries using LLMs.
Supports OpenAI GPT-4 and Anthropic Claude models.
"""

import os
from typing import Optional, Tuple
from .schema_context import SchemaContext
from .sql_validator import SQLValidator


class SQLGenerator:
    """Generates SQL queries from natural language using LLMs."""
    
    def __init__(self, conn, provider: str = "openai"):
        """
        Initialize the SQL generator.
        
        Args:
            conn: Database connection for schema context
            provider: LLM provider ("openai" or "anthropic")
        """
        self.conn = conn
        self.provider = provider
        self.schema_context = SchemaContext(conn)
        self.validator = SQLValidator(strict_mode=True)
        self._client = None
        self._conversation_history = []
    
    def _get_client(self):
        """Lazy-load the LLM client."""
        if self._client is not None:
            return self._client
        
        if self.provider == "openai":
            try:
                from openai import OpenAI
                api_key = os.getenv("OPENAI_API_KEY")
                if not api_key:
                    raise ValueError("OPENAI_API_KEY environment variable not set")
                self._client = OpenAI(api_key=api_key)
            except ImportError:
                raise ImportError("openai package not installed. Run: pip install openai")
        
        elif self.provider == "anthropic":
            try:
                import anthropic
                api_key = os.getenv("ANTHROPIC_API_KEY")
                if not api_key:
                    raise ValueError("ANTHROPIC_API_KEY environment variable not set")
                self._client = anthropic.Anthropic(api_key=api_key)
            except ImportError:
                raise ImportError("anthropic package not installed. Run: pip install anthropic")
        
        else:
            raise ValueError(f"Unknown provider: {self.provider}")
        
        return self._client
    
    def generate(self, question: str, use_conversation: bool = True) -> Tuple[str, bool, Optional[str]]:
        """
        Generate SQL from a natural language question.
        
        Args:
            question: The natural language question
            use_conversation: Whether to use conversation history for context
            
        Returns:
            Tuple of (sql_query, is_valid, error_message)
        """
        try:
            client = self._get_client()
        except (ImportError, ValueError) as e:
            return "", False, str(e)
        
        # Build messages
        if use_conversation and self._conversation_history:
            # Use quick context for follow-ups
            system_prompt = self.schema_context.get_quick_context()
            messages = self._conversation_history.copy()
            messages[0] = {"role": "system", "content": system_prompt}
        else:
            # Use full context for first question
            system_prompt = self.schema_context.build_system_prompt()
            messages = [{"role": "system", "content": system_prompt}]
            self._conversation_history = messages.copy()
        
        # Add user question
        messages.append({"role": "user", "content": question})
        
        # Generate SQL based on provider
        try:
            if self.provider == "openai":
                sql = self._generate_openai(client, messages)
            else:
                sql = self._generate_anthropic(client, messages, system_prompt)
        except Exception as e:
            return "", False, f"LLM API error: {str(e)}"
        
        # Validate the generated SQL
        is_valid, cleaned_sql, error = self.validator.validate(sql)
        
        if is_valid:
            # Add to conversation history
            self._conversation_history.append({"role": "user", "content": question})
            self._conversation_history.append({"role": "assistant", "content": cleaned_sql})
            
            # Keep history manageable (last 10 exchanges)
            if len(self._conversation_history) > 22:  # system + 10 pairs
                self._conversation_history = [self._conversation_history[0]] + self._conversation_history[-20:]
        
        return cleaned_sql or sql, is_valid, error
    
    def generate_with_retry(self, question: str, conn, max_retries: int = 3, 
                           status_callback=None) -> Tuple[str, bool, Optional[str], list]:
        """
        Generate SQL with automatic retry on errors.
        
        Args:
            question: The natural language question
            conn: Database connection for testing queries
            max_retries: Maximum number of retry attempts (default 3)
            status_callback: Optional callback function(attempt, message) for status updates
            
        Returns:
            Tuple of (sql_query, is_valid, error_message, attempt_history)
        """
        import pandas as pd
        
        attempt_history = []
        last_error = None
        previous_attempts = []
        
        for attempt in range(1, max_retries + 1):
            if status_callback:
                if attempt == 1:
                    status_callback(attempt, f"🔄 Generating SQL (attempt {attempt}/{max_retries})...")
                else:
                    status_callback(attempt, f"🔄 Retrying with different approach (attempt {attempt}/{max_retries})...")
            
            # Build question with error context if this is a retry
            if previous_attempts:
                error_context = "\n\nPREVIOUS ATTEMPTS THAT FAILED:\n"
                for prev in previous_attempts:
                    error_context += f"- SQL: {prev['sql'][:200]}...\n  Error: {prev['error']}\n"
                error_context += "\nPlease try a DIFFERENT approach. Use different tables or simpler joins."
                modified_question = question + error_context
            else:
                modified_question = question
            
            # Generate SQL
            sql, is_valid, validation_error = self.generate(modified_question, use_conversation=(attempt == 1))
            
            attempt_record = {
                'attempt': attempt,
                'sql': sql,
                'validation_error': validation_error,
                'execution_error': None,
                'success': False
            }
            
            # Check validation
            if not is_valid:
                attempt_record['execution_error'] = validation_error
                last_error = validation_error
                previous_attempts.append({'sql': sql, 'error': validation_error})
                attempt_history.append(attempt_record)
                continue
            
            # Try to execute the query
            try:
                pd.read_sql(sql, conn)
                attempt_record['success'] = True
                attempt_history.append(attempt_record)
                
                if status_callback and attempt > 1:
                    status_callback(attempt, f"✅ Success on attempt {attempt}!")
                
                return sql, True, None, attempt_history
                
            except Exception as e:
                exec_error = str(e)
                attempt_record['execution_error'] = exec_error
                last_error = exec_error
                previous_attempts.append({'sql': sql, 'error': exec_error})
                attempt_history.append(attempt_record)
                
                if status_callback:
                    status_callback(attempt, f"⚠️ Attempt {attempt} failed: {exec_error[:100]}...")
        
        # All retries exhausted
        final_error = f"Failed after {max_retries} attempts. Last error: {last_error}"
        return "", False, final_error, attempt_history
    
    def _generate_openai(self, client, messages: list) -> str:
        """Generate SQL using OpenAI API."""
        response = client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o"),
            messages=messages,
            temperature=0,  # Deterministic output for SQL
            max_tokens=1000
        )
        return response.choices[0].message.content.strip()
    
    def _generate_anthropic(self, client, messages: list, system_prompt: str) -> str:
        """Generate SQL using Anthropic API."""
        # Anthropic uses system prompt separately
        anthropic_messages = [
            {"role": msg["role"], "content": msg["content"]}
            for msg in messages
            if msg["role"] != "system"
        ]
        
        response = client.messages.create(
            model=os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
            max_tokens=1000,
            system=system_prompt,
            messages=anthropic_messages
        )
        return response.content[0].text.strip()
    
    def clear_conversation(self):
        """Clear the conversation history."""
        self._conversation_history = []
    
    def analyze_results(self, question: str, sql: str, df, max_rows: int = 20) -> str:
        """
        Analyze query results and provide insights.
        
        Args:
            question: Original user question
            sql: The SQL query that was executed
            df: Pandas DataFrame with results
            max_rows: Maximum rows to include in context
            
        Returns:
            Human-readable analysis of the results
        """
        try:
            client = self._get_client()
        except (ImportError, ValueError) as e:
            return f"Could not analyze results: {str(e)}"
        
        # Prepare data summary
        row_count = len(df)
        col_info = ", ".join([f"{col} ({df[col].dtype})" for col in df.columns])
        
        # Sample data (limit rows to control token usage)
        sample_data = df.head(max_rows).to_string(index=False)
        
        # Build analysis prompt
        analysis_prompt = f"""The user asked: "{question}"

This SQL was executed:
```sql
{sql}
```

Results ({row_count} rows, columns: {col_info}):
```
{sample_data}
```

Provide a brief, insightful analysis of these results:
1. Summarize the key findings (2-3 sentences)
2. Highlight notable patterns or outliers
3. If relevant, suggest follow-up questions

**FORMAT VALUES CORRECTLY based on metric_unit column (if present) or data type:**
- USD → Currency: $1,234,567.89
- Percent → Percentage: 85.5%
- Count → Integer: 1,234
- Days → Duration: 5.2 days
- Hours → Duration: 48 hours
- Revenue/Amount/Price columns → Currency format
- Rate/Ratio columns → Percentage or decimal

Keep the response concise and business-focused. Use bullet points for clarity."""

        try:
            if self.provider == "openai":
                system_msg = "You are a data analyst providing insights on query results. Be concise and focus on actionable insights. Always format numbers appropriately: USD as $X,XXX.XX, percentages as X.X%, counts as X,XXX, days/hours with units."
                response = client.chat.completions.create(
                    model=os.getenv("OPENAI_MODEL", "gpt-4o"),
                    messages=[
                        {"role": "system", "content": system_msg},
                        {"role": "user", "content": analysis_prompt}
                    ],
                    temperature=0.3,
                    max_tokens=500
                )
                return response.choices[0].message.content.strip()
            else:
                system_msg = "You are a data analyst providing insights on query results. Be concise and focus on actionable insights. Always format numbers appropriately: USD as $X,XXX.XX, percentages as X.X%, counts as X,XXX, days/hours with units."
                response = client.messages.create(
                    model=os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
                    max_tokens=500,
                    system=system_msg,
                    messages=[{"role": "user", "content": analysis_prompt}]
                )
                return response.content[0].text.strip()
        except Exception as e:
            return f"Could not analyze results: {str(e)}"
    
    def get_suggestions(self) -> list:
        """
        Get suggested questions based on available data.
        
        Returns:
            List of suggested question strings
        """
        return [
            "What is our total revenue by territory?",
            "Show me the top 10 customers by lifetime value",
            "What is the monthly revenue trend?",
            "Which products have the highest profit margin?",
            "Show me customers at risk of churning",
            "What is the average order value by customer segment?",
            "How many orders do we have by status?",
            "What is revenue by product category?",
            "Show me employee quota achievement rates",
            "What is our inventory value by category?"
        ]
