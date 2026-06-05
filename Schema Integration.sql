-- Demografie-Daten (Bevölkerung)

/*
    Attribute:
        - Stichtag (identischer Wert an jeder Stelle) - Datum (Format DD.MM.YYYY)
        - Kennziffer (Bundesland, Kreis, Gemeinde -> je nach Eintrag)
            - Für Bundesland wird Wert "DG" gespeichert
        - Name in Klartext (Bundesland, Kreis, Gemeinde ...)
        - Altersgruppe Klartext
        - Insgesamt (Männlich & Weiblich kombiniert) - Ganzzahliger Wert
        - Männlich - Ganzzahliger Wert
        - Weiblich - Ganzzahliger Wert

    Column-Separator: ';'
    Encoding: 'UTF-8'
    Zeilenendung: 'LF'
 */

CREATE TABLE Staging_Population (
    reporting_date         VARCHAR(15), -- I. d. R. immer der selbe Wert in allen Zeilen
    spatial_identification VARCHAR(8),  -- Kennziffer kann maximal 8 Zeichen lang sein (wegen DG Wert muss String verwendet werden)
    location_name          VARCHAR(100), -- Je nach Stufe bspw. "Deutschland", "Kelheim, Landkreis"
    age_group_name         VARCHAR(40),
    total_population       INTEGER,
    male_population        INTEGER,
    female_population      INTEGER
);

CREATE TABLE Staging_Population_Age_Groups (
    gender VARCHAR(8), -- Männlich, Weiblich
    age_group_code VARCHAR(10), -- bspw. 00_BIS_17
    age_group_desc VARCHAR(30),
    -- Für einfachere Queries
    min_age INTEGER,
    max_age INTEGER
);


-- Fahrzeugbestand (Fahrzeugzulassungen FZ 3)

/*
    Attribute:
        - Bundesland (Klartext)
        - Zulassungsbezirk (letztendlich Landkreis)
            - Besteht aus Kreis-Kennziffer und Kreisnamen getrennt per Leerzeichen
            - Nicht in allen Fällen identisch zum Landkreis aber meistens
        - Gemeinde
            - Setzt sich zusammen aus Amtlichem Gemeindeschlüssel und Gemeindenamen getrennt per Leerzeichen
            - AGS ist achtstellig
        - Krafträder - Ganzzahliger Wert
        - Personenkraftwagen gesamt - Ganzzahliger Wert
        - Personenkraftwagen gewerblich - Ganzzahliger Wert

    Restliche Attribute für Projekt irrelevant
    Tausender sind per Punkt separiert
 */

CREATE TABLE Staging_Registered_Vehicles (
    state_name VARCHAR(30),
    district VARCHAR(50),
    municipality VARCHAR(70),
    motorcycles VARCHAR(10),
    passenger_vehicles_total VARCHAR(10),
    passenger_vehicles_commercial VARCHAR(10)
);


-- Raumtyp (Raumgliederung)

CREATE TABLE Staging_Spatial_Classification (
    GEM2024 INTEGER, -- Amtlicher Gemeindeschlüssel (achtstellig)
    GEM_NAME VARCHAR(60), -- Gemeindename
    Bez_GEM VARCHAR(50), -- Gemeindeeinstufung
    fl24 DOUBLE, -- Fläche in km2
    KRS2024 INTEGER, -- Kreiskennziffer (Bestandteil des AGS)
    KRS_NAME VARCHAR(60),
    BLD2024 INTEGER, -- Bundesland-Kennziffer
    BLD_NAME VARCHAR(30),
    RBG2024 INTEGER,
    RBG_NAME VARCHAR(40),
    RLG2024 INTEGER,
    RLG_NAME VARCHAR(20),
    RS52024 INTEGER,
    RS5_NAME VARCHAR(50),
    GTU2024 INTEGER,
    GTU_NAME VARCHAR(30)
);


-- Haltestellendaten (erweiterte Informationen - nicht direkt in GTFS Daten gebundelt)

/*
    Alle Attribute werden als Strings gespeichert
    Column-Separator: ';'
    Encoding: 'UTF-8 with BOM'
    Zeilenendung: CLRF
 */

