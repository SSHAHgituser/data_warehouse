#!/bin/bash

set -e

echo "📚 Starting dbt docs generation and serving..."

# Wait for PostgreSQL to be ready (if needed)
if [ -n "$WAIT_FOR_DB" ]; then
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h ${DBT_HOST:-postgres} -p ${DBT_PORT:-5432} -U ${DBT_USER:-postgres}; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done
    echo "PostgreSQL is up - executing command"
fi

# Generate dbt docs
echo "Generating dbt documentation..."
export DBT_PROFILES_DIR=/app

# Update profiles.yml with environment variables if provided
if [ -n "$DBT_HOST" ]; then
    sed -i "s/host:.*/host: ${DBT_HOST}/" /app/profiles.yml
fi
if [ -n "$DBT_PORT" ]; then
    sed -i "s/port:.*/port: ${DBT_PORT}/" /app/profiles.yml
fi
if [ -n "$DBT_USER" ]; then
    sed -i "s/user:.*/user: ${DBT_USER}/" /app/profiles.yml
fi
if [ -n "$DBT_PASSWORD" ]; then
    sed -i "s/password:.*/password: ${DBT_PASSWORD}/" /app/profiles.yml
fi
if [ -n "$DBT_DBNAME" ]; then
    sed -i "s/dbname:.*/dbname: ${DBT_DBNAME}/" /app/profiles.yml
fi
if [ -n "$DBT_SCHEMA" ]; then
    sed -i "s/schema:.*/schema: ${DBT_SCHEMA}/" /app/profiles.yml
fi

# Generate docs
if ! dbt docs generate; then
    echo "⚠️  Warning: Could not generate docs. Serving existing docs if available."
    if [ ! -f "/app/target/index.html" ]; then
        echo "❌ No docs found. Please generate docs first or ensure database connection."
        echo "You can generate docs locally with: ./generate_docs.sh"
        exit 1
    fi
fi

echo "✅ Documentation generated successfully"

# Configure nginx
echo "Configuring nginx..."

# Remove default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "Removed default nginx site"
fi

# Create our custom configuration
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /app/target;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test nginx configuration
if ! nginx -t; then
    echo "❌ Nginx configuration test failed"
    exit 1
fi

echo "✅ Nginx configuration is valid"
echo "✅ Starting nginx server..."
exec nginx -g "daemon off;"

