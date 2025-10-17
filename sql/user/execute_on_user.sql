SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT Cleaning up existing travel agency objects...
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE BODY travel_agency_api'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE travel_agency_api'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE travel_agency_apex'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW top_rated_hotels_v'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW family_packages_v'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW available_offers_v'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW booking_party_summary_v'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW apex_client_accounts_v'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT Dropping existing tables...
BEGIN
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
    'ITINERARY_ACTIVITIES','ITINERARY_DAYS','ITINERARIES',
    'REVIEWS','BOOKING_COSTS','BOOKING_CUSTOMER_SNAPSHOTS','BOOKING_INSURANCES','BOOKING_TRANSPORTS',
    'BOOKING_ROOMS','BOOKING_TRAVELLERS','BOOKING_STATUS_HISTORY','BOOKINGS',
    'TRANSPORT_OPTIONS','HOTEL_ROOM_INVENTORY','HOTEL_ROOM_TYPE_AMENITIES',
    'HOTEL_ROOM_TYPES','AMENITIES','HOTELS','GUIDE_LANGUAGES',
    'GUIDES','ATTRACTIONS','INSURANCES','DISCOUNTS','TRAVELLERS',
    'CLIENT_PREFERENCES','CLIENTS','CITIES','COUNTRIES','CONTINENTS'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

PROMPT Dropping sequences...
BEGIN
  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_%') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

PROMPT Creating geographic tables...
CREATE TABLE continents (
  continent_id      NUMBER        PRIMARY KEY,
  continent_code    VARCHAR2(10)  NOT NULL UNIQUE,
  name              VARCHAR2(100) NOT NULL,
  description       VARCHAR2(4000)
);

CREATE TABLE countries (
  country_id    NUMBER        PRIMARY KEY,
  continent_id  NUMBER        NOT NULL,
  iso_code      CHAR(2)       NOT NULL UNIQUE,
  name          VARCHAR2(150) NOT NULL,
  currency_code CHAR(3)       NOT NULL,
  CONSTRAINT fk_countries_continent
    FOREIGN KEY (continent_id)
    REFERENCES continents(continent_id)
    ON DELETE CASCADE
);

CREATE TABLE cities (
  city_id        NUMBER        PRIMARY KEY,
  country_id     NUMBER        NOT NULL,
  name           VARCHAR2(150) NOT NULL,
  state_province VARCHAR2(150),
  timezone       VARCHAR2(60),
  latitude       NUMBER(9,6),
  longitude      NUMBER(9,6),
  CONSTRAINT fk_cities_country
    FOREIGN KEY (country_id)
    REFERENCES countries(country_id)
    ON DELETE CASCADE
);

PROMPT Creating customer tables...
CREATE TABLE clients (
  client_id                 NUMBER        PRIMARY KEY,
  first_name                VARCHAR2(80)  NOT NULL,
  last_name                 VARCHAR2(120) NOT NULL,
  email                     VARCHAR2(200) NOT NULL UNIQUE,
  phone                     VARCHAR2(40),
  username                  VARCHAR2(80)  NOT NULL UNIQUE,
  password_hash             VARCHAR2(200) NOT NULL,
  account_status            VARCHAR2(20)  DEFAULT 'ACTIVE'
                               CHECK (account_status IN ('ACTIVE','LOCKED','DISABLED')),
  last_login                DATE,
  preferred_language        VARCHAR2(10),
  preferred_contact_method  VARCHAR2(20)  DEFAULT 'EMAIL'
                               CHECK (preferred_contact_method IN ('EMAIL','PHONE','SMS','WHATSAPP')),
  marketing_opt_in          CHAR(1)       DEFAULT 'N' CHECK (marketing_opt_in IN ('Y','N')),
  created_at                DATE          DEFAULT SYSDATE,
  updated_at                DATE,
  calculated_total          NUMBER(12,2),
  calculated_at             DATE
);

CREATE TABLE client_preferences (
  preference_id              NUMBER        PRIMARY KEY,
  client_id                  NUMBER        NOT NULL UNIQUE,
  travelling_with_children   CHAR(1)       DEFAULT 'N' CHECK (travelling_with_children IN ('Y','N')),
  travelling_with_pets       CHAR(1)       DEFAULT 'N' CHECK (travelling_with_pets IN ('Y','N')),
  accessibility_needs        VARCHAR2(500),
  dietary_preferences        VARCHAR2(500),
  preferred_room_type        VARCHAR2(100),
  preferred_food_type        VARCHAR2(100),
  preferred_transport        VARCHAR2(100),
  preferred_city_id          NUMBER,
  notes                      VARCHAR2(1000),
  CONSTRAINT fk_client_preferences_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_client_preferences_city
    FOREIGN KEY (preferred_city_id)
    REFERENCES cities(city_id)
    ON DELETE SET NULL
);

CREATE TABLE travellers (
  traveller_id         NUMBER        PRIMARY KEY,
  client_id            NUMBER        NOT NULL,
  first_name           VARCHAR2(80)  NOT NULL,
  last_name            VARCHAR2(120) NOT NULL,
  date_of_birth        DATE,
  traveller_type       VARCHAR2(20)  DEFAULT 'ADULT'
                          CHECK (traveller_type IN ('ADULT','CHILD','INFANT','SENIOR')),
  gender               VARCHAR2(20),
  passport_number      VARCHAR2(30),
  passport_expiry      DATE,
  relationship_to_client VARCHAR2(40),
  special_needs        VARCHAR2(1000),
  preferred_language   VARCHAR2(10),
  CONSTRAINT fk_travellers_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE CASCADE
);

PROMPT Creating personnel tables...
CREATE TABLE guides (
  guide_id         NUMBER        PRIMARY KEY,
  first_name       VARCHAR2(80)  NOT NULL,
  last_name        VARCHAR2(120) NOT NULL,
  email            VARCHAR2(200),
  phone            VARCHAR2(40),
  bio              VARCHAR2(2000),
  rating           NUMBER(3,2),
  years_experience NUMBER,
  speciality       VARCHAR2(200),
  daily_rate       NUMBER(10,2)
);

CREATE TABLE guide_languages (
  guide_language_id NUMBER       PRIMARY KEY,
  guide_id          NUMBER       NOT NULL,
  language_code     VARCHAR2(10) NOT NULL,
  is_native         CHAR(1)      DEFAULT 'N' CHECK (is_native IN ('Y','N')),
  CONSTRAINT fk_guide_languages_guide
    FOREIGN KEY (guide_id)
    REFERENCES guides(guide_id)
    ON DELETE CASCADE
);

PROMPT Creating accommodation tables...
CREATE TABLE hotels (
  hotel_id        NUMBER        PRIMARY KEY,
  city_id         NUMBER        NOT NULL,
  name            VARCHAR2(200) NOT NULL,
  description     VARCHAR2(2000),
  address         VARCHAR2(400),
  latitude        NUMBER(9,6),
  longitude       NUMBER(9,6),
  star_rating     NUMBER(2,1),
  contact_email   VARCHAR2(200),
  contact_phone   VARCHAR2(40),
  website         VARCHAR2(200),
  check_in_time   VARCHAR2(20),
  check_out_time  VARCHAR2(20),
  family_friendly CHAR(1) DEFAULT 'Y' CHECK (family_friendly IN ('Y','N')),
  CONSTRAINT fk_hotels_city
    FOREIGN KEY (city_id)
    REFERENCES cities(city_id)
);

CREATE TABLE amenities (
  amenity_id  NUMBER        PRIMARY KEY,
  name        VARCHAR2(150) NOT NULL UNIQUE,
  description VARCHAR2(500)
);

CREATE TABLE hotel_room_types (
  room_type_id      NUMBER        PRIMARY KEY,
  hotel_id          NUMBER        NOT NULL,
  name              VARCHAR2(150) NOT NULL,
  description       VARCHAR2(1000),
  max_adults        NUMBER(3)     NOT NULL,
  max_children      NUMBER(3)     DEFAULT 0 NOT NULL,
  max_occupancy     NUMBER(3)     NOT NULL,
  bed_configuration VARCHAR2(200),
  base_rate         NUMBER(10,2)  NOT NULL,
  currency_code     CHAR(3)       DEFAULT 'EUR',
  family_friendly   CHAR(1)       DEFAULT 'N' CHECK (family_friendly IN ('Y','N')),
  accessible        CHAR(1)       DEFAULT 'N' CHECK (accessible IN ('Y','N')),
  CONSTRAINT fk_room_types_hotel
    FOREIGN KEY (hotel_id)
    REFERENCES hotels(hotel_id)
    ON DELETE CASCADE,
  CONSTRAINT chk_room_capacity
    CHECK (max_occupancy >= max_adults + max_children)
);

