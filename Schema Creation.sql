-- Übung 3 → Schema Creation

OPEN SCHEMA NIKOLAS_POLLIN;

-- Zeiten, die über service_id referenziert werden, gehören separater Dimension an
-- Routentypen, sprich Fahrzeugarten, die über route_type referenziert werden, gehören Fahrzeug-Dimension an
CREATE TABLE Dim_Trips (
    trip_id INTEGER PRIMARY KEY,
    trip_headsign VARCHAR(100),
    trip_short_name VARCHAR(50),
    direction VARCHAR(10), -- Enum Werte VORWÄRTS, RÜCKWÄRTS
    wheelchair_accessible BOOLEAN,
    bikes_allowed BOOLEAN,

    -- Linie -> Hierarchiestufe
    route_short_name VARCHAR(50),
    route_long_name VARCHAR(100),
    transport_mode VARCHAR(20),
    -- ///

    -- Betreiber -> Hierarchiestufe
    agency_name VARCHAR(100)
    -- ///
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
    name VARCHAR(80), -- Name der Haltestelle
    description VARCHAR(100), -- Zusätzliche Informationen zur Haltestelle
    type VARCHAR(40),
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
    gender VARCHAR(8), -- Männlich, Weiblich
    age_group_code VARCHAR(10), -- bspw. 00_TO_17
    age_group_desc VARCHAR(30),
    -- Für einfachere Queries
    min_age INTEGER,
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
    arrival_time_sec INTEGER, -- Zeit in Sekunden seit Mitternacht
    departure_time_sec INTEGER,
    duration_of_stay_sec INTEGER,
    duration_until_next_stop_sec INTEGER,
    -- PK enthält stop_sequence wegen bspw. Kreisfahrten und ähnlichem
    PRIMARY KEY (station_id, trip_id, "date", stop_sequence)
);



-- Beispielsdatensätze

-- Fahrt, Linie, Betreiber - Dimensionstabelle

INSERT INTO DIM_TRIPS VALUES (1, 'Nordhorn Bahnhof', '039101', 'Vorwärts',false, true,
                              '6018', 'Uni-Express','Bus',
                              'Stadtverkehr Bingen');

INSERT INTO DIM_TRIPS VALUES (2, 'Mainburg; Griesplatz/Zentrum', '077191', 'Rückwärts',true, false,
                              '9012', 'Tram 8','Stadtbahn',
                              'RVG Regionalverkehr Gera');


-- Fahrzeugart - Dimensionstabelle

INSERT INTO DIM_VEHICLE_TYPE VALUES (1, 'PKW', true);
INSERT INTO DIM_VEHICLE_TYPE VALUES (2, 'Krafträder', false);


-- Gemeinde, Raumtyp, Kreis, Bundesland - Dimensionstabelle

INSERT INTO DIM_MUNICIPALITIES VALUES (09184114, 'Brunnthal', 'Kreisangehörige Gemeinde', 37.95,
                                       09184000, 'München',
                                       09, 'Bayern',
                                       2, 'teilweise städtisch', 1, 'sehr zentral',
                                       55, 'Kleinstädtischer, dörflicher Raum', 40, 'Kleine Kleinstadt');

INSERT INTO DIM_MUNICIPALITIES VALUES (07232296, 'Prüm, Stadt', 'Stadt', 22.86,
                                       07232000, 'Eifelkreis Bitburg-Prüm',
                                       07, 'Rheinland-Pfalz',
                                       3, 'überwiegend ländlich', 3, 'peripher',
                                       55, 'Kleinstädtischer, dörflicher Raum', 40, 'Kleine Kleinstadt');


-- Haltestelle - Dimensionstabelle

INSERT INTO DIM_STATIONS VALUES (1, 09184114, 'de:09184:2304:0:2',
                                 'Brunnthal, Abzw. Waldbrunn', 'Bushalt Werner-Seelenbinder-Straße hinter Prignitzstraße', 'HALTESTELLE/BAHNHSTEIG',
                                 48.042787000000,11.670418000000, false, '');

INSERT INTO DIM_STATIONS VALUES (2, 07232296, 'de:07137:030432:01',
                                 'Kottenheim Keltenstraße', 'S-Bahnsteig Gleis 1', 'BAHNHOF',
                                 50.344424000000,7.255198000000, true, '5');


-- Bevölkerung - Dimensionstabelle

INSERT INTO DIM_POPULATION VALUES (1, 'MÄNNLICH', '30_TO_34', '30 bis unter 35 Jahre', 30, 34);
INSERT INTO DIM_POPULATION VALUES (2, 'WEIBLICH', '55_TO_59', '55 bis unter 60 Jahre', 55, 59);


-- Fahrzeugbestand - Faktentabelle

INSERT INTO FACT_REGISTERED_VEHICLES VALUES (07232296, 1, '2025-01-01', 542);
INSERT INTO FACT_REGISTERED_VEHICLES VALUES (09184114, 2, '2025-01-01', 596);


-- Zensus - Faktentabelle

INSERT INTO FACT_CENSUS VALUES (07232296, 1, '2024-12-31', 213);
INSERT INTO FACT_CENSUS VALUES (07232296, 2, '2024-12-31', 226);


-- ÖPNV-Halte - Faktentabelle

INSERT INTO FACT_STOPS VALUES (1, 1, '2026-08-12', 3,
                               false, false, 29700, 29760,
                               60, 120);

INSERT INTO FACT_STOPS VALUES (2, 2, '2026-09-06', 12,
                               false, true, 70200, 70200,
                               0, NULL);


-- Snowflake vs Star Schema

/*
    Die einzigen Dimensionen, die davon betroffen wären, sind die, die mehrere Hierarchiestufen haben.
    Das sind also Tag bzw. Zeit (wofür es keine eigene Tabelle gibt), Haltestelle bzw. Ort & Fahrt bzw. Fortbewegungsmittel.

    Man müsste die Gemeinde Tabelle auftrennen in Gemeinde selbst, Raumtyp, Kreis und Bundesland, wobei Kreis einen Fremdschlüssel
    auf Bundesland hätte und Gemeinde einen Fremdschlüssel auf Raumtyp und Kreis. Die Haltestelle Tabelle würde weiterhin eigenständig
    bleiben mit Fremdschlüssel auf Gemeinde.
    Da weder Kreis noch Bundesland viele Attribute beinhalten, lohnt sich der Join-Aufwand nicht (außerdem sind die Attribute sehr fest
    und werden sich vermutlich nicht ändern → kein Update-Aufwand).
    Da es auch verhältnismäßig wenige Gemeinden gibt (ca 11 000), ist die Redundanz des denormalisiertem Raumtypen eher gering. Es lohnt
    sich vermutlich nicht, diese Informationen wieder extra auszulagern und sie an einen Join zu "binden".

    Auch die Fahrten Tabelle müsste man in Fahrt, Linie & Betreiber aufteilen.
    Betreiber enthält nur minimale, sich nicht ändernde, Informationen, bei denen Normalisierung keinen Sinn macht.
    Auch bei den Linien gibt sich, wegen der wenigen Attribute, kein direkter Grund zu normalisieren.
 */