CREATE TABLE Staging_Extended_Stops (
    SeqNo VARCHAR(10), -- In CSV eindeutige ID
    Type CHAR(1), -- Art der Haltestelle (deckt sich mit location_type in stops.txt)
    DHID VARCHAR(60), -- Deutschlandweit eindeutige Haltestellen-ID
    Parent VARCHAR(60), -- Enthält DHID des Parents
    Name VARCHAR(80),
    Latitude VARCHAR(25), -- Nachkommastellen per Komma statt Punkt getrennt (daher String)
    Longitude VARCHAR(25),
    MunicipalityCode VARCHAR(8), -- AGS
    Municipality VARCHAR(60), -- Gemeindename
    DistrictCode VARCHAR(5),
    District VARCHAR(60),
    Description VARCHAR(200),
    Authority VARCHAR(30),
    DelfiName VARCHAR(80),
    SEV VARCHAR(15)
);


-- GTFS Hauptdaten

-- stop_code ignoriert, da Wert nie gefüllt wird
CREATE TABLE Staging_Stops (
    stop_id VARCHAR(60), -- Identisch zu DHID in Staging_Extended_Stops
    stop_name VARCHAR(80), -- Wesentlicher Name
    stop_description VARCHAR(200), -- Zusätzliche beschreibende Informationen
    stop_lat VARCHAR(25), -- Längengrad, gespeichert als String, mit Punt als Nachkommastellen-Trennsymbol
    stop_lon VARCHAR(25),
    location_type INTEGER, -- Enum Wert für Art der Haltestelle
    parent_station VARCHAR(60), -- Enthält stop_id bzw. DHID des Parents (Leeres Feld, falls kein Parent existiert)
    wheelchair_boarding INTEGER, -- Enum Wert
    platform_code VARCHAR(30)
);

-- stop_headsign ist immer leer, daher ignoriert
CREATE TABLE Staging_Stop_Times (
    trip_id INTEGER, -- FK zu trips.txt
    stop_id VARCHAR(60), -- FK auf stops.txt (enthält DHID)
    stop_sequence INTEGER, -- Eindeutige Nummerierung eines Halts innerhalb einer Fahrt
    pickup_type INTEGER,
    drop_off_type INTEGER,
    arrival_time VARCHAR(8), -- Zeit in normaler Timestamp Formatierung (z. B. 08:18:30)
    departure_time VARCHAR(8)
);

-- block_id & shape_id werden nicht gebraucht, daher ignoriert
CREATE TABLE Staging_Trips (
    route_id VARCHAR(60), -- FK auf routes.txt
    service_id INTEGER, -- FK auf calender.txt
    trip_id INTEGER,
    trip_headsign VARCHAR(100),
    trip_short_name VARCHAR(10),
    direction_id INTEGER,
    wheelchair_accessible INTEGER,
    bikes_allowed INTEGER
);

-- exact_times sind in frequencies.txt Datensatz insgesamt nicht gesetzt
CREATE TABLE Staging_Frequencies (
    trip_id INTEGER, -- FK auf trips.txt
    start_time VARCHAR(8), -- Zeit in normaler Timestamp Formatierung (z. B. 08:18:30)
    end_time VARCHAR(8),
    headway_secs INTEGER
);

CREATE TABLE Staging_Calender (
    service_id INTEGER,
    monday INTEGER,
    tuesday INTEGER,
    wednesday INTEGER,
    thursday INTEGER,
    friday INTEGER,
    saturday INTEGER,
    sunday INTEGER,
    start_date VARCHAR(8), -- Datum im Format YYYYMMDD
    end_date VARCHAR(8)
);

CREATE TABLE Staging_Calender_Dates (
    service_id INTEGER, -- FK auf calender.txt
    "date" VARCHAR(8),
    exception_type INTEGER
);

-- route_color, route_text_color & route_desc in routes.txt fast nicht gesetzt, daher ignoriert
CREATE TABLE Staging_Routes (
    route_id VARCHAR(60),
    agency_id INTEGER,
    route_short_name VARCHAR(50),
    route_long_name VARCHAR(250),
    route_type INTEGER
);


-- Enthält die Definitionen der einzelnen Routing Types entsprechend der Dokumentation.
-- In einem richtigen DW würde es sich anbieten, die Transportart als eigene Dimension bzw. Hierarchie-Stufe einer Dimension zu modellieren.
-- Mapping File nutzt als Grundlage Google Doku (https://developers.google.com/transit/gtfs/reference/extended-route-types?hl=de).
-- File wurde von KI generiert.
CREATE TABLE Staging_GTFS_Extended_Type_Mapping (
    route_type INTEGER,
    main_category_desc VARCHAR(20),
    sub_category_desc VARCHAR(50)
);

CREATE TABLE Staging_Agencies (
    agency_id INTEGER,
    agency_name VARCHAR(100)
);