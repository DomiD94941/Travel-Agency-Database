------------------------------------------------------------
-- AUTO-DETECT AND SETUP ACTIVE DATA DIRECTORY
------------------------------------------------------------
DECLARE
  v_path VARCHAR2(200);
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY DANE_ACTIVE AS ''/home/oracle/dane_do_uzycia''';
    v_path := '/home/oracle/dane_do_uzycia';
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY DANE_ACTIVE AS ''/opt/oracle/dane''';
        v_path := '/opt/oracle/dane';
      EXCEPTION
        WHEN OTHERS THEN
          v_path := 'NONE';
      END;
  END;

  IF v_path <> 'NONE' THEN
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY DANE_ACTIVE TO "TRAVEL-AGENCY"';
    DBMS_OUTPUT.PUT_LINE('✅ Using data directory: ' || v_path);
  ELSE
    DBMS_OUTPUT.PUT_LINE('❌ No accessible data directory found.');
  END IF;
END;
/
------------------------------------------------------------
-- DATABASE INITIALIZATION
------------------------------------------------------------
BEGIN
  FOR t IN (
    SELECT table_name FROM user_tables WHERE table_name NOT LIKE 'LOGMNR%'
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/
------------------------------------------------------------
-- KONTYNENTY
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (ID_Kontynentu CHAR(10), Nazwa CHAR(100))
  )
  LOCATION ('kontynenty.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Kontynenty SELECT * FROM Kontynenty_EXT;
------------------------------------------------------------
-- KRAJE
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Kraju CHAR(10),
      Nazwa_Kraju CHAR(100),
      Kontynenty_ID_Kontynentu CHAR(10)
    )
  )
  LOCATION ('kraje.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Kraje SELECT * FROM Kraje_EXT;
------------------------------------------------------------
-- MIASTA
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Miasta CHAR(10),
      Nazwa_Miasta CHAR(100),
      Kraje_ID_Kraju CHAR(10)
    )
  )
  LOCATION ('miasta.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Miasta SELECT * FROM Miasta_EXT;
------------------------------------------------------------
-- HOTELE
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Hotelu CHAR(10),
      Nazwa_Hotelu CHAR(150),
      Ocena_Hotelu CHAR(10),
      Miasta_ID_Miasta CHAR(10)
    )
  )
  LOCATION ('hotele.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Hotele SELECT * FROM Hotele_EXT;
------------------------------------------------------------
-- KLIENCI
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Klienta CHAR(10),
      Imie CHAR(50),
      Nazwisko CHAR(50),
      Email CHAR(100),
      Telefon CHAR(20),
      Wiek CHAR(10)
    )
  )
  LOCATION ('klienci.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Klienci SELECT * FROM Klienci_EXT;
------------------------------------------------------------
-- PRACOWNICY
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Pracownika CHAR(10),
      Imie CHAR(50),
      Nazwisko CHAR(50),
      Stanowisko CHAR(100),
      Email CHAR(100),
      Telefon CHAR(20),
      Wiek CHAR(10)
    )
  )
  LOCATION ('pracownicy.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Pracownicy SELECT * FROM Pracownicy_EXT;
------------------------------------------------------------
-- PRZEWODNICY
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Przewodnika CHAR(10),
      Imie CHAR(50),
      Nazwisko CHAR(50),
      Specjalizacja CHAR(100),
      Telefon CHAR(20),
      Email CHAR(100),
      Wiek CHAR(10)
    )
  )
  LOCATION ('przewodnicy.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przewodnicy SELECT * FROM Przewodnicy_EXT;
------------------------------------------------------------
-- WYCIECZKI
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Wycieczki CHAR(10),
      Nazwa CHAR(150),
      Opis CHAR(4000),
      Data_Wyjazdu CHAR(20) DATE_FORMAT DATE MASK "YYYY-MM-DD",
      Data_Powrotu CHAR(20) DATE_FORMAT DATE MASK "YYYY-MM-DD",
      Liczba_Osob CHAR(10),
      Cena CHAR(20),
      Miasta_ID_Miasta CHAR(10)
    )
  )
  LOCATION ('wycieczki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Wycieczki SELECT * FROM Wycieczki_EXT;
------------------------------------------------------------
-- OCENY
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Oceny CHAR(10),
      Ocena CHAR(10),
      Komentarz CHAR(1000),
      Klienci_ID_Klienta CHAR(10),
      Wycieczka_ID_Wycieczki CHAR(10)
    )
  )
  LOCATION ('oceny.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Oceny SELECT * FROM Oceny_EXT;
------------------------------------------------------------
-- UBEZPIECZENIA
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Ubezpieczenia CHAR(10),
      Nazwa_Ubezpieczenia CHAR(200),
      Cena CHAR(20)
    )
  )
  LOCATION ('ubezpieczenia.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Ubezpieczenia SELECT * FROM Ubezpieczenia_EXT;
------------------------------------------------------------
-- REZERWACJE
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Rezerwacji CHAR(10),
      Data_Rezerwacji CHAR(20) DATE_FORMAT DATE MASK "YYYY-MM-DD",
      Status_Rezerwacji CHAR(50),
      Klienci_ID_Klienta CHAR(10),
      Wycieczki_ID_Wycieczki CHAR(10),
      Pracownicy_ID_Pracownika CHAR(10)
    )
  )
  LOCATION ('rezerwacje.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Rezerwacje SELECT * FROM Rezerwacje_EXT;
------------------------------------------------------------
-- REZERWACJE_UBEZPIECZEN
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Rezerwacji_Ubezpieczenia CHAR(10),
      Ubezpieczenia_ID_Ubezpieczenia CHAR(10),
      Rezerwacje_ID_Rezerwacji CHAR(10)
    )
  )
  LOCATION ('rezerwacje_ubezpieczen.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Rezerwacje_Ubezpieczen SELECT * FROM Rezerwacje_Ubezpieczen_EXT;
------------------------------------------------------------
-- TRANSPORT
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Transportu CHAR(10),
      Wycieczki_ID_Wycieczki CHAR(10)
    )
  )
  LOCATION ('transport.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Transport SELECT * FROM Transport_EXT;
------------------------------------------------------------
-- ETAPY_TRANSPORTU
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Etapu CHAR(10),
      Numer_Etapu CHAR(10),
      Rodzaj_Transportu CHAR(100),
      Miejsce_Wyjazdu CHAR(100),
      Miejsce_Przyjazdu CHAR(100),
      Data_Wyjazdu CHAR(25) DATE_FORMAT DATE MASK "YYYY-MM-DD HH24:MI:SS",
      Data_Przyjazdu CHAR(25) DATE_FORMAT DATE MASK "YYYY-MM-DD HH24:MI:SS",
      Typ_Etapu CHAR(50),
      Transport_ID_Transportu CHAR(10)
    )
  )
  LOCATION ('etapy_transportu.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Etapy_Transportu SELECT * FROM Etapy_Transportu_EXT;
------------------------------------------------------------
-- PRZESIADKI
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Przesiadki CHAR(10),
      Numer_Przesiadki CHAR(10),
      Miejsce_Przesiadki CHAR(100),
      Data_Przesiadki CHAR(25) DATE_FORMAT DATE MASK "YYYY-MM-DD HH24:MI:SS",
      Etapy_Transportu_ID_Etapu CHAR(10)
    )
  )
  LOCATION ('przesiadki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przesiadki SELECT * FROM Przesiadki_EXT;

------------------------------------------------------------
-- PRZEWODNICY_WYCIECZKI
------------------------------------------------------------
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
  DEFAULT DIRECTORY DANE_ACTIVE
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    CHARACTERSET UTF8
    SKIP 1
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      ID_Przewodnika_Wycieczki CHAR(10),
      Przewodnicy_ID_Przewodnika CHAR(10),
      Wycieczki_ID_Wycieczki CHAR(10)
    )
  )
  LOCATION ('przewodnicy_wycieczki.csv')
)
REJECT LIMIT UNLIMITED;

INSERT INTO Przewodnicy_Wycieczki SELECT * FROM Przewodnicy_Wycieczki_EXT;

------------------------------------------------------------
-- COMMIT + SUMMARY
------------------------------------------------------------
COMMIT;

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
SELECT 'Przesiadki', COUNT(*) FROM Przesiadki;
