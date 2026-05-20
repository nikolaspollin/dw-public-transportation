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
    location_name          VARCHAR(50), -- Je nach Stufe bspw. "Deutschland", "Kelheim, Landkreis"
    age_group_name         VARCHAR(40),
    total_population       INTEGER,
    male_population        INTEGER,
    female_population      INTEGER
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
    RGB_NAME VARCHAR(40),
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
    DHID VARCHAR(30), -- Deutschlandweit eindeutige Haltestellen-ID
    Parent VARCHAR(30), -- Enthält DHID des Parents
    Name VARCHAR(80),
    Latitude VARCHAR(15), -- Nachkommastellen per Komma statt Punkt getrennt (daher String)
    Longitude VARCHAR(15),
    MunicipalityCode VARCHAR(8), -- AGS
    Municipality VARCHAR(60), -- Gemeindename
    DistrictCode VARCHAR(5),
    District VARCHAR(60),
    Description VARCHAR(100),
    Authority VARCHAR(30),
    DelfiName VARCHAR(80),
    SEV VARCHAR(15)
);


-- GTFS Hauptdaten

-- stop_code ignoriert, da Wert nie gefüllt wird
CREATE TABLE Staging_Stops (
    stop_id VARCHAR(30), -- Identisch zu DHID in Staging_Extended_Stops
    stop_name VARCHAR(80), -- Wesentlicher Name
    stop_description VARCHAR(100), -- Zusätzliche beschreibende Informationen
    stop_lat VARCHAR(15), -- Längengrad, gespeichert als String, mit Punt als Nachkommastellen-Trennsymbol
    stop_lon VARCHAR(15),
    location_type INTEGER, -- Enum Wert für Art der Haltestelle
    parent_station VARCHAR(30), -- Enthält stop_id bzw. DHID des Parents (Leeres Feld, falls kein Parent existiert)
    wheelchair_boarding INTEGER, -- Enum Wert
    platform_code VARCHAR(30)
);

-- TODO stops.txt schon abgearbeitet, sonst fehlen noch alle restlichen GTFS Haupt-Tables
--  Alle anderen Daten haben schon fertige Tables