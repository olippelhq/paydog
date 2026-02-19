#!/bin/bash
set -e

# Create schemas
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS auth;
    CREATE SCHEMA IF NOT EXISTS payments;
EOSQL

echo "Schemas created: auth, payments"

# Apply auth migrations
for f in /docker-entrypoint-initdb.d/auth/*.sql; do
    echo "Applying auth migration: $f"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

# Apply payment migrations
for f in /docker-entrypoint-initdb.d/payment/*.sql; do
    echo "Applying payment migration: $f"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

echo "All migrations applied successfully"
