------------------------------------------------------------
-- DATABASE INITIALIZATION
------------------------------------------------------------

-- Drop all existing user tables safely (ignores LogMiner/system tables)
BEGIN
  FOR t IN (
    SELECT table_name
    FROM user_tables
    WHERE table_name NOT LIKE 'LOGMNR%'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

------------------------------------------------------------
-- GEOGRAPHY: CONTINENTS, COUNTRIES, CITIES
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Kontynenty CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Kontynenty (
  ID_Kontynentu NUMBER PRIMARY KEY,
  Nazwa VARCHAR2(100)
);

CREATE TABLE Kontynenty_EXT (
  ID_Kontynentu NUMBER,
  Nazwa VARCHAR2(100)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Kontynentu, Nazwa)
  )
  LOCATION ('kontynenty.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Kontynenty SELECT * FROM Kontynenty_EXT;

------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Kraje CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Kraje (
  ID_Kraju NUMBER PRIMARY KEY,
  Nazwa_Kraju VARCHAR2(100),
  Kontynenty_ID_Kontynentu NUMBER REFERENCES Kontynenty(ID_Kontynentu)
);

CREATE TABLE Kraje_EXT (
  ID_Kraju NUMBER,
  Nazwa_Kraju VARCHAR2(100),
  Kontynenty_ID_Kontynentu NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Kraju, Nazwa_Kraju, Kontynenty_ID_Kontynentu)
  )
  LOCATION ('kraje.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Kraje SELECT * FROM Kraje_EXT;

------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Miasta CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Miasta (
  ID_Miasta NUMBER PRIMARY KEY,
  Nazwa_Miasta VARCHAR2(100),
  Kraje_ID_Kraju NUMBER REFERENCES Kraje(ID_Kraju)
);

CREATE TABLE Miasta_EXT (
  ID_Miasta NUMBER,
  Nazwa_Miasta VARCHAR2(100),
  Kraje_ID_Kraju NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Miasta, Nazwa_Miasta, Kraje_ID_Kraju)
  )
  LOCATION ('miasta.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Miasta SELECT * FROM Miasta_EXT;

------------------------------------------------------------
-- HOTELS
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Hotele CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Hotele (
  ID_Hotelu NUMBER PRIMARY KEY,
  Nazwa_Hotelu VARCHAR2(150),
  Ocena_Hotelu NUMBER(3,1),
  Miasta_ID_Miasta NUMBER REFERENCES Miasta(ID_Miasta)
);

CREATE TABLE Hotele_EXT (
  ID_Hotelu NUMBER,
  Nazwa_Hotelu VARCHAR2(150),
  Ocena_Hotelu NUMBER(3,1),
  Miasta_ID_Miasta NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Hotelu, Nazwa_Hotelu, Ocena_Hotelu, Miasta_ID_Miasta)
  )
  LOCATION ('hotele.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Hotele SELECT * FROM Hotele_EXT;

------------------------------------------------------------
-- CLIENTS
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Klienci CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Klienci (
  ID_Klienta NUMBER PRIMARY KEY,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Email VARCHAR2(100),
  Telefon VARCHAR2(20),
  Wiek NUMBER
);

CREATE TABLE Klienci_EXT (
  ID_Klienta NUMBER,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Email VARCHAR2(100),
  Telefon VARCHAR2(20),
  Wiek NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Klienta, Imie, Nazwisko, Email, Telefon, Wiek)
  )
  LOCATION ('klienci.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Klienci SELECT * FROM Klienci_EXT;

------------------------------------------------------------
-- EMPLOYEES
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Pracownicy CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Pracownicy (
  ID_Pracownika NUMBER PRIMARY KEY,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Stanowisko VARCHAR2(100),
  Email VARCHAR2(100),
  Telefon VARCHAR2(20),
  Wiek NUMBER
);

CREATE TABLE Pracownicy_EXT (
  ID_Pracownika NUMBER,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Stanowisko VARCHAR2(100),
  Email VARCHAR2(100),
  Telefon VARCHAR2(20),
  Wiek NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Pracownika, Imie, Nazwisko, Stanowisko, Email, Telefon, Wiek)
  )
  LOCATION ('pracownicy.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Pracownicy SELECT * FROM Pracownicy_EXT;

------------------------------------------------------------
-- GUIDES
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Przewodnicy CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Przewodnicy (
  ID_Przewodnika NUMBER PRIMARY KEY,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Specjalizacja VARCHAR2(100),
  Telefon VARCHAR2(20),
  Email VARCHAR2(100),
  Wiek NUMBER
);

CREATE TABLE Przewodnicy_EXT (
  ID_Przewodnika NUMBER,
  Imie VARCHAR2(50),
  Nazwisko VARCHAR2(50),
  Specjalizacja VARCHAR2(100),
  Telefon VARCHAR2(20),
  Email VARCHAR2(100),
  Wiek NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Przewodnika, Imie, Nazwisko, Specjalizacja, Telefon, Email, Wiek)
  )
  LOCATION ('przewodnicy.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przewodnicy SELECT * FROM Przewodnicy_EXT;

------------------------------------------------------------
-- TOURS
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Wycieczki CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Wycieczki (
  ID_Wycieczki NUMBER PRIMARY KEY,
  Nazwa VARCHAR2(150),
  Opis VARCHAR2(4000),
  Data_Wyjazdu DATE,
  Data_Powrotu DATE,
  Liczba_Osob NUMBER,
  Cena NUMBER(10,2),
  Miasta_ID_Miasta NUMBER REFERENCES Miasta(ID_Miasta)
);

CREATE TABLE Wycieczki_EXT (
  ID_Wycieczki NUMBER,
  Nazwa VARCHAR2(150),
  Opis VARCHAR2(4000),
  Data_Wyjazdu DATE,
  Data_Powrotu DATE,
  Liczba_Osob NUMBER,
  Cena NUMBER(10,2),
  Miasta_ID_Miasta NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Wycieczki, Nazwa, Opis,
     Data_Wyjazdu DATE "YYYY-MM-DD",
     Data_Powrotu DATE "YYYY-MM-DD",
     Liczba_Osob, Cena, Miasta_ID_Miasta)
  )
  LOCATION ('wycieczki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Wycieczki SELECT * FROM Wycieczki_EXT;

------------------------------------------------------------
-- GUIDES_TRIPS LINK TABLE
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Przewodnicy_Wycieczki CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Przewodnicy_Wycieczki (
  ID_Przewodnika_Wycieczki NUMBER PRIMARY KEY,
  Przewodnicy_ID_Przewodnika NUMBER REFERENCES Przewodnicy(ID_Przewodnika),
  Wycieczki_ID_Wycieczki NUMBER REFERENCES Wycieczki(ID_Wycieczki)
);

CREATE TABLE Przewodnicy_Wycieczki_EXT (
  ID_Przewodnika_Wycieczki NUMBER,
  Przewodnicy_ID_Przewodnika NUMBER,
  Wycieczki_ID_Wycieczki NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
  )
  LOCATION ('przewodnicy_wycieczki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przewodnicy_Wycieczki SELECT * FROM Przewodnicy_Wycieczki_EXT;

------------------------------------------------------------
-- REVIEWS (OCENY)
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Oceny CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Oceny (
  ID_Oceny NUMBER PRIMARY KEY,
  Ocena NUMBER(2,1),
  Komentarz VARCHAR2(1000),
  Klienci_ID_Klienta NUMBER REFERENCES Klienci(ID_Klienta),
  Wycieczka_ID_Wycieczki NUMBER REFERENCES Wycieczki(ID_Wycieczki)
);

CREATE TABLE Oceny_EXT (
  ID_Oceny NUMBER,
  Ocena NUMBER(2,1),
  Komentarz VARCHAR2(1000),
  Klienci_ID_Klienta NUMBER,
  Wycieczka_ID_Wycieczki NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Oceny, Ocena, Komentarz, Klienci_ID_Klienta, Wycieczka_ID_Wycieczki)
  )
  LOCATION ('oceny.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Oceny SELECT * FROM Oceny_EXT;

------------------------------------------------------------
-- INSURANCES
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Ubezpieczenia CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Ubezpieczenia (
  ID_Ubezpieczenia NUMBER PRIMARY KEY,
  Nazwa_Ubezpieczenia VARCHAR2(200),
  Cena NUMBER(10,2)
);

CREATE TABLE Ubezpieczenia_EXT (
  ID_Ubezpieczenia NUMBER,
  Nazwa_Ubezpieczenia VARCHAR2(200),
  Cena NUMBER(10,2)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Ubezpieczenia, Nazwa_Ubezpieczenia, Cena)
  )
  LOCATION ('ubezpieczenia.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Ubezpieczenia SELECT * FROM Ubezpieczenia_EXT;

------------------------------------------------------------
-- BOOKINGS
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rezerwacje CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Rezerwacje (
  ID_Rezerwacji NUMBER PRIMARY KEY,
  Data_Rezerwacji DATE,
  Status_Rezerwacji VARCHAR2(50),
  Klienci_ID_Klienta NUMBER REFERENCES Klienci(ID_Klienta),
  Wycieczki_ID_Wycieczki NUMBER REFERENCES Wycieczki(ID_Wycieczki),
  Pracownicy_ID_Pracownika NUMBER REFERENCES Pracownicy(ID_Pracownika)
);

CREATE TABLE Rezerwacje_EXT (
  ID_Rezerwacji NUMBER,
  Data_Rezerwacji DATE,
  Status_Rezerwacji VARCHAR2(50),
  Klienci_ID_Klienta NUMBER,
  Wycieczki_ID_Wycieczki NUMBER,
  Pracownicy_ID_Pracownika NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Rezerwacji,
     Data_Rezerwacji DATE "YYYY-MM-DD",
     Status_Rezerwacji,
     Klienci_ID_Klienta,
     Wycieczki_ID_Wycieczki,
     Pracownicy_ID_Pracownika)
  )
  LOCATION ('rezerwacje.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Rezerwacje SELECT * FROM Rezerwacje_EXT;

------------------------------------------------------------
-- BOOKINGS-INSURANCES LINK TABLE
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rezerwacje_Ubezpieczen CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Rezerwacje_Ubezpieczen (
  ID_Rezerwacji_Ubezpieczenia NUMBER PRIMARY KEY,
  Ubezpieczenia_ID_Ubezpieczenia NUMBER REFERENCES Ubezpieczenia(ID_Ubezpieczenia),
  Rezerwacje_ID_Rezerwacji NUMBER REFERENCES Rezerwacje(ID_Rezerwacji)
);

CREATE TABLE Rezerwacje_Ubezpieczen_EXT (
  ID_Rezerwacji_Ubezpieczenia NUMBER,
  Ubezpieczenia_ID_Ubezpieczenia NUMBER,
  Rezerwacje_ID_Rezerwacji NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Rezerwacji_Ubezpieczenia, Ubezpieczenia_ID_Ubezpieczenia, Rezerwacje_ID_Rezerwacji)
  )
  LOCATION ('rezerwacje_ubezpieczen.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Rezerwacje_Ubezpieczen SELECT * FROM Rezerwacje_Ubezpieczen_EXT;

------------------------------------------------------------
-- TRANSPORT
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Transport CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Transport (
  ID_Transportu NUMBER PRIMARY KEY,
  Wycieczki_ID_Wycieczki NUMBER REFERENCES Wycieczki(ID_Wycieczki)
);

CREATE TABLE Transport_EXT (
  ID_Transportu NUMBER,
  Wycieczki_ID_Wycieczki NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Transportu, Wycieczki_ID_Wycieczki)
  )
  LOCATION ('transport.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Transport SELECT * FROM Transport_EXT;

------------------------------------------------------------
-- TRANSPORT STAGES
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Etapy_Transportu CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Etapy_Transportu (
  ID_Etapu NUMBER PRIMARY KEY,
  Numer_Etapu NUMBER,
  Rodzaj_Transportu VARCHAR2(100),
  Miejsce_Wyjazdu VARCHAR2(100),
  Miejsce_Przyjazdu VARCHAR2(100),
  Data_Wyjazdu DATE,
  Data_Przyjazdu DATE,
  Typ_Etapu VARCHAR2(50),
  Transport_ID_Transportu NUMBER REFERENCES Transport(ID_Transportu)
);

CREATE TABLE Etapy_Transportu_EXT (
  ID_Etapu NUMBER,
  Numer_Etapu NUMBER,
  Rodzaj_Transportu VARCHAR2(100),
  Miejsce_Wyjazdu VARCHAR2(100),
  Miejsce_Przyjazdu VARCHAR2(100),
  Data_Wyjazdu DATE,
  Data_Przyjazdu DATE,
  Typ_Etapu VARCHAR2(50),
  Transport_ID_Transportu NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Etapu, Numer_Etapu, Rodzaj_Transportu,
     Miejsce_Wyjazdu, Miejsce_Przyjazdu,
     Data_Wyjazdu DATE "YYYY-MM-DD HH24:MI:SS",
     Data_Przyjazdu DATE "YYYY-MM-DD HH24:MI:SS",
     Typ_Etapu, Transport_ID_Transportu)
  )
  LOCATION ('etapy_transportu.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Etapy_Transportu SELECT * FROM Etapy_Transportu_EXT;

------------------------------------------------------------
-- TRANSFERS
------------------------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Przesiadki CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Przesiadki (
  ID_Przesiadki NUMBER PRIMARY KEY,
  Numer_Przesiadki NUMBER,
  Miejsce_Przesiadki VARCHAR2(100),
  Data_Przesiadki DATE,
  Etapy_Transportu_ID_Etapu NUMBER REFERENCES Etapy_Transportu(ID_Etapu)
);

CREATE TABLE Przesiadki_EXT (
  ID_Przesiadki NUMBER,
  Numer_Przesiadki NUMBER,
  Miejsce_Przesiadki VARCHAR2(100),
  Data_Przesiadki DATE,
  Etapy_Transportu_ID_Etapu NUMBER
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DANE1
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
    MISSING FIELD VALUES ARE NULL
    (ID_Przesiadki, Numer_Przesiadki, Miejsce_Przesiadki,
     Data_Przesiadki DATE "YYYY-MM-DD HH24:MI:SS",
     Etapy_Transportu_ID_Etapu)
  )
  LOCATION ('przesiadki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przesiadki SELECT * FROM Przesiadki_EXT;

------------------------------------------------------------
-- CLEANUP TEMPORARY EXTERNAL TABLES
------------------------------------------------------------

BEGIN
  FOR t IN (
    SELECT table_name FROM user_tables WHERE table_name LIKE '%_EXT%'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" PURGE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

------------------------------------------------------------
-- COMMIT ALL CHANGES
------------------------------------------------------------
COMMIT;

------------------------------------------------------------
-- FINAL RECORD COUNT SUMMARY
------------------------------------------------------------
SELECT 'Kontynenty', COUNT(*) FROM Kontynenty UNION ALL
SELECT 'Kraje', COUNT(*) FROM Kraje UNION ALL
SELECT 'Miasta', COUNT(*) FROM Miasta UNION ALL
SELECT 'Hotele', COUNT(*) FROM Hotele UNION ALL
SELECT 'Klienci', COUNT(*) FROM Klienci UNION ALL
SELECT 'Pracownicy', COUNT(*) FROM Pracownicy UNION ALL
SELECT 'Przewodnicy', COUNT(*) FROM Przewodnicy UNION ALL
SELECT 'Wycieczki', COUNT(*) FROM Wycieczki UNION ALL
SELECT 'Oceny', COUNT(*) FROM Oceny UNION ALL
SELECT 'Ubezpieczenia', COUNT(*) FROM Ubezpieczenia UNION ALL
SELECT 'Rezerwacje', COUNT(*) FROM Rezerwacje UNION ALL
SELECT 'Rezerwacje_Ubezpieczen', COUNT(*) FROM Rezerwacje_Ubezpieczen UNION ALL
SELECT 'Transport', COUNT(*) FROM Transport UNION ALL
SELECT 'Etapy_Transportu', COUNT(*) FROM Etapy_Transportu UNION ALL
SELECT 'Przesiadki', COUNT(*) FROM Przesiadki UNION ALL
SELECT 'Przewodnicy_Wycieczki', COUNT(*) FROM Przewodnicy_Wycieczki;
