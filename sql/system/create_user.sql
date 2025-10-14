-- Create a new user for your project
CREATE USER travel_app IDENTIFIED BY travel123
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

-- Grant privileges so this user can create objects
GRANT CONNECT, RESOURCE TO travel_app;
GRANT CREATE VIEW, CREATE SYNONYM, CREATE SEQUENCE TO travel_app;

-- (optional, for debugging or external tables)
GRANT READ, WRITE ON DIRECTORY DANE1 TO travel_app;

