-- Create additional databases for Solid Cache, Solid Queue, Solid Cable.
-- Primary database (mediateca_production) and user (mediateca) are created by PostgreSQL image env.

CREATE DATABASE mediateca_production_cache;
CREATE DATABASE mediateca_production_queue;
CREATE DATABASE mediateca_production_cable;

GRANT ALL PRIVILEGES ON DATABASE mediateca_production_cache TO mediateca;
GRANT ALL PRIVILEGES ON DATABASE mediateca_production_queue TO mediateca;
GRANT ALL PRIVILEGES ON DATABASE mediateca_production_cable TO mediateca;

\c mediateca_production_cache
GRANT ALL ON SCHEMA public TO mediateca;

\c mediateca_production_queue
GRANT ALL ON SCHEMA public TO mediateca;

\c mediateca_production_cable
GRANT ALL ON SCHEMA public TO mediateca;