CREATE TABLE hotel_room_type_amenities (
  room_type_id NUMBER NOT NULL,
  amenity_id   NUMBER NOT NULL,
  CONSTRAINT pk_room_type_amenities
    PRIMARY KEY (room_type_id, amenity_id),
  CONSTRAINT fk_rta_room_type
    FOREIGN KEY (room_type_id)
    REFERENCES hotel_room_types(room_type_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_rta_amenity
    FOREIGN KEY (amenity_id)
    REFERENCES amenities(amenity_id)
    ON DELETE CASCADE
);

CREATE TABLE hotel_room_inventory (
  inventory_id  NUMBER       PRIMARY KEY,
  room_type_id  NUMBER       NOT NULL,
  inventory_date DATE        NOT NULL,
  rooms_total   NUMBER(5)    NOT NULL,
  rooms_booked  NUMBER(5)    DEFAULT 0 NOT NULL,
  rate          NUMBER(10,2) NOT NULL,
  currency_code CHAR(3)      DEFAULT 'EUR',
  CONSTRAINT fk_inventory_room_type
    FOREIGN KEY (room_type_id)
    REFERENCES hotel_room_types(room_type_id)
    ON DELETE CASCADE,
  CONSTRAINT chk_rooms_total
    CHECK (rooms_total >= 0),
  CONSTRAINT chk_rooms_booked
    CHECK (rooms_booked >= 0 AND rooms_booked <= rooms_total),
  CONSTRAINT uq_inventory UNIQUE (room_type_id, inventory_date)
);

PROMPT Creating attractions and transport tables...
CREATE TABLE attractions (
  attraction_id    NUMBER        PRIMARY KEY,
  city_id          NUMBER        NOT NULL,
  name             VARCHAR2(200) NOT NULL,
  attraction_type  VARCHAR2(100),
  description      VARCHAR2(2000),
  duration_minutes NUMBER(5),
  base_price       NUMBER(10,2),
  currency_code    CHAR(3)       DEFAULT 'EUR',
  family_friendly  CHAR(1)       DEFAULT 'Y' CHECK (family_friendly IN ('Y','N')),
  recommended_age  VARCHAR2(100),
  CONSTRAINT fk_attractions_city
    FOREIGN KEY (city_id)
    REFERENCES cities(city_id)
);

CREATE TABLE transport_options (
  transport_option_id NUMBER        PRIMARY KEY,
  transport_type      VARCHAR2(20)  NOT NULL
                          CHECK (transport_type IN ('FLIGHT','TRAIN','TRANSFER','CAR_RENTAL','BUS','CRUISE')),
  provider_name       VARCHAR2(150),
  from_city_id        NUMBER,
  to_city_id          NUMBER,
  departure_time      DATE,
  arrival_time        DATE,
  duration_minutes    NUMBER(6),
  capacity            NUMBER(5),
  base_price          NUMBER(10,2),
  currency_code       CHAR(3)       DEFAULT 'EUR',
  family_friendly     CHAR(1)       DEFAULT 'Y' CHECK (family_friendly IN ('Y','N')),
  CONSTRAINT fk_transport_from_city
    FOREIGN KEY (from_city_id)
    REFERENCES cities(city_id),
  CONSTRAINT fk_transport_to_city
    FOREIGN KEY (to_city_id)
    REFERENCES cities(city_id)
);

PROMPT Creating pricing tables...
CREATE TABLE discounts (
  discount_id   NUMBER        PRIMARY KEY,
  name          VARCHAR2(150) NOT NULL,
  description   VARCHAR2(1000),
  discount_type VARCHAR2(20)  NOT NULL CHECK (discount_type IN ('PERCENTAGE','FIXED')),
  value         NUMBER(7,2)   NOT NULL CHECK (value > 0),
  min_people    NUMBER(3),
  min_nights    NUMBER(3),
  valid_from    DATE,
  valid_to      DATE,
  promo_code    VARCHAR2(40),
  family_only   CHAR(1)       DEFAULT 'N' CHECK (family_only IN ('Y','N'))
);

CREATE TABLE insurances (
  insurance_id   NUMBER        PRIMARY KEY,
  name           VARCHAR2(150) NOT NULL,
  description    VARCHAR2(1000),
  coverage_level VARCHAR2(100),
  price          NUMBER(10,2)  NOT NULL,
  currency_code  CHAR(3)       DEFAULT 'EUR'
);

PROMPT Creating booking tables...
CREATE TABLE bookings (
  booking_id        NUMBER        PRIMARY KEY,
  client_id         NUMBER        NOT NULL,
  booking_reference VARCHAR2(30)  NOT NULL UNIQUE,
  status            VARCHAR2(20)  NOT NULL CHECK (status IN ('NEW','OPTION','CONFIRMED','CANCELLED','COMPLETED')),
  start_date        DATE,
  end_date          DATE,
  total_adults      NUMBER(3)     DEFAULT 0,
  total_children    NUMBER(3)     DEFAULT 0,
  budget_amount     NUMBER(12,2),
  currency_code     CHAR(3)       DEFAULT 'EUR',
  discount_id       NUMBER,
  notes             VARCHAR2(2000),
  created_at        DATE          DEFAULT SYSDATE,
  updated_at        DATE,
  CONSTRAINT fk_bookings_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bookings_discount
    FOREIGN KEY (discount_id)
    REFERENCES discounts(discount_id),
  CONSTRAINT chk_booking_dates
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE TABLE booking_travellers (
  booking_traveller_id NUMBER       PRIMARY KEY,
  booking_id           NUMBER       NOT NULL,
  traveller_id         NUMBER       NOT NULL,
  traveller_role       VARCHAR2(20) DEFAULT 'ADULT' CHECK (traveller_role IN ('PRIMARY','ADULT','CHILD','INFANT')),
  is_lead_contact      CHAR(1)      DEFAULT 'N' CHECK (is_lead_contact IN ('Y','N')),
  CONSTRAINT fk_bt_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bt_traveller
    FOREIGN KEY (traveller_id)
    REFERENCES travellers(traveller_id),
  CONSTRAINT uq_booking_travellers UNIQUE (booking_id, traveller_id)
);

CREATE TABLE booking_rooms (
  booking_room_id NUMBER       PRIMARY KEY,
  booking_id      NUMBER       NOT NULL,
  room_type_id    NUMBER       NOT NULL,
  check_in_date   DATE         NOT NULL,
  check_out_date  DATE         NOT NULL,
  number_of_rooms NUMBER(3)    DEFAULT 1 CHECK (number_of_rooms > 0),
  nightly_rate    NUMBER(10,2) NOT NULL,
  discount_amount NUMBER(10,2) DEFAULT 0,
  currency_code   CHAR(3)      DEFAULT 'EUR',
  CONSTRAINT fk_booking_rooms_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_booking_rooms_room_type
    FOREIGN KEY (room_type_id)
    REFERENCES hotel_room_types(room_type_id),
  CONSTRAINT chk_booking_room_dates
    CHECK (check_out_date > check_in_date)
);

CREATE TABLE booking_transports (
  booking_transport_id NUMBER       PRIMARY KEY,
  booking_id           NUMBER       NOT NULL,
  transport_option_id  NUMBER       NOT NULL,
  traveller_count      NUMBER(3)    NOT NULL CHECK (traveller_count > 0),
  price                NUMBER(10,2) NOT NULL,
  currency_code        CHAR(3)      DEFAULT 'EUR',
  seat_class           VARCHAR2(30),
  notes                VARCHAR2(1000),
  CONSTRAINT fk_bt_booking_main
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bt_transport
    FOREIGN KEY (transport_option_id)
    REFERENCES transport_options(transport_option_id)
);

CREATE TABLE booking_insurances (
  booking_insurance_id NUMBER       PRIMARY KEY,
  booking_id           NUMBER       NOT NULL,
  insurance_id         NUMBER       NOT NULL,
  coverage_amount      NUMBER(10,2),
  price                NUMBER(10,2),
  currency_code        CHAR(3)      DEFAULT 'EUR',
  CONSTRAINT fk_bi_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bi_insurance
    FOREIGN KEY (insurance_id)
    REFERENCES insurances(insurance_id),
  CONSTRAINT uq_booking_insurance UNIQUE (booking_id, insurance_id)
);

CREATE TABLE booking_costs (
  booking_cost_id NUMBER       PRIMARY KEY,
  booking_id      NUMBER       NOT NULL,
  cost_type       VARCHAR2(30) NOT NULL,
  reference_id    NUMBER,
  description     VARCHAR2(500),
  amount          NUMBER(10,2) NOT NULL,
  currency_code   CHAR(3)      DEFAULT 'EUR',
  CONSTRAINT fk_booking_costs_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE
);

CREATE TABLE booking_customer_snapshots (
  snapshot_id                NUMBER        PRIMARY KEY,
  booking_id                 NUMBER        NOT NULL UNIQUE,
  client_id                  NUMBER        NOT NULL,
  client_first_name          VARCHAR2(80)  NOT NULL,
  client_last_name           VARCHAR2(120) NOT NULL,
  client_email               VARCHAR2(200) NOT NULL,
  client_phone               VARCHAR2(40),
  account_username           VARCHAR2(80),
  account_status             VARCHAR2(20),
  last_login                 DATE,
  preferred_language         VARCHAR2(10),
  preferred_contact_method   VARCHAR2(20),
  marketing_opt_in           CHAR(1),
  travelling_with_children   CHAR(1),
  travelling_with_pets       CHAR(1),
  accessibility_needs        VARCHAR2(500),
  dietary_preferences        VARCHAR2(500),
  preferred_room_type        VARCHAR2(100),
  preferred_food_type        VARCHAR2(100),
  preferred_transport        VARCHAR2(100),
  preferred_city_id          NUMBER,
  preferred_city_name        VARCHAR2(150),
  created_at                 DATE          DEFAULT SYSDATE,
  updated_at                 DATE,
  CONSTRAINT fk_bcs_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bcs_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_bcs_preferred_city
    FOREIGN KEY (preferred_city_id)
    REFERENCES cities(city_id)
    ON DELETE SET NULL
);

CREATE TABLE booking_status_history (
  history_id   NUMBER       PRIMARY KEY,
  booking_id   NUMBER       NOT NULL,
  old_status   VARCHAR2(20),
  new_status   VARCHAR2(20) NOT NULL,
  changed_at   DATE         DEFAULT SYSDATE,
  changed_by   VARCHAR2(100),
  reason       VARCHAR2(1000),
  CONSTRAINT fk_bsh_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE
);

PROMPT Creating itinerary tables...
CREATE TABLE itineraries (
  itinerary_id NUMBER        PRIMARY KEY,
  booking_id   NUMBER        NOT NULL,
  name         VARCHAR2(200) NOT NULL,
  start_date   DATE,
  end_date     DATE,
  summary      VARCHAR2(2000),
  CONSTRAINT fk_itineraries_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE
);

CREATE TABLE itinerary_days (
  itinerary_day_id NUMBER       PRIMARY KEY,
  itinerary_id     NUMBER       NOT NULL,
  day_number       NUMBER(3)    NOT NULL,
  day_date         DATE,
  theme            VARCHAR2(200),
  is_rest_day      CHAR(1)      DEFAULT 'N' CHECK (is_rest_day IN ('Y','N')),
  notes            VARCHAR2(1000),
  CONSTRAINT fk_itinerary_days_itinerary
    FOREIGN KEY (itinerary_id)
    REFERENCES itineraries(itinerary_id)
    ON DELETE CASCADE,
  CONSTRAINT uq_itinerary_day UNIQUE (itinerary_id, day_number)
);

CREATE TABLE itinerary_activities (
  itinerary_activity_id NUMBER       PRIMARY KEY,
  itinerary_day_id      NUMBER       NOT NULL,
  activity_type         VARCHAR2(20) NOT NULL CHECK (activity_type IN ('ATTRACTION','TRANSPORT','REST','OTHER')),
  attraction_id         NUMBER,
  transport_option_id   NUMBER,
  guide_id              NUMBER,
  start_time            DATE,
  end_time              DATE,
  notes                 VARCHAR2(2000),
  CONSTRAINT fk_ia_day
    FOREIGN KEY (itinerary_day_id)
    REFERENCES itinerary_days(itinerary_day_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_ia_attraction
    FOREIGN KEY (attraction_id)
    REFERENCES attractions(attraction_id),
  CONSTRAINT fk_ia_transport
    FOREIGN KEY (transport_option_id)
    REFERENCES transport_options(transport_option_id),
  CONSTRAINT fk_ia_guide
    FOREIGN KEY (guide_id)
    REFERENCES guides(guide_id),
  CONSTRAINT chk_activity_refs
    CHECK (
      (activity_type = 'ATTRACTION' AND attraction_id IS NOT NULL)
      OR (activity_type = 'TRANSPORT' AND transport_option_id IS NOT NULL)
      OR (activity_type = 'REST' AND attraction_id IS NULL AND transport_option_id IS NULL AND guide_id IS NULL)
      OR (activity_type = 'OTHER')
    )
);

PROMPT Creating review tables...
CREATE TABLE reviews (
  review_id             NUMBER       PRIMARY KEY,
  booking_id            NUMBER,
  client_id             NUMBER,
  review_type           VARCHAR2(20) NOT NULL CHECK (review_type IN ('HOTEL','ATTRACTION','GUIDE')),
  hotel_id              NUMBER,
  attraction_id         NUMBER,
  guide_id              NUMBER,
  rating                NUMBER(2,1)  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title                 VARCHAR2(200),
  comments              VARCHAR2(2000),
  reviewed_on           DATE         DEFAULT SYSDATE,
  would_recommend       CHAR(1)      DEFAULT 'Y' CHECK (would_recommend IN ('Y','N')),
  family_suitability_score NUMBER(2,1),
  CONSTRAINT fk_reviews_booking
    FOREIGN KEY (booking_id)
    REFERENCES bookings(booking_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reviews_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE SET NULL,
  CONSTRAINT fk_reviews_hotel
    FOREIGN KEY (hotel_id)
    REFERENCES hotels(hotel_id)
    ON DELETE SET NULL,
  CONSTRAINT fk_reviews_attraction
    FOREIGN KEY (attraction_id)
    REFERENCES attractions(attraction_id)
    ON DELETE SET NULL,
  CONSTRAINT fk_reviews_guide
    FOREIGN KEY (guide_id)
    REFERENCES guides(guide_id)
    ON DELETE SET NULL,
  CONSTRAINT chk_review_target
    CHECK (
      (review_type = 'HOTEL' AND hotel_id IS NOT NULL AND attraction_id IS NULL AND guide_id IS NULL)
      OR (review_type = 'ATTRACTION' AND hotel_id IS NULL AND attraction_id IS NOT NULL AND guide_id IS NULL)
      OR (review_type = 'GUIDE' AND hotel_id IS NULL AND attraction_id IS NULL AND guide_id IS NOT NULL)
    )
);

PROMPT Creating sequences and triggers...
CREATE SEQUENCE seq_continents START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_countries START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_cities START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_clients START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_client_preferences START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_travellers START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_guides START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_guide_languages START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_hotels START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_amenities START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_room_types START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_room_inventory START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_attractions START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_transport_options START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_discounts START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_insurances START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_bookings START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_travellers START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_rooms START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_transports START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_insurances START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_costs START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_customer_snapshots START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking_status_history START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_itineraries START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_itinerary_days START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_itinerary_activities START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_reviews START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_continents_bi
BEFORE INSERT ON continents
FOR EACH ROW
BEGIN
  IF :NEW.continent_id IS NULL THEN
    SELECT seq_continents.NEXTVAL INTO :NEW.continent_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_countries_bi
BEFORE INSERT ON countries
FOR EACH ROW
BEGIN
  IF :NEW.country_id IS NULL THEN
    SELECT seq_countries.NEXTVAL INTO :NEW.country_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_cities_bi
BEFORE INSERT ON cities
FOR EACH ROW
BEGIN
  IF :NEW.city_id IS NULL THEN
    SELECT seq_cities.NEXTVAL INTO :NEW.city_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_clients_bi
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
  IF :NEW.client_id IS NULL THEN
    SELECT seq_clients.NEXTVAL INTO :NEW.client_id FROM dual;
  END IF;
  IF :NEW.created_at IS NULL THEN
    :NEW.created_at := SYSDATE;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_client_preferences_bi
BEFORE INSERT ON client_preferences
FOR EACH ROW
BEGIN
  IF :NEW.preference_id IS NULL THEN
    SELECT seq_client_preferences.NEXTVAL INTO :NEW.preference_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_travellers_bi
BEFORE INSERT ON travellers
FOR EACH ROW
BEGIN
  IF :NEW.traveller_id IS NULL THEN
    SELECT seq_travellers.NEXTVAL INTO :NEW.traveller_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_guides_bi
BEFORE INSERT ON guides
FOR EACH ROW
BEGIN
  IF :NEW.guide_id IS NULL THEN
    SELECT seq_guides.NEXTVAL INTO :NEW.guide_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_guide_languages_bi
BEFORE INSERT ON guide_languages
FOR EACH ROW
BEGIN
  IF :NEW.guide_language_id IS NULL THEN
    SELECT seq_guide_languages.NEXTVAL INTO :NEW.guide_language_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_hotels_bi
BEFORE INSERT ON hotels
FOR EACH ROW
BEGIN
  IF :NEW.hotel_id IS NULL THEN
    SELECT seq_hotels.NEXTVAL INTO :NEW.hotel_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_amenities_bi
BEFORE INSERT ON amenities
FOR EACH ROW
BEGIN
  IF :NEW.amenity_id IS NULL THEN
    SELECT seq_amenities.NEXTVAL INTO :NEW.amenity_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_room_types_bi
BEFORE INSERT ON hotel_room_types
FOR EACH ROW
BEGIN
  IF :NEW.room_type_id IS NULL THEN
    SELECT seq_room_types.NEXTVAL INTO :NEW.room_type_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_room_inventory_bi
BEFORE INSERT ON hotel_room_inventory
FOR EACH ROW
BEGIN
  IF :NEW.inventory_id IS NULL THEN
    SELECT seq_room_inventory.NEXTVAL INTO :NEW.inventory_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_attractions_bi
BEFORE INSERT ON attractions
FOR EACH ROW
BEGIN
  IF :NEW.attraction_id IS NULL THEN
    SELECT seq_attractions.NEXTVAL INTO :NEW.attraction_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_transport_options_bi
BEFORE INSERT ON transport_options
FOR EACH ROW
BEGIN
  IF :NEW.transport_option_id IS NULL THEN
    SELECT seq_transport_options.NEXTVAL INTO :NEW.transport_option_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_discounts_bi
BEFORE INSERT ON discounts
FOR EACH ROW
BEGIN
  IF :NEW.discount_id IS NULL THEN
    SELECT seq_discounts.NEXTVAL INTO :NEW.discount_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_insurances_bi
BEFORE INSERT ON insurances
FOR EACH ROW
BEGIN
  IF :NEW.insurance_id IS NULL THEN
    SELECT seq_insurances.NEXTVAL INTO :NEW.insurance_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_bookings_bi
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
  IF :NEW.booking_id IS NULL THEN
    SELECT seq_bookings.NEXTVAL INTO :NEW.booking_id FROM dual;
  END IF;
  IF :NEW.created_at IS NULL THEN
    :NEW.created_at := SYSDATE;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_bookings_status_audit
AFTER INSERT OR UPDATE OF status ON bookings
FOR EACH ROW
BEGIN
  INSERT INTO booking_status_history (booking_id,
                                      old_status,
                                      new_status,
                                      changed_by,
                                      reason)
  VALUES (:NEW.booking_id,
          CASE WHEN INSERTING THEN NULL ELSE :OLD.status END,
          :NEW.status,
          USER,
          CASE WHEN INSERTING THEN 'Initial booking status' ELSE 'Status updated via workflow' END);
END;
/

CREATE OR REPLACE TRIGGER trg_booking_travellers_bi
BEFORE INSERT ON booking_travellers
FOR EACH ROW
BEGIN
  IF :NEW.booking_traveller_id IS NULL THEN
    SELECT seq_booking_travellers.NEXTVAL INTO :NEW.booking_traveller_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE PROCEDURE update_booking_party_counts(p_booking_id IN NUMBER) IS
  v_total_adults   NUMBER := 0;
  v_total_children NUMBER := 0;
BEGIN
  SELECT NVL(SUM(CASE WHEN t.traveller_type IN ('ADULT','SENIOR','PRIMARY') THEN 1 ELSE 0 END), 0),
         NVL(SUM(CASE WHEN t.traveller_type IN ('CHILD','INFANT') THEN 1 ELSE 0 END), 0)
    INTO v_total_adults, v_total_children
    FROM booking_travellers bt
    JOIN travellers t ON t.traveller_id = bt.traveller_id
   WHERE bt.booking_id = p_booking_id;

  UPDATE bookings
     SET total_adults   = v_total_adults,
         total_children = v_total_children,
         updated_at     = SYSDATE
   WHERE booking_id = p_booking_id;
END;
/

CREATE OR REPLACE PROCEDURE refresh_booking_customer_snapshot(p_booking_id IN NUMBER) IS
BEGIN
  MERGE INTO booking_customer_snapshots bcs
  USING (
          SELECT b.booking_id,
                 c.client_id,
                 c.first_name,
                 c.last_name,
                 c.email,
                 c.phone,
                 c.username,
                 c.account_status,
                 c.last_login,
                 c.preferred_language,
                 c.preferred_contact_method,
                 c.marketing_opt_in,
                 cp.travelling_with_children,
                 cp.travelling_with_pets,
                 cp.accessibility_needs,
                 cp.dietary_preferences,
                 cp.preferred_room_type,
                 cp.preferred_food_type,
                 cp.preferred_transport,
                 cp.preferred_city_id,
                 ci.name AS preferred_city_name
            FROM bookings b
            JOIN clients c ON c.client_id = b.client_id
            LEFT JOIN client_preferences cp ON cp.client_id = c.client_id
            LEFT JOIN cities ci ON ci.city_id = cp.preferred_city_id
           WHERE b.booking_id = p_booking_id
       ) src
     ON (bcs.booking_id = src.booking_id)
  WHEN MATCHED THEN
    UPDATE SET bcs.client_id                = src.client_id,
               bcs.client_first_name        = src.first_name,
               bcs.client_last_name         = src.last_name,
               bcs.client_email             = src.email,
               bcs.client_phone             = src.phone,
               bcs.account_username         = src.username,
               bcs.account_status           = src.account_status,
               bcs.last_login               = src.last_login,
               bcs.preferred_language       = src.preferred_language,
               bcs.preferred_contact_method = src.preferred_contact_method,
               bcs.marketing_opt_in         = src.marketing_opt_in,
               bcs.travelling_with_children = src.travelling_with_children,
               bcs.travelling_with_pets     = src.travelling_with_pets,
               bcs.accessibility_needs      = src.accessibility_needs,
               bcs.dietary_preferences      = src.dietary_preferences,
               bcs.preferred_room_type      = src.preferred_room_type,
               bcs.preferred_food_type      = src.preferred_food_type,
               bcs.preferred_transport      = src.preferred_transport,
               bcs.preferred_city_id        = src.preferred_city_id,
               bcs.preferred_city_name      = src.preferred_city_name,
               bcs.updated_at               = SYSDATE
  WHEN NOT MATCHED THEN
    INSERT (booking_id,
            client_id,
            client_first_name,
            client_last_name,
            client_email,
            client_phone,
            account_username,
            account_status,
            last_login,
            preferred_language,
            preferred_contact_method,
            marketing_opt_in,
            travelling_with_children,
            travelling_with_pets,
            accessibility_needs,
            dietary_preferences,
            preferred_room_type,
            preferred_food_type,
            preferred_transport,
            preferred_city_id,
            preferred_city_name,
            created_at,
            updated_at)
    VALUES (src.booking_id,
            src.client_id,
            src.first_name,
            src.last_name,
            src.email,
            src.phone,
            src.username,
            src.account_status,
            src.last_login,
            src.preferred_language,
            src.preferred_contact_method,
            src.marketing_opt_in,
            src.travelling_with_children,
            src.travelling_with_pets,
            src.accessibility_needs,
            src.dietary_preferences,
            src.preferred_room_type,
            src.preferred_food_type,
            src.preferred_transport,
            src.preferred_city_id,
            src.preferred_city_name,
            SYSDATE,
            SYSDATE);

  IF SQL%ROWCOUNT = 0 THEN
    DELETE FROM booking_customer_snapshots WHERE booking_id = p_booking_id;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_travellers_sync
FOR INSERT OR UPDATE OR DELETE ON booking_travellers
COMPOUND TRIGGER
  TYPE t_booking_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_booking_ids t_booking_ids;

  PROCEDURE add_booking_id(p_booking_id NUMBER) IS
  BEGIN
    IF p_booking_id IS NOT NULL THEN
      g_booking_ids(p_booking_id) := p_booking_id;
    END IF;
  END;

AFTER EACH ROW IS
BEGIN
  IF INSERTING OR UPDATING THEN
    add_booking_id(:NEW.booking_id);
  END IF;
  IF DELETING THEN
    add_booking_id(:OLD.booking_id);
  END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
  v_idx PLS_INTEGER;
BEGIN
  v_idx := g_booking_ids.FIRST;
  WHILE v_idx IS NOT NULL LOOP
    update_booking_party_counts(g_booking_ids(v_idx));
    v_idx := g_booking_ids.NEXT(v_idx);
  END LOOP;
  g_booking_ids.DELETE;
END AFTER STATEMENT;
END trg_booking_travellers_sync;
/

CREATE OR REPLACE TRIGGER trg_booking_rooms_bi
BEFORE INSERT ON booking_rooms
FOR EACH ROW
BEGIN
  IF :NEW.booking_room_id IS NULL THEN
    SELECT seq_booking_rooms.NEXTVAL INTO :NEW.booking_room_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_transports_bi
BEFORE INSERT ON booking_transports
FOR EACH ROW
BEGIN
  IF :NEW.booking_transport_id IS NULL THEN
    SELECT seq_booking_transports.NEXTVAL INTO :NEW.booking_transport_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_insurances_bi
BEFORE INSERT ON booking_insurances
FOR EACH ROW
BEGIN
  IF :NEW.booking_insurance_id IS NULL THEN
    SELECT seq_booking_insurances.NEXTVAL INTO :NEW.booking_insurance_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_costs_bi
BEFORE INSERT ON booking_costs
FOR EACH ROW
BEGIN
  IF :NEW.booking_cost_id IS NULL THEN
    SELECT seq_booking_costs.NEXTVAL INTO :NEW.booking_cost_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_customer_snapshots_bi
BEFORE INSERT ON booking_customer_snapshots
FOR EACH ROW
BEGIN
  IF :NEW.snapshot_id IS NULL THEN
    SELECT seq_booking_customer_snapshots.NEXTVAL INTO :NEW.snapshot_id FROM dual;
  END IF;
  IF :NEW.created_at IS NULL THEN
    :NEW.created_at := SYSDATE;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_bookings_customer_snapshot_aiu
AFTER INSERT OR UPDATE OF client_id ON bookings
FOR EACH ROW
BEGIN
  refresh_booking_customer_snapshot(:NEW.booking_id);
END;
/

CREATE OR REPLACE TRIGGER trg_clients_customer_snapshot_au
AFTER UPDATE OF first_name, last_name, email, phone, username, account_status, last_login,
                 preferred_language, preferred_contact_method, marketing_opt_in
ON clients
FOR EACH ROW
BEGIN
  FOR rec IN (SELECT booking_id FROM bookings WHERE client_id = :NEW.client_id) LOOP
    refresh_booking_customer_snapshot(rec.booking_id);
  END LOOP;
END;
/

CREATE OR REPLACE TRIGGER trg_client_preferences_snapshot_aud
AFTER INSERT OR UPDATE OR DELETE ON client_preferences
FOR EACH ROW
DECLARE
  v_client_id NUMBER;
BEGIN
  IF INSERTING OR UPDATING THEN
    v_client_id := :NEW.client_id;
  ELSE
    v_client_id := :OLD.client_id;
  END IF;

  FOR rec IN (SELECT booking_id FROM bookings WHERE client_id = v_client_id) LOOP
    refresh_booking_customer_snapshot(rec.booking_id);
  END LOOP;
END;
/

CREATE OR REPLACE TRIGGER trg_booking_status_history_bi
BEFORE INSERT ON booking_status_history
FOR EACH ROW
BEGIN
  IF :NEW.history_id IS NULL THEN
    SELECT seq_booking_status_history.NEXTVAL INTO :NEW.history_id FROM dual;
  END IF;
  IF :NEW.changed_at IS NULL THEN
    :NEW.changed_at := SYSDATE;
  END IF;
  IF :NEW.changed_by IS NULL THEN
    :NEW.changed_by := USER;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_itineraries_bi
BEFORE INSERT ON itineraries
FOR EACH ROW
BEGIN
  IF :NEW.itinerary_id IS NULL THEN
    SELECT seq_itineraries.NEXTVAL INTO :NEW.itinerary_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_itinerary_days_bi
BEFORE INSERT ON itinerary_days
FOR EACH ROW
BEGIN
  IF :NEW.itinerary_day_id IS NULL THEN
    SELECT seq_itinerary_days.NEXTVAL INTO :NEW.itinerary_day_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_itinerary_activities_bi
BEFORE INSERT ON itinerary_activities
FOR EACH ROW
BEGIN
  IF :NEW.itinerary_activity_id IS NULL THEN
    SELECT seq_itinerary_activities.NEXTVAL INTO :NEW.itinerary_activity_id FROM dual;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_reviews_bi
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
  IF :NEW.review_id IS NULL THEN
    SELECT seq_reviews.NEXTVAL INTO :NEW.review_id FROM dual;
  END IF;
END;
/

PROMPT Adding comments...
COMMENT ON TABLE continents IS 'Reference table of world continents.';
COMMENT ON COLUMN continents.continent_code IS 'Short code for the continent (e.g. EU, NA).';
COMMENT ON COLUMN continents.name IS 'Display name of the continent.';

COMMENT ON TABLE countries IS 'Countries served by the travel agency.';
COMMENT ON COLUMN countries.currency_code IS 'ISO 4217 currency used for pricing in the country.';

COMMENT ON TABLE cities IS 'Cities that host hotels, attractions, or transport services.';
COMMENT ON COLUMN cities.timezone IS 'IANA timezone identifier for scheduling.';

COMMENT ON TABLE clients IS 'Primary customer accounts with login credentials and contact details for bookings.';
COMMENT ON COLUMN clients.username IS 'Unique login identifier stored directly with the client record.';
COMMENT ON COLUMN clients.password_hash IS 'Password credential stored as either plain fallback or SHA256:<HEX> hash for APEX authentication.';
COMMENT ON COLUMN clients.account_status IS 'Controls whether the client account can sign in (ACTIVE, LOCKED, DISABLED).';
COMMENT ON COLUMN clients.last_login IS 'Timestamp of the most recent successful sign in for the client.';
COMMENT ON COLUMN clients.calculated_total IS 'Latest calculated total cost for the client''s booking when applicable.';

COMMENT ON TABLE client_preferences IS 'Travel and lifestyle preferences for APEX personalization.';
COMMENT ON COLUMN client_preferences.preferred_city_id IS 'Preferred destination city to seed hotel recommendations.';

COMMENT ON TABLE travellers IS 'All travellers linked to a client, including children and companions.';

COMMENT ON TABLE guides IS 'Local guides and experts available for attractions.';

COMMENT ON TABLE guide_languages IS 'Languages spoken by each guide with native fluency flags.';

COMMENT ON TABLE hotels IS 'Hotels and resorts offered by the agency.';
COMMENT ON COLUMN hotels.family_friendly IS 'Indicates whether the hotel is suitable for family stays.';

COMMENT ON TABLE amenities IS 'Catalog of amenities that can be attached to room types.';

COMMENT ON TABLE hotel_room_types IS 'Detailed room type definitions including capacity and pricing.';
COMMENT ON COLUMN hotel_room_types.family_friendly IS 'Room types recommended for families or multi-person groups.';

COMMENT ON TABLE hotel_room_type_amenities IS 'Bridge table linking room types with amenities.';

COMMENT ON TABLE hotel_room_inventory IS 'Daily availability and dynamic pricing for each room type.';

COMMENT ON TABLE attractions IS 'Attractions, tours, and day activities.';
COMMENT ON COLUMN attractions.family_friendly IS 'Flag indicating if an attraction is suitable for families.';

COMMENT ON TABLE transport_options IS 'Transport options including flights, transfers, and car rentals.';

COMMENT ON TABLE discounts IS 'Discount programs such as early-bird or promo codes.';

COMMENT ON TABLE insurances IS 'Insurance products that can be attached to a booking.';

COMMENT ON TABLE bookings IS 'Master booking records for trips, families, and groups.';
COMMENT ON COLUMN bookings.budget_amount IS 'Optional budget ceiling captured during booking creation.';

COMMENT ON TABLE booking_travellers IS 'Link between bookings and travellers showing the group composition.';

COMMENT ON TABLE booking_rooms IS 'Reserved hotel rooms for each booking.';

COMMENT ON TABLE booking_transports IS 'Transport components linked to a booking.';

COMMENT ON TABLE booking_insurances IS 'Insurance policies attached to bookings.';

COMMENT ON TABLE booking_costs IS 'Additional pricing components, surcharges, and discounts.';

COMMENT ON TABLE booking_customer_snapshots IS 'Flattened customer account and preference details captured per booking.';
COMMENT ON COLUMN booking_customer_snapshots.account_username IS 'Client login name associated with the booking at the time of capture.';
COMMENT ON COLUMN booking_customer_snapshots.preferred_city_name IS 'Human-readable name for the preferred destination city at booking time.';

COMMENT ON TABLE booking_status_history IS 'Audit history of booking status transitions for workflow tracking.';
COMMENT ON TABLE apex_client_accounts_v IS 'Flattened client account metadata for APEX authentication and personalization.';
COMMENT ON TABLE booking_party_summary_v IS 'Helper view comparing stored party counts with calculated traveller totals.';

COMMENT ON TABLE itineraries IS 'High-level itineraries generated per booking.';

COMMENT ON TABLE itinerary_days IS 'Day-by-day plan for each itinerary.';

COMMENT ON TABLE itinerary_activities IS 'Planned activities, rest periods, and transport segments per day.';

COMMENT ON TABLE reviews IS 'Client reviews of hotels, attractions, and guides.';


PROMPT Inserting sample reference data...
INSERT INTO continents (continent_code, name, description) VALUES ('EU', 'Europe', 'European destinations and experiences.');
INSERT INTO continents (continent_code, name, description) VALUES ('NA', 'North America', 'Destinations in the United States and Canada.');
INSERT INTO continents (continent_code, name, description) VALUES ('AS', 'Asia', 'Popular Asian destinations.');

INSERT INTO countries (continent_id, iso_code, name, currency_code)
VALUES ((SELECT continent_id FROM continents WHERE continent_code = 'EU'), 'ES', 'Spain', 'EUR');
INSERT INTO countries (continent_id, iso_code, name, currency_code)
VALUES ((SELECT continent_id FROM continents WHERE continent_code = 'EU'), 'IT', 'Italy', 'EUR');
INSERT INTO countries (continent_id, iso_code, name, currency_code)
VALUES ((SELECT continent_id FROM continents WHERE continent_code = 'NA'), 'US', 'United States', 'USD');

INSERT INTO cities (country_id, name, state_province, timezone, latitude, longitude)
VALUES ((SELECT country_id FROM countries WHERE iso_code = 'ES'), 'Barcelona', 'Catalonia', 'Europe/Madrid', 41.385064, 2.173404);
INSERT INTO cities (country_id, name, state_province, timezone, latitude, longitude)
VALUES ((SELECT country_id FROM countries WHERE iso_code = 'IT'), 'Rome', 'Lazio', 'Europe/Rome', 41.902782, 12.496366);
INSERT INTO cities (country_id, name, state_province, timezone, latitude, longitude)
VALUES ((SELECT country_id FROM countries WHERE iso_code = 'IT'), 'Florence', 'Tuscany', 'Europe/Rome', 43.769562, 11.255814);
INSERT INTO cities (country_id, name, state_province, timezone, latitude, longitude)
VALUES ((SELECT country_id FROM countries WHERE iso_code = 'US'), 'New York', 'New York', 'America/New_York', 40.712776, -74.005974);

PROMPT Inserting sample clients and travellers...
INSERT INTO clients (first_name, last_name, email, phone, username, password_hash, account_status, last_login,
                     preferred_language, preferred_contact_method, marketing_opt_in)
VALUES ('John', 'Walker', 'john.walker@example.com', '+1-202-555-0182', 'john.walker', 'SHA256:DF4CB36319F7A32464C0198F086C99C7FC2704AE929E6DF15C4830406D52E51D', 'ACTIVE', SYSDATE - 2,
        'EN', 'EMAIL', 'Y');
INSERT INTO clients (first_name, last_name, email, phone, username, password_hash, account_status, last_login,
                     preferred_language, preferred_contact_method, marketing_opt_in)
VALUES ('Sofia', 'Ramirez', 'sofia.ramirez@example.es', '+34-612-555-121', 'sofia.r', 'SHA256:E8FABD2A9A0482A07C994D460A3C3A0D38906D2CAE3B0EE19987DCB8DD1C58AF', 'ACTIVE', SYSDATE - 5,
        'ES', 'WHATSAPP', 'Y');
INSERT INTO clients (first_name, last_name, email, phone, username, password_hash, account_status, last_login,
                     preferred_language, preferred_contact_method, marketing_opt_in)
VALUES ('Chen', 'Li', 'chen.li@example.com', '+86-138-555-3434', 'chen.li', 'SHA256:0745D3FB2E86988A036947C663304CCCDBE80094CE26308994CA65D6F6DE9748', 'LOCKED', NULL,
        'ZH', 'SMS', 'N');

INSERT INTO client_preferences (client_id, travelling_with_children, travelling_with_pets, accessibility_needs, dietary_preferences, preferred_room_type, preferred_food_type, preferred_transport, preferred_city_id, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'Y', 'N', 'Stroller friendly routes', 'Vegetarian-friendly options', 'Family Apartment', 'Mediterranean', 'Direct Flight', (SELECT city_id FROM cities WHERE name = 'Barcelona'), 'Enjoys cultural tours with free afternoons.');
INSERT INTO client_preferences (client_id, travelling_with_children, travelling_with_pets, accessibility_needs, dietary_preferences, preferred_room_type, preferred_food_type, preferred_transport, preferred_city_id, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'sofia.ramirez@example.es'), 'N', 'Y', 'Pet-friendly hotels', 'Tapas and seafood', 'Suite', 'Spanish', 'High-speed Train', (SELECT city_id FROM cities WHERE name = 'Rome'), 'Travels with a small dog.');
INSERT INTO client_preferences (client_id, travelling_with_children, travelling_with_pets, accessibility_needs, dietary_preferences, preferred_room_type, preferred_food_type, preferred_transport, preferred_city_id, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'chen.li@example.com'), 'N', 'N', 'Requires Mandarin speaking guide', 'No spicy food', 'Executive Suite', 'Asian Fusion', 'Business Class Flight', (SELECT city_id FROM cities WHERE name = 'New York'), 'Prefers technology-focused attractions.');

INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'John', 'Walker', TO_DATE('1985-04-12','YYYY-MM-DD'), 'ADULT', 'M', 'Self', NULL, 'EN');
INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'Emily', 'Walker', TO_DATE('1986-07-08','YYYY-MM-DD'), 'ADULT', 'F', 'Spouse', NULL, 'EN');
INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'Liam', 'Walker', TO_DATE('2014-09-21','YYYY-MM-DD'), 'CHILD', 'M', 'Son', 'Nut allergy', 'EN');
INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'Ava', 'Walker', TO_DATE('2017-02-14','YYYY-MM-DD'), 'CHILD', 'F', 'Daughter', NULL, 'EN');

INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'sofia.ramirez@example.es'), 'Sofia', 'Ramirez', TO_DATE('1990-11-18','YYYY-MM-DD'), 'ADULT', 'F', 'Self', 'Travels with pet', 'ES');
INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'sofia.ramirez@example.es'), 'Diego', 'Ramirez', TO_DATE('1988-05-03','YYYY-MM-DD'), 'ADULT', 'M', 'Partner', NULL, 'ES');

INSERT INTO travellers (client_id, first_name, last_name, date_of_birth, traveller_type, gender, relationship_to_client, special_needs, preferred_language)
VALUES ((SELECT client_id FROM clients WHERE email = 'chen.li@example.com'), 'Chen', 'Li', TO_DATE('1978-03-25','YYYY-MM-DD'), 'ADULT', 'M', 'Self', NULL, 'ZH');

PROMPT Inserting sample guides and languages...
INSERT INTO guides (first_name, last_name, email, phone, bio, rating, years_experience, speciality, daily_rate)
VALUES ('Laura', 'Rossi', 'laura.rossi@travelpro.it', '+39-06-555-0172', 'Licensed guide focusing on family-friendly experiences in Rome.', 4.9, 12, 'History & Food', 180);
INSERT INTO guides (first_name, last_name, email, phone, bio, rating, years_experience, speciality, daily_rate)
VALUES ('Miguel', 'Torres', 'miguel.torres@barcelonatours.es', '+34-93-555-4422', 'Expert in Barcelona modernism and kids activities.', 4.8, 9, 'Architecture & Family Tours', 160);
INSERT INTO guides (first_name, last_name, email, phone, bio, rating, years_experience, speciality, daily_rate)
VALUES ('Harper', 'Johnson', 'harper.johnson@cityexplore.us', '+1-646-555-8721', 'NYC local guide specializing in bilingual tours.', 4.7, 7, 'Culture & Food', 150);

INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'laura.rossi@travelpro.it'), 'IT', 'Y');
INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'laura.rossi@travelpro.it'), 'EN', 'N');
INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'miguel.torres@barcelonatours.es'), 'ES', 'Y');
INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'miguel.torres@barcelonatours.es'), 'EN', 'N');
INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'harper.johnson@cityexplore.us'), 'EN', 'Y');
INSERT INTO guide_languages (guide_id, language_code, is_native)
VALUES ((SELECT guide_id FROM guides WHERE email = 'harper.johnson@cityexplore.us'), 'ES', 'N');

PROMPT Inserting sample hotels, room types, and amenities...
INSERT INTO hotels (city_id, name, description, address, latitude, longitude, star_rating, contact_email, contact_phone, website, check_in_time, check_out_time, family_friendly)
VALUES ((SELECT city_id FROM cities WHERE name = 'Barcelona'), 'Sunset Family Resort', 'Beachfront resort with family-focused programming and spacious apartments.', 'Av. del Litoral 12, Barcelona', 41.389, 2.197, 4.5, 'hello@sunsetfamilyresort.es', '+34-93-555-0101', 'https://sunsetfamilyresort.es', '15:00', '11:00', 'Y');
INSERT INTO hotels (city_id, name, description, address, latitude, longitude, star_rating, contact_email, contact_phone, website, check_in_time, check_out_time, family_friendly)
VALUES ((SELECT city_id FROM cities WHERE name = 'Rome'), 'Roman Holiday Suites', 'Boutique suites near the Colosseum with private family guides.', 'Via dei Fori Imperiali 45, Rome', 41.892, 12.486, 4.7, 'stay@romanholidaysuites.it', '+39-06-555-1010', 'https://romanholidaysuites.it', '14:00', '10:00', 'Y');
INSERT INTO hotels (city_id, name, description, address, latitude, longitude, star_rating, contact_email, contact_phone, website, check_in_time, check_out_time, family_friendly)
VALUES ((SELECT city_id FROM cities WHERE name = 'New York'), 'Hudson Central Hotel', 'Modern suites in Midtown with family loft options and kids concierge.', '455 7th Ave, New York', 40.752, -73.989, 4.3, 'info@hudsoncentralhotel.com', '+1-212-555-0100', 'https://hudsoncentralhotel.com', '16:00', '12:00', 'Y');

