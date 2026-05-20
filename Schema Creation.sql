-- Übung 3 → Schema Creation

OPEN SCHEMA NIKOLAS_POLLIN;

-- Zeiten, die über service_id referenziert werden, gehören separater Dimension an
-- Routentypen, sprich Fahrzeugarten, die über route_type referenziert werden, gehören Fahrzeug-Dimension an
CREATE TABLE Dim_Trips (
    trip_id INTEGER PRIMARY KEY,

    -- Linie -> Hierarchiestufe
    route_short_name VARCHAR(50),
    route_long_name VARCHAR(100),
    route_desc VARCHAR(1000),
    transport_mode VARCHAR(20),
    -- ///

    -- Betreiber -> Hierarchiestufe
    agency_name VARCHAR(100),
    -- ///

    trip_headsign VARCHAR(100),
    trip_short_name VARCHAR(50),
    direction VARCHAR(10), -- Enum Werte VORWÄRTS, RÜCKWÄRTS
    wheelchair_accessible BOOLEAN,
    bikes_allowed BOOLEAN
);


CREATE TABLE Dim_Vehicle_Type (
    vehicle_type_id INTEGER PRIMARY KEY,
    type VARCHAR(20), -- bspw. Motorrad, LKW, PKW
    commercial BOOLEAN
);


-- parent_station Attribut wurde vorerst weggelassen (kann notfalls noch nachgetragen werden)
CREATE TABLE Dim_Stations (
    station_id INTEGER PRIMARY KEY, -- Surrogatschlüssel
    municipality_code INTEGER REFERENCES Dim_Municipalities(municipality_code),
    dh_id VARCHAR(30), -- Deutschlandweite ID der Haltestellen
    short_identification VARCHAR(30), -- stop_code in stops.txt
    name VARCHAR(80), -- Name der Haltestelle
    description VARCHAR(100), -- Zusätzliche Informationen zur Haltestelle
    type VARCHAR(20),
    latitude DOUBLE,
    longitude DOUBLE,
    wheelchair_accessible BOOLEAN,
    platform_code VARCHAR(30)
);


CREATE TABLE Dim_Municipalities (
    municipality_code INTEGER PRIMARY KEY, -- Amtlicher Gemeindeschlüssel
    name VARCHAR(60),
    description VARCHAR(50),
    area_km2 DOUBLE,

    -- Kreis --> Hierarchiestufe
    county_code INTEGER,
    county_name VARCHAR(60),
    -- ///

    -- Bundesland --> Hierarchiestufe
    state_code INTEGER,
    state_name VARCHAR(30),
    -- ///

    -- Raumtyp --> Hierarchiestufe
    spatial_settlement_code INTEGER, -- RBG
    spatial_settlement_desc VARCHAR(40),
    geographical_location_code INTEGER, -- RLG
    geographical_location_desc VARCHAR(20),
    spatial_typology_code INTEGER, -- RS5
    spatial_typology_desc VARCHAR(50),
    municipality_type_code INTEGER, -- GTU
    municipality_type_desc VARCHAR(30)
    -- ///
);


CREATE TABLE Dim_Population (
    population_group_id INTEGER PRIMARY KEY,
    gender VARCHAR(8),
    age_group_code VARCHAR(10), -- bspw. 00_TO_17
    age_group_desc VARCHAR(30),
    min_age INTEGER, -- Für einfachere Queries
    max_age INTEGER
);


CREATE TABLE Fact_Registered_Vehicles (
    municipality_code INTEGER REFERENCES Dim_Municipalities(municipality_code),
    vehicle_type_id INTEGER REFERENCES Dim_Vehicle_Type(vehicle_type_id),
    "date" DATE,
    amount INTEGER,
    PRIMARY KEY (municipality_code, vehicle_type_id, "date")
);


CREATE TABLE Fact_Census (
    municipality_code INTEGER REFERENCES Dim_Municipalities(municipality_code),
    population_group_id INTEGER REFERENCES Dim_Population(population_group_id),
    "date" DATE,
    amount INTEGER,
    PRIMARY KEY (municipality_code, population_group_id, "date")
);


CREATE TABLE Fact_Stops (
    station_id INTEGER REFERENCES Dim_Stations(station_id),
    trip_id INTEGER REFERENCES Dim_Trips(trip_id),
    "date" DATE, -- Konkreter Tag, an dem Fahrt stattfindet
    stop_sequence INTEGER, -- Position der Haltestelle in der konkreten Fahrt
    no_drop_off BOOLEAN,
    no_pick_up BOOLEAN,
    arrival_time TIMESTAMP,
    departure_time TIMESTAMP,
    duration_of_stay_sec INTEGER,
    duration_until_next_stop_sec INTEGER,
    PRIMARY KEY (station_id, trip_id, "date", stop_sequence)
);