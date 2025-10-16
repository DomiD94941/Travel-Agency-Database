-- Grant privileges so this user can create objects
GRANT CONNECT, RESOURCE TO "TRAVEL-AGENCY";
GRANT CREATE VIEW, CREATE SYNONYM, CREATE SEQUENCE TO "TRAVEL-AGENCY";

-- (optional, for debugging or external tables)

CREATE OR REPLACE DIRECTORY DANE_LOCAL AS '/home/oracle/dane_do_uzycia';
GRANT READ, WRITE ON DIRECTORY DANE_LOCAL TO "TRAVEL-AGENCY";