INSERT INTO amenities (name, description) VALUES ('Kids Club', 'Supervised activities and play areas for children.');
INSERT INTO amenities (name, description) VALUES ('Rooftop Pool', 'Outdoor heated pool with city views.');
INSERT INTO amenities (name, description) VALUES ('Kitchenette', 'In-room kitchenette with microwave and fridge.');
INSERT INTO amenities (name, description) VALUES ('Accessible Bathroom', 'Roll-in shower and grab bars.');
INSERT INTO amenities (name, description) VALUES ('Pet Friendly', 'Accommodates pets with special amenities.');

INSERT INTO hotel_room_types (hotel_id, name, description, max_adults, max_children, max_occupancy, bed_configuration, base_rate, currency_code, family_friendly, accessible)
VALUES ((SELECT hotel_id FROM hotels WHERE name = 'Sunset Family Resort'), 'Family Apartment', 'Two-bedroom apartment with sea view and full kitchen.', 2, 3, 5, '1 king + 2 twins + sofa bed', 280, 'EUR', 'Y', 'Y');
INSERT INTO hotel_room_types (hotel_id, name, description, max_adults, max_children, max_occupancy, bed_configuration, base_rate, currency_code, family_friendly, accessible)
VALUES ((SELECT hotel_id FROM hotels WHERE name = 'Sunset Family Resort'), 'Junior Suite', 'Spacious junior suite with balcony and partial sea view.', 2, 1, 3, '1 king + sofa bed', 210, 'EUR', 'Y', 'N');
INSERT INTO hotel_room_types (hotel_id, name, description, max_adults, max_children, max_occupancy, bed_configuration, base_rate, currency_code, family_friendly, accessible)
VALUES ((SELECT hotel_id FROM hotels WHERE name = 'Roman Holiday Suites'), 'Two-Bedroom Suite', 'Suite with private courtyard and dedicated concierge.', 2, 2, 4, '1 queen + 2 twins', 320, 'EUR', 'Y', 'Y');
INSERT INTO hotel_room_types (hotel_id, name, description, max_adults, max_children, max_occupancy, bed_configuration, base_rate, currency_code, family_friendly, accessible)
VALUES ((SELECT hotel_id FROM hotels WHERE name = 'Hudson Central Hotel'), 'Family Loft', 'Loft-style suite with bunk beds and skyline views.', 2, 3, 5, '1 king + bunk beds', 350, 'USD', 'Y', 'N');

INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'), (SELECT amenity_id FROM amenities WHERE name = 'Kids Club'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'), (SELECT amenity_id FROM amenities WHERE name = 'Kitchenette'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'), (SELECT amenity_id FROM amenities WHERE name = 'Rooftop Pool'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Two-Bedroom Suite'), (SELECT amenity_id FROM amenities WHERE name = 'Accessible Bathroom'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Two-Bedroom Suite'), (SELECT amenity_id FROM amenities WHERE name = 'Kids Club'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Loft'), (SELECT amenity_id FROM amenities WHERE name = 'Pet Friendly'));
INSERT INTO hotel_room_type_amenities (room_type_id, amenity_id)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Loft'), (SELECT amenity_id FROM amenities WHERE name = 'Rooftop Pool'));

PROMPT Inserting hotel availability...
INSERT INTO hotel_room_inventory (room_type_id, inventory_date, rooms_total, rooms_booked, rate, currency_code)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'), TO_DATE('2024-07-01','YYYY-MM-DD'), 10, 4, 295, 'EUR');
INSERT INTO hotel_room_inventory (room_type_id, inventory_date, rooms_total, rooms_booked, rate, currency_code)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'), TO_DATE('2024-07-02','YYYY-MM-DD'), 10, 6, 300, 'EUR');
INSERT INTO hotel_room_inventory (room_type_id, inventory_date, rooms_total, rooms_booked, rate, currency_code)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Junior Suite'), TO_DATE('2024-07-01','YYYY-MM-DD'), 8, 5, 215, 'EUR');
INSERT INTO hotel_room_inventory (room_type_id, inventory_date, rooms_total, rooms_booked, rate, currency_code)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Two-Bedroom Suite'), TO_DATE('2024-08-15','YYYY-MM-DD'), 5, 1, 335, 'EUR');
INSERT INTO hotel_room_inventory (room_type_id, inventory_date, rooms_total, rooms_booked, rate, currency_code)
VALUES ((SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Loft'), TO_DATE('2024-09-05','YYYY-MM-DD'), 6, 2, 360, 'USD');

PROMPT Inserting attractions and transport options...
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'Barcelona'), 'Sagrada Familia Private Tour', 'Cultural', 'Private guided visit with kid-friendly storytelling.', 150, 75, 'EUR', 'Y', '6+');
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'Barcelona'), 'Park Güell Family Adventure', 'Outdoor', 'Interactive treasure hunt inside Park Güell.', 180, 55, 'EUR', 'Y', '5+');
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'Barcelona'), 'Magic Fountain Evening Show', 'Leisure', 'Reserved seating for the iconic fountain light show.', 90, 25, 'EUR', 'Y', 'All');
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'Rome'), 'Colosseum Explorer', 'Cultural', 'Skip-the-line tour with VR experience for kids.', 120, 68, 'EUR', 'Y', '7+');
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'Rome'), 'Vatican Art & Chill Day', 'Cultural', 'Half-day Vatican visit with optional afternoon rest at spa.', 240, 95, 'EUR', 'N', '12+');
INSERT INTO attractions (city_id, name, attraction_type, description, duration_minutes, base_price, currency_code, family_friendly, recommended_age)
VALUES ((SELECT city_id FROM cities WHERE name = 'New York'), 'Central Park Bike Discovery', 'Outdoor', 'Guided cycling tour through Central Park with picnic stop.', 180, 65, 'USD', 'Y', '8+');

INSERT INTO transport_options (transport_type, provider_name, from_city_id, to_city_id, departure_time, arrival_time, duration_minutes, capacity, base_price, currency_code, family_friendly)
VALUES ('FLIGHT', 'SkyJet Airlines', (SELECT city_id FROM cities WHERE name = 'New York'), (SELECT city_id FROM cities WHERE name = 'Barcelona'),
        TO_DATE('2024-06-30 18:45','YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-01 08:05','YYYY-MM-DD HH24:MI'), 500, 220, 780, 'USD', 'Y');
INSERT INTO transport_options (transport_type, provider_name, from_city_id, to_city_id, departure_time, arrival_time, duration_minutes, capacity, base_price, currency_code, family_friendly)
VALUES ('TRANSFER', 'Barcelona Family Shuttles', (SELECT city_id FROM cities WHERE name = 'Barcelona'), (SELECT city_id FROM cities WHERE name = 'Barcelona'),
        TO_DATE('2024-07-01 09:30','YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-01 10:00','YYYY-MM-DD HH24:MI'), 30, 12, 75, 'EUR', 'Y');
INSERT INTO transport_options (transport_type, provider_name, from_city_id, to_city_id, departure_time, arrival_time, duration_minutes, capacity, base_price, currency_code, family_friendly)
VALUES ('TRAIN', 'Italo', (SELECT city_id FROM cities WHERE name = 'Rome'), (SELECT city_id FROM cities WHERE name = 'Florence'),
        NULL, NULL, 95, 400, 45, 'EUR', 'Y');
INSERT INTO transport_options (transport_type, provider_name, from_city_id, to_city_id, departure_time, arrival_time, duration_minutes, capacity, base_price, currency_code, family_friendly)
VALUES ('CAR_RENTAL', 'Hudson Rentals', (SELECT city_id FROM cities WHERE name = 'New York'), (SELECT city_id FROM cities WHERE name = 'New York'),
        TO_DATE('2024-09-05 09:00','YYYY-MM-DD HH24:MI'), TO_DATE('2024-09-10 18:00','YYYY-MM-DD HH24:MI'), 7200, 50, 420, 'USD', 'Y');

PROMPT Inserting discounts and insurances...
INSERT INTO discounts (name, description, discount_type, value, min_people, min_nights, valid_from, valid_to, promo_code, family_only)
VALUES ('Family 10% Off', 'Automatic family discount for bookings with at least two children.', 'PERCENTAGE', 10, 4, 4, TO_DATE('2024-01-01','YYYY-MM-DD'), TO_DATE('2024-12-31','YYYY-MM-DD'), 'FAMILY10', 'Y');
INSERT INTO discounts (name, description, discount_type, value, min_people, min_nights, valid_from, valid_to, promo_code, family_only)
VALUES ('Early Bird 50', 'Fixed discount for early bookings paid in advance.', 'FIXED', 50, 2, 3, TO_DATE('2024-01-01','YYYY-MM-DD'), TO_DATE('2024-06-30','YYYY-MM-DD'), 'EARLY50', 'N');

INSERT INTO insurances (name, description, coverage_level, price, currency_code)
VALUES ('Comprehensive Family Cover', 'Medical, baggage, and trip interruption cover for families.', 'Premium', 95, 'EUR');
INSERT INTO insurances (name, description, coverage_level, price, currency_code)
VALUES ('Adventure Add-on', 'Covers high-adrenaline activities and sports.', 'Gold', 45, 'EUR');

PROMPT Inserting sample bookings...
INSERT INTO bookings (client_id, booking_reference, status, start_date, end_date, total_adults, total_children, budget_amount, currency_code, discount_id, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'BK-2024-FAM1', 'CONFIRMED', TO_DATE('2024-07-01','YYYY-MM-DD'), TO_DATE('2024-07-07','YYYY-MM-DD'), 2, 2, 6000, 'EUR',
        (SELECT discount_id FROM discounts WHERE promo_code = 'FAMILY10'), 'Barcelona summer holiday for the Walker family.');
INSERT INTO bookings (client_id, booking_reference, status, start_date, end_date, total_adults, total_children, budget_amount, currency_code, discount_id, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'sofia.ramirez@example.es'), 'BK-2024-ROME', 'OPTION', TO_DATE('2024-08-15','YYYY-MM-DD'), TO_DATE('2024-08-20','YYYY-MM-DD'), 2, 0, 4500, 'EUR',
        (SELECT discount_id FROM discounts WHERE promo_code = 'EARLY50'), 'Romantic Roman getaway with pet-friendly focus.');
INSERT INTO bookings (client_id, booking_reference, status, start_date, end_date, total_adults, total_children, budget_amount, currency_code, notes)
VALUES ((SELECT client_id FROM clients WHERE email = 'chen.li@example.com'), 'BK-2024-NYC', 'NEW', TO_DATE('2024-09-05','YYYY-MM-DD'), TO_DATE('2024-09-10','YYYY-MM-DD'), 1, 0, 7000, 'USD',
        'Tech and culture immersion in New York City.');

