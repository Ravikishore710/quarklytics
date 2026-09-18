-- Docker creates the quarklytics database. Run this file against a server only when
-- provisioning outside Docker; CREATE DATABASE cannot run inside a transaction.
-- CREATE DATABASE quarklytics;
SELECT current_database() AS database_name;