PROMPT Linking travellers to bookings...
INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role, is_lead_contact)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'John' AND last_name = 'Walker' AND traveller_type = 'ADULT'), 'PRIMARY', 'Y');
INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Emily' AND last_name = 'Walker'), 'ADULT');
INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Liam' AND last_name = 'Walker'), 'CHILD');
INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Ava' AND last_name = 'Walker'), 'CHILD');

INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role, is_lead_contact)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Sofia' AND last_name = 'Ramirez'), 'PRIMARY', 'Y');
INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Diego' AND last_name = 'Ramirez'), 'ADULT');

INSERT INTO booking_travellers (booking_id, traveller_id, traveller_role, is_lead_contact)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-NYC'),
        (SELECT traveller_id FROM travellers WHERE first_name = 'Chen' AND last_name = 'Li'), 'PRIMARY', 'Y');

PROMPT Adding booked rooms, transports, insurances, and costs...
INSERT INTO booking_rooms (booking_id, room_type_id, check_in_date, check_out_date, number_of_rooms, nightly_rate, discount_amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Apartment'),
        TO_DATE('2024-07-01','YYYY-MM-DD'), TO_DATE('2024-07-07','YYYY-MM-DD'), 1, 295, 50, 'EUR');
INSERT INTO booking_rooms (booking_id, room_type_id, check_in_date, check_out_date, number_of_rooms, nightly_rate, discount_amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME'),
        (SELECT room_type_id FROM hotel_room_types WHERE name = 'Two-Bedroom Suite'),
        TO_DATE('2024-08-15','YYYY-MM-DD'), TO_DATE('2024-08-20','YYYY-MM-DD'), 1, 335, 50, 'EUR');
INSERT INTO booking_rooms (booking_id, room_type_id, check_in_date, check_out_date, number_of_rooms, nightly_rate, discount_amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-NYC'),
        (SELECT room_type_id FROM hotel_room_types WHERE name = 'Family Loft'),
        TO_DATE('2024-09-05','YYYY-MM-DD'), TO_DATE('2024-09-10','YYYY-MM-DD'), 1, 360, 0, 'USD');

INSERT INTO booking_transports (booking_id, transport_option_id, traveller_count, price, currency_code, seat_class, notes)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT transport_option_id FROM transport_options WHERE provider_name = 'SkyJet Airlines'),
        4, 3120, 'USD', 'Premium Economy', 'Overnight flight to Barcelona with family seating.');
INSERT INTO booking_transports (booking_id, transport_option_id, traveller_count, price, currency_code, seat_class, notes)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT transport_option_id FROM transport_options WHERE provider_name = 'Barcelona Family Shuttles'),
        4, 90, 'EUR', NULL, 'Private transfer to hotel with child seats.');
INSERT INTO booking_transports (booking_id, transport_option_id, traveller_count, price, currency_code, seat_class, notes)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-NYC'),
        (SELECT transport_option_id FROM transport_options WHERE provider_name = 'Hudson Rentals'),
        1, 420, 'USD', NULL, 'Compact SUV rental for city exploration.');

INSERT INTO booking_insurances (booking_id, insurance_id, coverage_amount, price, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT insurance_id FROM insurances WHERE name = 'Comprehensive Family Cover'), 5000, 95, 'EUR');

INSERT INTO booking_costs (booking_id, cost_type, reference_id, description, amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'), 'ATTRACTION',
        (SELECT attraction_id FROM attractions WHERE name = 'Sagrada Familia Private Tour'), 'Private tour tickets for four travellers.', 300, 'EUR');
INSERT INTO booking_costs (booking_id, cost_type, reference_id, description, amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'), 'ATTRACTION',
        (SELECT attraction_id FROM attractions WHERE name = 'Park Güell Family Adventure'), 'Interactive park experience.', 220, 'EUR');
INSERT INTO booking_costs (booking_id, cost_type, description, amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'), 'FEE', 'APEX service fee', 45, 'EUR');
INSERT INTO booking_costs (booking_id, cost_type, description, amount, currency_code)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'), 'DISCOUNT', 'Promo FAMILY10 automatic discount applied at checkout.', -150, 'EUR');

UPDATE bookings
   SET status = 'COMPLETED',
       updated_at = SYSDATE
 WHERE booking_reference = 'BK-2024-FAM1';

UPDATE bookings
   SET status = 'CONFIRMED',
       updated_at = SYSDATE
 WHERE booking_reference = 'BK-2024-NYC';

PROMPT Building itinerary for the Walker family...
INSERT INTO itineraries (booking_id, name, start_date, end_date, summary)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'), 'Walker Family Barcelona Plan', TO_DATE('2024-07-01','YYYY-MM-DD'), TO_DATE('2024-07-06','YYYY-MM-DD'), 'Balanced cultural visits and rest days.');

INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 1, TO_DATE('2024-07-01','YYYY-MM-DD'), 'Arrival & Exploration', 'N', 'Morning arrival, afternoon exploration.');
INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 2, TO_DATE('2024-07-02','YYYY-MM-DD'), 'Relax & Beach', 'Y', 'Rest day with beach time and pool access.');
INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 3, TO_DATE('2024-07-03','YYYY-MM-DD'), 'Gaudí Highlights', 'N', 'Park Güell adventure.');
INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 4, TO_DATE('2024-07-04','YYYY-MM-DD'), 'Free Day', 'N', 'Flexible day for optional shopping.');
INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 5, TO_DATE('2024-07-05','YYYY-MM-DD'), 'Magic Evening', 'N', 'Evening fountain show.');
INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
VALUES ((SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan'), 6, TO_DATE('2024-07-06','YYYY-MM-DD'), 'Departure Prep', 'Y', 'Pack and relax before departure.');

INSERT INTO itinerary_activities (itinerary_day_id, activity_type, attraction_id, start_time, end_time, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 1),
        'ATTRACTION', (SELECT attraction_id FROM attractions WHERE name = 'Sagrada Familia Private Tour'),
        TO_DATE('2024-07-01 14:00','YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-01 16:30','YYYY-MM-DD HH24:MI'), 'Meet guide Miguel for storytelling session.');
INSERT INTO itinerary_activities (itinerary_day_id, activity_type, attraction_id, start_time, end_time, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 3),
        'ATTRACTION', (SELECT attraction_id FROM attractions WHERE name = 'Park Güell Family Adventure'),
        TO_DATE('2024-07-03 10:00','YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-03 13:00','YYYY-MM-DD HH24:MI'), 'Treasure hunt with prizes for kids.');
INSERT INTO itinerary_activities (itinerary_day_id, activity_type, attraction_id, start_time, end_time, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 5),
        'ATTRACTION', (SELECT attraction_id FROM attractions WHERE name = 'Magic Fountain Evening Show'),
        TO_DATE('2024-07-05 20:00','YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-05 22:00','YYYY-MM-DD HH24:MI'), 'Reserved seating provided.');
INSERT INTO itinerary_activities (itinerary_day_id, activity_type, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 4),
        'OTHER', 'Optional chocolate workshop or shopping.');
INSERT INTO itinerary_activities (itinerary_day_id, activity_type, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 2),
        'REST', 'Enjoy resort amenities and kids club.');
INSERT INTO itinerary_activities (itinerary_day_id, activity_type, notes)
VALUES ((SELECT itinerary_day_id FROM itinerary_days WHERE itinerary_id = (SELECT itinerary_id FROM itineraries WHERE name = 'Walker Family Barcelona Plan') AND day_number = 6),
        'REST', 'Late checkout and packing assistance.');

PROMPT Capturing reviews...
INSERT INTO reviews (booking_id, client_id, review_type, hotel_id, rating, title, comments, reviewed_on, would_recommend, family_suitability_score)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'HOTEL',
        (SELECT hotel_id FROM hotels WHERE name = 'Sunset Family Resort'), 4.8, 'Perfect for our kids',
        'Spacious apartment and amazing kids club. Transfer could be slightly faster.', TO_DATE('2024-07-08','YYYY-MM-DD'), 'Y', 4.9);
INSERT INTO reviews (booking_id, client_id, review_type, attraction_id, rating, title, comments, reviewed_on, would_recommend, family_suitability_score, guide_id)
VALUES ((SELECT booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1'),
        (SELECT client_id FROM clients WHERE email = 'john.walker@example.com'), 'ATTRACTION',
        (SELECT attraction_id FROM attractions WHERE name = 'Park Güell Family Adventure'), 5.0, 'Kids loved it!',
        'Guide Miguel kept the children engaged throughout the treasure hunt.', TO_DATE('2024-07-04','YYYY-MM-DD'), 'Y', 5.0,
        (SELECT guide_id FROM guides WHERE email = 'miguel.torres@barcelonatours.es'));


PROMPT Creating helper views...
CREATE OR REPLACE VIEW apex_client_accounts_v AS
SELECT c.client_id,
       c.username,
       c.password_hash,
       c.account_status,
       c.first_name,
       c.last_name,
       c.email,
       c.phone,
       c.preferred_language,
       c.preferred_contact_method,
       c.marketing_opt_in,
       NVL(cp.travelling_with_children, 'N') AS travelling_with_children,
       NVL(cp.travelling_with_pets, 'N') AS travelling_with_pets,
       cp.accessibility_needs,
       cp.dietary_preferences,
       cp.preferred_room_type,
       cp.preferred_food_type,
       cp.preferred_transport,
       cp.preferred_city_id,
       ci.name AS preferred_city_name,
       c.last_login,
       c.created_at,
       c.updated_at
  FROM clients c
  LEFT JOIN client_preferences cp ON cp.client_id = c.client_id
  LEFT JOIN cities ci ON ci.city_id = cp.preferred_city_id
 WHERE c.account_status <> 'DISABLED';
/

CREATE OR REPLACE VIEW booking_party_summary_v AS
SELECT b.booking_id,
       b.booking_reference,
       b.status,
       b.total_adults,
       b.total_children,
       NVL(SUM(CASE WHEN t.traveller_type IN ('ADULT','SENIOR','PRIMARY') THEN 1 ELSE 0 END), 0) AS calculated_adults,
       NVL(SUM(CASE WHEN t.traveller_type IN ('CHILD','INFANT') THEN 1 ELSE 0 END), 0)       AS calculated_children,
       NVL(COUNT(bt.booking_traveller_id), 0)                                               AS total_travellers,
       CASE
         WHEN NVL(b.total_adults, 0) = NVL(SUM(CASE WHEN t.traveller_type IN ('ADULT','SENIOR','PRIMARY') THEN 1 ELSE 0 END), 0)
          AND NVL(b.total_children, 0) = NVL(SUM(CASE WHEN t.traveller_type IN ('CHILD','INFANT') THEN 1 ELSE 0 END), 0)
         THEN 'N'
         ELSE 'Y'
       END AS needs_sync
  FROM bookings b
  LEFT JOIN booking_travellers bt ON bt.booking_id = b.booking_id
  LEFT JOIN travellers t ON t.traveller_id = bt.traveller_id
 GROUP BY b.booking_id, b.booking_reference, b.status, b.total_adults, b.total_children;
/

CREATE OR REPLACE VIEW available_offers_v AS
SELECT h.hotel_id,
       h.name AS hotel_name,
       c.name AS city_name,
       r.room_type_id,
       r.name AS room_type_name,
       r.max_adults,
       r.max_children,
       r.max_occupancy,
       inv.inventory_date,
       (inv.rooms_total - inv.rooms_booked) AS rooms_available,
       inv.rate,
       inv.currency_code,
       r.family_friendly,
       h.family_friendly AS hotel_family_friendly,
       NVL(avg_rev.avg_rating, h.star_rating) AS overall_rating
  FROM hotels h
  JOIN cities c ON c.city_id = h.city_id
  JOIN hotel_room_types r ON r.hotel_id = h.hotel_id
  JOIN (
        SELECT room_type_id,
               inventory_date,
               rooms_total,
               rooms_booked,
               rate,
               currency_code
          FROM hotel_room_inventory
       ) inv ON inv.room_type_id = r.room_type_id
 LEFT JOIN (
        SELECT hotel_id,
               ROUND(AVG(rating),2) AS avg_rating
          FROM reviews
         WHERE review_type = 'HOTEL'
         GROUP BY hotel_id
       ) avg_rev ON avg_rev.hotel_id = h.hotel_id
 WHERE inv.inventory_date >= TRUNC(SYSDATE) - 1
   AND (inv.rooms_total - inv.rooms_booked) > 0;
/

CREATE OR REPLACE VIEW family_packages_v AS
SELECT h.hotel_id,
       h.name AS hotel_name,
       c.name AS city_name,
       r.room_type_id,
       r.name AS room_type,
       r.max_adults + r.max_children AS max_family_size,
       r.base_rate,
       r.currency_code,
       NVL(rv.avg_rating, h.star_rating) AS review_score,
       NVL(rv.avg_family_score, CASE WHEN r.family_friendly = 'Y' THEN 5 ELSE 0 END)
         AS family_score,
       NVL(inv.next_available, SYSDATE) AS next_available_date,
       NVL(inv.available_rooms, 0) AS rooms_available
  FROM hotels h
  JOIN cities c ON c.city_id = h.city_id
  JOIN hotel_room_types r ON r.hotel_id = h.hotel_id
  LEFT JOIN (
        SELECT hotel_id,
               ROUND(AVG(rating),2) AS avg_rating,
               ROUND(AVG(family_suitability_score),2) AS avg_family_score
          FROM reviews
         WHERE review_type = 'HOTEL'
         GROUP BY hotel_id
       ) rv ON rv.hotel_id = h.hotel_id
 LEFT JOIN (
        SELECT room_type_id,
               MIN(inventory_date) AS next_available,
               SUM(rooms_total - rooms_booked) AS available_rooms
          FROM hotel_room_inventory
         WHERE inventory_date >= TRUNC(SYSDATE)
         GROUP BY room_type_id
       ) inv ON inv.room_type_id = r.room_type_id
 WHERE r.family_friendly = 'Y'
   AND NVL(inv.available_rooms, 0) > 0;
/

CREATE OR REPLACE VIEW top_rated_hotels_v AS
SELECT h.hotel_id,
       h.name AS hotel_name,
       c.name AS city_name,
       h.star_rating,
       NVL(rv.avg_rating, h.star_rating) AS review_rating,
       NVL(rv.review_count, 0) AS review_count,
       NVL(rv.avg_family_score, 0) AS family_focus
  FROM hotels h
  JOIN cities c ON c.city_id = h.city_id
  LEFT JOIN (
        SELECT hotel_id,
               ROUND(AVG(rating),2) AS avg_rating,
               COUNT(*) AS review_count,
               ROUND(AVG(NVL(family_suitability_score, rating)),2) AS avg_family_score
          FROM reviews
         WHERE review_type = 'HOTEL'
         GROUP BY hotel_id
       ) rv ON rv.hotel_id = h.hotel_id;
/

PROMPT Creating travel agency API package...
CREATE OR REPLACE PACKAGE travel_agency_api AS
  PROCEDURE sync_booking_party(
    p_booking_id IN NUMBER);

  PROCEDURE sync_booking_customer_snapshot(
    p_booking_id IN NUMBER);

  PROCEDURE find_best_family_offer(
    p_adults    IN NUMBER,
    p_children  IN NUMBER,
    p_budget    IN NUMBER DEFAULT NULL,
    p_city_id   IN NUMBER DEFAULT NULL,
    p_results   OUT SYS_REFCURSOR);

  PROCEDURE recommend_hotel_for_booking(
    p_booking_id IN NUMBER,
    p_results    OUT SYS_REFCURSOR);

  PROCEDURE generate_itinerary(
    p_booking_id        IN NUMBER,
    p_days              IN NUMBER,
    p_include_rest_days IN VARCHAR2 DEFAULT 'Y',
    p_itinerary_id      OUT NUMBER);

  FUNCTION calculate_total_booking_cost(
    p_booking_id IN NUMBER) RETURN NUMBER;
END travel_agency_api;
/

CREATE OR REPLACE PACKAGE BODY travel_agency_api AS
  PROCEDURE sync_booking_party(
    p_booking_id IN NUMBER) IS
  BEGIN
    update_booking_party_counts(p_booking_id);
  END sync_booking_party;

  PROCEDURE sync_booking_customer_snapshot(
    p_booking_id IN NUMBER) IS
  BEGIN
    refresh_booking_customer_snapshot(p_booking_id);
  END sync_booking_customer_snapshot;

  PROCEDURE find_best_family_offer(
    p_adults    IN NUMBER,
    p_children  IN NUMBER,
    p_budget    IN NUMBER DEFAULT NULL,
    p_city_id   IN NUMBER DEFAULT NULL,
    p_results   OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_results FOR
      SELECT h.hotel_id,
             h.name AS hotel_name,
             c.name AS city_name,
             r.room_type_id,
             r.name AS room_type_name,
             r.max_adults,
             r.max_children,
             inv.min_rate,
             inv.next_available_date,
             inv.available_rooms,
             NVL(rv.avg_rating, h.star_rating) AS review_rating,
             NVL(rv.avg_family_score, 0) AS family_score
        FROM hotels h
        JOIN cities c ON c.city_id = h.city_id
        JOIN hotel_room_types r ON r.hotel_id = h.hotel_id
        JOIN (
              SELECT room_type_id,
                     MIN(rate) AS min_rate,
                     MIN(inventory_date) AS next_available_date,
                     SUM(rooms_total - rooms_booked) AS available_rooms
                FROM hotel_room_inventory
               WHERE inventory_date >= TRUNC(SYSDATE)
               GROUP BY room_type_id
             ) inv ON inv.room_type_id = r.room_type_id
       LEFT JOIN (
              SELECT hotel_id,
                     ROUND(AVG(rating),2) AS avg_rating,
                     ROUND(AVG(NVL(family_suitability_score, rating)),2) AS avg_family_score
                FROM reviews
               WHERE review_type = 'HOTEL'
               GROUP BY hotel_id
             ) rv ON rv.hotel_id = h.hotel_id
       WHERE h.family_friendly = 'Y'
         AND r.family_friendly = 'Y'
         AND NVL(r.max_adults, 0) >= NVL(p_adults, 0)
         AND NVL(r.max_children, 0) >= NVL(p_children, 0)
         AND (p_city_id IS NULL OR h.city_id = p_city_id)
         AND (p_budget IS NULL OR inv.min_rate <= p_budget)
         AND inv.available_rooms > 0
       ORDER BY NVL(rv.avg_rating, h.star_rating) DESC,
                inv.min_rate ASC
      FETCH FIRST 10 ROWS ONLY;
  END find_best_family_offer;

  PROCEDURE recommend_hotel_for_booking(
    p_booking_id IN NUMBER,
    p_results    OUT SYS_REFCURSOR) IS
    v_client_id      NUMBER;
    v_adults         NUMBER := 0;
    v_children       NUMBER := 0;
    v_budget         NUMBER := NULL;
    v_city_id        NUMBER := NULL;
    v_pref_city      NUMBER := NULL;
    v_pref_room      VARCHAR2(100);
    v_with_children  CHAR(1) := 'N';
  BEGIN
    sync_booking_party(p_booking_id);

    SELECT client_id, NVL(total_adults, 0), NVL(total_children, 0), budget_amount
      INTO v_client_id, v_adults, v_children, v_budget
      FROM bookings
     WHERE booking_id = p_booking_id;

    BEGIN
      SELECT preferred_city_id,
             preferred_room_type,
             travelling_with_children
        INTO v_pref_city,
             v_pref_room,
             v_with_children
        FROM client_preferences
       WHERE client_id = v_client_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_pref_city := NULL;
        v_pref_room := NULL;
        v_with_children := CASE WHEN v_children > 0 THEN 'Y' ELSE 'N' END;
    END;

    BEGIN
      SELECT MIN(h.city_id)
        INTO v_city_id
        FROM booking_rooms br
        JOIN hotel_room_types rt ON rt.room_type_id = br.room_type_id
        JOIN hotels h ON h.hotel_id = rt.hotel_id
       WHERE br.booking_id = p_booking_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_city_id := NULL;
    END;

    IF v_city_id IS NULL THEN
      v_city_id := v_pref_city;
    END IF;

    OPEN p_results FOR
      SELECT h.hotel_id,
             h.name AS hotel_name,
             c.name AS city_name,
             r.room_type_id,
             r.name AS room_type_name,
             r.max_adults,
             r.max_children,
             inv.min_rate,
             inv.next_available_date,
             inv.available_rooms,
             r.currency_code,
             NVL(rv.avg_rating, h.star_rating) AS review_rating,
             NVL(rv.avg_family_score, 0) AS family_score
        FROM hotels h
        JOIN cities c ON c.city_id = h.city_id
        JOIN hotel_room_types r ON r.hotel_id = h.hotel_id
        JOIN (
              SELECT room_type_id,
                     MIN(rate) AS min_rate,
                     MIN(inventory_date) AS next_available_date,
                     SUM(rooms_total - rooms_booked) AS available_rooms
                FROM hotel_room_inventory
               WHERE inventory_date >= TRUNC(SYSDATE)
               GROUP BY room_type_id
             ) inv ON inv.room_type_id = r.room_type_id
        LEFT JOIN (
              SELECT hotel_id,
                     ROUND(AVG(rating),2) AS avg_rating,
                     ROUND(AVG(NVL(family_suitability_score, rating)),2) AS avg_family_score
                FROM reviews
               WHERE review_type = 'HOTEL'
               GROUP BY hotel_id
             ) rv ON rv.hotel_id = h.hotel_id
       WHERE (v_city_id IS NULL OR h.city_id = v_city_id)
         AND (v_with_children = 'N' OR h.family_friendly = 'Y')
         AND (v_with_children = 'N' OR r.family_friendly = 'Y')
         AND NVL(r.max_adults, 0) >= v_adults
         AND NVL(r.max_children, 0) >= v_children
         AND (v_budget IS NULL OR inv.min_rate <= v_budget)
         AND (v_pref_room IS NULL OR INSTR(LOWER(r.name), LOWER(v_pref_room)) > 0 OR INSTR(LOWER(NVL(r.description, '')), LOWER(v_pref_room)) > 0)
         AND inv.available_rooms > 0
       ORDER BY NVL(rv.avg_rating, h.star_rating) DESC,
                inv.min_rate ASC
       FETCH FIRST 10 ROWS ONLY;
  END recommend_hotel_for_booking;

  PROCEDURE generate_itinerary(
    p_booking_id        IN NUMBER,
    p_days              IN NUMBER,
    p_include_rest_days IN VARCHAR2 DEFAULT 'Y',
    p_itinerary_id      OUT NUMBER) IS
    v_start_date    DATE;
    v_end_date      DATE;
    v_city_id       NUMBER;
    v_itinerary_id  NUMBER;
    v_day_date      DATE;
    v_day_id        NUMBER;
    v_is_rest       BOOLEAN;
    v_attraction_id NUMBER;
    v_include_rest  BOOLEAN :=
      (UPPER(TRIM(NVL(p_include_rest_days, 'Y'))) IN ('Y','YES','TRUE','T','1'));
  BEGIN
    IF p_days <= 0 THEN
      RAISE_APPLICATION_ERROR(-20000, 'Number of days must be greater than zero.');
    END IF;

    SELECT start_date, end_date INTO v_start_date, v_end_date
      FROM bookings
     WHERE booking_id = p_booking_id;

    IF v_start_date IS NULL OR v_end_date IS NULL THEN
      SELECT MIN(check_in_date), MAX(check_out_date)
        INTO v_start_date, v_end_date
        FROM booking_rooms
       WHERE booking_id = p_booking_id;
    END IF;

    IF v_start_date IS NULL THEN
      v_start_date := SYSDATE;
    END IF;

    IF v_end_date IS NULL THEN
      v_end_date := v_start_date + (p_days - 1);
    END IF;

    SELECT MIN(h.city_id)
      INTO v_city_id
      FROM booking_rooms br
      JOIN hotel_room_types rt ON rt.room_type_id = br.room_type_id
      JOIN hotels h ON h.hotel_id = rt.hotel_id
     WHERE br.booking_id = p_booking_id;

    INSERT INTO itineraries (booking_id, name, start_date, end_date, summary)
    VALUES (p_booking_id,
            'Auto Itinerary ' || p_booking_id,
            v_start_date,
            v_start_date + (p_days - 1),
            'Automatically generated itinerary based on family friendly attractions.')
    RETURNING itinerary_id INTO v_itinerary_id;

    FOR i IN 1 .. p_days LOOP
      v_day_date := v_start_date + (i - 1);
      v_is_rest := FALSE;
      IF v_include_rest AND MOD(i, 3) = 0 THEN
        v_is_rest := TRUE;
      END IF;

      INSERT INTO itinerary_days (itinerary_id, day_number, day_date, theme, is_rest_day, notes)
      VALUES (v_itinerary_id,
              i,
              v_day_date,
              CASE WHEN v_is_rest THEN 'Rest & Recharge' ELSE 'Experience Day ' || i END,
              CASE WHEN v_is_rest THEN 'Y' ELSE 'N' END,
              CASE WHEN v_is_rest THEN 'Auto rest day scheduled for the family.' ELSE 'Auto activity day.' END)
      RETURNING itinerary_day_id INTO v_day_id;

      IF v_is_rest THEN
        INSERT INTO itinerary_activities (itinerary_day_id, activity_type, notes)
        VALUES (v_day_id, 'REST', 'Enjoy free time or hotel amenities.');
      ELSE
        BEGIN
          SELECT attraction_id
            INTO v_attraction_id
            FROM (
                  SELECT a.attraction_id
                    FROM attractions a
                   WHERE (v_city_id IS NULL OR a.city_id = v_city_id)
                   ORDER BY a.family_friendly DESC, NVL(a.base_price, 0)
                 )
           WHERE ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_attraction_id := NULL;
        END;

        IF v_attraction_id IS NOT NULL THEN
          INSERT INTO itinerary_activities (itinerary_day_id, activity_type, attraction_id, start_time, end_time, notes)
          VALUES (v_day_id,
                  'ATTRACTION',
                  v_attraction_id,
                  v_day_date + (10/24),
                  v_day_date + (13/24),
                  'Auto-selected family attraction.');
        ELSE
          INSERT INTO itinerary_activities (itinerary_day_id, activity_type, notes)
          VALUES (v_day_id,
                  'OTHER',
                  'Free exploration suggested by system.');
        END IF;
      END IF;
    END LOOP;

    UPDATE bookings
       SET updated_at = SYSDATE
     WHERE booking_id = p_booking_id;

    p_itinerary_id := v_itinerary_id;
  END generate_itinerary;

  FUNCTION calculate_total_booking_cost(
    p_booking_id IN NUMBER) RETURN NUMBER IS
    v_rooms_total      NUMBER := 0;
    v_transport_total  NUMBER := 0;
    v_insurance_total  NUMBER := 0;
    v_extra_total      NUMBER := 0;
    v_total            NUMBER := 0;
    v_discount_id      NUMBER;
    v_discount_type    discounts.discount_type%TYPE;
    v_discount_value   discounts.value%TYPE;
    v_min_people       NUMBER := 0;
    v_min_nights       NUMBER := 0;
    v_family_only      CHAR(1) := 'N';
    v_adults           NUMBER := 0;
    v_children         NUMBER := 0;
    v_people           NUMBER := 0;
    v_start_date       DATE;
    v_end_date         DATE;
    v_nights           NUMBER := 0;
  BEGIN
    sync_booking_party(p_booking_id);

    SELECT NVL(SUM((check_out_date - check_in_date) * nightly_rate * number_of_rooms - NVL(discount_amount, 0)), 0)
      INTO v_rooms_total
      FROM booking_rooms
     WHERE booking_id = p_booking_id;

    SELECT NVL(SUM(price), 0)
      INTO v_transport_total
      FROM booking_transports
     WHERE booking_id = p_booking_id;

    SELECT NVL(SUM(price), 0)
      INTO v_insurance_total
      FROM booking_insurances
     WHERE booking_id = p_booking_id;

    SELECT NVL(SUM(amount), 0)
      INTO v_extra_total
      FROM booking_costs
     WHERE booking_id = p_booking_id;

    SELECT discount_id, total_adults, total_children, start_date, end_date
      INTO v_discount_id, v_adults, v_children, v_start_date, v_end_date
      FROM bookings
     WHERE booking_id = p_booking_id;

    v_total := v_rooms_total + v_transport_total + v_insurance_total + v_extra_total;
    v_people := NVL(v_adults, 0) + NVL(v_children, 0);
    IF v_start_date IS NOT NULL AND v_end_date IS NOT NULL THEN
      v_nights := v_end_date - v_start_date;
    END IF;

    IF v_discount_id IS NOT NULL THEN
      SELECT discount_type, value, NVL(min_people, 0), NVL(min_nights, 0), NVL(family_only, 'N')
        INTO v_discount_type, v_discount_value, v_min_people, v_min_nights, v_family_only
        FROM discounts
       WHERE discount_id = v_discount_id;

      IF (v_min_people = 0 OR v_people >= v_min_people)
         AND (v_min_nights = 0 OR v_nights >= v_min_nights)
         AND (v_family_only = 'N' OR v_children > 0) THEN
        IF v_discount_type = 'PERCENTAGE' THEN
          v_total := v_total - (v_total * v_discount_value / 100);
        ELSE
          v_total := v_total - v_discount_value;
        END IF;
      END IF;
    END IF;

    UPDATE bookings
       SET calculated_total = ROUND(v_total, 2),
           calculated_at = SYSDATE,
           updated_at = SYSDATE
     WHERE booking_id = p_booking_id;

    RETURN ROUND(v_total, 2);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END calculate_total_booking_cost;
END travel_agency_api;
/

PROMPT Creating APEX integration helpers...
CREATE OR REPLACE PACKAGE travel_agency_apex AS
  FUNCTION authenticate_client(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2) RETURN BOOLEAN;

  PROCEDURE log_successful_login(
    p_username IN VARCHAR2);

  PROCEDURE set_client_password(
    p_client_id      IN NUMBER,
    p_plain_password IN VARCHAR2);

  PROCEDURE unlock_client(
    p_username IN VARCHAR2);
END travel_agency_apex;
/

CREATE OR REPLACE PACKAGE BODY travel_agency_apex AS
  FUNCTION authenticate_client(
    p_username IN VARCHAR2,
    p_password IN VARCHAR2) RETURN BOOLEAN IS
    v_hash    clients.password_hash%TYPE;
    v_status  clients.account_status%TYPE;
    v_target  VARCHAR2(200);
    v_result  BOOLEAN := FALSE;
  BEGIN
    SELECT password_hash,
           account_status
      INTO v_hash,
           v_status
      FROM clients
     WHERE UPPER(username) = UPPER(p_username);

    IF v_status <> 'ACTIVE' THEN
      RETURN FALSE;
    END IF;

    IF v_hash LIKE 'SHA256:%' THEN
      v_target := SUBSTR(v_hash, 8);
      IF v_target = RAWTOHEX(STANDARD_HASH(p_password, 'SHA256')) THEN
        v_result := TRUE;
      END IF;
    ELSE
      IF v_hash = p_password THEN
        v_result := TRUE;
      END IF;
    END IF;

    IF v_result THEN
      log_successful_login(p_username);
    END IF;

    RETURN v_result;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END authenticate_client;

  PROCEDURE log_successful_login(
    p_username IN VARCHAR2) IS
  BEGIN
    UPDATE clients
       SET last_login    = SYSDATE,
           updated_at    = SYSDATE,
           account_status = CASE WHEN account_status = 'LOCKED' THEN 'ACTIVE' ELSE account_status END
     WHERE UPPER(username) = UPPER(p_username);
  END log_successful_login;

  PROCEDURE set_client_password(
    p_client_id      IN NUMBER,
    p_plain_password IN VARCHAR2) IS
  BEGIN
    UPDATE clients
       SET password_hash = 'SHA256:' || RAWTOHEX(STANDARD_HASH(p_plain_password, 'SHA256')),
           updated_at    = SYSDATE
     WHERE client_id = p_client_id;
  END set_client_password;

  PROCEDURE unlock_client(
    p_username IN VARCHAR2) IS
  BEGIN
    UPDATE clients
       SET account_status = 'ACTIVE',
           updated_at     = SYSDATE
     WHERE UPPER(username) = UPPER(p_username);
  END unlock_client;
END travel_agency_apex;
/

PROMPT Running sample calculations and automation...
DECLARE
  v_total       NUMBER;
  v_booking_id  NUMBER;
  v_adults      NUMBER;
  v_children    NUMBER;
BEGIN
  SELECT booking_id INTO v_booking_id FROM bookings WHERE booking_reference = 'BK-2024-FAM1';
  travel_agency_api.sync_booking_party(v_booking_id);
  travel_agency_api.sync_booking_customer_snapshot(v_booking_id);
  SELECT total_adults, total_children INTO v_adults, v_children FROM bookings WHERE booking_id = v_booking_id;
  v_total := travel_agency_api.calculate_total_booking_cost(v_booking_id);
  DBMS_OUTPUT.PUT_LINE('Walker family total cost: ' || TO_CHAR(v_total));
  DBMS_OUTPUT.PUT_LINE('Walker party composition -> Adults: ' || v_adults || ', Children: ' || v_children);

  SELECT booking_id INTO v_booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME';
  v_total := travel_agency_api.calculate_total_booking_cost(v_booking_id);
  DBMS_OUTPUT.PUT_LINE('Ramirez trip total cost: ' || TO_CHAR(v_total));

  SELECT booking_id INTO v_booking_id FROM bookings WHERE booking_reference = 'BK-2024-NYC';
  v_total := travel_agency_api.calculate_total_booking_cost(v_booking_id);
  DBMS_OUTPUT.PUT_LINE('Chen Li trip total cost: ' || TO_CHAR(v_total));
END;
/

DECLARE
  v_booking_id   NUMBER;
  v_itinerary_id NUMBER;
BEGIN
  SELECT booking_id INTO v_booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME';
  travel_agency_api.generate_itinerary(v_booking_id => v_booking_id,
                                       p_days => 5,
                                       p_include_rest_days => 'Y',
                                       p_itinerary_id => v_itinerary_id);
  DBMS_OUTPUT.PUT_LINE('Generated itinerary ' || v_itinerary_id || ' for Ramirez booking.');
END;
/

DECLARE
  v_booking_id    NUMBER;
  v_results       SYS_REFCURSOR;
  v_hotel_id      NUMBER;
  v_hotel_name    VARCHAR2(200);
  v_city_name     VARCHAR2(150);
  v_room_type_id  NUMBER;
  v_room_type     VARCHAR2(150);
  v_max_adults    NUMBER;
  v_max_children  NUMBER;
  v_rate          NUMBER;
  v_available_on  DATE;
  v_available_cnt NUMBER;
  v_rating        NUMBER;
  v_family_score  NUMBER;
  v_currency_code CHAR(3);
BEGIN
  SELECT booking_id INTO v_booking_id FROM bookings WHERE booking_reference = 'BK-2024-ROME';
  travel_agency_api.recommend_hotel_for_booking(p_booking_id => v_booking_id,
                                               p_results    => v_results);

  FETCH v_results
    INTO v_hotel_id,
         v_hotel_name,
         v_city_name,
         v_room_type_id,
         v_room_type,
         v_max_adults,
         v_max_children,
         v_rate,
         v_available_on,
         v_available_cnt,
         v_currency_code,
         v_rating,
         v_family_score;

  IF v_results%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Recommended option for Ramirez booking: ' || v_hotel_name || ' - ' || v_room_type ||
                         ' @ ' || TO_CHAR(v_rate) || ' ' || v_currency_code);
    DBMS_OUTPUT.PUT_LINE('Availability on ' || TO_CHAR(v_available_on, 'YYYY-MM-DD') || ': ' || v_available_cnt || ' rooms (rating ' || v_rating || ', family score ' || v_family_score || ').');
  ELSE
    DBMS_OUTPUT.PUT_LINE('No hotel recommendation found for Ramirez booking.');
  END IF;

  CLOSE v_results;
END;
/

DECLARE
  v_auth BOOLEAN;
BEGIN
  v_auth := travel_agency_apex.authenticate_client('john.walker', 'Walker#2024');
  DBMS_OUTPUT.PUT_LINE('APEX auth (correct) for john.walker -> ' || CASE WHEN v_auth THEN 'SUCCESS' ELSE 'FAIL' END);

  v_auth := travel_agency_apex.authenticate_client('john.walker', 'WrongPassword');
  DBMS_OUTPUT.PUT_LINE('APEX auth (wrong) for john.walker -> ' || CASE WHEN v_auth THEN 'SUCCESS' ELSE 'FAIL' END);
END;
/

COMMIT;

PROMPT Summary of seeded data rows...
SELECT 'CONTINENTS' AS table_name, COUNT(*) AS row_count FROM continents UNION ALL
SELECT 'COUNTRIES', COUNT(*) FROM countries UNION ALL
SELECT 'CITIES', COUNT(*) FROM cities UNION ALL
SELECT 'CLIENTS', COUNT(*) FROM clients UNION ALL
SELECT 'TRAVELLERS', COUNT(*) FROM travellers UNION ALL
SELECT 'HOTELS', COUNT(*) FROM hotels UNION ALL
SELECT 'ROOM_TYPES', COUNT(*) FROM hotel_room_types UNION ALL
SELECT 'ROOM_INVENTORY', COUNT(*) FROM hotel_room_inventory UNION ALL
SELECT 'ATTRACTIONS', COUNT(*) FROM attractions UNION ALL
SELECT 'BOOKINGS', COUNT(*) FROM bookings UNION ALL
SELECT 'BOOKING_CUSTOMER_SNAPSHOTS', COUNT(*) FROM booking_customer_snapshots UNION ALL
SELECT 'BOOKING_STATUS_HISTORY', COUNT(*) FROM booking_status_history UNION ALL
SELECT 'ITINERARIES', COUNT(*) FROM itineraries UNION ALL
SELECT 'REVIEWS', COUNT(*) FROM reviews;

